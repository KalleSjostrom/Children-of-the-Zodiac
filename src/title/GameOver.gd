class_name GameOver
extends GameMode
## Port of title.GameOver: shows the game over screen and switches to the
## title screen when the player presses the cross button (or after 22 s).

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
	g.drawImage(background, 0, 0)
	super.draw(g)
