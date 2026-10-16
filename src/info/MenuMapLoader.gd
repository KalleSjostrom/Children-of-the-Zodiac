class_name MenuMapLoader
extends AbstractMapLoader
## Port of info.MenuMapLoader.

var labyrinthName = ""
var map = null

func _init(name = null) -> void:
	labyrinthName = name
	map = LabyrinthMap.new()

## Java parseFile(String filename) delegating to parseFile(LabyrinthMaps, filename).
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.LabyrinthMaps, path)
	else:
		super.parseFile(path, filename)

func getMap():
	return map

func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "dir":
		var source: int = J.parseInt(tokenizer.nextToken())
		var dir: int = J.parseInt(tokenizer.nextToken())
		var destination: int = J.parseInt(tokenizer.nextToken())
		InsertNodes(source, dir, destination)
	elif command == "inv":
		var i = Inventory.createInventory(tokenizer, map, labyrinthName)
		if i != null:
			map.putInventory(i.getDatabaseName(), i)
	elif command == "mapPos":
		var mapPos: Array = J.array(2, 0)
		mapPos[0] = J.parseInt(tokenizer.nextToken())
		mapPos[1] = J.parseInt(tokenizer.nextToken())
		map.setMapPos(mapPos)

func InsertNodes(source, direction, destination):
	var sourceNode
	var destNode
	sourceNode = map.getNode(source)
	if sourceNode == null:
		sourceNode = LabyrinthNode.new(source)
		map.put(source, sourceNode)
	destNode = map.getNode(destination)
	if destNode == null:
		destNode = LabyrinthNode.new(destination)
		map.put(destination, destNode)
	sourceNode.putNeighbours(Values.getCounterAngle(direction), destNode)
	destNode.putNeighbours(direction, sourceNode)
