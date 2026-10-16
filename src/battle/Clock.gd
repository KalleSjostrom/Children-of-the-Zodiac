class_name Clock
extends Hideable
## Port of battle.Clock: manages the time in battle (shown as a TimeBar) and
## draws the "Fleeing" text.

const FLEE_SPEED = 60
const FLEE_DESTINATION_X = 440
# Java: Values.ORIGINAL_RESOLUTION[Values.X] (1024). A constant here because
# Values may not be initialized when this script's statics are.
const DEFAULT_X_POS: int = 1024
var timeBar = null
var abort: bool = false
var fleeing: bool = false
var timeLeft: float = 0.0
var fleeXpos: float = DEFAULT_X_POS
var maxTime: int = 0
const TIME = 10


## Constructs a new hideable clock. It uses an instance of TimeBar to
## illustrate the time.
func _init() -> void:
	super(1)
	setLimit(false)
	setMovementSpeed(false)
	instantHide()
	timeBar = TimeBar.new(0)
	timeBar.update(1)


## Resets the clock. (Java: a thread updating the time bar every 30 ms until
## finish() is called; here a per-frame Scheduler task.)
func reset():
	timeBar.update(1)
	timeLeft = TIME
	maxTime = TIME
	abort = false
	Scheduler.every(_tickTimeBar)


func _tickTimeBar(_dt) -> bool:
	if timeLeft > 0 and not abort:
		# timeLeft -= .03 (disabled in the original)
		timeBar.update(timeLeft / maxTime)
		return true
	return false


## Finishes the current clock so that a new one is ready to be reset.
func finish():
	abort = true


## Initiates the drawing of the clock.
func initDraw(g: Graphics):
	setPos(BattleValues.CLOCK_POSITION)
	timeBar.initDraw(g)


## Initiates the flee procedure.
func initFlee():
	fleeXpos = DEFAULT_X_POS
	fleeing = true


## Resets the flee procedure.
func resetFlee():
	fleeing = false


## Draws the time on the screen.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.loadIdentity()
	g.setFontSize(40)
	if visible and fleeing:
		if fleeXpos - FLEE_SPEED > FLEE_DESTINATION_X:
			fleeXpos = fleeXpos - FLEE_SPEED
		else:
			fleeXpos = FLEE_DESTINATION_X
		var shadowX: int = J.round(DEFAULT_X_POS - (fleeXpos + 144))
		var hy: int = Values.ORIGINAL_RESOLUTION[Values.Y]
		g.drawWithShadow("Fleeing", shadowX + 4, hy, JColor.BLACK)
		g.drawWithShadow("Fleeing", J.round(fleeXpos), hy)
	translate(g)
	timeBar.draw(g)


## Checks if the time is up (always false in the original).
func timesUp():
	return false # timeLeft <= 0


func getTime():
	return TIME - timeLeft
