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
## update of that frame. sleep() timers fire after Main._process (SceneTree
## timers; in deterministic mode game clock timers stepped by processTimers).

static var _tasks: Array = []
static var _timers: Array = [] # deterministic mode: [{"left": ms, "timer": _GameTimer}]
static var tree: SceneTree


## A one-shot timer on the game clock (deterministic mode).
class _GameTimer extends RefCounted:
	signal timeout


## Returns a signal emitted after ms milliseconds (use with await).
static func sleep(ms: float) -> Signal:
	if J.deterministic:
		var t := _GameTimer.new()
		_timers.append({"left": maxf(ms, 0.0), "timer": t})
		return t.timeout
	return tree.create_timer(maxf(ms, 0.0) / 1000.0, true, false, true).timeout


## Calls action once after ms milliseconds.
static func after(ms: float, action: Callable) -> void:
	_tasks.append({"at": J.currentTimeMillis() + ms, "cond": Callable(), "action": action})


## Calls action once, as soon as cond returns true (checked every frame).
static func waitUntil(cond: Callable, action: Callable) -> void:
	_tasks.append({"at": 0, "cond": cond, "action": action})


## Calls tick(delta_ms) every frame until it returns false.
static func every(tick: Callable) -> void:
	_tasks.append({"at": 0, "cond": Callable(), "action": Callable(), "tick": tick})


static func process(delta_ms: float) -> void:
	if _tasks.is_empty():
		return
	var now := J.currentTimeMillis()
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


## Steps the sleep() timers of deterministic mode by delta_ms, at the end of
## the frame like SceneTree timers (timers started meanwhile wait a frame).
static func processTimers(delta_ms: float) -> void:
	if _timers.is_empty():
		return
	var current := _timers
	_timers = []
	var keep: Array = []
	for t in current:
		t.left -= delta_ms
		if t.left <= 0.0:
			t.timer.timeout.emit()
		else:
			keep.append(t)
	keep.append_array(_timers)
	_timers = keep


static func clear() -> void:
	_tasks.clear()
