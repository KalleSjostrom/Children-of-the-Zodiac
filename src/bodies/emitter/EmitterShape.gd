class_name EmitterShape
extends Body
## Port of bodies.emitter.EmitterShape: the shape bodies are emitted from.


func _init(settings = null) -> void:
	if settings != null:
		setPosition(settings.getVector(ShapeSettings.POSITION))


## Abstract in Java.
func getEmittancePos():
	return null


## Abstract in Java.
func modifyDirection(direction):
	return direction
