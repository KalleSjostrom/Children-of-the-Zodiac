class_name Bodies
extends RefCounted
## Port of bodies.Bodies: a list of bodies with a simple iterator.

var list = null


func _init() -> void:
	list = []


func add(b):
	list.append(b)
	return b


func iterator():
	return BodyItr.new(list)


func size():
	return list.size()


## Java inner class BodyItr; the outer list is passed explicitly.
class BodyItr extends RefCounted:
	var current = 0
	var list = null

	func _init(l = null) -> void:
		list = l

	func hasNext():
		return current < list.size()

	func next():
		var b = list[current]
		current += 1
		return b

	func remove():
		J.removeAt(list, current)
