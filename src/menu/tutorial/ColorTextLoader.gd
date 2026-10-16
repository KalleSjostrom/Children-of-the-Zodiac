class_name ColorTextLoader
extends AbstractMapLoader
## Port of menu.tutorial.ColorTextLoader: parses the tutorial (.tut) and help
## (.help) files under Values.Tutorials into chapters of colored rows.

var currentChapter = null
var title = null
var currentMap = null
var vectorVariables: Dictionary = {}
var book: Dictionary = {}
var x: int = 0
var y: int = 0

func _init(x = null, y = null) -> void:
	self.x = x
	self.y = y

## Java: parseFile(String filename) -> super.parseFile(Values.Tutorials, filename).
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.Tutorials, path)
	else:
		super.parseFile(path, filename)

func executeCommand(command: String, tokenizer: StringTokenizer):
	var t: StringTokenizer = tokenizer
	if command == "title":
		var args: Array = Parser.getArgument(t.nextToken())
		title = Parser.getText(t, args[1])[0]
	elif command == "newtext":
		currentChapter = Chapter.new(x, y)
	elif command == "addRow":
		var args: Array
		var newpage: bool = false
		var usemap: bool = false
		var button: int = -1
		var xoffset: int = 0
		var yoffset: int = 0
		var iconxoffset: int = 0
		var iconyoffset: int = 0
		var iconscale: float = 1
		var temp = null
		var iconName = null
		var icon = null

		while t.hasMoreTokens():
			args = Parser.getArgument(t.nextToken())
			if args[0] == "newpage":
				newpage = J.parseBoolean(args[1])
			elif args[0] == "text":
				temp = Parser.getText(t, args[1])
			elif args[0] == "usemap":
				usemap = J.parseBoolean(args[1])
			elif args[0] == "button":
				button = getButton(args[1])
				iconName = AbstractPage.BUTTON_ICONS[button]
			elif args[0] == "xoffset":
				xoffset = J.parseInt(args[1])
			elif args[0] == "yoffset":
				yoffset = J.parseInt(args[1])
			elif args[0] == "icon":
				iconName = Values.res + args[1].replace("_", " ")
			elif args[0] == "iconxoffset":
				iconxoffset = J.parseInt(args[1])
			elif args[0] == "iconyoffset":
				iconyoffset = J.parseInt(args[1])
			elif args[0] == "iconscale":
				iconscale = J.parseFloat(args[1])
		if iconName != null:
			icon = Icon.new(iconName, iconxoffset, iconyoffset, iconscale)
		var map = currentMap if usemap else null
		currentChapter.addRow(newpage, xoffset, yoffset, temp[0], map, icon)
	elif command == "putMap":
		if currentMap == null:
			currentMap = {}
		var index: int = 0
		var vec = null
		while t.hasMoreTokens():
			var args: Array = Parser.getArgument(t.nextToken())
			if args[0] == "vector":
				vec = vectorVariables.get(args[1])
				if vec == null:
					var v: Array = J.split(args[1], ",")
					vec = Vector3f.new(J.parseFloat(v[0]), J.parseFloat(v[1]), J.parseFloat(v[2]))
			elif args[0] == "index":
				index = J.parseInt(args[1])
		currentMap[index] = vec
	elif command == "newMap":
		currentMap = {}
	elif command == "var":
		var name = null
		var type = null
		while t.hasMoreTokens():
			var args: Array = Parser.getArgument(t.nextToken())
			if args[0] == "type":
				type = args[1]
			elif args[0] == "name":
				name = args[1]
			elif args[0] == "value":
				if type == "vector":
					var v: Array = J.split(args[1], ",")
					var vec = Vector3f.new(J.parseFloat(v[0]), J.parseFloat(v[1]), J.parseFloat(v[2]))
					vectorVariables[name] = vec
	elif command == "put":
		var turn: int = 0
		while t.hasMoreTokens():
			var args: Array = Parser.getArgument(t.nextToken())
			if args[0] == "turn":
				turn = J.parseInt(args[1])
		book[turn] = currentChapter

func getButton(button):
	var b: int = -1
	if button == "leftright":
		b = GameMode.LEFT_RIGHT
	elif button == "cross":
		b = GameMode.CROSS
	elif button == "circle":
		b = GameMode.CIRCLE
	elif button == "triangle":
		b = GameMode.TRIANGLE
	elif button == "square":
		b = GameMode.SQUARE
	elif button == "l1r1":
		b = GameMode.L1R1
	elif button == "l2r2":
		b = GameMode.L2R2
	elif button == "r1":
		b = GameMode.R1
	elif button == "r2":
		b = GameMode.R2
	elif button == "updown":
		b = GameMode.UP_DOWN
	return b

func getCurrentChapter():
	return currentChapter

func getBook():
	return book

func getTitle():
	return title

func getFirstPage():
	return book.get(0).getPage(0)
