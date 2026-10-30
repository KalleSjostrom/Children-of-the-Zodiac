class_name Landscape
extends LandscapeLoader
## Port of landscape.Landscape: the landscape game mode.

const WEST_CONTINENT = 0
const EAST_CONTINENT = 1
const NORTH_CONTINENT = 2
const NORMAL = 0
const CONTINUE_MUSIC = 1
const NIGHT_MUSIC = 2
## Java: public static int music.
static var music_ = 0
var currentNode = null
var currentRoad = null
var visitedNodes = []
var visitedRoads = {}
var speed: int = 40
var stepTime: int = 0
var playerAngle: int = 0
var zerotime: int = 0
var animate: bool = false
var message: bool = false

const BRIDGE_TEST_SCENE := "res://tools/bridge_test/BridgeTest.tscn"
## Bridge (phase 4.1 step B): the UI node of the name plate.
const NAME_PLATE_VIEW := "res://scenes/ui/NamePlate.tscn"


## Java: public void init(HashMap<String, String> info). The first argument
## is the info map.
func init(name, lab = null, hinders = null):
	var info = name
	var newInfo = info
	if music_ != NORMAL:
		newInfo = {}
		newInfo.merge(info, true)
		var m = ""
		match music_:
			NIGHT_MUSIC:
				m = str(info.get("music")) + "night"
			CONTINUE_MUSIC:
				m = "continue"
			_:
				m = info.get("music")
		newInfo["music"] = m
	super.init(newInfo)
	var nodeName: String = newInfo.get("startNode")
	var zone = LandscapeLoader.checkPlace(nodeName)
	openRoads(zone)
	var v = Visited.getVisited()
	var vRoads = v.getVroads(zone)
	for i in vRoads:
		var r = getRoad(i)
		visitedRoads[r.getAddress()] = r
		r.visit()
	var vNodes = v.getVnodes(zone)
	for s in vNodes:
		var n = getNode(s)
		n.visit()
		visitedNodes.append(n)
	currentNode = getNode(nodeName.replace("_", " ").replace("night", ""))

	if not currentNode.isVisited():
		visitedNodes.append(currentNode)
		currentNode.visit()
	for i in range(4):
		var r = currentNode.getRoad(i)
		if r != null and not r.isClosed():
			visitedRoads[r.getAddress()] = r
			r.visit()
	player.setXandY(currentNode.getXpos(), currentNode.getYpos())
	player.standStill(Values.DOWN)
	inputManager.resetAllGameActions()

	music_ = NORMAL
	logicLoading = false


func openRoads(zone):
	openClosedRoads(Database.getOpenedRoads(zone))


## Java: public void resume() restores the landscape. With arguments this is
## GameMode's protected resume(detectionMode, ...) (resumeWith).
func resume(detectionMode = null, fadeMusic = null, fadein = null):
	if detectionMode == null:
		resumeWith(Values.DETECT_INIT, not resumedFromMenu())
	else:
		resumeWith(detectionMode, fadeMusic, fadein)


## Updates the positions if the player has pressed something.
func update(elapsedTime: float):
	if animate:
		var step: int = (J.currentTimeMillis() - zerotime) / speed
		if step >= stepTime:
			var ang: int = currentRoad.movePlayer(player, step)
			if ang == -1:
				stopMoving()
			elif playerAngle != ang:
				playerAngle = ang
				player.move(playerAngle)
			stepTime += 1
		player.update(int(elapsedTime))
	else:
		checkGameInput()
	super.update(elapsedTime)


## Starts moving the landscape player in the given direction.
func startMoving(dir):
	animate = true
	zerotime = J.currentTimeMillis()
	stepTime = 0
	playerAngle = dir
	player.move(playerAngle)


## Closes the animation and changes the current node.
func stopMoving():
	animate = false
	currentNode = currentRoad.getDest()
	if not currentNode.isVisited():
		visitedNodes.append(currentNode)
		currentNode.visit()

	for i in range(4):
		var r = currentNode.getRoad(i)
		if (r != null and not r.isClosed() and r != currentRoad
				and not visitedRoads.has(r.getAddress())):
			visitedRoads[r.getAddress()] = r
			r.visit()

	player.standStill(playerAngle)
	currentRoad = null
	resetAll()


## Gets the names of all the visited nodes in the landscape.
func getVisitedNodes():
	var vn: Array = []
	for i in range(visitedNodes.size()):
		vn.append(visitedNodes[i].getName())
	return vn


## Gets the addresses of all the visited roads in the landscape.
func getVisitedRoads():
	var retArray: Array = []
	for k in visitedRoads:
		retArray.append(k)
	return retArray


## Checks the game input.
func checkGameInput():
	if not animate:
		var angle: int = -1
		var somethingsPressed: bool = true
		if gameActions[UP].isPressed():
			angle = Values.UP
		elif gameActions[RIGHT].isPressed():
			angle = Values.RIGHT
		elif gameActions[DOWN].isPressed():
			angle = Values.DOWN
		elif gameActions[LEFT].isPressed():
			angle = Values.LEFT
		elif gameActions[CROSS].isPressed():
			if not message:
				somethingsPressed = false
			crossPressed()
		elif gameActions[SQUARE].isPressed():
			if Database.getStatusFor("airship") >= 1:
				nextPlace = "air" + String(currentNode.getName()).replace(" ", "_")
				exitLandscape(Values.EXIT, currentNode.getName())
		elif MenuStarter.isMenuButtonPressed(gameActions):
			super.queueEnterMenu()
		else:
			somethingsPressed = false
		if somethingsPressed and message:
			message = false
		if angle != -1:
			var r = currentNode.getRoad(angle)
			if r != null and not r.isClosed():
				r.setIsSource(currentNode.isSource(angle))
				currentRoad = r
				startMoving(angle)


## Executes the events when the cross button is pressed.
func crossPressed():
	var s: String = String(currentNode.getName()).replace(" ", "_") + "node"
	var status: int = Database.getStatusFor(Organizer.convert(s))
	var p_mode: int = -1
	var zone: String = currentNode.getName()
	if status != -2:
		if status == -1 or status == 0:
			nextPlace = currentNode.getName()
			if currentNode.getType() == "village":
				nextPlace = J.split(nextPlace, "-mark")[0]
				p_mode = Values.VILLAGE
				VillageLoader.staticStartPos = 0
			elif currentNode.getType() == "labyrinth":
				p_mode = Values.LABYRINTH
		else:
			nextPlace = s + str(status)
			p_mode = Values.VILLAGE_STORY
			VillageLoader.staticStartPos = 0
		if p_mode != -1:
			exitLandscape(p_mode, zone)
	else:
		message = true


func exitLandscape(p_mode, place):
	var zone = LandscapeLoader.checkPlace(place)
	Visited.getVisited().setVnodes(zone, getVisitedNodes())
	Visited.getVisited().setVroads(zone, getVisitedRoads())
	exit(p_mode)


## The scene of the world map (docs/ARCHITECTURE.md section 13): the map's
## scene the loader built it from (WorldMapScene, scene_root), or none with
## --legacy=world_map (drawn by legacy code); with Main --bridge-test (dev
## only, which implies --legacy=world_map) the bridge test's placeholder,
## which stands in for the background tiles (section 8).
func create_scene() -> Node:
	if scene_root != null:
		return scene_root
	if Main.bridge_test:
		var packed: PackedScene = ResourceLoader.load(BRIDGE_TEST_SCENE)
		return packed.instantiate()
	return null


## The drawing method of landscape. A map scene draws the map (draw_scene);
## another scene (the bridge test) shows instead of the background tiles.
func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(30)
	if scene_root is WorldMapScene:
		draw_scene(g)
	else:
		if scene_root == null:
			background.drawBottom(g)
		for address in visitedRoads:
			visitedRoads.get(address).drawRoad(g)
		for i in range(nodes.size()):
			if nodes[i].isVisited():
				nodes[i].draw(g)
		player.draw(g)
		background.drawTop(g, false, null)
		g.drawCenteredImage(nameBackGround, 10)
		if not animate:
			if currentNode.getType() != "crossroad":
				g.drawSingleCenteredText(plateName(currentNode.getName()), 60, 1, 0)
	if message:
		Dialog.getDialog().draw(g, true, "Kin", "We can't enter now!", "", false)
	super.checkMenu()
	super.draw(g)


## The name the plate shows for a node's name: up to its first "-".
static func plateName(name: String) -> String:
	if name.contains("-"):
		name = J.split(name, "-")[0]
	return name


## Bridge (phase 4.1 step B, docs/ARCHITECTURE.md section 13): the scene
## draws what draw would draw (drawBottom, the visited roads' dots, the
## visited nodes, the player and drawTop), each part with the colour and the
## material of the GL state where it would be drawn, and the drawing's state
## changes are made: each image's bind (Graphics.skip_image), drawTop's
## alpha test. The name plate is a UI node (show_name_plate).
func draw_scene(g):
	var scene: WorldMapScene = scene_root
	scene_bottom(g, scene, background)
	var color: Color = g.getCurrentColor()
	var mat = g.canvas_material()
	var addresses := PackedInt32Array()
	for address in visitedRoads:
		addresses.append(address)
		for dot in visitedRoads.get(address).dots:
			g.skip_image(dot.dot)
	scene.show_roads(addresses, color, mat)
	var visited: Array[bool] = []
	for i in range(nodes.size()):
		visited.append(nodes[i].isVisited())
		if nodes[i].isVisited():
			g.skip_image(nodes[i].im)
	scene.show_nodes(visited, color, mat)
	scene_player(g, scene, player)
	scene_top(g, scene, background)
	var with_name: bool = not animate and currentNode.getType() != "crossroad"
	show_name_plate(g, nameBackGround, plateName(currentNode.getName()) if with_name else "", with_name)


## Bridge (phase 4.1 step B): DoubleBackground.drawBottom for a map scene
## (also the airship's): the binds of the tiles drawBottomLayer draws (the
## maps never scroll: all of them), then the scene's background in the GL
## state. The maps have no particle systems and no extra background.
static func scene_bottom(g, scene, bg) -> void:
	var pos: Array = bg.getPos()
	for i in range(bg.HORIZONTAL_IMAGES):
		var x: int = int(i * bg.imageWidth + pos[Values.X]) + bg.offsetx
		if x > -bg.imageWidth and x < Values.ORIGINAL_RESOLUTION[Values.X]:
			for j in range(bg.VERTICAL_IMAGES):
				var y: int = int(j * bg.imageHeight + pos[Values.Y] + bg.offsety)
				if y > -bg.imageHeight and y < Values.ORIGINAL_RESOLUTION[Values.Y]:
					g.skip_image(bg.bg[i][j])
	scene.show_background(g.getCurrentColor(), g.canvas_material())


## Bridge (phase 4.1 step B): LandPlayer.draw (the player or the airship)
## for a map scene: the image where it would be drawn (place_view: the
## legacy rounding), bound as drawImage binds it.
static func scene_player(g, scene, sprite) -> void:
	var color: Color = g.getCurrentColor()
	var mat = g.canvas_material()
	var placed: Array = sprite.place_view()
	var t = g.skip_image(placed[0])
	scene.show_player(t.getGodotTexture() if t != null else null, Vector2i(placed[1], placed[2]),
			color, mat)


## Bridge (phase 4.1 step B): DoubleBackground.drawTop(g, false, null) for a
## map scene: every top layer piece (bound), the alpha test 0 it sets, then
## the night layer when the map was loaded at night (nightTop; drawn only
## when its image exists: East's and North's, standardOvernight.png, does
## not).
static func scene_top(g, scene, bg) -> void:
	var color: Color = g.getCurrentColor()
	var mat = g.canvas_material()
	for entry in bg.top:
		g.skip_image(entry[1])
	g.setAlphaFunc(0)
	var night_shown := false
	if bg.nightTop != null:
		night_shown = g.skip_image(bg.nightTop) != null
	scene.show_top(color, mat, night_shown, g.getCurrentColor(), g.canvas_material())


## Bridge (phase 4.1 step B, docs/ARCHITECTURE.md section 13): the name plate
## of the world map and the airship without the drawing: drawCenteredImage
## of plate at y 10 (its bind) and, with_name, drawSingleCenteredText of name
## at y 60 (startText(1, 0) and finishText: the text colour, alpha and the
## current colour it leaves); the UI node scenes/ui/NamePlate.tscn shows
## them where they would be drawn (Graphics.show_ui), in the colour, font
## and material of the legacy drawing.
static func show_name_plate(g, plate, name: String, with_name: bool) -> void:
	var tint: Color = g.getCurrentColor()
	var mat = g.canvas_material()
	var t = g.skip_image(plate)
	var at := Vector2i.ZERO
	if t != null:
		at = Vector2i(Values.ORIGINAL_RESOLUTION[Values.X] / 2 - J.round(t.getWidth() / 2.0), 10)
	var color := Color.BLACK
	var bold := false
	if with_name:
		g.startText(1, 0)
		color = Graphics.text_color(g.text_alpha())
		bold = Graphics.font_bold()
		g.finishText()
	var view = g.show_ui(NAME_PLATE_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_plate(t != null, at, tint, name if with_name else "", color, mat, bold)


func getName():
	return "Landscape" if currentNode == null else currentNode.getName()


static func convert(zone):
	var land: int = 0
	if zone.contains("0"):
		land = WEST_CONTINENT
	elif zone.contains("1"):
		land = EAST_CONTINENT
	elif zone.contains("2"):
		land = NORTH_CONTINENT
	return land


static func setInfo(string):
	if string.begins_with("normal"):
		music_ = NORMAL
	elif string.begins_with("continue"):
		music_ = CONTINUE_MUSIC
	elif string.begins_with("night"):
		music_ = NIGHT_MUSIC


static func isNight():
	return music_ != NORMAL
