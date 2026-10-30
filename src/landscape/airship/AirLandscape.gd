class_name AirLandscape
extends AirLandscapeLoader
## Port of landscape.airship.AirLandscape: the airship game mode.

var currentNode = null
var currentPlace = ""


## Java: public void init(HashMap<String, String> info).
func init(name, lab = null, hinders = null):
	var info = name
	super.init(info)
	var nodeName: String = info.get("startNode")
	setCurrentNode(getNode(nodeName.replace("_", " ").replace("night", "")))
	airShip.setXandY(currentNode.getXpos(), currentNode.getYpos())
	if currentNode.isCross():
		currentNode = null
	airShip.standStill(Values.DOWN)
	inputManager.resetAllGameActions()

	logicLoading = false


## Java: public void resume(). With arguments this is GameMode's protected
## resume(detectionMode, ...) (resumeWith).
func resume(detectionMode = null, fadeMusic = null, fadein = null):
	if detectionMode == null:
		resumeWith(Values.DETECT_INIT)
	else:
		resumeWith(detectionMode, fadeMusic, fadein)


func update(elapsedTime: float):
	airShip.update(elapsedTime)
	checkNodes()
	checkGameInput()
	super.update(elapsedTime)


func checkNodes():
	var pos = airShip.getPos()
	if currentNode == null or not checkNode(currentNode, pos):
		var found: bool = false
		var i: int = 0
		while i < nodes.size() and not found:
			var n = nodes[i]
			if not n.isCross():
				found = checkNode(n, pos)
				if found:
					setCurrentNode(n)
			i += 1
		if not found:
			currentNode = null


func setCurrentNode(n):
	currentNode = n
	currentPlace = currentNode.getName()
	if currentPlace.contains("-mark"):
		currentPlace = J.split(currentPlace, "-mark")[0]


func checkNode(n, pos = null):
	var x: float = absf(pos[Values.X] - n.getXpos())
	var y: float = absf(pos[Values.Y] - n.getYpos())
	var sqrdist: float = x * x + y * y
	return sqrdist < 400


func checkGameInput():
	if airShip.isMoving():
		var shouldStop: bool = true
		for i in range(UP, LEFT + 1):
			if not gameActions[i].isReleased():
				shouldStop = false
		if shouldStop:
			airShip.standStill()
	else:
		airShip.standStill()
	checkDirectionalButtons()
	if gameActions[CROSS].isPressed():
		crossPressed()
	elif MenuStarter.isMenuButtonPressed(gameActions):
		super.queueEnterMenu()
	elif MenuStarter.isMapButtonPressed(gameActions):
		super.queueEnterMap()


func checkDirectionalButtons():
	for i in range(UP, LEFT + 1):
		if gameActions[i].isPressed():
			airShip.go(i - UP)


func crossPressed():
	if currentNode != null:
		Graphics.setFadeImage(Graphics.FADE_TO_BLACK)
		Database.addStatus("Landscape", currentNode.getZone())
		nextPlace = String(currentNode.getName()).replace(" ", "_").to_lower()
		mode = Values.EXIT
		exit(mode)


## The scene of the airship (docs/ARCHITECTURE.md section 13): the map's
## scene the loader built it from (WorldMapScene, scene_root), or none with
## --legacy=airship (drawn by legacy code).
func create_scene() -> Node:
	return scene_root


## The drawing method of the airship. A map scene draws the map, the
## airship and the name plate (Landscape.scene_bottom, scene_player,
## scene_top and show_name_plate: the drawing's state changes, each part in
## the legacy GL state).
func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(30)
	if scene_root is WorldMapScene:
		Landscape.scene_bottom(g, scene_root, background)
		Landscape.scene_player(g, scene_root, airShip)
		Landscape.scene_top(g, scene_root, background)
		Landscape.show_name_plate(g, nameBackGround, plateName() if currentNode != null else "",
				currentNode != null)
	else:
		background.drawBottom(g)
		airShip.draw(g)
		background.drawTop(g, false, null)
		g.drawCenteredImage(nameBackGround, 10)
		if currentNode != null:
			g.drawSingleCenteredText(plateName(), 60, 1, 0)
	super.checkMenu()
	super.draw(g)


## The name the plate shows for the current place: up to its first "-",
## without "land".
func plateName() -> String:
	var name: String = currentPlace
	if name.contains("-"):
		name = J.split(name, "-")[0]
	if name.begins_with("land"):
		name = name.replace("land", "")
	return name
