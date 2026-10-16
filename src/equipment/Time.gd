class_name EquipmentTime
extends RefCounted
## Port of equipment.Time: a clock which counts the minutes and hours that
## the player has played.
##
## The Java "Game Clock" thread (sleep 1 s, count down while the game is not
## paused, update every 60 counted seconds) runs as a Scheduler.every task.

var hours: int = 0
var min: int = 0
var updated: bool = false

var _clockCounter: int = 60
var _clockElapsed: float = 0.0


## Creates a new clock with the initial values set to the given time.
func _init(hour = null, p_min = null) -> void:
	if hour != null:
		hours = hour
	if p_min != null:
		self.min = p_min
	Scheduler.every(_tickClock)


## The body of the Java clock thread.
func _tickClock(delta_ms: float) -> bool:
	_clockElapsed += delta_ms
	while _clockElapsed >= 1000.0:
		_clockElapsed -= 1000.0
		if not GameCore.isPaused():
			_clockCounter -= 1
		if _clockCounter <= 0:
			update()
			_clockCounter = 60
	return true


## Updates the clock (one minute).
func update():
	self.min += 1
	if self.min == 60:
		self.min = 0
		hours += 1
	updated = true


func getHours():
	return getTime(hours)


func getMin():
	return getTime(self.min)


## Gets the string representation of the given time ("0" + time if < 10).
static func getTime(time):
	return ("0" + str(time)) if time < 10 else str(time)


## The time as a string, "hours minutes" (e.g. "15 40").
func _to_string():
	return getHours() + " " + getMin()


## Checks if the clock has been updated since the last call.
func hasChanged():
	var u := updated
	updated = false
	return u
