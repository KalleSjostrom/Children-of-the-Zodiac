@tool
class_name VillageSpawn
extends Marker2D
## A start position of the player in a village (a "start<N>" line of a .vil
## file), in village pixels. A door or story picks the spawn by number.

## The spawn's number; -1 for a "start" line without one (used when no
## numbered spawn applies).
@export var number := -1
## The direction the player faces (0 up, 1 right, 2 down, 3 left).
@export var facing := 0


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(1.0, 1.0, 1.0)
	draw_rect(Rect2(-5, -5, 10, 10), color, false, 2.0)
	var dir: Vector2 = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT][clampi(facing, 0, 3)]
	draw_line(Vector2.ZERO, dir * 16.0, color, 2.0)
