class_name Organizer
extends GameCore
## Port of organizer.Organizer: keeps track of the main game loop.
##
## Reads maps/Main/main.bank, which has information about where to "go" next,
## and switches between the game modes (title, villages, landscapes,
## labyrinths, menus, ...). Constructed as a singleton.

static var o: Organizer
static var continueMusic := false

var nextPlace = "Title Screen"
## Developer option (--load=<slot>): save slot loaded in init_ before the
## first game mode starts; the game then starts at the saved location.
var loadSlot := ""
var mainInfo := {}
var currentInfo = {}
var classMap := {}
var currentGameMode: GameMode
var previousGameMode: GameMode
var suspendedGameModes := GameModeQueue.new()
var mode := 0
var next := true


func _init() -> void:
	super.init()
	classMap = Values.getClassMap()
	o = self


static func getOrganizer() -> Organizer:
	return o


## Initializes the game: parses main.bank and starts the first game mode.
func init_(obs: Array = []) -> void:
	super.init2(obs)
	classMap = Values.getClassMap()
	mainInfo = GameResourceLoader.getResourceLoader().getMainInfo("main.bank")
	Values.init()
	if loadSlot != "":
		Load.loadGame(loadSlot)
		if nextPlace == "Title Screen":
			nextPlace = Load.getStartLocation()
	_initNext()


func _initNext() -> void:
	_checkNext()
	ImageHandler.setGameMode(mode)
	if mode == Values.LABYRINTH or mode == Values.BOSS_BATTLE_AREA:
		Values.zoom(false)
		GameEventListener.set3D()
	elif mode == Values.VILLAGE or mode == Values.VILLAGE_STORY:
		Values.zoom(true)
		GameEventListener.set2D()
	else:
		Values.zoom(false)
		GameEventListener.set2D()
	var className: String = classMap.get(mode, "")
	if className == "":
		push_error("Organizer: no game mode class for mode " + str(mode))
		return
	previousGameMode = currentGameMode
	if currentGameMode != null and currentGameMode.isSuspended():
		suspendedGameModes.push(currentGameMode)
	currentGameMode = ClassRegistry.newInstance(className)
	var newInfo
	if continueMusic:
		newInfo = {}
		if currentInfo != null:
			newInfo.merge(currentInfo)
		newInfo["music"] = "continue"
		continueMusic = false
	else:
		newInfo = currentInfo
	currentGameMode.init(newInfo)


func _checkNext() -> void:
	if next:
		currentInfo = getInformationFor(nextPlace)
		if currentInfo == null:
			# Java threw a NullPointerException; report the place and go to the title.
			push_error("Organizer: unknown place '%s' (not in main.bank)" % str(nextPlace))
			nextPlace = "Title Screen"
			currentInfo = getInformationFor(nextPlace)
		mode = J.parseInt(currentInfo["mode"])
		next = false


## Lower cases the given string and replaces '_' with ' '.
static func convert(s: String) -> String:
	return _convertChars(s.replace("_", " ").to_lower())


static func convertKeepCase(s: String) -> String:
	return _convertChars(s.replace("_", " "))


## Java removed 'NUL' characters here; GDScript strings cannot contain them.
static func _convertChars(s: String) -> String:
	return s


static func convertBack(string: String) -> String:
	return string.replace(" ", "_")


## Creates (and initializes) the game mode with the given name in main.bank.
func getGameMode(name: String) -> GameMode:
	var info: Dictionary = mainInfo.get(Organizer.convert(name))
	var m := J.parseInt(info["mode"])
	var gameMode: GameMode = ClassRegistry.newInstance(classMap[m])
	gameMode.init(info)
	return gameMode


static func continueMeusic() -> void:
	continueMusic = true


## Returns null when the place is unknown (as Java did).
func getInformationFor(p_nextPlace):
	var info = null
	if p_nextPlace != null:
		var np: String = Organizer.convert(str(p_nextPlace))
		info = {}
		if np.begins_with("land"):
			var startNode: String
			if np.begins_with("land::"):
				var i := J.split(np, "::")
				startNode = i[2]
				Landscape.setInfo(i[1])
			else:
				startNode = np.replace("land", "")
			var world: String = LandscapeLoader.checkPlace(startNode)
			info = mainInfo.get(world)
			info["startNode"] = startNode
		elif np.begins_with("air"):
			info = mainInfo.get("airworld")
			info["startNode"] = np.replace("air", "")
		else:
			info = mainInfo.get(np)
	return info


func _goBackToSuspendedMode() -> void:
	ImageHandler.swapGameMode()
	if suspendedGameModes.size() == 0:
		var temp := currentGameMode
		currentGameMode = previousGameMode
		previousGameMode = temp
	else:
		previousGameMode = currentGameMode
		currentGameMode = suspendedGameModes.pop()
	currentGameMode.resume()


func getNextSuspendedMode() -> GameMode:
	return suspendedGameModes.peek()


func setNext(p_next: bool) -> void:
	next = p_next


func updateNextPlaceFor(infoName: String, p_nextPlace: String) -> void:
	var info: Dictionary = mainInfo.get(Organizer.convert(infoName))
	info["nextPlace"] = p_nextPlace


func deleteSuspended() -> void:
	suspendedGameModes.delete()


## Updates the current mode and checks if it is time to exit it.
## elapsedTime is in milliseconds.
func update(elapsedTime: float) -> void:
	if currentGameMode == null or currentGameMode.isLoading():
		return
	currentGameMode.update(elapsedTime)
	if GameCore.inputManager.hasSelectDownBeenPressed() and not (currentGameMode is Cheater):
		currentGameMode.exitWithoutFading(Values.CHEATER)
		mode = currentGameMode.getExitMode()
		_initNext()
		return
	if currentGameMode.checkExit() != Values.NO_MODE_IS_SELECTED:
		currentGameMode.finishOff()
		mode = currentGameMode.getExitMode()
		next = currentGameMode.shouldGetInfoFromMain()
		nextPlace = currentGameMode.getNextPlace()
		currentInfo = currentGameMode.getInfoForNextPlace()
		if mode == Values.SWITCH_BACK:
			_goBackToSuspendedMode()
		else:
			_initNext()


func draw(g: Graphics) -> void:
	ImageHandler.load(g)
	if currentGameMode == null:
		return
	if ImageHandler.getLoadQueueSize() == 0:
		currentGameMode.loadingDone()
	if currentGameMode.isLoading():
		return
	currentGameMode.draw(g)


func closeGame(status: int) -> void:
	GameCore.exitGame()


func getPreviousMode() -> GameMode:
	return previousGameMode


func getCurrentMode() -> GameMode:
	return currentGameMode


func overwritePreviousMode(p_mode: GameMode) -> void:
	previousGameMode = p_mode


static func reset() -> void:
	Database.reset()


func isPausable() -> bool:
	if currentGameMode != null:
		return currentGameMode.isPausable()
	return false
