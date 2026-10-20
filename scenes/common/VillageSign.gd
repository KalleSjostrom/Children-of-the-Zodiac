@tool
class_name VillageSign
extends Node2D
## A sign of a village scene (a "sign" line of a .vil file and its "signL"
## / "signL2" text lines). The node's position is the sign's position in
## village pixels. The player reads the first sign in range, so the order of
## the signs matters.

## Distance in pixels below which the player can read the sign; -1 for the
## legacy default (Sign.DEFAULT_WIDTH).
@export var radius := -1
## The directions the player may face to read it (0 up, 1 right, 2 down,
## 3 left).
@export var directions: PackedInt32Array = [0]
## The text lines in file order (at most two are shown).
@export var lines: PackedStringArray = []
## For each line: true for a "signL" line, which also lists the sign once more
## in the village's sign list (as VillageLoader does: a two-line sign is
## listed twice, which does not matter because the first sign in range
## wins); false for "signL2", which only adds text.
@export var listed: Array[bool] = []


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(0.1, 1.0, 0.1)
	draw_arc(Vector2.ZERO, radius if radius >= 0 else 20, 0.0, TAU, 32, color, 2.0)
	draw_rect(Rect2(-4, -4, 8, 8), color)
