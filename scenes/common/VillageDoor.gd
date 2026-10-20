@tool
class_name VillageDoor
extends Node2D
## A door of a village scene (a "door" or "holeDoor" line of a .vil file).
## The node's position is the door's position in village pixels. The player
## uses the door when closer than radius (and facing one of directions);
## VillageScene.load_into builds the legacy StoreDoor from these properties.
## The first door in range wins, so the order of the doors matters.

## A hole door is entered by walking into it (the village's hole door list);
## a door by pressing the action button.
@export var hole := false
## What the door leads to, one entry per door status ("house", "inn",
## "weapon", "card", "church", "library", "labyrinth", "village", "switch",
## "story").
@export var kinds: PackedStringArray = []
## The building or place for each entry of kinds, written as in the .vil file
## ("_" for spaces). The door's status in the Database picks the entry.
@export var targets: PackedStringArray = []
## Distance in pixels below which the player is at the door.
@export var radius := 30
## The directions the player may face to use the door (0 up, 1 right, 2 down,
## 3 left).
@export var directions: PackedInt32Array = [0]
## The door only opens once the Database status "<village><target>activation"
## has this value; -1: always active.
@export var activation_status := -1
## How the music fades when the door is used (StoreDoor.FADE_*).
@export var fade := 3
## Where the player appears in the target: StoreDoor.toPos, [y, x, facing,
## facing after a store]; -1 where not given. Empty: not given at all.
@export var to_pos: PackedFloat64Array = []
## The door's sign (for example the message of a locked door): up to two
## lines, the text after "doorSignFl" / "doorSignSl" (with its leading space).
@export var sign_lines: PackedStringArray = []


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(0.0, 1.0, 1.0) if hole else Color(0.2, 0.5, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, 2.0)
	draw_line(Vector2(-6, 0), Vector2(6, 0), color, 2.0)
	draw_line(Vector2(0, -6), Vector2(0, 6), color, 2.0)
