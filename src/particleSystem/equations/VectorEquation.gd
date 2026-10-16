class_name VectorEquation
extends RefCounted
## Port of particleSystem.equations.VectorEquation (Java interface).
## (Java interface: implementing classes do not extend this; use duck typing,
## e.g. x.has_method("getVectorAfterTime").)


func modifyVector(v, elapsedTime):
	return null

func getVectorAfterTime(v, elapsedTime):
	return null
