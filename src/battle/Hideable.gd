class_name Hideable
extends Object2D
## Port of battle.Hideable: an Object2D that slides in (show) and out (hide)
## along one axis. Used by battle and labyrinth HUD elements.
##
## Port notes: Java's setPos(x, y)/setPos(float[]) and
## setLimit(low, high, lowHide)/setLimit(topRight) and
## setMovementSpeed(show, hide)/setMovementSpeed(float[])/setMovementSpeed(topRight)
## are merged; call them with the same arguments as in Java.

const SHOW := 0
const HIDE := 1
const LIMITS_LOW := 0
const LIMITS_HIGH := 1
const X_AXIS := 0
const Y_AXIS := 1

var shouldTranslate_ := true
var visible := true
var trans := [0.0, 0.0]
var transAmount := [0.0, 0.0]
var limits := [0.0, 0.0]
var pos := [0.0, 0.0]
var visLimits := [0, 0]
var currentTransAmount := 0.0
var axis := X_AXIS
var zDepth := BattleValues.STANDARD_Z_DEPTH
var states: Array = []


func _init(size: int = 0) -> void:
	super(size)


func _shouldTranslate() -> bool:
	var higher: bool = trans[axis] > limits[0]
	var lower: bool = trans[axis] < limits[1]
	return higher and lower


## Loads identity and translates to this object's current position.
func translate(g: Graphics) -> void:
	g.loadIdentity()
	g.translate(pos[X] + trans[X], pos[Y] + trans[Y], zDepth)


func update() -> void:
	if shouldTranslate_:
		trans[axis] += currentTransAmount
		shouldTranslate_ = _shouldTranslate()
		if not shouldTranslate_:
			trans[axis] = limits[visLimits[SHOW] if visible else visLimits[HIDE]]


func setZdepth(z: float) -> void:
	zDepth = z


func show() -> void:
	if not visible:
		visible = true
		shouldTranslate_ = true
		currentTransAmount = transAmount[SHOW]


func hide() -> void:
	if visible:
		visible = false
		shouldTranslate_ = true
		currentTransAmount = transAmount[HIDE]


func pushState() -> void:
	states.append(visible)


func popState() -> void:
	var v: bool = states.pop_back()
	if v:
		show()
	else:
		hide()


func toggle() -> void:
	if visible:
		hide()
	else:
		show()


func instantHide() -> void:
	if visible:
		visible = false
		currentTransAmount = transAmount[HIDE]
		var guard := 0
		while shouldTranslate_ and guard < 100000:
			trans[axis] += currentTransAmount
			shouldTranslate_ = _shouldTranslate()
			guard += 1


## Java overloads setPos(float x, float y) and setPos(float[] pos).
func setPos(x, y = null) -> void:
	if y == null:
		pos = x
	else:
		pos = [float(x), float(y)]


func setAxis(p_axis: int) -> void:
	axis = p_axis


## Java overloads setLimit(low, high, lowHide) and setLimit(boolean topRight).
func setLimit(a, high = null, lowHide = null) -> void:
	if high == null:
		var topRight: bool = a
		setLimit(0.0 if topRight else -1.0, 1.0 if topRight else 0.0, not topRight)
		return
	limits[LIMITS_LOW] = float(a)
	limits[LIMITS_HIGH] = float(high)
	visLimits[HIDE] = LIMITS_LOW if lowHide else LIMITS_HIGH
	visLimits[SHOW] = LIMITS_HIGH if lowHide else LIMITS_LOW


## Java overloads setMovementSpeed(show, hide), setMovementSpeed(float[]) and
## setMovementSpeed(boolean topRight).
func setMovementSpeed(a, p_hide = null) -> void:
	if p_hide != null:
		transAmount[SHOW] = float(a)
		transAmount[HIDE] = float(p_hide)
	elif a is Array:
		transAmount = a
	else:
		var topRight: bool = a
		setMovementSpeed([-0.1 if topRight else 0.1, 0.1 if topRight else -0.1])


func getYtrans() -> float:
	return pos[Y] + trans[Y]


func getXtrans() -> float:
	return pos[X] + trans[X]


func getPos(p_axis: int) -> float:
	return pos[p_axis]
