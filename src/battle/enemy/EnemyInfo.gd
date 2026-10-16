class_name EnemyInfo
extends RefCounted
## Port of battle.enemy.EnemyInfo: graphical information about an enemy
## (scale, height, depth ...) and its attacks.
## Port notes: set(int, float) / get(int) are set_ / get_. The two Java
## overloads setAttack(name, power, type, element, isAll, probability, frames,
## target) and setAttack(AttackInfo) are merged (one argument = AttackInfo).
## The attacks are iterated in Java HashMap<String, ...> order (emulated in
## _javaKeyOrder) so getRandomAttack picks exactly like the original.

const SCALE = 0
const HEIGHT = 1
const DEPTH = 2
const X_OFFSET = 3
const MIDDLE_POINT = 4
const INFO_SIZE = 5
var attack = {}
var info = J.array(INFO_SIZE, 0.0)


func set_(index, value):
	info[index] = float(value)


func setAttack(name, power = null, type = null, element = null, isAll = null, probability = null, frames = null, target = null):
	if power == null and name is AttackInfo:
		var attackInfo = name
		attack[attackInfo.getName()] = attackInfo
		return
	attack[name] = AttackInfo.new(name, power, type, element, isAll, probability, frames, target)


func get_(index):
	return info[index]


func getAttackInfo(name):
	return attack.get(name)


func getRandomAttack(type):
	var list: Array = []
	for key in _javaKeyOrder():
		var ai = attack[key]
		if ai.getType() == type:
			list.append(ai)
	var p: float = 0.0
	var r: float = J.random()
	var index: int = 0
	var found: bool = false
	var i: int = 0
	while i < list.size() and not found:
		p += list[i].getProbability()
		found = r <= p
		if found:
			index = i
		i += 1
	if list.is_empty():
		push_error("EnemyInfo.getRandomAttack: no attack of type " + str(type))
		return null
	return list[index]


func getAttack(name):
	for key in _javaKeyOrder():
		var ai = attack[key]
		if ai.getName() == name:
			return ai
	push_error("This enemy does not have the attack \"" + str(name) + "\" (Attack list: " + _to_string() + ")")
	return null


func _to_string():
	var s: String = "{"
	var first: bool = true
	for key in _javaKeyOrder():
		if not first:
			s += ", "
		first = false
		s += str(key) + "=" + str(attack[key])
	return s + "}"


## Returns the keys of attack in the iteration order of a Java HashMap with
## String keys (bucket index of the spread hash, insertion order inside a
## bucket; the table starts at 16 and doubles when size > 0.75 * capacity).
func _javaKeyOrder() -> Array:
	var keys: Array = attack.keys()
	var capacity: int = 16
	while keys.size() > capacity * 0.75:
		capacity *= 2
	var buckets: Array = []
	for k in keys:
		var h: int = J.stringHashCode(str(k)) & 0xFFFFFFFF
		h = h ^ (h >> 16)
		buckets.append(h & (capacity - 1))
	var order: Array = range(keys.size())
	order.sort_custom(func(a, b):
		if buckets[a] != buckets[b]:
			return buckets[a] < buckets[b]
		return a < b)
	var result: Array = []
	for i in order:
		result.append(keys[i])
	return result
