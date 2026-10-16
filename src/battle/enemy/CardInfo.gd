class_name CardInfo
extends RefCounted
## Port of battle.enemy.CardInfo: a card used in an enemy attack frame and
## the source (Vector3f) of its particle system.

var source = null
var c = null


func _init(card = null, source = null) -> void:
	c = card
	self.source = source


func getCard():
	return c


func getSource():
	return source
