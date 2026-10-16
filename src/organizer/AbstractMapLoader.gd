class_name AbstractMapLoader
extends RefCounted
## Port of organizer.AbstractMapLoader: base class for the line based parsers
## of the game's text data files. Each non-empty line not starting with '#' is
## split into a command (first token) and a tokenizer with the rest.

var lastLine := ""
var lineCount := 0
var comment := false


## Parses the file with the given path and filename.
func parseFile(path: String, filename: String = "") -> void:
	var reader = GameResourceLoader.getResourceLoader().getBufferedReader(path, filename)
	if reader == null:
		return
	var line = ""
	lineCount = 0
	Parser.reset()
	while line != null:
		line = reader.readLine()
		lineCount += 1
		if line != null:
			line = String(line).strip_edges()
			if line != "" and not line.begins_with("#"):
				parseLine(line)
	reader.close()


func parseLine(line: String) -> void:
	lastLine = line
	var tokenizer := StringTokenizer.new(line)
	var lineOk := line != "" and line != " " and line != "\t"
	if lineOk and tokenizer.hasMoreTokens():
		var command := tokenizer.nextToken()
		if command == "/*":
			comment = true
		if not comment and command != "#":
			executeCommand(command, tokenizer)
		if command == "*/":
			comment = false


## Executes the given command using the rest of the line in the tokenizer.
func executeCommand(command: String, tokenizer: StringTokenizer) -> void:
	pass
