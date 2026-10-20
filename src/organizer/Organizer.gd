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
## Developer option (--start-time=<day|night>): the first place is started
## with this time of day (its info "time", read by VillageLoader.load), so
## the "at Night" village variants can be reached without a story.
var startTime := ""
## Developer option (--status=<name>:<value>,...): Database statuses set
## after the save slot is loaded, before the first game mode starts (for
## example a village status for a story that a shipped save cannot reach).
var startStatuses := {}
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
	for name in startStatuses:
		Database.addStatus(Organizer.convert(name), startStatuses[name])
	_initNext()


func _initNext() -> void:
	var newPlace: bool = next
	var leaving: GameMode = currentGameMode
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
	if startTime != "" and newInfo is Dictionary:
		# Developer option, first place only; main.bank's info is shared.
		newInfo = newInfo.duplicate()
		newInfo["time"] = startTime
		startTime = ""
	currentGameMode.init(newInfo)
	_autosaveOnEntering(newPlace, leaving)


## Port addition (COTZ-005): autosave (Easy and Medium) when a village, a
## labyrinth floor, the world map or the airship is entered from another
## place. Not when a game is loaded (from the title, the menu or the command
## line): that would overwrite the autosave with an older game.
func _autosaveOnEntering(newPlace: bool, leaving: GameMode) -> void:
	if not newPlace or leaving == null or leaving is TitleScreen or leaving is MainMenu:
		return
	if mode == Values.VILLAGE or mode == Values.LABYRINTH or mode == Values.LANDSCAPE 			or mode == Values.AIR_SHIP:
		Save.autosave_at(str(nextPlace))


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
	# Java: Select + Down opened the Cheater here; the debug console's
	# "cheater" command does now (open_cheater, COTZ-006).
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


## Bridge (COTZ-006, the debug console): goes to a main.bank place now,
## leaving the current mode without its finishOff or a fade, as the
## Cheater's jumps do. The "Start" game is loaded first when none is.
func jump_to(place: String) -> void:
	if not Load.hasLoaded():
		Load.loadGame("Start")
	if currentGameMode != null:
		currentGameMode.exitWithoutFading(Values.EXIT)
	nextPlace = place
	next = true
	_initNext()


## Bridge (COTZ-006): opens the developer Cheater's menu of places (what
## Select + Down did).
func open_cheater() -> void:
	if currentGameMode == null or currentGameMode is Cheater:
		return
	currentGameMode.exitWithoutFading(Values.CHEATER)
	mode = currentGameMode.getExitMode()
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
