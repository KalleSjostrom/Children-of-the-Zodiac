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


## The drawing method of landscape.
func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(30)
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
			var name: String = currentNode.getName()
			if name.contains("-"):
				name = J.split(name, "-")[0]
			g.drawSingleCenteredText(name, 60, 1, 0)
	if message:
		Dialog.getDialog().draw(g, true, "Kin", "We can't enter now!", "", false)
	super.checkMenu()
	super.draw(g)


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
