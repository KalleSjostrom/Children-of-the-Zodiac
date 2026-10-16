class_name RiddleGame
extends GameMode
## Port of miniGames.RiddleGame: manages the riddles in the labyrinth. A riddle
## is a "labyrinth drawable" (see labyrinth.LabyrinthDrawable): the labyrinth
## creates it in enterRiddle(name, className, hinders), calls
## init(name, labyrinth, hinders), then update/initDraw/draw/drawTopLayer
## every frame until the riddle calls labyrinth.exitRiddle().
##
## Port note: Java's overloads init(String name, Labyrinth lab,
## Inventory[] hinders) and init(HashMap info) are one method here. A non
## String first argument selects the info version.

var dialog = Dialog.getDialog()
var labyrinth = null

var fade: float = 0.0
var fadingUp: bool = true
var fadingDown: bool = false
var image = null
var hinders = null
var texts = null


## Constructs a new riddle. The riddle is set up in init(name, lab, hinders).
func _init() -> void:
	pass


## Java: init(String name, Labyrinth lab, Inventory[] hinders) loads the
## riddle file with the given name (maps/MiniGames/name); lab is the
## labyrinth that the riddle is in. Java: init(HashMap info) when the first
## argument is not a String.
func init(name, lab = null, p_hinders = null):
	if not (name is String):
		_initInfo(name)
		return
	var rl := RiddleLoader.new()
	rl.parseFile(name)
	var info = rl.getInfo()
	_initInfo(info)
	self.hinders = p_hinders
	dialog.setDS(rl.getDialog(), null)
	texts = rl.getText()
	labyrinth = lab
	var images: Array = rl.getImages()
	image = images[0]
	logicLoading = false


## Java: public void init(HashMap<String, String> info).
func _initInfo(info) -> void:
	initGameMode(info, Values.DETECT_AS_KEY, false)


## Updates the riddle. elapsedTime is the time in ms since the last update.
func update(elapsedTime: float):
	checkInput()
	if fadingDown:
		fade -= .12
		if fade < 0:
			labyrinth.exitRiddle()
	elif fadingUp:
		fade += .1
		if fade >= 1:
			fadingUp = false
	super.update(elapsedTime)


## Checks the input for changes.
func checkInput():
	if not isRiddleFading():
		if gameActions[CROSS].isPressed():
			fadingDown = true


## Gets the (first) image of the riddle (a RiddleLoader.RiddleLoaderImage).
func getImage():
	return image


func isRiddleFading():
	return fadingDown or fadingUp


func initDraw(g):
	pass


func draw(g, alpha = null):
	pass


func drawTopLayer(g):
	var fos: float = fade * image.getAlpha()
	g.fadeOldSchool(1 - fos)
	g.setColor(1, 1, 1, fade)
	image.draw(g)
