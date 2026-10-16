extends Node2D
## Dev-only scene for the phase 0 bridge test (Main --bridge-test): Village
## returns it from create_scene(). A full-screen panel stands in for the
## background tiles, a label counts the frames this node has processed (proof
## that it keeps its state while its mode is suspended) and a Camera2D with an
## offset moves this scene, but not the legacy drawing above it.
##
## It holds no reference to its game mode: the mode owns the scene and frees
## it when the mode itself is freed.

const GRID_STEP := 128
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.35)

var frames := 0

@onready var _counter: Label = $Counter


func _ready() -> void:
	print("BridgeTest: ready")


func _enter_tree() -> void:
	print("BridgeTest: entered the tree at frame %d" % frames)


func _exit_tree() -> void:
	print("BridgeTest: left the tree at frame %d" % frames)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		print("BridgeTest: freed after %d frames" % frames)


func _process(_delta: float) -> void:
	frames += 1
	_counter.text = "BridgeTest frame %d" % frames


func _draw() -> void:
	var size := Vector2(1024, 768)
	for x in range(0, int(size.x) + 1, GRID_STEP):
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR, 2.0)
	for y in range(0, int(size.y) + 1, GRID_STEP):
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, 2.0)
