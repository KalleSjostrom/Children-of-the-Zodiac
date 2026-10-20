class_name Village
extends VillageLoader
## Port of villages.Village: coordinates the graphics, input and animation
## for the village (the game mode for towns). When the player is in the
## middle of the screen, the background moves instead of the player.

var talkingVillager = null
var storyInfo = null
var sign = null
var elements = []
var exitName = null
var buildingName = null
var showSignDialog: bool = false
var inStore: bool = false
var fromStory: bool = false
var question: bool = false
var talkmode: bool = false
static var fromHouse = null
var inHouse: bool = false

const BRIDGE_TEST_SCENE := "res://tools/bridge_test/BridgeTest.tscn"

## Java Arrays.sort(elements) with SortingElement.compareTo (sorted on y).
var _elementSorter: Callable = func(a, b): return a.yPos < b.yPos

## Java: init(HashMap<String, String> info). Constructs the village from the
## map file given in the information map.
func init(name, lab = null, hinders = null):
	var info = name
	loadVillage(info)
	setDrawPos(0)
	setDrawPos(1)
	createSpritesList()
	Graphics.setTextColor(JColor.black)
	exitName = infoMap.get("landname")
	var delay: int = 0
	if info.has("delay"):
		delay = J.parseInt(info.get("delay"))
	if delay > 0:
		Scheduler.after(delay, func(): self.logicLoading = false)
	else:
		logicLoading = false


## Creates the list containing the sprites in this village (the villagers as
## well as the party members).
func createSpritesList():
	var pmList = player.getPartyMembers()
	for i in range(pmList.size()):
		var s = pmList[i]
		sprites[s.get_instance_id()] = s
	elements = J.array(sprites.size(), null)
	var i: int = 0
	for index in sprites:
		var s = sprites[index]
		elements[i] = SortingElement.new(s.getY(), index)
		i += 1


## Shortcut to VillageLoader.init().
func loadVillage(info):
	super.init(info)


## Java: resume() (overridden). Resumes and restores this village. With a
## detection mode it is GameMode's protected resume(detectionMode, ...).
func resume(detectionMode = null, fadeMusic = null, fadein = null):
	if detectionMode != null:
		resumeWith(detectionMode, fadeMusic, fadein)
		return
	var fade: bool = true
	if inHouse or inside:
		fade = false
	resumeWith(Values.DETECT_ALL, fade, fromStory or inStore or inHouse)
	if inStore:
		player.setPartyMembers()
		player.setDirectionForAll(Values.DOWN)
		inStore = false
	elif inHouse:
		var dir: int = Values.DOWN
		if fromHouse != null:
			dir = int(fromHouse[2] if fromHouse[2] != -1 else Values.DOWN)
		else:
			fromHouse = [0.0, 0.0, 0.0]
			fromHouse[0] = player.getPos()[0]
			fromHouse[1] = player.getPos()[1]
		fromHouse[2] = dir
		player.setPos(fromHouse)
		player.setPartyMembers()
		inHouse = false
	player.standStill()


## Updates the village: checks the player input and updates the villagers
## and the player. If the player is at the edge of the screen the village is
## exited.
func update(elapsedTime: float):
	background.update(elapsedTime)
	if mode == Values.NO_MODE_IS_SELECTED:
		var x: float = player.getPos()[Values.X]
		var y: float = player.getPos()[Values.Y]

		if x < 0 or x > backgroundWidth or y < 0 or y > backgroundHeight:
			if not checkDoors(holeDoors, player.getDirection()):
				Organizer.getOrganizer().deleteSuspended()
				exit()
			return
		checkGameInput()
		player.update(elapsedTime)
	checkVillagers(elapsedTime)
	super.update(elapsedTime)


func checkDoor(d, direction):
	var entered: bool = false
	if d.canBeOpened(direction):
		if d.isLocked():
			setSign(d.getSign())
			if sign == null:
				createSign("The door is locked.", "", null)
		else:
			entered = true
			mode = d.getMode()
			if mode == Values.VILLAGE or mode == Values.SWITCH_BACK or mode == Values.HOUSE:
				setFade(d.getFadeMode())

			fromHouse = d.getToPos()
			if mode == Values.SWITCH_BACK:
				var gm = Organizer.getOrganizer().getNextSuspendedMode()
				if gm == null or gm.getName() != d.getBuildingName():
					mode = Values.HOUSE
					if fromHouse != null:
						fromHouse[2] = fromHouse[3]
				else:
					nextPlace = null
					exit(mode)
					return entered
			if mode == Values.LABYRINTH or mode == Values.STORY_SEQUENSE:
				nextPlace = d.getBuildingName()
				exit(mode)
			elif mode == Values.VILLAGE:
				nextPlace = d.getBuildingName()
				staticStartPos = int(fromHouse[2] if fromHouse != null else 0)
				inHouse = true
				exit(mode)
			elif mode == Values.HOUSE:
				nextPlace = d.getBuildingName()
				staticStartPos = int(fromHouse[2] if fromHouse != null else 0)
				inHouse = true
				setSuspended(true, false, true)
				exit(Values.VILLAGE)
			else:
				buildingName = d.getBuildingName()
				nextPlace = null
				inStore = true
				setSuspended(true, true, true)
				exit(mode)
	return entered


func setFade(fadeMode):
	match fadeMode:
		StoreDoor.FADE_UP:
			setMusicMode(SoundValues.FADE_IN, SoundValues.FAST,
					SoundValues.ALL_THE_WAY, SoundValues.RESUME_PLAY)
		StoreDoor.FADE_DOWN:
			setMusicMode(SoundValues.FADE_OUT, SoundValues.FAST,
					SoundValues.ALL_THE_WAY, SoundValues.PAUSE)
		StoreDoor.FADE_TO_HALF:
			setMusicMode(SoundValues.FADE_OUT, SoundValues.FAST,
					SoundValues.HALF, SoundValues.NORMAL)


## Updates the villagers (and the other sprites except the party members).
func checkVillagers(elapsedTime):
	for k in sprites:
		var s = sprites[k]
		if s is Villager:
			s.update(elapsedTime, player, true)
		elif s is BodiesParticleSystem:
			s.update(elapsedTime)
		elif not (s is PartyMember):
			s.update(elapsedTime)


## Initiates the question dialog (the villager asks a question).
func initQuestionDialog():
	question = true
	changeDirBehaviour(Values.DETECT_INIT)


## Quits the question dialog (the player has answered).
func exitQuestionDialog():
	question = false
	dialog.loadResponse()
	changeDirBehaviour(Values.DETECT_ALL)


## Checks the input from the user and acts according to the button.
func checkGameInput():
	if not (talkmode or showSignDialog):
		if player.isMoving():
			var shouldStop: bool = true
			for i in range(UP, LEFT + 1):
				if not gameActions[i].isReleased():
					shouldStop = false
			if shouldStop:
				player.standStill()

		checkDirectionalButtons()
		if MenuStarter.isMenuButtonPressed(gameActions):
			super.queueEnterMenu()
	elif question:
		checkDirectionalButtonsForQuestion()
	if gameActions[CROSS].isPressed():
		if showSignDialog:
			showSignDialog = false
			return
		crossPressed()


## Sets whether or not the villager and the player are in a conversation.
func setTalking(talking):
	talkmode = talking
	talkingVillager.setTalking(talking, Values.getCounterAngle(player.getDirection()))
	player.standStill()


## Checks if any directional buttons have been pressed (two buttons on
## different axes move the player diagonally). Holding circle sprints.
func checkDirectionalButtons():
	var dirs := []
	for i in range(UP, LEFT + 1):
		if gameActions[i].isPressed():
			dirs.append(i - UP)
	# The press is consumed so that holding circle into the menu or a store
	# does not also count as "back" there.
	gameActions[CIRCLE].isPressed()
	player.sprinting = gameActions[CIRCLE].isPressedDontReset()
	var speed: float = Player.SPRINT if player.sprinting else 1.0
	# A diagonal move is as fast as a straight one, and if one of its
	# directions is blocked the player slides along the obstacle at full speed.
	var blocked := []
	if dirs.size() == 2 and dirs[0] % 2 != dirs[1] % 2:
		for dir in dirs:
			if not canGo(dir, speed * Player.DIAGONAL):
				blocked.append(dir)
		if blocked.is_empty():
			speed *= Player.DIAGONAL
	# A blocked direction takes no step (but may still lead through a door),
	# and goes first so that the player faces the way they slide.
	for dir in blocked:
		move(dir, 0.0)
	for dir in dirs:
		if not dir in blocked:
			move(dir, speed)
	if not dirs.is_empty():
		player.setPartyMembersPositions()
	else:
		background.stop()


## Checks the directional buttons when the player is answering a question.
func checkDirectionalButtonsForQuestion():
	for i in range(UP, LEFT + 1):
		if gameActions[i].isPressed():
			dialog.move(i)


## Moves the player in the given direction (speed scales the step, see
## Player.go).
func move(direction, speed = 1.0):
	if not checkDoors(holeDoors, direction):
		if checkVillagerCollision(direction):
			player.move(direction)
		elif not showSignDialog:
			player.go(direction, speed, obstacleHandler)
			if setDrawPos(direction % 2):
				var XorY: int = direction % 2
				background.setPos(XorY, BACK_POS[XorY])
			else:
				background.stop()


## True if the player can take a step in the given direction (no villager
## or obstacle in the way).
func canGo(direction, speed):
	return not checkVillagerCollision(direction) \
			and player.canGo(direction, speed, obstacleHandler)


func setDrawPos(XorY):
	var pos = player.getPos()
	if obstacleHandler.isInMiddle(pos[XorY], XorY):
		BACK_POS[XorY] = obstacleHandler.getBackPos(pos[XorY], XorY)
		return true
	return false


## Called when the action button (cross) is pressed: talks to villagers,
## takes loot, enters buildings, reads signs or shows the next dialog.
func crossPressed():
	if not talkmode:
		if checkLoot() or checkNearbyVillagers() \
				or checkDoors(doors, player.getDirection()) or checkSigns():
			return
	else:
		if question:
			exitQuestionDialog()

		var gl = dialog.getGift()
		if gl != null:
			Load.collectLoot(gl)
		var takeName = dialog.getTakeName()
		if takeName != null:
			var takeAmount: int = dialog.getTakeAmount()
			if takeName == "gold":
				Load.getPartyItems().addGold(-takeAmount)
			else:
				Load.getPartyItems().take(takeName, takeAmount)
		var t = dialog.getBeforeTriggers()
		var triggerAdds = dialog.getTriggerAdds()
		var finished: bool = dialog.isFinished()
		doTriggers(t)
		if triggerAdds != null:
			Database.incrementStatus(triggerAdds)
		if finished:
			setTalking(false)
			if dialog.shouldTrigger():
				t = dialog.getTriggers()
				doTriggers(t)
				executeTrigger(talkingVillager)
			else:
				dialog.resetDialog()
		else:
			if dialog.isQuestion():
				initQuestionDialog()


func doTriggers(t):
	if t != null:
		Database.updateStatus(t)
		for name in t.keys():
			updateVillagerDialog(name, t.get(name))


## Checks if there is any loot nearby to take.
func checkLoot():
	var found: bool = false
	var i: int = 0
	while i < loots.size() and not found:
		var l = loots[i]
		if l.isInRange(player.getPos()) and l.checkPlayerDir(player.getDirection()):
			if l.decrementStatus():
				J.removeAt(loots, i)
				Load.collectLoot(l)
				createSign(l.getLine(0), l.getLine(1), l.getContent())
				player.standStill()
			found = true
		i += 1
	return found


func createSign(fl, sl, content):
	setSign(Sign.new(fl, sl, content))


func setSign(s):
	showSignDialog = true
	sign = s
	player.standStill()


## Checks if there are any villagers nearby to talk to.
func checkNearbyVillagers():
	for k in sprites:
		var s = sprites[k]
		if s is Villager:
			if s.checkTalkable(player.getPos(), player.getDirection()):
				return executeTalkableVillager(s)
	return false


## Executes the dialog sequence that the given villager has. If the
## villager's next dialog is a story sequence, one is initiated.
func executeTalkableVillager(v):
	var ans: bool = false

	if v.isDialogSequence():
		ans = true
		if Creature.isOneInTeamDead(Load.getCharactersAsCreatures()):
			# Can't happen in current version...
			dialog.resetDialog()
			dialog.setDS(DialogSequence.new(v.getName(), "...", "", true, false, false))
		else:
			buildingName = null
			var filename: String = v.getSequenceFilename()
			if filename.begins_with("exit"):
				nextPlace = filename.replace("exit", "")
				exit(Values.STORY_SEQUENSE)
			else:
				storyInfo = Organizer.getOrganizer().getInformationFor(filename)
				var mus = storyInfo.get("music")
				nextPlace = null
				switchGameMode(Values.VILLAGE_STORY, mus != null and mus != "continue", false)
			return true
	elif v.getDialog().size() > 0:
		dialog.setDS(v.getDialog(), v.getResponses())
		ans = true
		var t = dialog.getBeforeTriggers()
		if t != null:
			Database.updateStatus(t)
	else:
		return false
	talkingVillager = v
	setTalking(true)
	return ans


## Checks if there are any signs nearby to read.
func checkSigns():
	for i in range(signs.size()):
		if signs[i].isInRange(player.getPos(), player.getDirection()):
			setSign(signs[i])
			return true
	return false


## Checks if there are any doors around to enter.
func checkDoors(doors, direction):
	var stopSeaching: bool = false
	var found: bool = false
	var i: int = 0
	while i < doors.size() and not stopSeaching:
		stopSeaching = doors[i].isInRange(player.getPos())
		if stopSeaching:
			found = checkDoor(doors[i], direction)
		i += 1
	return found


## Executes the trigger associated with the given villager.
func executeTrigger(vil):
	var s = vil.getStoredTriggers()
	if s != null:
		Database.storeTriggers("inn", s)
	dialog.resetDialog()


func updateVillagerDialog(name, value):
	var v = getVillager(name)
	if v != null:
		v.updateDialog(value)


## Gets the information map for the next place, if it is one of this
## village's buildings; otherwise the story info (null for the landscape).
func getInfoForNextPlace():
	if buildingName != null:
		return buildingInfo.get(buildingName)
	return storyInfo


func getTestInfoForType(name):
	for next in buildingInfo:
		if String(next).contains(name):
			return buildingInfo.get(next)
	return null


## Checks if the player has collided with a villager.
func checkVillagerCollision(direction):
	var found: bool = false
	for k in sprites:
		if found:
			break
		var s = sprites[k]
		if s is Villager:
			found = player.checkCollision(s, direction)
	return found


## The scene of the village (docs/ARCHITECTURE.md): for a converted place the
## VillageScene it was loaded from (VillageLoader.load), which draws the
## world (phase 1 step B); for the others the bridge test's placeholder
## (Main --bridge-test, dev only), which stands in for the background tiles.
func create_scene() -> Node:
	if scene_root != null:
		return scene_root
	if Main.bridge_test:
		var packed: PackedScene = ResourceLoader.load(BRIDGE_TEST_SCENE)
		return packed.instantiate()
	return null


## Draws the village. GameMode.draw is used to fade in and out. A converted
## place's scene draws the world (draw_scene); the emotions, dialogs and signs
## stay legacy overlays until phase 3.
func draw(g, alpha = null):
	g.setColor(1)
	if scene_root is VillageScene:
		update_draw_state()
		draw_scene(g)
		drawOverlays(g, sprites)
	else:
		drawBottom(g)
		drawTop(g, sprites)
	super.checkMenu()
	super.draw(g)


## Draws the bottom layer of the village: background, animated objects and
## villagers (sorted on their y position).
func drawBottom(g):
	if scene_root != null:
		# The scene shows instead of the background tiles (bridge test); the
		# bottom layer particle systems are still drawn here.
		if background.extraBackground == null:
			background.drawSystem(g, background.systems.get(DoubleBackground.BOTTOM_LAYER))
	else:
		background.drawBottom(g)
	var bpos = background.getPos()
	var x: int = int(bpos[Values.X])
	var y: int = int(bpos[Values.Y])
	var n: int = sortSprites()
	for i in range(n):
		var s = sprites.get(elements[i].getIndex())
		if s == null:
			continue
		if s is PartyMember:
			var asx: int = J.round(s.getX() + x)
			var asy: int = J.round(s.getY() + y)
			s.draw(g, asx, asy)
		else:
			s.draw(g, x, y)


## Sorts the sprites on their y position for drawing (elements); returns how
## many elements to draw.
func sortSprites() -> int:
	var index: int = 0
	var n: int = elements.size()
	for k in sprites:
		if index < n:
			var se = elements[index]
			se.setYpos(sprites[k].getY())
			se.setIndex(k)
		index += 1
	elements.sort_custom(_elementSorter)
	if sprites.size() != n:
		push_warning("Village: the sprite list and elements are not of equal length")
	return mini(index, n)


## Draws the top layer of the village: roofs and treetops, emotions and
## dialogs.
func drawTop(g, sprites = null):
	background.drawTop(g, true, sprites)
	drawOverlays(g, sprites)


## Draws what is drawn over the village: the emotion bubbles of the given
## sprites (none if null), the dialog or the sign.
func drawOverlays(g, sprites = null):
	if sprites != null:
		for k in sprites:
			sprites[k].drawEmotions(g)

	if talkmode:
		dialog.draw(g)
	elif showSignDialog:
		Dialog.getDialog().drawMessages(g, sign.getText()[0], sign.getText()[1], true)
		var content = sign.getContent()
		if content != null:
			if content is Card:
				DeckPage.drawCardInfo(g, content, 530)


## Bridge (phase 1 step B, docs/ARCHITECTURE.md): what drawBottom and
## drawTop would draw this frame, without drawing it. Prepared where they
## would run (in draw, so the state they change changes at the same moment):
## the sprites sorted (sortSprites) and placed (Sprite.place_view: the
## villagers' drawX/drawY, the emotion bubbles' positions, the particle
## systems' positions, textures and particle lives). draw_list holds the
## sprites in draw order, [key, image path or null, screen x, screen y], or
## [key, particle view] for a particle system; draw_systems holds the
## background's particle systems per layer, [key, particle view] each.
var draw_list := []
var draw_systems := {}


func update_draw_state():
	var bpos = background.getPos()
	var x: int = int(bpos[Values.X])
	var y: int = int(bpos[Values.Y])
	draw_systems.clear()
	for layer in [DoubleBackground.BOTTOM_LAYER, DoubleBackground.UPPER_LAYER,
			DoubleBackground.WEATHER_LAYER]:
		var views := []
		if layer != DoubleBackground.BOTTOM_LAYER or background.extraBackground == null:
			var list = background.systems.get(layer)
			if list != null:
				for p in list:
					views.append([p.get_instance_id(), p.place_view(x, y)])
		draw_systems[layer] = views
	draw_list.clear()
	var n: int = sortSprites()
	for i in range(n):
		var key = elements[i].getIndex()
		var s = sprites.get(key)
		if s == null:
			continue
		var placed
		if s is PartyMember:
			placed = s.place_view(J.round(s.getX() + x), J.round(s.getY() + y))
		else:
			placed = s.place_view(x, y)
		if placed is Dictionary:
			draw_list.append([key, placed])
		elif not placed.is_empty():
			draw_list.append([key, placed[0], placed[1], placed[2]])


## Bridge (phase 1 step B): the scene draws the world that drawBottom and
## drawTop would draw (prepared by update_draw_state), with the colour and
## alpha test each part would get, and the GL state is left as that drawing
## would leave it for the overlays and the next frame.
func draw_scene(g):
	var scene: VillageScene = scene_root
	var state := SceneGLState.new(g)
	var bpos = background.getPos()
	var scroll := Vector2i(int(bpos[Values.X]), int(bpos[Values.Y]))
	scene.show_view(scroll, 1.0, Vector2.ZERO)
	scene_bottom(scene, state)
	scene.show_actors(scene_sprites(state, scroll))
	scene_top(scene, state, sprites)
	state.apply(g)


## Bridge (phase 1 step B): DoubleBackground.drawBottom for the scene: the
## bottom layer particle systems, then the tiles (or the extra background a
## story sets).
func scene_bottom(scene, state):
	var extra: Texture2D = null
	var systems := []
	if background.extraBackground == null:
		for entry in draw_systems.get(DoubleBackground.BOTTOM_LAYER, []):
			systems.append(state.particles(entry))
	else:
		extra = ImageHandler.getTexture(background.extraBackground).getGodotTexture()
	scene.show_bottom(extra, systems, state.color, state.alpha)


## Bridge (phase 1 step B): the sprites of drawBottom as entries for
## VillageScene.show_actors, in draw order.
func scene_sprites(state, scroll: Vector2i) -> Array:
	var entries := []
	for d in draw_list:
		if d.size() == 2:
			entries.append(["particles"] + state.particles(d))
		else:
			var texture: Texture2D = null
			if d[1] != null:
				var t = ImageHandler.getTexture(d[1])
				texture = t.getGodotTexture() if t != null else null
			entries.append(["sprite", d[0], texture, Vector2i(d[2] - scroll.x, d[3] - scroll.y),
					state.color, state.alpha])
	return entries


## Bridge (phase 1 step B): DoubleBackground.drawTop for the scene: the roofs
## and treetops (alpha test 0.9), the night layer (alpha test 0), the upper
## and weather particle systems. The scene always draws the roofs and
## treetops (plan 6.1); the legacy code draws a piece only where a sprite
## overlaps it (sprites given), which --legacy=village_top_layer keeps.
## The overlap test runs either way: it is where drawTop brings the party
## members' positions up to date (PartyMember.getMemberPos).
func scene_top(scene, state, sprites = null):
	var top: bool = background.extraBackground == null
	var color: Color = state.color
	var pieces := []
	if top:
		pieces = background.overlapped_pieces(sprites)
		state.set_alpha(0)
	if not Main.is_legacy("village_top_layer"):
		pieces = []
	var systems := []
	for layer in [DoubleBackground.UPPER_LAYER, DoubleBackground.WEATHER_LAYER]:
		for entry in draw_systems.get(layer, []):
			systems.append(state.particles(entry))
	scene.show_top(top, pieces, color, top and background.nightTop != null, color, systems)


## Bridge (phase 1 step B): the GL state that the legacy world drawing passes
## from part to part (the colour images are tinted with, the alpha test), as
## it changes, and the changes to make to the real Graphics at the end.
class SceneGLState extends RefCounted:
	var color := Color(1, 1, 1, 1)
	## Alpha test threshold (Graphics.alpha_threshold), -1: none.
	var alpha := -1.0
	var _alphaSet := false
	var _colorReset := false
	var _particlesDrawn := false

	func _init(g) -> void:
		color = g.getCurrentColor()
		alpha = g.alpha_threshold()

	## g.setAlphaFunc(a).
	func set_alpha(a: float) -> void:
		alpha = a
		_alphaSet = true

	## g.setColor(r, g, b, a) followed later by g.setColor(1).
	func reset_color() -> void:
		color = Color(1, 1, 1, 1)
		_colorReset = true

	## A particle system entry [key, view]: an active one (drawIt) draws its
	## image in the current colour, then leaves blending on, alpha test 0.1
	## and colour 1.
	## Returns the entry with the image's colour.
	func particles(entry: Array) -> Array:
		var view: Dictionary = entry[1]
		if not view.is_empty():
			view["image_color"] = color
			_particlesDrawn = true
			set_alpha(0.1)
			reset_color()
		return entry

	func apply(g) -> void:
		if _particlesDrawn:
			g.glEnable(Graphics.GL_BLEND)
		if _alphaSet:
			g.setAlphaFunc(alpha)
		if _colorReset:
			g.setColor(1)


func getPlayer():
	return player


func getVillageFolderName():
	return folderName


func getBackground():
	return background


## Gets a map of all the villagers in the village (the party members are
## removed from the sprite map).
func getVillagers():
	for i in range(player.getPartyMembers().size()):
		var h: int = player.getPartyMembers()[i].get_instance_id()
		sprites.erase(h)
	updateSpriteList()
	return sprites


## Adds the given list of villagers (and the party members) to this village.
func addVillagers(removedVillagers):
	for i in range(removedVillagers.size()):
		var s = removedVillagers[i]
		if s is Villager:
			sprites[s.get_instance_id()] = s
	for i in range(player.getPartyMembers().size()):
		var s = player.getPartyMembers()[i]
		sprites[s.get_instance_id()] = s
	updateSpriteList()


func addOnlyVillagers(removedVillagers):
	for i in range(removedVillagers.size()):
		var s = removedVillagers[i]
		if s is Villager:
			sprites[s.get_instance_id()] = s
	updateSpriteList()


func addSprite(s):
	sprites[s.get_instance_id()] = s
	updateSpriteList()


## Makes sure every sprite in the sprite list has a SortingElement (used to
## draw them sorted on y).
func updateSpriteList():
	if sprites.size() != elements.size():
		elements = J.array(sprites.size(), null)
		var i: int = 0
		for index in sprites:
			var s = sprites[index]
			elements[i] = SortingElement.new(s.getY(), index)
			i += 1


## Called when the story mode has finished and the village should continue.
func initFromStory(pos, removedVillagers, nextPlace):
	player.setPos(pos)
	player.update(Values.LOGIC_INTERVAL)
	addVillagers(removedVillagers)
	if nextPlace != null and nextPlace != " " and nextPlace != "_":
		self.exitName = nextPlace


## Sets this village to be ready (it does not fade in or out when started).
func setReady():
	fadein = false
	fadeout = false
	fadeValue = 1.0
	loadingDone()


## Java overloads: Village.exit() (to the landscape, or exitName) and
## GameMode.exit(int mode).
func exit(next = null, fadeBattleMusic = null):
	if next != null:
		super.exit(next)
		return
	nextPlace = exitName
	Organizer.getOrganizer().deleteSuspended()
	exit(Values.LANDSCAPE)


func setBackground(string):
	background.setExtraBack(string)


func getParticleSystem(name):
	for s in sprites.values():
		if s is BodiesParticleSystem:
			if s.getName() == name:
				return s
	return background.getParticleSystem(name)
