extends SceneTree
## Renders a dungeon floor scene as the editor shows it (DungeonFloor built
## with GL's default state, the objects' Views, the editor markers of the
## objects, doors and marks), for checking a conversion without opening the
## editor. Windowed (a renderer is needed), from the project root:
##
##   godot --path . --script res://tools/import/dungeon_preview.gd -- <scene> <out>
##
## Writes <out>_rig.png (from the scene's Rig camera: the first door, the
## legacy projection) and <out>_top.png (from above, orthographic, the whole
## floor; the roofs face down and are culled from there). <scene> may be a
## path outside the project (a dry run of map_to_scene.gd --out).

var _scene: DungeonScene
var _out := ""
var _frames := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: dungeon_preview.gd -- <scene> <out>")
		quit(2)
		return
	_out = args[1]
	_scene = (load(args[0]) as PackedScene).instantiate()
	root.add_child(_scene)
	(_scene.get_node(^"Layout") as DungeonFloor).build(_scene.style)
	for o: DungeonObject in _scene.get_node(^"Objects").get_children():
		o._add_editor_marker()
	var cam := _scene.get_node(^"Rig/Camera") as Camera3D
	cam.current = true
	# The sky is in eye space: in front of the Rig's camera.
	(_scene.get_node(^"Layout") as DungeonFloor).set_sky_camera(cam.global_transform)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		_save("_rig")
		_top_camera()
	elif _frames == 10:
		_save("_top")
		return true
	return false


func _save(suffix: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(_out + suffix + ".png")
	print("wrote " + _out + suffix + ".png")


## An orthographic camera above the floor's cells.
func _top_camera() -> void:
	var layout := (_scene.get_node(^"Layout") as DungeonFloor).layout
	var lo := Vector3(INF, 0, INF)
	var hi := Vector3(-INF, 0, -INF)
	for c in layout.cells:
		lo = lo.min(c.center() - Vector3(2, 0, 2))
		hi = hi.max(c.center() + Vector3(2, 0, 2))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(hi.z - lo.z, (hi.x - lo.x) * 0.75) + 4
	cam.near = 1
	cam.far = 100
	cam.position = Vector3((lo.x + hi.x) / 2, 50, (lo.z + hi.z) / 2)
	cam.rotation = Vector3(-PI / 2, 0, 0)
	_scene.add_child(cam)
	cam.current = true
