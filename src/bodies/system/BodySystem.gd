class_name BodySystem
extends Sprite
## Port of bodies.system.BodySystem: a sprite holding a set of bodies.

var bodies = Bodies.new()


func _init() -> void:
	animImages = []


func getBodies():
	return bodies


func addBody(b):
	return bodies.add(b)


