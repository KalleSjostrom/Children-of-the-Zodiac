extends RefCounted
## The code of scene_preview.gd (its header has the usage), run by it once the
## autoloads are registered (docs/ARCHITECTURE.md section 17, "Tools").


## The launcher's tree (its quit, root and frames).
var tree: SceneTree


## Runs the tool (the launcher's _initialize).
func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: scene_preview.gd -- <scene.tscn> <out.png> [scale]")
		tree.quit(2)
		return
	var packed: PackedScene = load(args[0])
	if packed == null:
		push_error("scene_preview: cannot load " + args[0])
		tree.quit(1)
		return
	var scale := float(args[2]) if args.size() > 2 else 1.0
	var scene := packed.instantiate()
	var size := Vector2i(1024, 768)
	if scene is VillageScene and scene.size != Vector2i.ZERO:
		size = scene.size
	var camera := scene.get_node_or_null("Camera") as Camera2D
	if camera != null:
		camera.enabled = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i((Vector2(size) * scale).round())
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	viewport.canvas_transform = Transform2D.IDENTITY.scaled(Vector2(scale, scale))
	viewport.add_child(scene)
	for i in 4:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png(args[1])
	print("scene_preview: %s -> %s %s" % [args[0], args[1], image.get_size()])
	tree.quit()
