class_name RiddleLoader
extends AbstractMapLoader
## Port of miniGames.RiddleLoader: loads the information, texts, dialog and
## images used in a riddle (files in maps/MiniGames/).
##
## Java's inner class RiddleLoader.Image is RiddleLoader.RiddleLoaderImage.

var info = {}
var firstLine = ""
var secondLine = ""
var dialog = []
var images = []
var texts = []


## Java: parseFile(String filename) parses Values.MiniGamesMaps + filename.
## (parseFile(path, filename) is the inherited two argument version.)
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.MiniGamesMaps, path)
	else:
		super.parseFile(path, filename)


## Gets the information map (HashMap<String, String>) for the riddle.
func getInfo():
	return info


## Gets the dialog sequences (Array of DialogSequence) used by the riddle.
func getDialog():
	return dialog


func executeCommand(command: String, tokenizer: StringTokenizer):
	var tok := tokenizer
	if command == "music":
		info["music"] = tok.nextToken()
	elif command == "image":
		var name: String = tok.nextToken()
		var x: int = J.parseInt(tok.nextToken())
		var y: int = J.parseInt(tok.nextToken())
		var scale: float = J.parseFloat(tok.nextToken())
		var alpha: float = J.parseFloat(tok.nextToken())
		if name == "_":
			images.append(RiddleLoaderImage.new(null, x, y, scale, alpha))
		else:
			images.append(RiddleLoaderImage.new(Values.MiniGamesImages + name, x, y, scale, alpha))
	elif command == "fl":
		firstLine = lastLine.replace("fl ", "")
	elif command == "sl":
		var temp: String = tok.nextToken()
		if temp == "end":
			secondLine = ""
		else:
			secondLine = lastLine.replace("sl ", "")
		var ds := DialogSequence.new(firstLine, secondLine)
		dialog.append(ds)
	elif command == "text":
		texts.append(lastLine.replace("text ", ""))


## Gets the images (Array of RiddleLoaderImage).
func getImages():
	return images


## Gets the text lines (Array of String).
func getText():
	return texts


## Java: RiddleLoader.Image.
class RiddleLoaderImage extends RefCounted:
	var name = ""
	var x: int = 0
	var y: int = 0
	var scale: float = 0.0
	var alpha: float = 0.0

	func _init(p_name = null, p_x = null, p_y = null, p_scale = null, p_alpha = null) -> void:
		name = p_name
		x = p_x
		y = p_y
		scale = p_scale
		alpha = p_alpha

	func getName():
		return name

	func getAlpha():
		return alpha

	func getScale():
		return scale

	func getY():
		return y

	func getX():
		return x

	func draw(g):
		g.drawImage(name, x, y, scale)
