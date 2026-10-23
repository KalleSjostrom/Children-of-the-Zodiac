class_name Labyrinth
extends MenuStarter
## Port of labyrinth.Labyrinth: the 3D dungeon game mode. A graph of nodes,
## where each node is one step in the labyrinth.
##
## Port notes:
##  - init(info) takes the info Dictionary in its first parameter.
##  - resume() is the Java public resume(); called with a detection mode it
##    forwards to GameMode.resumeWith(...).
##  - exit(next: String, fadeBattleMusic: bool) is Labyrinth's exit; exit(int)
##    is GameMode.exit(mode).
##  - drawDialog dispatches the Java overloads (first, second),
##    (firstDialogImage, name, first, second, whisper), (DialogSequence) and
##    (ArrayList<DialogSequence>) on the type of the first argument.
##  - checkNode(dir) and move(dir) take the Java arguments (extra params unused).
##
## Phase 2 (docs/ARCHITECTURE.md section 10): a converted floor is built from
## its scene (MapLoader, step A) and drawn by it (create_scene, step B): draw
## hands the scene what the display list, the objects and the weather would
## have drawn; the battle, the minimap and the 2D overlays stay legacy.

var graph = null
var player = null
var currentNode = null
var mapLoader = null
var renderer = null
var name = ""
var dialog = null
var card = null
var labDrawable = null
var mapRenderer = null
var mission = null
var subGameModeInitiated: bool = false
var labyrinthInitiaded: bool = false
var dir: int = 0
var lastAddress: int = 0
var drawList: int = 0
var steps: int = 0
var tempTotalSteps: int = 0
var currentStepsToBattle: int = 0
var stepsToBattle = null
var hasEnemies: bool = false
var runSubGameMode: bool = false
var weatherSystem = null
var battles: int = 0
var noEncounters: bool = false
var battleMusic = null
var dialogSequence = null
var topLayer = {}

## Creates, loads and starts the labyrinth. info contains "map", "start",
## "music", "name".
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_AS_KEY)
	if ImageHandler.isCurrentGameModeCleared():
		updateCharacterDecks()
	infoMap.get("name")
	var mapName: String = info.get("map")
	self.name = mapName.replace(".map", "").replace("_", " ")
	var ef = EnemyFactory.getEnemyFactory()
	var eg = ef.getEnemyGroup(self.name)
	hasEnemies = (eg != null) and eg.hasEnemies()
	if hasEnemies:
		eg.loadTextures()
	var labInfo = Database.getMap(mapName)
	mapLoader = MapLoader.new(mapName)
	mission = MissionFactory.createMission(mapLoader.getMission())

	var map = mapLoader.getMap()
	if labInfo != null:
		var m = labInfo.getFloor(mapName, true)
		if m != null:
			map = m
	graph = Graph.new(mapName, map)
	mapRenderer = MapRenderer.new(map)
	stepsToBattle = mapLoader.getStepsToBattle()
	resetSteps()
	var gm = Organizer.getOrganizer().getPreviousMode()
	var lastNameInMain = null
	if gm is Labyrinth:
		steps = gm.steps - 2
		var n = gm.currentNode
		if n.hasInventory():
			var inv = n.getInventory()
			if inv is AbstractDoor:
				lastNameInMain = inv.getNameInMain()
	var start: int = J.parseInt(info.get("start"))
	currentNode = graph.getStartNode(start)
	# COTZ-005: a game saved on this floor starts where it was saved; a
	# "-save" place on a floor without a save point (saved before that)
	# starts at the floor's first door instead of crashing.
	var savedAt: Array = Load.take_labyrinth_position(self.name)
	var savedDir: int = -1
	if savedAt.size() == 2 and map.getNode(savedAt[0]) != null:
		currentNode = map.getNode(savedAt[0])
		savedDir = savedAt[1]
	elif currentNode == null:
		currentNode = graph.getStartNode(0)
	currentNode.visit()
	if currentNode.hasInventory():
		var inv = currentNode.getInventory()
		if inv is AbstractDoor:
			inv.setHaveBeen(lastNameInMain)
	renderer = mapLoader.getRenderer()
	weatherSystem = renderer.getWeatherSystem()
	dir = graph.getAngle()
	if savedDir >= 0:
		dir = savedDir
	graph.setLabyrinth(self)
	graph.sortInventory()
	var nodePos = currentNode.getPos()
	var pos = LabyrinthPosition.new(nodePos.getX(), nodePos.getZ(), Values.TO_ANGLE[dir])
	player = LabyrinthPlayer.new(pos)
	battleMusic = mapLoader.getBattleMusic()
	# Dev only (--no-encounters, the console's noenemies; Main): the original
	# never sets noEncounters.
	if Main.no_encounters:
		noEncounters = true

	logicLoading = false
	print("Logic loading done")
	if currentNode.getInventory() is AbstractDoor:
		currentNode.arrive(self)

func updateCharacterDecks():
	var chars: Array = Load.getCharacters()
	for i in range(chars.size()):
		var deck = chars[i].get2DDeck()
		if deck != null:
			deck.setNeedUpdate(true)

## Bridge (phase 2 step B, docs/ARCHITECTURE.md section 10): the floor's
## scene (DungeonScene), which draws the walls, the objects and the weather
## while the legacy objects stay in charge; null for a floor that is not
## converted and with --legacy=dungeons (the legacy drawing draws it then).
## --legacy=dungeon_drawing (dev, for checking step A on its own) keeps the
## legacy drawing of a floor built from its scene.
func create_scene() -> Node:
	if mapLoader == null or Main.is_legacy("dungeon_drawing"):
		return null
	return mapLoader.dungeon_scene_for(mapLoader.labyrinthName)


## Bridge (phase 2 step B): init3D for a floor its scene draws, without the
## display list: the same GL state (lights, material, fog, the clear colour,
## and what compiling the walls leaves: the current colour, normal, texture
## coordinate and texture, the enabled caps), the same textures, objects and
## minimap set up. The scene builds the walls in the GL state they would
## have been compiled in (DungeonScene.show_floor).
func init_scene_3d(g, scene):
	renderer.addLight(g)
	renderer.setMaterial(g)
	renderer.addFog(g)
	renderer.init(g)
	g.setTextureEnabled(false)
	g.setLightEnabled(false)
	g.clearColor(0)
	var st: Dictionary = g.render_state_3d()
	var left: Dictionary = scene.show_floor({"color": g.getCurrentColor(), "normal": g.current_normal(),
		"uv": g.current_tex_coord(), "additive": st.additive, "opaque": st.opaque,
		"alpha_func": st.alpha_func, "alpha_ref": st.alpha_ref, "depth_test": st.depth_test,
		"depth_write": st.depth_write, "cull": st.cull})
	if renderer.getSetting(MapLoader.SKY):
		# renderSky's state changes (its matrix push and pop leave none).
		g.setDepthTestEnabled(true)
		g.getGL().glEnable(Graphics.GL_CULL_FACE)
	g.getGL().glColor4f(left.color.r, left.color.g, left.color.b, left.color.a)
	g.setTextureEnabled(true)
	g.setLightEnabled(true)
	if left.slot >= 0:
		renderer.textures[left.slot].getTexture().bind(g)
	g.getGL().glNormal3f(left.normal.x, left.normal.y, left.normal.z)
	g.getGL().glTexCoord2f(left.uv.x, left.uv.y)
	renderer.setLight(g)
	graph.initDrawInventory(g)
	mapRenderer.initDraw(g)


## Bridge (phase 2 step B): where draw called the display list and
## Graph.drawInventory: the camera (the modelview LabyrinthPlayer.lookAt
## set) and the objects, handed to the scene; this frame's legacy 3D drawing
## goes into the scene's 3D world (Graphics.use_scene_3d).
func show_scene(g, scene):
	g.use_scene_3d(scene.legacy_root())
	scene.show_view(g.getModelView())
	graph.show_inventory(g, scene)


## Bridge (phase 2 step B): a weather pass for the scene (WeatherSystem.draw
## without the drawing).
func show_weather(g, scene, front):
	var q: Dictionary = weatherSystem.place_particles(g, player, front)
	scene.show_weather(&"front" if front else &"back", q)


## Sets light, fog and draws the labyrinth into a display list.
func init3D(g):
	renderer.addLight(g)
	renderer.setMaterial(g)
	renderer.addFog(g)

	renderer.init(g)

	drawList = ImageHandler.generateDrawList(g)
	g.compileDrawList(drawList)
	g.setTextureEnabled(false)
	g.setLightEnabled(false)
	g.clearColor(0)

	renderer.renderSky(g)
	g.setTextureEnabled(true)
	g.setLightEnabled(true)
	renderer.draw(g)
	g.endList()

	renderer.setLight(g)
	graph.initDrawInventory(g)

	mapRenderer.initDraw(g)

## Java public resume(): resumes the labyrinth (after the menu, a battle...).
## With arguments it is GameMode's protected resume(detectionMode, ...).
func resume(detectionMode = null, fadeMusic = null, fadein = null):
	if detectionMode != null:
		resumeWith(detectionMode, fadeMusic, fadein)
		return
	resumeWith(Values.DETECT_ALL, false)
	GameEventListener.set3D()

func update(elapsedTime: float):
	mapRenderer.update()
	if weatherSystem != null:
		weatherSystem.update()
	if runSubGameMode:
		labDrawable.update(elapsedTime)
		super.update(elapsedTime)
		return
	if not fadeout:
		if player.isMoving():
			player.update(int(elapsedTime))
		else:
			if not checkBossFight() and checkSteps():
				if checkEnterBattle(dir):
					enterBattle(false, null)
				else:
					checkButtons()
			else:
				checkButtons()
	super.update(elapsedTime)

## Java checkNode(int dir).
func checkNode(n, pos = null):
	var d: int = n
	if not player.isMoving():
		var temp: bool = false
		if currentNode.hasInventory():
			var inv = currentNode.getInventory()
			if inv is InventoryDoor or inv is HinderDoor:
				temp = graph.isDirectedTowards(currentNode, d)
			if temp:
				graph.activateInventory(currentNode, self)
		if not temp:
			var node = currentNode.getNode(d)
			# A door is on the far wall of its own node and is entered from
			# there; from the node before it, it was entered from too far
			# away (COTZ-010). Chests, levers and villagers in the next node
			# are still used from here, and so are ladders: a ladder's node
			# cannot be entered (LadderDoor.isPassable), so it is climbed from
			# the node before it, as in the Java (COTZ-010 had made the
			# ladders of Grivera and Mt. Cesadur unusable; found in the phase
			# 2 rollout).
			if node != null and node.hasInventory() and \
					(not node.getInventory() is AbstractDoor or node.getInventory() is LadderDoor):
				graph.activateInventory(node, self)

func checkBossFight():
	if not player.isMoving():
		return graph.checkBossNode(currentNode, self)
	return false

func checkEnterBattle(dir):
	var freeToBattle: bool = false
	if not currentNode.hasInventory() and not hasWallTowards(currentNode, dir):
		var n = currentNode.getNode(dir)
		if n != null and not n.hasInventory() and not hasWallTowards(n, dir):
			n = n.getNode(dir)
			if n != null and not n.hasInventory():
				freeToBattle = true
	return freeToBattle

## True when a wall is drawn between the node and its neighbour in direction
## d although the two are connected: the map's "wall" lines can put one
## there (the walls the player can walk through in Mt. Cesadur). A battle
## facing it showed the wall instead of the enemy behind it (COTZ-011).
func hasWallTowards(node, d: int) -> bool:
	var next = node.getNode(d)
	if next == null:
		return false
	return node.walls[d] != -1 or next.walls[Values.getCounterAngle(d)] != -1

func enterBattle(boss, bossName = null):
	push()
	if battleMusic[0].to_lower() != "no music":
		setMusicMode(SoundValues.FADE_OUT, 1000, SoundValues.ALL_THE_WAY, SoundValues.PAUSE)
	var bm = BattleManager.new()
	labDrawable = bm
	bm.setBattleStarter(self)
	bm.init(getBattleInfo(boss, bossName))
	runSubGameMode = true
	subGameModeInitiated = false
	battles += 1

func leaveBattle():
	pop()
	runSubGameMode = false
	if battleMusic[0].to_lower() != "no music":
		labDrawable.setMusicMode(SoundValues.FADE_OUT, SoundValues.FAST,
			SoundValues.NORMAL, SoundValues.KILL_MUSIC_ON_FADE_DOWN)
	var chars: Array = Load.getCharacters()
	for c in chars:
		if not c.isAlive():
			c.cureFromDead()
			c.cure(1)
	resetSteps()
	resume()
	Save.autosave(self)

## Bridge (COTZ-005): where the player is, for a save made here: [floor
## name, node address, direction] (Save.labyrinthPosition, Load).
func save_position() -> Array:
	return [name, currentNode.getAddress(), dir]

func gameOver():
	exit("Game Over Screen", true)


## Port fix: Java's garbage collector freed the labyrinth together with its
## graph, player and battle, which refer back to it; reference counting
## cannot free that cycle, so every floor visited stayed in memory (and with
## a converted floor its scene). The references back are dropped when the
## floor is left (docs/ARCHITECTURE.md sections 8 and 10); not when it is
## suspended for the menu, which also ends with finishOff.
func finishOff() -> void:
	super.finishOff()
	if not isSuspended():
		releaseBackReferences()


## Also when the debug console jumps away (Organizer.jump_to skips finishOff);
## not for the Cheater, which can switch back to the floor.
func exitWithoutFading(p_mode: int) -> void:
	super.exitWithoutFading(p_mode)
	if p_mode == Values.EXIT:
		releaseBackReferences()


## Phase 2 (docs/ARCHITECTURE.md section 10): reports in the log that the
## floor's mode is freed (its scene with it), so parity runs show that every
## floor left is.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("Labyrinth: freed %s" % name)


func releaseBackReferences():
	if graph != null:
		graph.setLabyrinth(null)
	if player != null:
		player.labyrinth = null
	if labDrawable != null and "starter" in labDrawable:
		labDrawable.starter = null

## Java exit(String next, boolean fadeBattleMusic); exit(int) is GameMode's.
func exit(next = null, fadeBattleMusic = null):
	if next is int:
		super.exit(next)
		return
	if not isFading():
		resetSteps()
		if fadeBattleMusic and labDrawable != null and labDrawable is BattleManager:
			labDrawable.setMusicMode(SoundValues.FADE_OUT, 4000,
				SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN)
		setFadeOutSpeed(0.01)
		nextPlace = next
		super.exit(Values.EXIT)

## Enters the riddle mode; riddleClassName is the Java class name.
func enterRiddle(name, riddleClassName, hinders):
	push()
	runSubGameMode = true
	setMusicMode(SoundValues.FADE_OUT, SoundValues.SLOW, SoundValues.HALF)
	var riddle = ClassRegistry.newInstance(riddleClassName)
	if riddle != null:
		riddle.init(name, self, hinders)
		labDrawable = riddle

func exitRiddle():
	runSubGameMode = false
	setMusicMode(SoundValues.FADE_IN, SoundValues.SLOW, SoundValues.ALL_THE_WAY)
	labDrawable = null
	resume()
	pop()

func getBattleInfo(boss, bossName):
	var info := {}
	info["music"] = battleMusic[1] if boss else battleMusic[0]
	info["boss"] = "true" if boss else "false"
	info["name"] = bossName if boss else name
	return info

func checkButtons():
	if dialog == null:
		if gameActions[UP].isPressed():
			move(dir)
		elif gameActions[DOWN].isPressed():
			move(Values.getCounterAngle(dir))
		elif gameActions[LEFT].isPressed():
			turn(LabyrinthPlayer.LEFT_TURN)
		elif gameActions[RIGHT].isPressed():
			turn(LabyrinthPlayer.RIGHT_TURN)
		if MenuStarter.isMenuButtonPressed(gameActions):
			super.queueEnterMenu()
		elif MenuStarter.isMapButtonPressed(gameActions):
			super.queueEnterMap()
	else:
		var button: int = -1
		if gameActions[UP].isPressed():
			button = UP
		elif gameActions[DOWN].isPressed():
			button = DOWN
		elif gameActions[LEFT].isPressed():
			button = LEFT
		elif gameActions[RIGHT].isPressed():
			button = RIGHT
		if button != -1:
			Dialog.getDialog().move(button)
	if gameActions[CROSS].isPressed():
		exitDialog()
		checkNode(dir)

## Java move(int dir).
func move(direction, diagonal = null):
	var d: int = direction
	var n = currentNode.getNode(d)
	if n != null and not graph.checkForHinder(currentNode, n, d) and not graph.checkBossNode(n, self):
		lastAddress = currentNode.getAddress()
		currentNode = n
		player.moveTo(currentNode, self)
		Load.getPartyItems().takeStep()
		steps += 1
		tempTotalSteps += 1
		Load.cureParty()
		inputManager.resetAllGameActions()

func getPlayerAngle():
	return player.getDirection()

func getPlayerDirection():
	return dir

func turn(turnDir):
	dir += turnDir
	if dir < 0:
		dir = Values.LEFT
	elif dir > Values.LEFT:
		dir = Values.UP
	player.turnYTo(Values.TO_ANGLE[dir], turnDir)
	inputManager.resetAllGameActions()

func draw(g, alpha = null):
	# Phase 2 step B: a converted floor's scene draws what the display list,
	# the objects and the weather drew (show_scene, show_weather).
	var scene = ensure_scene() as DungeonScene
	if not labyrinthInitiaded:
		if scene != null:
			init_scene_3d(g, scene)
		else:
			init3D(g)
		labyrinthInitiaded = true

	player.lookAt(g)
	if scene != null:
		show_scene(g, scene)
	else:
		g.callList(drawList)
		graph.drawInventory(g)
	g.setLightEnabled(false)

	if weatherSystem != null:
		if scene != null:
			show_weather(g, scene, false)
		else:
			weatherSystem.draw(g, player, false)
	if runSubGameMode:
		g.push()
		drawExtra(g, false)
		g.pop()

	if weatherSystem != null:
		# Over a battle or riddle the legacy front pass draws (into the
		# scene's 3D world, after the battle), as it did over the walls.
		if scene != null and not runSubGameMode:
			show_weather(g, scene, true)
		else:
			if scene != null:
				scene.hide_weather(&"front")
			weatherSystem.draw(g, player, true)
	g.loadIdentity()
	g.getGL().glDepthMask(false)
	g.getGL().glDisable(Graphics.GL_DEPTH_TEST)
	mapRenderer.draw(g, player.get_(), player.getDirection(), currentNode.getAddress(), lastAddress)

	g.loadIdentity()
	GameEventListener.set2DNow(g)
	if mission != null:
		mission.draw(g)
	if dialog != null:
		g.setColor(1)
		Dialog.getDialog().draw(g)
		if card != null:
			DeckPage.drawCardInfo(g, card, 530)
	if runSubGameMode:
		g.push()
		drawExtra(g, true)
		g.pop()
	if not topLayer.is_empty():
		g.push()
		for i in topLayer.values():
			i.drawTopLayer(g)
		g.pop()
	super.draw(g)

	g.setLightEnabled(true)
	super.checkMenu()

func addTopLayer(i):
	topLayer[ClassRegistry.getClassName(i)] = i

func removeFromTopLayer(i):
	topLayer.erase(ClassRegistry.getClassName(i))

func drawExtra(g, isTopLayer):
	if not subGameModeInitiated:
		labDrawable.initDraw(g)
		subGameModeInitiated = true
	if isTopLayer:
		labDrawable.drawTopLayer(g)
	else:
		labDrawable.draw(g)

func checkSteps():
	if currentStepsToBattle == -1:
		return false
	return not noEncounters and (steps >= currentStepsToBattle and hasEnemies)

func isFading():
	return super.isFading()

func resetSteps():
	steps = 0
	if stepsToBattle[0] == -1:
		currentStepsToBattle = -1
	else:
		currentStepsToBattle = JRandom.new().nextInt(stepsToBattle[1]) + stepsToBattle[0]

func setNextPlace(next):
	self.nextPlace = next

func checkNextPlace():
	return nextPlace

func exitLabyrinth(exitMode):
	exit(exitMode)

## Java overloads drawDialog(first, second),
## drawDialog(firstDialogImage, name, first, second, whisper),
## drawDialog(DialogSequence) and drawDialog(ArrayList<DialogSequence>).
func drawDialog(firstDialogImage, name = null, first = null, second = null, whisper = null):
	if firstDialogImage is bool:
		drawDialog(DialogSequence.new(name, first, second, firstDialogImage, whisper))
	elif firstDialogImage is String:
		drawDialog(DialogSequence.new(firstDialogImage, name))
	elif firstDialogImage is Array:
		var dia: Array = firstDialogImage
		dialog = dia[0]
		dialogSequence = dia
		Dialog.getDialog().resetDialog()
		Dialog.getDialog().setDS(dialogSequence, null)
		push()
	else:
		dialog = firstDialogImage
		Dialog.getDialog().setDS(dialog)
		push()

func exitDialog():
	if Dialog.getDialog().isFinished():
		if dialog != null:
			pop()
			dialog = null
			card = null

func push():
	mapRenderer.pushState()
	mapRenderer.hide()
	if mission != null:
		mission.pushState()
		mission.hide()

func pop():
	mapRenderer.popState()
	if mission != null:
		mission.popState()

func drawCard(c):
	card = c

func getName():
	return name

func getSimpleName():
	return J.split(name, "--")[0]

func getMainName():
	return infoMap.get("name")

func getFloorName():
	var s: Array = J.split(name, "--")
	if s.size() > 1:
		return s[1]
	return null

func getCurrentNode():
	return currentNode

func getMission():
	return mission

func getMissionNext():
	if mission != null:
		return mission.getNext()
	return null

func resetMissionNext():
	if mission != null:
		mission.resetNext()

func notifySwitchMusic(music, fadeSpeed):
	pass

func overwriteStarterMusic(music, oggPlayer):
	print("Overwrite")
	if self.oggPlayer != null:
		self.oggPlayer.exit()
	self.oggPlayer = oggPlayer
	self.music = music
