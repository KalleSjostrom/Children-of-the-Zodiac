class_name AirLandNode
extends RefCounted
## Port of landscape.airship.AirLandNode: a node in the airship landscape.

var name = ""
var type = ""
var x: int = 0
var y: int = 0
var zone: int = 0


func _init(x = null, y = null, type = null, name = null) -> void:
	self.x = x
	self.y = y
	self.type = type
	self.name = name


func getName():
	return name


func getXpos():
	return x


func getYpos():
	return y


func getType():
	return type


func getZone():
	return zone


func isCross():
	return type == "crossroad"


func setZone(zone):
	self.zone = zone
