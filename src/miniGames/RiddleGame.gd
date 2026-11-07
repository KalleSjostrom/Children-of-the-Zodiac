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

## Bridge (phase 4.2 step B): the node of the riddle's image (its legacy quad).
const IMAGE_VIEW := "res://scenes/ui/LevelBar.tscn"

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
##
## Port note: the Java's fade is a 32-bit float (fade += .1f, fade -= .12f):
## its fade-in ends at 1.0000001 after 10 updates and its fade-out after 9.
## In GDScript's 64-bit floats it ended at 1.1 after 11 updates (the dim at
## 1.1 times the image's alpha) and faded out in 10, so each step is rounded
## to a 32-bit float as the Java computes it (_toFloat).
func update(elapsedTime: float):
	checkInput()
	if fadingDown:
		fade = _toFloat(fade - _toFloat(.12))
		if fade < 0:
			labyrinth.exitRiddle()
	elif fadingUp:
		fade = _toFloat(fade + _toFloat(.1))
		if fade >= 1:
			fadingUp = false
	super.update(elapsedTime)


## Java float arithmetic: x rounded to the nearest 32-bit float (the sum or
## difference of two 32-bit floats computed in 64 bits and rounded once is
## the 32-bit result).
static func _toFloat(x: float) -> float:
	return PackedFloat32Array([x])[0]


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


## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14, "The riddles"):
## the riddle's parts are UI nodes in the frame's order, after the
## labyrinth's dialog (Graphics.show_ui): the dim a Fade node on the UI layer
## (draw_dim, --legacy=dim keeps fadeOldSchool), the image a LevelBar node (its
## legacy quad: RiddleLoaderImage.place), the kinds' images (tiles, markers,
## hands) MenuBackground nodes with their placed images
## (AbstractPage.show_pieces), their texts MenuText nodes
## (AbstractPage.show_lines), Cesadur's help a HelpLine (AbstractPage.draw_help,
## --legacy=menu_frame); --legacy=riddle keeps the legacy drawing of the image,
## the images and the texts.
func drawTopLayer(g):
	var fos: float = fade * image.getAlpha()
	draw_dim(g, 1 - fos)
	g.setColor(1, 1, 1, fade)
	if Main.is_legacy("riddle"):
		image.draw(g)
	else:
		var placed: Array = image.place(g)
		var view = g.show_ui(IMAGE_VIEW, Graphics.UI_LAYER)
		if view != null:
			view.show_parts([placed], g.canvas_material())


## Bridge (phase 4.2 step B): the riddle's dim, g.fadeOldSchool(fadeindex)
## (the current fade mode's image at alpha 1 - fadeindex), or with --legacy=dim
## off its twin: a Fade node on the UI layer, before the riddle's nodes
## (Graphics.show_fade), as the stores' confirm dims.
static func draw_dim(g, fadeindex: float) -> void:
	if Main.is_legacy("dim"):
		g.fadeOldSchool(fadeindex)
	else:
		g.show_fade(fadeindex, Graphics.UI_LAYER)


## Bridge (phase 4.2 step B): a line drawMultiString(text, x, y) would draw
## now, for AbstractPage.show_lines: [text, position (the baseline's start),
## font size, colour (the text colour at startText's alpha), bold, alignment].
static func multi_line(g, text, x: int, y: int) -> Array:
	return [str(text), Vector2i(x, y), g.getFontSize(), Graphics.text_color(g.text_alpha()),
			Graphics.font_bold(), HORIZONTAL_ALIGNMENT_LEFT]


## Bridge (phase 4.2 step B): a line drawMultiCenteredText(text, y) would draw
## now (centred on the screen's middle, as Graphics.calcAlignCenter), for
## AbstractPage.show_lines.
static func multi_centered_line(g, text: String, y: int) -> Array:
	return [text, Vector2i(Values.ORIGINAL_RESOLUTION[Values.X] / 2, y), g.getFontSize(),
			Graphics.text_color(g.text_alpha()), Graphics.font_bold(), HORIZONTAL_ALIGNMENT_CENTER]
