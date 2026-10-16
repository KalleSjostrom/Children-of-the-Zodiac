class_name SortingElement
extends RefCounted
## Port of villages.utils.SortingElement: an element used to sort the sprites
## in the village after their y position (to draw them in the correct order).

var yPos: float = 0.0
var index: int = 0


## Java: SortingElement(float y, int i).
func _init(p_y = null, i = null) -> void:
	if p_y != null:
		yPos = float(p_y)
	if i != null:
		index = int(i)


## Java Comparable.compareTo: -1 if this element should be drawn before se.
func compareTo(se):
	return -1 if yPos <= se.yPos else 1


func getYpos():
	return yPos


func getIndex():
	return index


func setYpos(p_y):
	yPos = float(p_y)


func setIndex(i):
	index = int(i)
