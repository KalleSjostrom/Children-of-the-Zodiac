class_name Load
extends AbstractMapLoader
## Port of factories.Load: loads the game from a save file and holds the
## party (characters, equipment, items, time).
##
## Save files: "Start.sav" is read from Values.Banks (shipped, read only).
## Other saves are read from Save.saveDir() (user://saves/) when they exist
## there, otherwise from Values.lib and then Values.Banks via
## GameResourceLoader (the shipped slot saves live in maps/Banks/).

static var characters = []
static var equipments = {}
static var time = null
static var partyItems = null
static var startl = null
static var exCharacter = []
static var saveSlotName = "Start"
static var charDeck: bool = false
static var hasLoaded_: bool = false
## Port addition (COTZ-005): the "labpos" of the loaded save ([floor,
## address, direction]), until the labyrinth takes it (take_labyrinth_position).
static var labyrinthPosition: Array = []
var currentMap = null
var currentCharacter = null


func _init() -> void:
	pass # Empty constructor.


static func reset():
	characters = []
	equipments = {}
	exCharacter = []

	time = null
	partyItems = null
	var name: String = Values.BattleImages + "stroke.png"
	ImageHandler.addPermanentlyLoadNow(name)
	startl = null
	Visited.getVisited().clearVisited()
	saveSlotName = "Start"
	charDeck = false
	labyrinthPosition = []


## Java overloads: loadGame(String save) and loadGame() (uses the slot set
## by setSlot()).
static func loadGame(save = null):
	if save == null:
		loadGame(saveSlotName)
		return
	reset()
	Organizer.reset()
	EnemyFactory.getEnemyFactory()
	AbstractPage.getImages()
	Load.new().parseFile(str(save) + ".sav")
	ParticleSystem.load()
	Flame2Emitter.getImage()
	hasLoaded_ = true


## Java: protected void parseFile(String filename). When filename is "" the
## file name is in path.
func parseFile(path: String, filename: String = ""):
	if filename != "":
		super.parseFile(path, filename)
		return
	filename = path
	if filename.to_lower() == "start.sav":
		super.parseFile(Values.Banks, filename)
		return
	if filename.is_absolute_path() and FileAccess.file_exists(filename):
		# Dev: --load=<path to a .sav, without the extension> (ticket saves).
		_parseUserFile(filename)
		return
	var userPath: String = Save.saveDir() + filename
	if FileAccess.file_exists(userPath):
		_parseUserFile(userPath)
	elif GameResourceLoader.fileExists(Values.lib + filename):
		super.parseFile(Values.lib, filename)
	else:
		super.parseFile(Values.Banks, filename)


## Parses a save file written by Save (under user://), line by line exactly
## like AbstractMapLoader.parseFile.
func _parseUserFile(userPath: String) -> void:
	var reader = GameResourceLoader.BufferedReader.new(FileAccess.get_file_as_string(userPath))
	var line = ""
	lineCount = 0
	Parser.reset()
	while line != null:
		line = reader.readLine()
		lineCount += 1
		if line != null:
			line = String(line).strip_edges()
			if line != "" and not line.begins_with("#"):
				parseLine(line)
	reader.close()


## Checks whether or not a new game, or a saved game, has been loaded.
static func hasLoaded():
	return hasLoaded_


## Gets the list of characters as a (new) list of creatures.
static func getCharactersAsCreatures():
	var list: Array = []
	for i in range(characters.size()):
		list.append(characters[i])
	return list


static func getCharacters():
	return characters


## Gets the list of extra characters that can be added to the party.
static func getExCharacters():
	return exCharacter


static func getPartyItems():
	return partyItems


static func getStartLocation():
	return startl


## Gets the equipment map (name -> equipment) of the party's backpack.
static func getEquipments():
	return equipments


static func getTime():
	return time


static func getCharacterByName(name):
	var index: int = getCharacterIndex(name)
	return null if index == -1 else characters[index]


static func getCharacterWithForWhom(forWhom):
	for i in range(characters.size()):
		var c = characters[i]
		if c.getIndex() == forWhom:
			return c
	return null


static func isCharacterActive(forWhom):
	var c = Values.characters.getCharacter(forWhom)
	return getCharacterByName(c.getName()) != null


static func getCharacterIndex(name):
	for i in range(characters.size()):
		if characters[i].getName() == name:
			return i
	return -1


## Adds the given equipment to the party's backpack.
static func addEquipment(equipment):
	var name = equipment.getName()
	var he = equipments.get(name)
	if he != null:
		he.addNumber()
	else:
		equipments[equipment.getName()] = equipment


static func setEquipment(equipment, number):
	equipment.setNumber(number)
	equipments[equipment.getName()] = equipment


## Removes one of the equipment with the given name.
static func removeEquipment(name):
	var he = equipments.get(name)
	if he != null:
		he.subtractNumber()
		if he.getNumber() == 0:
			equipments.erase(name)


static func convertArmorListToAbstractRemoveEquipped():
	return convertListToAbstractRemoveEquipped(Armor)


static func convertWeaponListToAbstractRemoveEquipped():
	return convertListToAbstractRemoveEquipped(Weapon)


static func convertShieldListToAbstractRemoveEquipped():
	return convertListToAbstractRemoveEquipped(Shield)


## Gets all unequipped equipment that are instances of the given class
## (a script such as Armor, Weapon or Shield).
static func convertListToAbstractRemoveEquipped(equipClass):
	var ae: Array = []
	for n in equipments:
		var eq = equipments.get(n)
		if not eq.isEquiped() and is_instance_of(eq, equipClass):
			ae.append(eq)
	return ae


## Gets the armors that the given character (Values.characters) can choose from.
static func getArmorFor(character):
	return getEquipmentFor(character, Armor)


static func getWeaponFor(character):
	return getEquipmentFor(character, Weapon)


## Java: getLeftHandFor(Values.characters character).
static func getLeftHandForStatic(character):
	return getEquipmentFor(character, Shield)


## Gets the unequipped equipment of exactly the given class that the given
## character can equip.
static func getEquipmentFor(character, equipClass):
	var ae: Array = []
	for n in equipments:
		var equip = equipments.get(n)
		if equip.get_script() == equipClass and equip.isFor(character):
			if not equip.isEquiped():
				ae.append(equip)
	return ae


static func setSlot(saveSlot):
	saveSlotName = saveSlot


## The node address and direction the loaded game was saved at on the given
## labyrinth floor ([address, direction]), once; [] for another floor or
## when it has been taken (COTZ-005).
static func take_labyrinth_position(floor: String) -> Array:
	if labyrinthPosition.size() != 3:
		return []
	var pos: Array = labyrinthPosition
	labyrinthPosition = []
	if Organizer.convert(pos[0]) != Organizer.convert(floor):
		return []
	return [pos[1], pos[2]]


func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "start":
		startl = Organizer.convertKeepCase(tokenizer.nextToken())
	elif command == "labpos":
		var floor: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var address: int = J.parseInt(tokenizer.nextToken())
		labyrinthPosition = [floor, address, J.parseInt(tokenizer.nextToken())]
	elif command == "visitedNodes":
		var zone: String = tokenizer.nextToken()
		Visited.getVisited().getVnodes(zone).append(
				Organizer.convertKeepCase(tokenizer.nextToken()))
	elif command == "visitedRoads":
		var zone: String = tokenizer.nextToken()
		Visited.getVisited().getVroads(zone).append(J.parseInt(tokenizer.nextToken()))
	elif command == "character":
		currentCharacter = createCharacter(tokenizer)
		currentCharacter.repairLevel()
		if _isLoaded(currentCharacter.getName()):
			return
		var index: int = Values.characters.getCharacter(currentCharacter.getName()).getIndex()
		if index <= characters.size():
			characters.insert(index, currentCharacter)
		else:
			characters.append(currentCharacter)
	elif command == "exCharacter":
		currentCharacter = createCharacter(tokenizer)
		currentCharacter.repairLevel()
		if not _isLoaded(currentCharacter.getName()):
			exCharacter.append(currentCharacter)
	elif command == "rightHand" or command == "leftHand" or command == "armor":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var ae = EquipmentFactory.getEquipment(name)
		currentCharacter.equip(ae, false)
		var number: int = 1
		if tokenizer.hasMoreTokens():
			number = J.parseInt(tokenizer.nextToken())
		setEquipment(ae, number)
	elif command == "partyweapons" or command == "partyshields" or command == "partyarmors":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var number: int = 1
		if tokenizer.hasMoreTokens():
			number = J.parseInt(tokenizer.nextToken())
		setEquipment(EquipmentFactory.getEquipment(name), number)
	elif command == "characterdeck":
		charDeck = true
	elif command == "maindeck":
		charDeck = false
	elif command == "card":
		var newCard = Card.createCard(tokenizer)
		if charDeck:
			currentCharacter.getDeck().insert(newCard)
		else:
			partyItems.addCard(newCard)
	elif command == "item":
		var name: String = tokenizer.nextToken()
		var Nr: int = J.parseInt(tokenizer.nextToken())
		name = Organizer.convertKeepCase(name)
		partyItems.addItem(name, Nr)
	elif command == "info":
		var gold: int = J.parseInt(tokenizer.nextToken())
		var hours: int = J.parseInt(tokenizer.nextToken())
		var p_min: int = J.parseInt(tokenizer.nextToken())
		time = EquipmentTime.new(hours, p_min)
		partyItems = PartyItems.new(gold)
		partyItems.setSteps(J.parseInt(tokenizer.nextToken()))
		partyItems.setBattles(J.parseInt(tokenizer.nextToken()))
	elif command == "status":
		var name: String = tokenizer.nextToken()
		var next: String = tokenizer.nextToken()
		if next == "->":
			name += tokenizer.nextToken()
			next = tokenizer.nextToken()
		var value: int = J.parseInt(next)
		name = Organizer.convert(name)
		Database.addStatus(name, value)
	elif command == "storedTrigger":
		var type: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		Database.storeTriggers(type, name)
	elif command == "counter":
		var name: String = Organizer.convert(tokenizer.nextToken())
		var counter: int = J.parseInt(tokenizer.nextToken())
		var offset: int = J.parseInt(tokenizer.nextToken())
		var s = Bestiary.getBestiary().getStats(name)
		if s == null:
			# Java threw a NullPointerException here. Some shipped saves count
			# enemies (e.g. "dragon") that enemyBank.bank does not define.
			push_warning("Load: no bestiary entry for counter '" + name + "'")
			return
		s.setCounter(counter)
		s.setCounterOffset(offset)
	elif command == "labmap":
		var labName: String = prepare(tokenizer.nextToken())
		currentMap = MapLoader.new(labName).getMap()
		Database.visitLabyrinth(labName.replace(".map", ""), currentMap)
	elif command == "node":
		var address: int = J.parseInt(tokenizer.nextToken())
		var isVisited: bool = J.parseBoolean(tokenizer.nextToken())
		var isSeen: bool = J.parseBoolean(tokenizer.nextToken())
		if currentMap.getNode(address) == null:
			push_error("Load: no node with address " + str(address))
			GameCore.exitGame()
			return
		currentMap.getNode(address).setVisitedAndSeen(isVisited, isSeen)
	elif command == "lastlab":
		Database.setLastVisitedLabyrinth(LabyrinthMap.convert(tokenizer.nextToken()))


## Port fix (COTZ-019): true (with a warning) when the save listed the
## character with the given name already, in the party or among the extra
## characters. Such a save loads each character once: one listed the party
## twice, and the party of six put the battle's character row off screen
## (BattleValues.setCharacterPosition). The second copy's equipment and deck
## lines go to that copy, which is dropped.
func _isLoaded(name: String) -> bool:
	var loaded: bool = getCharacterIndex(name) != -1
	for c in exCharacter:
		loaded = loaded or c.getName() == name
	if loaded:
		push_warning("Load: " + name + " is in the save twice; loaded once")
	return loaded


## Converts a labyrinth name to the "Capitalized Words" form used as key
## (e.g. "hall_of_memories" -> "Hall of Memories").
static func prepare(string):
	string = Organizer.convert(string)
	var sb: String = ""
	var split: Array = J.split(string, "\\s")
	for i in range(split.size()):
		var part: String = split[i]
		if part.length() > 0 and (check(part) or i == 0):
			var s: String = J.substring(part, 1)
			sb += part.substr(0, 1).to_upper() + s + " "
		else:
			sb += part + " "
	string = sb
	if string.contains("--"):
		split = J.split(string, "--")
		sb = ""
		if split.size() == 2:
			sb += split[0] + "--"
			var second: String = split[1]
			var s: String = J.substring(second, 1)
			sb += second.substr(0, 1).to_upper()
			sb += s
	return sb.strip_edges()


static func check(s):
	return not (s == "the" or s == "of")


## Creates a new character from the information in the given tokenizer.
func createCharacter(tokenizer):
	var name: String = tokenizer.nextToken()
	var attributes: Array = J.array(15, 0.0)
	for i in range(attributes.size()):
		var a: String = tokenizer.nextToken()
		if a == "--":
			attributes[i] = float(LevelFactory.NO_INCREASE)
		else:
			attributes[i] = float(J.parseInt(a))
	return Character.new(name, attributes, name + ".jpg")


## Sets up the game for a test run.
static func setupForTest():
	ImageHandler.setGameMode(0)
	loadGame("Start")
	GameCore.inputManager.addInputManager(FakeInputManager.new())
	Values.loadFont()


static func unloadNewCharacter(name):
	for i in range(characters.size()):
		var c = characters[i]
		if c.getName() == name:
			J.removeAt(characters, i)
			exCharacter.append(c)
			return
	push_warning("There are no extra characters left.")


## Adds the character with the given name to the party.
static func loadNewCharacter(name):
	var charEnum = Values.characters.getCharacter(name)
	if charEnum != Values.characters.NO_CHARACTER:
		for i in range(exCharacter.size()):
			var c = exCharacter[i]
			if c.getName() == name:
				J.removeAt(exCharacter, i)
				if charEnum.getIndex() > characters.size():
					characters.append(c)
				else:
					characters.insert(charEnum.getIndex(), c)
				return


## Collects the given loot and stores its content in the correct place.
static func collectLoot(l):
	var o = l.getContent()
	match l.getType():
		Loot.GOLD:
			partyItems.addGold(int(o))
		Loot.ITEM:
			partyItems.addItem(o)
		Loot.CARD:
			partyItems.addCard(o)
		Loot.EQUIPMENT:
			addEquipment(o)
		Loot.LIFE:
			Load.cureParty(float(o))
	if l.getType() != Loot.LIFE:
		l.takeLoot()


## Java overloads: cureParty() (0.5 %) and cureParty(float percent).
static func cureParty(percent = null):
	if percent == null:
		percent = 0.005
	for i in range(characters.size()):
		var c = characters[i]
		if not c.isAlive():
			c.cureFromDead()
		characters[i].curePercent(percent)


static func shuffleAllDecks():
	for i in range(characters.size()):
		var d = characters[i].get2DDeck()
		if d != null:
			d.shuffleAndDeal()
