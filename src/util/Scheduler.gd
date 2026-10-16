class_name Scheduler
extends RefCounted
## Replacement for the Java threads the original game used for waiting and
## timing (new Thread() { run() { ... Values.sleep(ms) ... } }.start()).
##
## Typical ports:
##   Thread that sleeps then acts      -> Scheduler.after(ms, func(): ...)
##   Thread that waits for a condition -> Scheduler.waitUntil(cond, action)
##   Thread body with sleeps in loops  -> a function using
##                                        `await Scheduler.sleep(ms)`, called
##                                        without await (fire and forget).
## All callbacks run on the main thread from Main._process, before the game
## update of that frame.

static var _tasks: Array = []
static var tree: SceneTree


## Returns a signal emitted after ms milliseconds (use with await).
static func sleep(ms: float) -> Signal:
	return tree.create_timer(maxf(ms, 0.0) / 1000.0, true, false, true).timeout


## Calls action once after ms milliseconds.
static func after(ms: float, action: Callable) -> void:
	_tasks.append({"at": Time.get_ticks_msec() + ms, "cond": Callable(), "action": action})


## Calls action once, as soon as cond returns true (checked every frame).
static func waitUntil(cond: Callable, action: Callable) -> void:
	_tasks.append({"at": 0, "cond": cond, "action": action})


## Calls tick(delta_ms) every frame until it returns false.
static func every(tick: Callable) -> void:
	_tasks.append({"at": 0, "cond": Callable(), "action": Callable(), "tick": tick})


static func process(delta_ms: float) -> void:
	if _tasks.is_empty():
		return
	var now := Time.get_ticks_msec()
	var current := _tasks
	_tasks = []
	var keep: Array = []
	for t in current:
		if t.has("tick"):
			if t.tick.is_valid() and t.tick.call(delta_ms):
				keep.append(t)
			continue
		var ready: bool
		if t.cond.is_valid():
			ready = t.cond.call()
		else:
			ready = now >= t.at
		if ready:
			if t.action.is_valid():
				t.action.call()
		else:
			keep.append(t)
	keep.append_array(_tasks)
	_tasks = keep


static func clear() -> void:
	_tasks.clear()
