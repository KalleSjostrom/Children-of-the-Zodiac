class_name LabyrinthInfo
extends RefCounted
## Port of info.LabyrinthInfo.

const MAX_FLOORS = 6
var labyrinthName = ""
var floors = {}

func _init(labyrinthName = null) -> void:
	self.labyrinthName = labyrinthName

func getLabyrinthName():
	return labyrinthName

func getFloor(name, split):
	if split:
		name = J.split(name, "--")[1].replace(".map", "")
	var f = null
	var found: bool = false
	for v in floors.values():
		if found:
			break
		f = v
		found = f.getName().to_lower() == name.to_lower()
	return f if found else null

func addFloor(name, labyrinthMap):
	var found: bool = false
	for v in floors.values():
		if found:
			break
		found = v.getName().to_lower() == name.to_lower()
	if not found:
		labyrinthMap.setName(name)
		var p = labyrinthMap.getMapPos()
		var preferredIndex: int = p[1] * 3 + p[0]
		floors[preferredIndex] = labyrinthMap

func getFloors():
	var fl: Array = []
	for i in range(MAX_FLOORS):
		var f = floors.get(i)
		if f != null:
			fl.append(f)
	return fl

func getFirstFloor():
	var found: bool = false
	var floor = null
	var i: int = 0
	while i < MAX_FLOORS and not found:
		floor = floors.get(i)
		found = floor != null
		i += 1
	return floor

func isFullyExplored():
	var isFullyExplored_: bool = true
	for map in floors.values():
		if not isFullyExplored_:
			break
		isFullyExplored_ = map.isFullyVisited()
	return isFullyExplored_
