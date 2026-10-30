@tool
class_name WorldMapRoad
extends Path2D
## A road of the world map: a "road" line of maps/Landscape/world<n>.map with
## its "co" points (the curve's points, exactly, in screen pixels) and its
## "oc" line. It draws the move dots (movedot.png) at its points, as
## Road.drawRoad draws the legacy MoveDots: every point but the first and the
## last (the nodes), which Road.done drops at the oc line.
##
## Phase 4.1 (docs/ARCHITECTURE.md section 13): WorldMapScene.load_into
## builds a Road from it (step A); the road shows while it is one of the
## legacy Landscape's visited roads (step B). Walking stays legacy
## (Road.movePlayer: 7 steps per segment between the points); nothing moves
## along the curve.

const MOVE_DOT := preload("res://res/Landscape/movedot.png")

## The road's address: the legacy Road's key (Landscape.visitedRoads, the
## saves' visitedRoads lines) and its Database status road<map>-<address>
## (0: closed).
@export var address := 0
## The node the road starts at (WorldMapNode.node_name), its first point.
@export var source := ""
## The direction (0 up, 1 right, 2 down, 3 left) the player presses at the
## source to walk the road.
@export var direction_to_destination := 0
## The node the road ends at, its last point.
@export var destination := ""
## The direction the player presses at the destination to walk it back.
@export var direction_to_source := 0
## The road's "oc" line was read (Road.done): no dots on the first and the
## last point.
@export var has_oc := true


func _ready() -> void:
	if Engine.is_editor_hint() and curve != null and not curve.changed.is_connected(queue_redraw):
		curve.changed.connect(queue_redraw)


## Where the dots are: the curve's points, without the first and the last
## with has_oc.
func dots() -> PackedVector2Array:
	var points := PackedVector2Array()
	if curve == null:
		return points
	for i in curve.point_count:
		points.append(curve.get_point_position(i))
	if has_oc and points.size() >= 2:
		points = points.slice(1, points.size() - 1)
	return points


func _draw() -> void:
	for p in dots():
		draw_texture(MOVE_DOT, p)
