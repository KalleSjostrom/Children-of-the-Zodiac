extends RefCounted
## The code of dungeon_preview.gd (its header has the usage), run by it once the
## autoloads are registered (docs/ARCHITECTURE.md section 17, "Tools").

var _scene: DungeonScene
var _out := ""
var _frames := 0


## The launcher's tree (its quit, root and frames).
var tree: SceneTree


## Runs the tool (the launcher's _initialize).
func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: dungeon_preview.gd -- <scene> <out>")
		tree.quit(2)
		return
	_out = args[1]
	_scene = (load(args[0]) as PackedScene).instantiate()
	tree.root.add_child(_scene)
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
	var img := tree.root.get_texture().get_image()
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
