class_name GameResourceLoader
extends AbstractMapLoader
## Port of organizer.ResourceLoader.
##
## Loads the resources used in the game. Java paths such as "res/Village/a.png"
## or "maps/Main/main.bank" are resolved case-insensitively against
## res://file_index.txt and mapped to "res://res/Village/a.png".

static var resLoader: GameResourceLoader

var mainInfo := {}
var variables := {}

static var _index := {} # lower-case path -> real path (without res://)
static var _dirs := {} # lower-case directories of the indexed files
static var _index_loaded := false


static func getResourceLoader() -> GameResourceLoader:
	if resLoader == null:
		resLoader = GameResourceLoader.new()
	return resLoader


static func _load_index() -> void:
	if _index_loaded:
		return
	_index_loaded = true
	var text := FileAccess.get_file_as_string("res://file_index.txt")
	for line in text.split("\n", false):
		var lower := line.to_lower()
		_index[lower] = line
		var dir := lower.get_base_dir()
		while dir != "" and not _dirs.has(dir):
			_dirs[dir] = true
			dir = dir.get_base_dir()


static func _normalize(name: String) -> String:
	var p := name.replace("\\", "/")
	if p.begins_with("res://"):
		p = p.substr(6)
	while p.begins_with("/") or p.begins_with("./"):
		p = p.substr(1) if p.begins_with("/") else p.substr(2)
	while p.contains("//"):
		p = p.replace("//", "/")
	return p


## Resolves a Java style resource path to a "res://" path, or "" if missing.
static func resolve(name: String) -> String:
	_load_index()
	var p := _normalize(name)
	var real: String = _index.get(p.to_lower(), "")
	if real == "":
		# Images were sometimes saved with the wrong extension.
		var base := p.get_basename().to_lower()
		for ext in [".png", ".jpg", ".jpeg"]:
			real = _index.get(base + ext, "")
			if real != "":
				break
	if real == "":
		return ""
	return "res://" + real


## Checks if the file or directory with the given name exists (Java's
## URL.getContent() also succeeds for directories, e.g. the tile folders
## "<name> at Nightfolder" that DoubleBackground looks for).
func exists(name: String) -> bool:
	return resolve(name) != "" or isDirectory(name)


static func isDirectory(name: String) -> bool:
	_load_index()
	var p := _normalize(name).to_lower()
	if p.ends_with("/"):
		p = p.left(-1)
	return _dirs.has(p)


static func fileExists(name: String) -> bool:
	return resolve(name) != ""


## Lists the file names (not paths) in the given directory, like File.list().
static func listFiles(dir: String) -> Array:
	_load_index()
	var d := _normalize(dir).to_lower()
	if not d.ends_with("/"):
		d += "/"
	var out: Array = []
	for k in _index:
		if k.begins_with(d) and not k.substr(d.length()).contains("/"):
			out.append(String(_index[k]).get_file())
	out.sort()
	return out


## Lists the sub directories of the given directory.
static func listDirectories(dir: String) -> Array:
	_load_index()
	var d := _normalize(dir).to_lower()
	if not d.ends_with("/"):
		d += "/"
	var seen := {}
	for k in _index:
		if k.begins_with(d):
			var rest: String = k.substr(d.length())
			var slash := rest.find("/")
			if slash > 0:
				var real: String = _index[k]
				seen[real.substr(d.length(), slash)] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## Reads a whole text file. Returns "" (and reports an error) if it is missing.
static func readText(name: String) -> String:
	var path := resolve(name)
	if path == "":
		push_error("ResourceLoader: file not found: " + name)
		return ""
	return _readFileText(path)


## Reads a UTF-8 file, dropping NUL bytes. Some of the original data files
## have stray NULs (e.g. "timea=450\0", "mark\00"); Godot stops decoding at
## the first one, which silently cut those files short. Java kept them as
## characters that trim() removed, so dropping them matches the original.
static func _readFileText(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	var nul := bytes.find(0)
	if nul == -1:
		return bytes.get_string_from_utf8()
	var clean := PackedByteArray()
	var start := 0
	while nul != -1:
		clean.append_array(bytes.slice(start, nul))
		start = nul + 1
		nul = bytes.find(0, start)
	clean.append_array(bytes.slice(start))
	return clean.get_string_from_utf8()


## Gets a line reader (java.io.BufferedReader) for the file path + filename.
func getBufferedReader(path: String, filename: String = "") -> BufferedReader:
	var full := path + filename
	var res := resolve(full)
	if res == "":
		push_error("ResourceLoader: file not found: " + full)
		return null
	return BufferedReader.new(_readFileText(res))


func parseFile(path: String, filename: String = "") -> void:
	if filename == "":
		super.parseFile(Values.MainMap, path)
	else:
		super.parseFile(path, filename)


func executeCommand(command: String, tok: StringTokenizer) -> void:
	var argument: Array
	var key: String
	var value
	if command == "place":
		var name = null
		var info := {}
		while tok.hasMoreTokens():
			argument = Parser.getArgument(tok.nextToken())
			key = argument[0]
			if String(argument[1]).begins_with("\""):
				value = Parser.getText(tok, argument[1])[0]
			else:
				value = variables.get(argument[1])
			if key == "name":
				name = value
			info[key] = value
		if name == null:
			Parser.error(str(lineCount) + " No Name Found!")
		var n := Organizer.convert(name)
		mainInfo[n] = info
	elif command == "var":
		argument = Parser.getArgument(tok.nextToken())
		key = argument[0]
		value = Parser.getText(tok, argument[1])[0]
		variables[key] = value
	else:
		Parser.error(str(lineCount) + " Unknown command " + command)


func getMainInfo(filename: String) -> Dictionary:
	parseFile(filename)
	return mainInfo


## Gets the image with the given path (java.awt.image.BufferedImage -> Image).
func getBufferedImage(name: String) -> Image:
	return ImageHandler.getImage(name)


## Java's ResourceLoader.getURL: here simply the resolved res:// path.
func getURL(name: String) -> String:
	return resolve(name)


## java.io.BufferedReader over a whole text file.
class BufferedReader extends RefCounted:
	var _lines: PackedStringArray
	var _pos := 0

	func _init(text: String) -> void:
		_lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
		# A trailing newline does not produce an extra (empty) line in Java.
		if _lines.size() > 0 and _lines[_lines.size() - 1] == "":
			_lines.resize(_lines.size() - 1)

	## Returns the next line, or null at the end of the file.
	func readLine():
		if _pos >= _lines.size():
			return null
		var l := _lines[_pos]
		_pos += 1
		return l

	func ready() -> bool:
		return _pos < _lines.size()

	func close() -> void:
		pass
