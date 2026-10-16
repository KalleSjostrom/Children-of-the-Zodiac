class_name Vector3f
extends RefCounted
## Port of bodies.Vector3f: a mutable 3D vector shared by reference (unlike
## Godot's Vector3 value type). Java overloads are merged and dispatched on the
## argument types (see docs/port_notes/particles-bodies.md).

const serialVersionUID = 1
static var ZERO = null
static var UNIT_X = null
static var UNIT_Y = null
static var UNIT_Z = null
static var UNIT_XYZ = null
var x: float = 0.0
var y: float = 0.0
var z: float = 0.0


static func _static_init() -> void:
	ZERO = Vector3f.new(0, 0, 0)
	UNIT_X = Vector3f.new(1, 0, 0)
	UNIT_Y = Vector3f.new(0, 1, 0)
	UNIT_Z = Vector3f.new(0, 0, 1)
	UNIT_XYZ = Vector3f.new(1, 1, 1)


## Java: Vector3f(), Vector3f(float x, float y, float z), Vector3f(Vector3f copy).
func _init(x = null, y = null, z = null) -> void:
	if x == null:
		self.x = 0.0
		self.y = 0.0
		self.z = 0.0
	elif x is Vector3f:
		self.x = x.x
		self.y = x.y
		self.z = x.z
	else:
		self.x = x
		self.y = y
		self.z = z


## Java: set(float x, float y, float z), set(Vector3f vect) and
## set(int index, float value) (two arguments).
func set_(x, y = null, z = null):
	if x is Vector3f:
		self.x = x.x
		self.y = x.y
		self.z = x.z
		return self
	if z == null and y != null:
		match int(x):
			0:
				self.x = y
				return
			1:
				self.y = y
				return
			2:
				self.z = y
				return
		push_error("index must be either 0, 1 or 2")
		return
	self.x = x
	self.y = y
	self.z = z
	return self


## Java: add(Vector3f vec), add(Vector3f vec, Vector3f result),
## add(float addX, float addY, float addZ).
func add(addX, addY = null, addZ = null):
	if addX == null:
		return null
	if addX is Vector3f:
		if addY == null:
			return Vector3f.new(x + addX.x, y + addX.y, z + addX.z)
		var result = addY
		result.x = x + addX.x
		result.y = y + addX.y
		result.z = z + addX.z
		return result
	return Vector3f.new(x + addX, y + addY, z + addZ)


## Java: addLocal(Vector3f vec), addLocal(float addX, float addY, float addZ).
func addLocal(addX, addY = null, addZ = null):
	if addX == null:
		return null
	if addX is Vector3f:
		x += addX.x
		y += addX.y
		z += addX.z
		return self
	x += addX
	y += addY
	z += addZ
	return self


## Java: scaleAdd(float scalar, Vector3f add), scaleAdd(float scalar,
## Vector3f mult, Vector3f add).
func scaleAdd(scalar, mult, add = null):
	if add == null:
		var a = mult
		x = x * scalar + a.x
		y = y * scalar + a.y
		z = z * scalar + a.z
		return
	self.x = mult.x * scalar + add.x
	self.y = mult.y * scalar + add.y
	self.z = mult.z * scalar + add.z


func dot(vec):
	if null == vec:
		return 0.0
	return x * vec.x + y * vec.y + z * vec.z


## Java: cross(Vector3f v), cross(Vector3f v, Vector3f result),
## cross(float otherX, float otherY, float otherZ, Vector3f result).
func cross(otherX, otherY = null, otherZ = null, result = null):
	if otherX is Vector3f:
		return cross(otherX.x, otherX.y, otherX.z, otherY)
	if result == null:
		result = Vector3f.new()
	var resX: float = ((y * otherZ) - (z * otherY))
	var resY: float = ((z * otherX) - (x * otherZ))
	var resZ: float = ((x * otherY) - (y * otherX))
	result.set_(resX, resY, resZ)
	return result


## Java: crossLocal(Vector3f v), crossLocal(float otherX, float otherY, float otherZ).
func crossLocal(otherX, otherY = null, otherZ = null):
	if otherX is Vector3f:
		return crossLocal(otherX.x, otherX.y, otherX.z)
	var tempx: float = (y * otherZ) - (z * otherY)
	var tempy: float = (z * otherX) - (x * otherZ)
	z = (x * otherY) - (y * otherX)
	x = tempx
	y = tempy
	return self


func length():
	return sqrt(x * x + y * y + z * z)


func lengthSquared():
	return x * x + y * y + z * z


func distanceSquared(v):
	var dx: float = x - v.x
	var dy: float = y - v.y
	var dz: float = z - v.z
	return dx * dx + dy * dy + dz * dz


func distance(v):
	return sqrt(distanceSquared(v))


## Java: mult(float scalar), mult(float scalar, Vector3f product),
## mult(Vector3f vec), mult(Vector3f vec, Vector3f store).
func mult(scalar, product = null):
	if scalar == null:
		return null
	if scalar is Vector3f:
		var store = product
		if store == null:
			store = Vector3f.new()
		return store.set_(x * scalar.x, y * scalar.y, z * scalar.z)
	if product == null:
		return Vector3f.new(x * scalar, y * scalar, z * scalar)
	product.x = x * scalar
	product.y = y * scalar
	product.z = z * scalar
	return product


## Java: multLocal(float scalar), multLocal(Vector3f vec).
func multLocal(scalar):
	if scalar == null:
		return null
	if scalar is Vector3f:
		x *= scalar.x
		y *= scalar.y
		z *= scalar.z
		return self
	x *= scalar
	y *= scalar
	z *= scalar
	return self


## Java: divide(float scalar), divide(Vector3f scalar).
func divide(scalar):
	if scalar is Vector3f:
		return Vector3f.new(x / scalar.x, y / scalar.y, z / scalar.z)
	var s: float = 1.0 / float(scalar)
	return Vector3f.new(x * s, y * s, z * s)


## Java: divideLocal(float scalar), divideLocal(Vector3f scalar).
func divideLocal(scalar):
	if scalar is Vector3f:
		x /= scalar.x
		y /= scalar.y
		z /= scalar.z
		return self
	var s: float = 1.0 / float(scalar)
	x *= s
	y *= s
	z *= s
	return self


func negate():
	return Vector3f.new(-x, -y, -z)


func negateLocal():
	x = -x
	y = -y
	z = -z
	return self


## Java: subtract(Vector3f vec), subtract(Vector3f vec, Vector3f result),
## subtract(float subtractX, float subtractY, float subtractZ).
func subtract(subtractX, subtractY = null, subtractZ = null):
	if subtractX is Vector3f:
		var vec = subtractX
		if subtractY == null:
			return Vector3f.new(x - vec.x, y - vec.y, z - vec.z)
		var result = subtractY
		result.x = x - vec.x
		result.y = y - vec.y
		result.z = z - vec.z
		return result
	return Vector3f.new(x - subtractX, y - subtractY, z - subtractZ)


## Java: subtractLocal(Vector3f vec), subtractLocal(float, float, float).
func subtractLocal(subtractX, subtractY = null, subtractZ = null):
	if subtractX == null:
		return null
	if subtractX is Vector3f:
		x -= subtractX.x
		y -= subtractX.y
		z -= subtractX.z
		return self
	x -= subtractX
	y -= subtractY
	z -= subtractZ
	return self


func normalize():
	var l: float = length()
	if l != 0:
		return divide(l)
	return divide(1.0)


func normalizeLocal():
	var l: float = length()
	if l != 0:
		return divideLocal(l)
	return self


func zero():
	x = 0.0
	y = 0.0
	z = 0.0


## Java: interpolate(Vector3f finalVec, float changeAmnt),
## interpolate(Vector3f beginVec, Vector3f finalVec, float changeAmnt).
func interpolate(beginVec, finalVec, changeAmnt = null):
	if changeAmnt == null:
		var fv = beginVec
		var c: float = finalVec
		self.x = (1 - c) * self.x + c * fv.x
		self.y = (1 - c) * self.y + c * fv.y
		self.z = (1 - c) * self.z + c * fv.z
		return
	self.x = (1 - changeAmnt) * beginVec.x + changeAmnt * finalVec.x
	self.y = (1 - changeAmnt) * beginVec.y + changeAmnt * finalVec.y
	self.z = (1 - changeAmnt) * beginVec.z + changeAmnt * finalVec.z


static func isValidVector(vector):
	if vector == null:
		return false
	if is_nan(vector.x) or is_nan(vector.y) or is_nan(vector.z):
		return false
	if is_inf(vector.x) or is_inf(vector.y) or is_inf(vector.z):
		return false
	return true


func clone():
	return Vector3f.new(x, y, z)


func toArray(floats):
	if floats == null:
		floats = J.array(3, 0.0)
	floats[0] = x
	floats[1] = y
	floats[2] = z
	return floats


func equals(o):
	if not (o is Vector3f):
		return false
	if self == o:
		return true
	var comp = o
	if x != comp.x:
		return false
	if y != comp.y:
		return false
	if z != comp.z:
		return false
	return true


## Java Float.floatToIntBits.
static func _floatToIntBits(f: float) -> int:
	var b := PackedFloat32Array([f]).to_byte_array()
	return b.decode_s32(0)


## Wraps an int to Java's 32-bit int range.
static func _wrap32(v: int) -> int:
	v = v & 0xFFFFFFFF
	if v >= 0x80000000:
		v -= 0x100000000
	return v


func hashCode():
	var hash_: int = 37
	hash_ = _wrap32(hash_ + 37 * hash_ + _floatToIntBits(x))
	hash_ = _wrap32(hash_ + 37 * hash_ + _floatToIntBits(y))
	hash_ = _wrap32(hash_ + 37 * hash_ + _floatToIntBits(z))
	return hash_


func _to_string():
	return "(" + str(x) + ", " + str(y) + ", " + str(z) + ")"


## Java readExternal(ObjectInput): reads three floats from a stream
## (FileAccess / StreamPeer, get_float()).
func readExternal(in_):
	x = in_.get_float()
	y = in_.get_float()
	z = in_.get_float()


## Java writeExternal(ObjectOutput): writes three floats (store_float / put_float).
func writeExternal(out):
	if out.has_method("store_float"):
		out.store_float(x)
		out.store_float(y)
		out.store_float(z)
	else:
		out.put_float(x)
		out.put_float(y)
		out.put_float(z)


func getClassTag():
	return get_script()


func getX():
	return x


func setX(x):
	self.x = x


func getY():
	return y


func setY(y):
	self.y = y


func getZ():
	return z


func setZ(z):
	self.z = z


func get_(index):
	match int(index):
		0:
			return x
		1:
			return y
		2:
			return z
	push_error("index must be either 0, 1 or 2")
	return 0.0
