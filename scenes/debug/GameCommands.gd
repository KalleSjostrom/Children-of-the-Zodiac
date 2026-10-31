class_name GameCommands
extends RefCounted
## The game's commands for the debug console (COTZ-006, DebugConsole):
## places (goto, exits, teleport, savepoint, boss, cheater), the party and
## battles (heal, god, kill, skip), the world (map, roads, noenemies) and
## development (status, trigger, difficulty, save, padlost, emotion). They replace the
## developer Cheater, whose menu the "cheater" command still opens.
##
## Jumps go through Organizer.jump_to, as the Cheater's did. A position on a
## labyrinth floor (boss) is handed to the labyrinth the way a save's is
## (Load.labyrinthPosition). Labyrinth facts (save points, bosses, the ways
## between nodes) are read from the .map files.

## God mode: the party takes no damage from enemies (EnemyLogic reads it).
static var god := false

## The instance whose methods the registered commands call.
static var _instance: GameCommands

const ROAD_ZONES := {"west": 0, "east": 1, "north": 2}
const SKIPPABLE: PackedStringArray = ["battle", "cutscene"]
const SAVE_SLOTS := {"1": "Slot 1", "2": "Slot 2", "3": "Slot 3", "autosave": SaveSlots.AUTOSAVE}
const LEVELS := {"easy": Difficulty.Level.EASY, "medium": Difficulty.Level.MEDIUM,
	"original": Difficulty.Level.ORIGINAL}
## The emotion bubbles, in Sprite's order (res/Emotions/<name>.png).
const EMOTIONS: PackedStringArray = ["exclamation", "question", "questionEx", "dot", "aye", "no",
	"zzz", "hihi", "ha1", "ha2"]

## The rounds "cast next" has not played yet (--casts=, see _cast).
var _casts := PackedStringArray()
var _casts_read := false
## Floor (Organizer.convert) -> {"floor", "save": bool, "boss": [address,
## name] or [], "ways": Array of [from, direction, to]}, from the .map files.
var _floors := {}


static func register(commands: DebugCommands) -> void:
	_instance = GameCommands.new()
	_instance._register(commands)


func _register(c: DebugCommands) -> void:
	c.group("Places")
	c.add("goto", "Goes to a place: a village, a labyrinth door, a story (main.bank), a world map node (land<node>)", _goto, [
		DebugCommands.arg("place", _place_names).to_end().loose()])
	c.add("exits", "Lists the doors of this labyrinth floor and where they lead", _exits)
	c.add("teleport", "Goes to a door of this labyrinth floor (exits lists them)", _teleport, [
		DebugCommands.arg("door", _door_names)])
	c.add("savepoint", "Goes to the save point of this labyrinth: this floor's, else another floor's", _savepoint)
	c.add("boss", "Goes next to the boss of this labyrinth or of the one given, facing it (step forward to fight)", _boss, [
		DebugCommands.opt("labyrinth", _boss_areas)])
	c.add("cheater", "Opens the old developer menu (places, stories, stores)", _cheater)
	c.group("Party and battle")
	c.add("heal", "Heals party members or enemies in a battle; a negative amount hurts", _heal, [
		DebugCommands.arg("amount", Callable(), "hp, negative hurts"),
		DebugCommands.opt("target", _heal_targets, "party if left out; all, enemies or a name").loose()])
	c.add("god", "The party takes no damage", _god, [DebugCommands.switch()])
	c.add("kill", "Kills the enemies of the battle, bosses too: the battle is won", _kill)
	c.add("skip", "Leaves the battle (no experience or gold, a boss lives on) or runs the cutscene to its end", _skip, [
		DebugCommands.opt("what", func() -> PackedStringArray: return SKIPPABLE, "the battle or cutscene going on if left out")])
	c.add("cast", "Plays cards on a party member's turn, as if they were in the weapon: support cards on the party, the others on the enemies", _cast, [
		DebugCommands.arg("cards", _card_names, "<card>[:<level>][:all] ..., e.g. Fire:3 Cure:2:all").to_end().loose()])
	c.group("World")
	c.add("map", "Shows the whole map of this labyrinth floor", _map)
	c.add("roads", "Opens the roads of the world map", _roads, [
		DebugCommands.opt("continent", func() -> PackedStringArray: return PackedStringArray(ROAD_ZONES.keys()), "all if left out")])
	c.add("noenemies", "No random battles in labyrinths", _noenemies, [DebugCommands.switch()])
	c.group("Game")
	c.add("status", "Where the game is: mode, place, labyrinth position, difficulty", _status)
	c.add("trigger", "Shows or sets a Database status (trigger)", _trigger, [
		DebugCommands.arg("name", Callable()), DebugCommands.opt("value", Callable())])
	c.add("difficulty", "Shows or sets the difficulty (either way, unlike the menu)", _difficulty, [
		DebugCommands.opt("level", func() -> PackedStringArray: return PackedStringArray(LEVELS.keys()))])
	c.add("give", "Gives the party a key item or a piece of equipment (weapon, shield, armour), as a chest gives one, number times", _give, [
		DebugCommands.arg("what", func() -> PackedStringArray: return PackedStringArray(["item", "equipment"])),
		DebugCommands.arg("name", _equipment_names, "_ for a space; any name for an item").loose(),
		DebugCommands.opt("number", Callable(), "1 if left out")])
	c.add("save", "Saves the game here, wherever this is", _save, [
		DebugCommands.arg("slot", func() -> PackedStringArray: return PackedStringArray(SAVE_SLOTS.keys()))])
	c.add("padlost", "Shows the game pad lost overlay, as if a game pad were unplugged, until its menu is answered", _padlost, [
		DebugCommands.switch()])
	c.add("emotion", "Shows an emotion bubble over a party member or villager of this village, as a cutscene sets one (shake: shaking); off hides it", _emotion, [
		DebugCommands.arg("who", _emotion_targets, "a name, _ for a space"),
		DebugCommands.arg("emotion", func() -> PackedStringArray: return EMOTIONS + PackedStringArray(["off"])),
		DebugCommands.opt("shake", func() -> PackedStringArray: return PackedStringArray(["shake"]))])


# --- The game ---

static func _organizer() -> Organizer:
	return Organizer.getOrganizer()


static func _mode() -> GameMode:
	var o := _organizer()
	return null if o == null else o.getCurrentMode()


static func _labyrinth() -> Labyrinth:
	var gm := _mode()
	return gm as Labyrinth


## The battle being fought in the labyrinth or a story's battle area, or null.
static func _battle() -> Battle:
	var area := _mode() as BossBattleArea
	if area != null:
		return null if area.bm == null else area.bm.battle
	var lab := _labyrinth()
	if lab == null or not lab.runSubGameMode or not (lab.labDrawable is BattleManager):
		return null
	return lab.labDrawable.battle


static func _ready_for_jump() -> DebugCommands.Result:
	var gm := _mode()
	if gm != null and gm.isLoading():
		return DebugCommands.fail("Not while loading")
	return null


## The main.bank place to enter a labyrinth floor at: its "-save" place,
## else any place on it.
func _place_on_floor(floor: String) -> String:
	var o := _organizer()
	if o.getInformationFor(floor + "-save") != null:
		return floor + "-save"
	var map := Organizer.convert(floor + ".map")
	for key in o.mainInfo:
		var info: Dictionary = o.mainInfo[key]
		if Organizer.convert(str(info.get("map", ""))) == map:
			return str(info.get("name", key))
	return ""


## What the .map file of a floor says (see _floors).
func _floor_data(floor: String) -> Dictionary:
	var key := Organizer.convert(floor)
	if _floors.has(key):
		return _floors[key]
	var data := {"floor": floor, "save": false, "boss": [], "ways": []}
	var text := GameResourceLoader.readText(Values.LabyrinthMaps + floor + ".map")
	for raw in text.split("\n"):
		var words := raw.strip_edges().split(" ", false)
		if words.size() >= 4 and words[0] == "dir":
			data.ways.append([int(words[1]), int(words[2]), int(words[3])])
		elif words.size() >= 2 and words[0] == "inv" and words[1] == "save":
			data.save = true
		elif words.size() >= 3 and words[0] == "inv" and words[1] == "boss":
			data.boss = [int(words[2]), words[words.size() - 1]]
	_floors[key] = data
	return data


## Every labyrinth floor ("Area--Floor"), from the .map files.
func _all_floors() -> PackedStringArray:
	var floors := PackedStringArray()
	for file in GameResourceLoader.listFiles(Values.LabyrinthMaps):
		if file.ends_with(".map") and file.contains("--"):
			floors.append(file.get_basename())
	return floors


static func _area_of(floor: String) -> String:
	return floor.split("--")[0]


## A node next to the given one and the direction from it towards it
## ([address, direction]), from the floor's ways ("dir a d b": b is a's
## neighbour in direction d + 2, a is b's in direction d).
static func _next_to(ways: Array, address: int) -> Array:
	for way in ways:
		if way[2] == address:
			return [way[0], Values.getCounterAngle(way[1])]
		if way[0] == address:
			return [way[2], way[1]]
	return []


# --- Places ---

## The places of main.bank and the world map's nodes ("land<node>").
func _place_names() -> PackedStringArray:
	var names := PackedStringArray()
	var o := _organizer()
	if o == null:
		return names
	for key in o.mainInfo:
		names.append(str(o.mainInfo[key].get("name", key)))
	for node in LandscapeLoader._getPlaceMap():
		names.append("land" + str(node))
	return names


func _goto(args: PackedStringArray) -> DebugCommands.Result:
	var not_now := _ready_for_jump()
	if not_now != null:
		return not_now
	if _organizer().getInformationFor(args[0]) == null:
		return DebugCommands.fail("No place %s" % args[0])
	_organizer().jump_to(args[0])
	return DebugCommands.done("Going to %s" % args[0])


## The doors of the current floor that main.bank has a place for ("mark0").
func _door_names() -> PackedStringArray:
	var names := PackedStringArray()
	var lab := _labyrinth()
	if lab == null:
		return names
	var prefix := Organizer.convert(lab.getName()) + "-mark"
	for key in _organizer().mainInfo:
		if String(key).begins_with(prefix):
			names.append("mark" + String(key).substr(prefix.length()))
	names.sort()
	return names


func _exits(_args: PackedStringArray) -> DebugCommands.Result:
	var lab := _labyrinth()
	if lab == null:
		return DebugCommands.fail("Not in a labyrinth")
	var leads := {}
	for key in lab.graph.map.getInventories():
		var inv = lab.graph.map.getInventory(key)
		if inv is InventoryDoor:
			leads[inv.index] = ", ".join(inv.nextPlaces)
		elif inv is HinderDoor:
			leads[inv.index] = str(inv.nextPlace)
	var lines := PackedStringArray()
	for door in _door_names():
		var index := int(door.substr(4))
		lines.append("%s  -> %s" % [door.rpad(7), leads.get(index, "?")])
	if lines.is_empty():
		return DebugCommands.done("No doors on %s" % lab.getName())
	return DebugCommands.done("\n".join(lines))


func _teleport(args: PackedStringArray) -> DebugCommands.Result:
	var lab := _labyrinth()
	if lab == null:
		return DebugCommands.fail("Not in a labyrinth (goto goes anywhere)")
	var not_now := _ready_for_jump()
	if not_now != null:
		return not_now
	var place: String = lab.getName() + "-" + args[0]
	_organizer().jump_to(place)
	return DebugCommands.done("Going to %s" % place)


func _savepoint(_args: PackedStringArray) -> DebugCommands.Result:
	var lab := _labyrinth()
	if lab == null:
		return DebugCommands.fail("Not in a labyrinth")
	var not_now := _ready_for_jump()
	if not_now != null:
		return not_now
	var floors := PackedStringArray([lab.getName()])
	for floor in _all_floors():
		if _area_of(floor) == _area_of(lab.getName()) and floor != lab.getName():
			floors.append(floor)
	for floor in floors:
		if _floor_data(floor).save:
			var place := floor + "-save"
			_organizer().jump_to(place)
			return DebugCommands.done("Going to %s" % place)
	return DebugCommands.fail("No save point in %s" % _area_of(lab.getName()))


## The labyrinths with a boss, spaces as "_".
func _boss_areas() -> PackedStringArray:
	var areas := PackedStringArray()
	for floor in _all_floors():
		var area := _area_of(floor).replace(" ", "_")
		if not areas.has(area) and not _floor_data(floor).boss.is_empty():
			areas.append(area)
	return areas


func _boss(args: PackedStringArray) -> DebugCommands.Result:
	var area := ""
	if not args.is_empty():
		area = args[0].replace("_", " ")
	elif _labyrinth() != null:
		area = _area_of(_labyrinth().getName())
	else:
		return DebugCommands.fail("Not in a labyrinth; name one (%s)" % ", ".join(_boss_areas()))
	var not_now := _ready_for_jump()
	if not_now != null:
		return not_now
	for floor in _all_floors():
		if Organizer.convert(_area_of(floor)) != Organizer.convert(area):
			continue
		var data := _floor_data(floor)
		if data.boss.is_empty():
			continue
		var spot := _next_to(data.ways, data.boss[0])
		var place := _place_on_floor(floor)
		if spot.is_empty() or place == "":
			return DebugCommands.fail("Cannot find a way to the boss on %s" % floor)
		Load.labyrinthPosition = [floor, spot[0], spot[1]]
		_organizer().jump_to(place)
		return DebugCommands.done("Going next to %s on %s; step forward to fight" % [data.boss[1], floor])
	return DebugCommands.fail("No boss in %s" % area)


func _cheater(_args: PackedStringArray) -> DebugCommands.Result:
	var not_now := _ready_for_jump()
	if not_now != null:
		return not_now
	_organizer().open_cheater()
	return DebugCommands.done("")


# --- Party and battle ---

## The enemies of the battle by name (lower case, "_" for spaces, a number
## after the second of a kind).
static func _enemies_by_name() -> Dictionary:
	var named := {}
	var battle := _battle()
	if battle == null:
		return named
	for enemy in battle.enemies:
		var base: String = str(enemy.getName()).to_lower().replace(" ", "_")
		var name := base
		var n := 2
		while named.has(name):
			name = base + str(n)
			n += 1
		named[name] = enemy
	return named


static func _party_by_name() -> Dictionary:
	var named := {}
	for c in Load.getCharacters():
		named[str(c.getName()).to_lower()] = c
	return named


func _heal_targets() -> PackedStringArray:
	var names := PackedStringArray(["party", "all"])
	names.append_array(PackedStringArray(_party_by_name().keys()))
	var enemies := _enemies_by_name()
	if not enemies.is_empty():
		names.append("enemies")
		names.append_array(PackedStringArray(enemies.keys()))
	return names


func _heal(args: PackedStringArray) -> DebugCommands.Result:
	if not args[0].is_valid_int():
		return DebugCommands.fail("The amount is a number of hp: %s" % args[0])
	if not Load.hasLoaded():
		return DebugCommands.fail("No game loaded")
	var amount := int(args[0])
	var target := "party" if args.size() < 2 else args[1].to_lower()
	var party := _party_by_name()
	var enemies := _enemies_by_name()
	var creatures: Array = []
	match target:
		"party":
			creatures = party.values()
		"enemies":
			creatures = enemies.values()
		"all":
			creatures = party.values() + enemies.values()
		_:
			if party.has(target):
				creatures = [party[target]]
			elif enemies.has(target):
				creatures = [enemies[target]]
			else:
				return DebugCommands.fail("No one called %s (%s)" % [target, ", ".join(_heal_targets())])
	if creatures.is_empty():
		return DebugCommands.fail("No %s here" % target)
	var lines := PackedStringArray()
	for creature in creatures:
		_change_hp(creature, amount)
		lines.append("%s %d/%d" % [creature.getName(), creature.getAttribute(Creature.HP),
				creature.getAttribute(Creature.MAX_HP)])
	var battle := _battle()
	if battle != null:
		battle.update_ = true
	return DebugCommands.done(", ".join(lines))


## Heals (a dead party member comes back) or, with a negative amount, hurts.
static func _change_hp(creature, amount: int) -> void:
	if amount >= 0:
		if not creature.isAlive() and creature is Character:
			creature.cureFromDead()
		creature.cure(amount)
	else:
		creature.damage(-amount)


func _god(args: PackedStringArray) -> DebugCommands.Result:
	god = DebugCommands.flip(args, god)
	return DebugCommands.done("God mode %s" % DebugCommands.on_off(god))


## Kills the enemies and ends the battle the way a killing blow does (spoils,
## a boss's last words, its next place). On a party member's turn the cards
## in the slots are not played.
func _kill(_args: PackedStringArray) -> DebugCommands.Result:
	var battle := _battle()
	if battle == null:
		return DebugCommands.fail("Not in a battle")
	var mode: int = battle.getMode()
	if mode != BattleManager.IDLING and mode != BattleManager.BATTLING:
		return DebugCommands.fail("Not now: on a party member's turn or while the bars fill")
	var killed := PackedStringArray()
	for enemy in battle.enemies:
		if enemy.isAlive():
			enemy.damage(enemy.getAttribute(Creature.HP))
			killed.append(enemy.getName())
	battle.glEnemies.checkDead()
	battle.glEnemies.check()
	battle.killMonster()
	if mode == BattleManager.BATTLING:
		# Battle.finishRound without the attack.
		battle.currentDeck.finish()
		battle.clock.hide()
		battle.legend.hide()
		battle.clock.finish()
		battle.hand.hide()
		battle.glCharacters.setTarget(-1, false)
	battle.checkIfEnemiesAreDead(mode == BattleManager.BATTLING)
	return DebugCommands.done("Killed %s" % ", ".join(killed))


## The cards cast can play: short name (lowercase) -> Java class name.
static func _card_classes() -> Dictionary:
	var classes := {}
	for java_name: String in ClassRegistry.JAVA_TO_PATH:
		var parts := java_name.split(".")
		if parts.size() == 3 and parts[0] == "cards" and parts[2] not in ["Magic", "PowerMagic", "Elements"]:
			classes[parts[2].to_lower()] = java_name
	return classes


func _card_names() -> PackedStringArray:
	var names := PackedStringArray()
	for java_name: String in _card_classes().values():
		names.append(java_name.get_slice(".", 2))
	return names


## Battle.finishRound with the given cards instead of the weapon's: the
## same animation (BattleAnimation: the card effects, the damage, the waits)
## on the first living enemy, or on the attacker for support cards.
## "cast next" plays the next round of the game argument --casts=<round>/
## <round>/... (dev, parity cases: rounds of <card>[:<level>][:all] joined
## by "+").
func _cast(args: PackedStringArray) -> DebugCommands.Result:
	var battle := _battle()
	if battle == null:
		return DebugCommands.fail("Not in a battle")
	if battle.getMode() != BattleManager.BATTLING:
		return DebugCommands.fail("Not now: on a party member's turn")
	var specs := " ".join(args)
	if specs == "next":
		if not _casts_read:
			_casts_read = true
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--casts="):
					_casts = a.trim_prefix("--casts=").split("/", false)
		if _casts.is_empty():
			return DebugCommands.fail("No more rounds in --casts=")
		specs = _casts[0].replace("+", " ")
		_casts.remove_at(0)
	var classes := _card_classes()
	var cards: Array = []
	for spec in specs.split(" ", false):
		var parts := spec.split(":")
		var java_name: String = classes.get(parts[0].to_lower(), "")
		if java_name == "":
			return DebugCommands.fail("No card called %s" % parts[0])
		var level := 1 if parts.size() < 2 else int(parts[1])
		if level < 1 or level > 3:
			return DebugCommands.fail("The level is 1, 2 or 3: %s" % spec)
		var gl_card := GLCard.new()
		gl_card.setCard(Card.createCard(java_name, level, parts.size() > 2 and parts[2] == "all"))
		cards.append(gl_card)
	if cards.is_empty():
		return DebugCommands.fail("No cards")
	var support: bool = cards[0].getCard().getType() == AbstractCard.SUPPORT
	var team: Array = battle.hand.party if support else battle.hand.enemies
	var target: int = maxi(team.find(battle.attacker), 0) if support else 0
	while not support and target < team.size() - 1 and not team[target].isAlive():
		target += 1
	battle.hand.setPos(support, target)
	battle.currentDeck.finish()
	battle.calcDamage(cards)
	battle.clock.hide()
	battle.legend.hide()
	battle.clock.finish()
	battle.hand.hide()
	battle.glCharacters.setTarget(-1, false)
	battle.animate.init(cards, target, team, battle.monster, battle.attacker, battle.glCharacters)
	battle.mode = BattleManager.ANIMATE
	var names := PackedStringArray()
	for gl_card in cards:
		names.append("%s %d" % [gl_card.getCard().getName(), gl_card.getCard().getLevel()])
	return DebugCommands.done("%s casts %s" % [battle.attacker.getName(), ", ".join(names)])


func _skip(args: PackedStringArray) -> DebugCommands.Result:
	var what := "" if args.is_empty() else args[0]
	if what == "battle" or (what == "" and _battle() != null):
		return _skip_battle()
	if what == "cutscene" or (what == "" and _mode() is VillageStory):
		return _skip_cutscene()
	return DebugCommands.fail("Neither in a battle nor in a cutscene")


## Leaves the battle the way fleeing does (Battle.flee).
func _skip_battle() -> DebugCommands.Result:
	var battle := _battle()
	if battle == null:
		return DebugCommands.fail("Not in a battle")
	if _mode() is BossBattleArea:
		return DebugCommands.fail("This battle has no way back (kill wins it)")
	var mode: int = battle.getMode()
	if mode in [BattleManager.EXIT, BattleManager.EXIT_TO_NEXT, BattleManager.GAME_OVER]:
		return DebugCommands.fail("The battle is ending")
	if mode == BattleManager.TALKING:
		battle.manager.setDialog(null)
	battle.hide()
	battle.setMode(BattleManager.EXIT)
	return DebugCommands.done("Leaving the battle")


## Runs the cutscene to its end, answering its dialogs (Main.skip_cutscene),
## so its triggers, gifts and the party's places are as after watching it.
func _skip_cutscene() -> DebugCommands.Result:
	var story := _mode() as VillageStory
	if story == null:
		return DebugCommands.fail("Not in a cutscene")
	Main.instance.skip_cutscene(story)
	return DebugCommands.done("Skipping %s" % story.getName())


# --- World ---

func _map(_args: PackedStringArray) -> DebugCommands.Result:
	var lab := _labyrinth()
	if lab == null:
		return DebugCommands.fail("Not in a labyrinth")
	var nodes = lab.graph.map.getNodes()
	for key in nodes:
		nodes[key].setVisitedAndSeen(true, true)
	return DebugCommands.done("%s: all %d nodes shown" % [lab.getName(), nodes.size()])


func _roads(args: PackedStringArray) -> DebugCommands.Result:
	var zones: Array = ROAD_ZONES.values() if args.is_empty() else [ROAD_ZONES[args[0]]]
	var opened := 0
	for land in zones:
		for address in _road_addresses("world%d.map" % land):
			Database.addStatus("road%d-%d" % [land, address], 1)
			opened += 1
	var gm := _mode()
	if gm is Landscape:
		gm.openRoads(LandscapeLoader.checkPlace(gm.getName()))
	return DebugCommands.done("Opened %d roads" % opened)


## The addresses of the roads of a world map file, in file order: its
## scene's roads (WorldMapRoad), or its road lines with --legacy=world_map.
static func _road_addresses(file: String) -> Array[int]:
	var out: Array[int] = []
	var path := WorldMapScene.path_for(file)
	if path != "" and not Main.is_legacy("world_map"):
		var scene: WorldMapScene = (load(path) as PackedScene).instantiate()
		for road: WorldMapRoad in scene.get_node("Roads").get_children():
			out.append(road.address)
		scene.free()
		return out
	for raw in GameResourceLoader.readText(Values.LandscapeMaps + file).split("\n"):
		var words := raw.strip_edges().split(" ", false)
		if words.size() >= 2 and words[0] == "road" and words[1].is_valid_int():
			out.append(words[1].to_int())
	return out


func _noenemies(args: PackedStringArray) -> DebugCommands.Result:
	Main.no_encounters = DebugCommands.flip(args, Main.no_encounters)
	var lab := _labyrinth()
	if lab != null:
		lab.noEncounters = Main.no_encounters
	return DebugCommands.done("No random battles %s" % DebugCommands.on_off(Main.no_encounters))


# --- Game ---

## The game pad lost overlay (GameCore.testDraw) without a game pad: its menu
## ("Try to reconnect", "Use keyboard instead") ends it, as with a pad.
func _padlost(args: PackedStringArray) -> DebugCommands.Result:
	var input := GameCore.inputManager
	input.lost_simulated = DebugCommands.flip(args, input.lost_simulated)
	return DebugCommands.done("Game pad lost %s" % DebugCommands.on_off(input.lost_simulated))


## The party members and villagers of the current village, by name.
func _village_sprites() -> Dictionary:
	var village := _mode() as Village
	var named := {}
	if village != null:
		for s in village.sprites.values():
			if s.getName() != null and str(s.getName()) != "":
				named[str(s.getName()).replace(" ", "_")] = s
	return named


func _emotion_targets() -> PackedStringArray:
	return PackedStringArray(_village_sprites().keys())


## An emotion bubble in a village (Sprite.setEmotion, which only cutscenes
## call): the village draws it over the sprite until it is hidden.
func _emotion(args: PackedStringArray) -> DebugCommands.Result:
	if not (_mode() is Village):
		return DebugCommands.fail("Not in a village")
	var target = null
	for name: String in _village_sprites():
		if name.to_lower() == args[0].to_lower():
			target = _village_sprites()[name]
	if target == null:
		return DebugCommands.fail("No one called %s here" % args[0])
	if args[1] == "off":
		target.setEmotion(false, -1, false)
		return DebugCommands.done("%s: no emotion" % args[0])
	var emotion := EMOTIONS.find(args[1])
	if emotion == -1:
		return DebugCommands.fail("No emotion %s" % args[1])
	target.setEmotion(true, emotion, args.size() > 2 and args[2] == "shake")
	return DebugCommands.done("%s: %s" % [args[0], args[1]])


func _status(_args: PackedStringArray) -> DebugCommands.Result:
	var gm := _mode()
	if gm == null:
		return DebugCommands.done("No game mode")
	var lines := PackedStringArray([
		"Mode: %s%s" % [ClassRegistry.getClassName(gm), " (loading)" if gm.isLoading() else ""],
		"Place: %s" % _organizer().nextPlace])
	var lab := _labyrinth()
	if lab != null and lab.currentNode != null:
		lines.append("Labyrinth: %s, node %d, direction %d" % [lab.getName(), lab.currentNode.getAddress(), lab.dir])
	if _battle() != null:
		lines.append("Battle: %s" % ", ".join(PackedStringArray(_enemies_by_name().keys())))
	lines.append("Difficulty: %s, god mode %s" % [Difficulty.name_of(Difficulty.current()), DebugCommands.on_off(god)])
	return DebugCommands.done("\n".join(lines))


func _trigger(args: PackedStringArray) -> DebugCommands.Result:
	var name := Organizer.convert(args[0])
	if args.size() > 1:
		if not args[1].is_valid_int():
			return DebugCommands.fail("The value is a number: %s" % args[1])
		Database.addStatus(name, int(args[1]))
	return DebugCommands.done("%s = %d" % [name, Database.getStatusFor(name)])


func _difficulty(args: PackedStringArray) -> DebugCommands.Result:
	if not args.is_empty():
		Database.addStatus(Difficulty.STATUS, LEVELS[args[0]])
	return DebugCommands.done("Difficulty: %s" % Difficulty.name_of(Difficulty.current()))


## Dev only (phase 4.2's menu cases): more key items and equipment than the
## shipped saves have, for the menu's lists that scroll in their bounding
## box ("Key Items", the equip page's lists) and their "(n)" numbers.
func _give(args: PackedStringArray) -> DebugCommands.Result:
	if not Load.hasLoaded():
		return DebugCommands.fail("No game loaded")
	var name := args[1].replace("_", " ")
	var number := 1
	if args.size() > 2:
		if not args[2].is_valid_int() or int(args[2]) < 1:
			return DebugCommands.fail("The number is a whole number from 1: %s" % args[2])
		number = int(args[2])
	if args[0] == "item":
		Load.getPartyItems().addItem(name, number)
		return DebugCommands.done("%s: %d more" % [name, number])
	if not EquipmentFactory._getFactory().bank.has(name):
		return DebugCommands.fail("No equipment called %s" % name)
	var ae = EquipmentFactory.getEquipment(name)
	for i in number:
		Load.addEquipment(ae)
	return DebugCommands.done("%s: %d owned" % [name, ae.getNumber()])


## The names of the equipment.bank, with _ for a space (give's completion).
static func _equipment_names() -> PackedStringArray:
	var names := PackedStringArray()
	for key in EquipmentFactory._getFactory().bank:
		names.append(str(key).replace(" ", "_"))
	names.sort()
	return names


func _save(args: PackedStringArray) -> DebugCommands.Result:
	var gm := _mode()
	if not (gm is Labyrinth or gm is Village or gm is Landscape or gm is AirLandscape):
		return DebugCommands.fail("Only in a labyrinth, a village, on the world map or the airship")
	var slot: String = SAVE_SLOTS[args[0]]
	Save.save_game_in(slot, gm)
	return DebugCommands.done("Saved to %s (%s)" % [slot, Save.place_for(gm)])
