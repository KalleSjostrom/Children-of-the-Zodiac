class_name TimeHideable
extends RefCounted
## Port of graphics.TimeHideable: something that can be hidden for a while.
## Port note: Java's hide(int time) is hideFor(time) (Hideable has hide()).

var _timeVisible := true


func isVisible() -> bool:
	return _timeVisible


## Hides this object for the given number of milliseconds.
func hideFor(time: int) -> void:
	_timeVisible = false
	Scheduler.after(time, func(): _timeVisible = true)
