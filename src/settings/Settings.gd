class_name Settings
extends RefCounted

const FALSE = 0
const TRUE = 1
var settings = {}
var name = null

func setName(name):
	self.name = name

func getName():
	return name

## Java returns an Iterator over the HashMap keys. Here: an Array of the keys
## in ascending order (the iteration order of Java's HashMap<Integer, ...>).
func iterator():
	var keys: Array = settings.keys()
	keys.sort()
	return keys

func getBoolean(i):
	return true if get_(i).value == TRUE else false

func getString(i):
	return get_(i).string

func getVector(i, defaultVector = null):
	var v = get_(i).vector
	if defaultVector != null and v == null:
		v = defaultVector
	return v

func getValue(i):
	return get_(i).value

func getVectorEquation(i):
	return get_(i).vectorEquation

func setBoolean(i, b):
	get_(i).value = float(TRUE if b else FALSE)

func setString(i, s):
	get_(i).string = s

func setValue(i, v):
	get_(i).value = float(v)

## Java overloads: setVector(i, float x, y, z), setVector(i, Vector3f),
## setVector(i, float[]), setVector(i, int[]).
func setVector(i, x, y = null, z = null):
	if y != null:
		setVector(i, Vector3f.new(float(x), float(y), float(z)))
	elif x is Array:
		setVector(i, float(x[0]), float(x[1]), float(x[2]))
	else:
		get_(i).vector = x

func setVectorEquation(i, ve):
	get_(i).vectorEquation = ve

func setSystemDrawable(i, ve):
	get_(i).systemDrawable = ve

func get_(i):
	var s = settings.get(i)
	if s == null:
		s = Setting.new()
		settings[i] = s
	return s

func clone():
	var sett: Dictionary = {}
	for key in settings:
		sett[key] = settings[key].copy()
	var s = get_script().new()
	s.name = name
	s.settings = sett
	return s


class Setting extends RefCounted:
	var systemDrawable = null
	var vectorEquation = null
	var value: float = 0.0
	var vector = null
	var string = null

	func copy():
		var s = Setting.new()
		s.systemDrawable = systemDrawable
		s.vectorEquation = vectorEquation
		s.value = value
		s.vector = null if vector == null else vector.clone()
		s.string = string
		return s
