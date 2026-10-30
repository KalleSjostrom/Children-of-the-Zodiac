class_name GameOver
extends GameMode
## Port of title.GameOver: shows the game over screen and switches to the
## title screen when the player presses the cross button (or after 22 s).
##
## Bridge (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the UI layer's
## GameOverScreen node shows the image where the drawing drew it
## (_show_image); --legacy=game_over keeps the drawing.

const GAME_OVER_VIEW := "res://scenes/ui/GameOverScreen.tscn"

var background = ""
var done_: bool = false

## Java: init(HashMap info).
func init(name, lab = null, hinders = null):
	var info = name
	initGameMode(info, Values.DETECT_INIT)
	setFadeInSpeed(.01)
	loadImages()

	logicLoading = false
	_doneTimer()


## Java: the thread that sets done after 22 seconds.
func _doneTimer() -> void:
	var i: int = 0
	while i < 22 and not done_:
		await Scheduler.sleep(1000)
		i += 1
	done_ = true


func loadImages(name = null, nightLayer = null, extra = null):
	var chars = Load.getCharacters()
	var n: String = "GameOver"
	for c in chars:
		n += c.getName()
	n += ".jpg"
	background = ImageHandler.addToCurrentLoadNow(Values.TitleImages + n)


func update(elapsedTime: float):
	checkGameInput()
	super.update(elapsedTime)


func checkGameInput():
	if done_ or gameActions[CROSS].isPressed():
		if not fadeout:
			done_ = true
			nextPlace = "Title Screen"
			exit(Values.EXIT)


func draw(g, alpha = null):
	g.setColor(1)
	g.setFontSize(24)
	if Main.is_legacy("game_over"):
		g.drawImage(background, 0, 0)
	else:
		_show_image(g)
	super.draw(g)


## Bridge (phase 4.2 step B): drawImage(background, 0, 0) without the drawing:
## its bind (Graphics.skip_image), and the frame's GameOverScreen node shows
## the image in the current colour, with the material of the 2D state.
func _show_image(g) -> void:
	var t = g.skip_image(background)
	var view = g.show_ui(GAME_OVER_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_image(t.getGodotTexture() if t != null else null, g.getCurrentColor(),
				g.canvas_material())
