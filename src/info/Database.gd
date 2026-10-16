class_name Database
extends RefCounted
## Port of info.Database: manages the information in the database such as
## level information, character status, road status and so on.
## The maps start empty (Java: null until reset() is called by Organizer).

static var status = {}
static var levelInformation = {}
static var storedTriggers = {}
static var visitedLabyrinth = {}
static var visitedLabyrinthList = []
static var lastVisitedLabyrinth = null


static func reset():
	status = {}
	storedTriggers = {}
	levelInformation = {}
	# Port fix: Java parsed levels.bank once (LevelFactory static init), so a
	# second Load.loadGame left levelInformation empty. Re-parse lazily.
	LevelFactory.levelFactory = null
	visitedLabyrinth = {}
	visitedLabyrinthList = []


## Java overloads: addStatus(HashMap<String, Integer> triggers) and
## addStatus(String name, int value).
static func addStatus(name, value = null):
	if value == null:
		var triggers = name
		if triggers != null:
			for n in triggers:
				var v: int = triggers.get(n)
				addStatus(n, v)
		return
	var key: String = String(name).to_lower()
	status[key] = int(value)


static func incrementStatus(triggers):
	for n in triggers:
		var value: int = triggers.get(n)
		value += getStatusFor(n)
		addStatus(n, value)


## Updates the status information contained in the given dictionary.
static func updateStatus(triggers):
	addStatus(triggers)


## Adds the given level up information about the character with the given name.
static func addLevelUpInfo(name, info):
	levelInformation[name] = info


## Gets the level up information about the character with the given name,
## for the given level and class.
static func getLevelFor(name, nextLevel, currentClass):
	var key: String = str(name) + "=" + str(int(currentClass)) + ":" + str(int(nextLevel))
	var result = levelInformation.get(key)
	return result


## Gets the current status for the entity with the given name, or -1 if
## the given name does not have a status.
static func getStatusFor(name):
	var s = status.get(name)
	var retStatus: int = -1 if s == null else s
	if retStatus == -1:
		var n: String = Organizer.convert(name)
		s = status.get(n)
		retStatus = -1 if s == null else s
	return retStatus


## Gets the status for all the roads of the given zone (address -> status).
static func getOpenedRoads(zone):
	var oRoads := {}
	var land: int = Landscape.convert(zone)
	for key in status:
		if String(key).begins_with("road" + str(land)):
			var val: int = status.get(key)
			var addr: int = J.parseInt(J.split(key, "-")[1])
			oRoads[addr] = val
	return oRoads


## Gets the status for the normal cards from the store with the given name.
static func getStatusForDeckStore(storeName, size):
	var ret: Array = J.array(size, -1)
	var i: int = 0
	for key in status:
		if String(key).begins_with(storeName):
			ret[i] = status.get(key)
			i += 1
	return ret


## Stores the given trigger with the given name (e.g. "inn").
static func storeTriggers(name, trigger):
	storedTriggers[String(name).to_lower()] = trigger


## Gets the stored trigger with the given name.
static func getStoredTriggers(name):
	return storedTriggers.get(String(name).to_lower())


## Removes the stored trigger stored with the given name, if any exists.
static func clearStoredTriggers(name):
	storedTriggers.erase(String(name).to_lower())


## Prints all the information in the database into the given writer
## (an object with println(String), see Save.SaveWriter).
static func saveData(writer):
	for key in status:
		var val: int = status.get(key)
		writer.println("status " + String(key).replace(" ", "_") + " " + str(val))
	for key in storedTriggers:
		var val: String = storedTriggers.get(key)
		writer.println("storedTrigger " +
				String(key).replace(" ", "_") + " " + val.replace(" ", "_"))


## Opens all roads in the database.
static func openAllRoads():
	for key in status.keys():
		if String(key).begins_with("road"):
			status[key] = 1


## Adds the given labyrinth map to the visited labyrinths.
static func visitLabyrinth(name, map):
	var found: bool = false
	var info = null
	var keys: Array = visitedLabyrinth.keys()
	var idx: int = 0
	while idx < keys.size() and not found:
		var s = keys[idx]
		idx += 1
		info = visitedLabyrinth.get(s)
		found = String(name).begins_with(info.getLabyrinthName())
	lastVisitedLabyrinth = LabyrinthMap.convert(name)
	if not found:
		info = LabyrinthInfo.new(lastVisitedLabyrinth[0])
		visitedLabyrinth[info.getLabyrinthName()] = info
		visitedLabyrinthList.append(info.getLabyrinthName())
	info.addFloor(lastVisitedLabyrinth[1], map)


## Gets the name of the last visited labyrinth.
static func getLastVisitedLabyrinth():
	return lastVisitedLabyrinth


## Gets all visited labyrinths (name -> LabyrinthInfo).
static func getVisitedLabyrinths():
	return visitedLabyrinth


static func getVisitedLabyrinthsList():
	return visitedLabyrinthList


## Gets the labyrinth info with the given name.
static func getMap(name):
	return visitedLabyrinth.get(Load.prepare(J.split(name, "--")[0]))


static func setLastVisitedLabyrinth(lab):
	lastVisitedLabyrinth = lab


static func getStoredKeys():
	var keys: Array = status.keys()
	keys.sort()
	return keys
