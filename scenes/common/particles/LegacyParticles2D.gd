@tool
class_name LegacyParticles2D
extends Node2D
## A particle system of a village scene: an entry of a "particlesystem" line
## of a .vil file (the systems are defined in
## maps/ParticleSystems/particleSystems.info). The layer node it is in is
## where it draws: Ground (bottom layer, under the background), Actors
## (villager layer, sorted with the sprites) or Effects (upper and weather
## layers). The node's position is the emitter's, for the editor.
##
## The legacy system (bodies.system.ParticleSystem) stays in charge. Every
## frame the village hands the node, per legacy system, what the legacy draw
## would draw (show_systems):
## * the GPU path (the default since the particles phase, plan 6.4): the
##   system's state; the node instances the system's generated scene
##   (VillageParticles2D, scenes/common/particles/systems/<system>.tscn) as a
##   child and hands the state on;
## * --legacy=particles (and --legacy=villages): the legacy simulation runs
##   and the node draws the quads its draw would draw, on its own canvas items
##   with the system's texture and blending.

## The system's name in particleSystems.info.
@export var system_name := ""
## The legacy layer: -1 bottom, 0 villager, 1 upper, 2 weather.
@export var layer := 1
## Whether the system runs from the start.
@export var start_active := true
## An inactive system starts when the Database status of system_name has this
## value; -1: never.
@export var activation_status := -1
## The system's position among all the particle systems of the .vil file: the
## legacy loader builds (and warms up) them in this order, and they draw
## random numbers.
@export var build_order := 0
## The particlesystem line of the .vil file the system is on (0, 1, ...): the
## systems of one line are built by one SystemLoader and share its settings
## objects (Vector3f positions and forces), as in the legacy loader.
@export var line := 0

## Keys (get_instance_id()) of the legacy systems this node draws: one name
## may build several systems.
var system_keys: Array[int] = []
var _items: Array[RID] = []
var _add_material: CanvasItemMaterial
var _gpu := {} # definition name -> its VillageParticles2D (or null: no scene)


## Draws the given systems, one Dictionary per legacy system in draw order
## (BodiesParticleSystem.place_particles; empty: an inactive system).
## On the GPU path a view is the state of its system ("gpu",
## BodiesParticleSystem.gpu_view): the generated scene named "definition" is
## placed so that its local coordinates are the legacy body coordinates
## ("position" and scroll: the legacy drawing's offset) and takes the state
## (VillageParticles2D.show_state); a slave's view is drawn by its master's
## scene, and a system without a view this frame draws nothing.
## With --legacy=particles a view has "texture" (Texture2D), "additive"
## (bool), "corners" (PackedVector2Array,
## four corners per particle in the legacy vertex order) and "colors"
## (PackedColorArray, one per corner), and optionally "image" (Texture2D) at
## "image_at" (Vector2i) in "image_color", drawn first with normal blending.
## Positions are screen pixels of the legacy drawing, for which the village's
## origin is at scroll. An empty array draws nothing, as does every array
## with --hide-particles (Main.hide_particles).
func show_systems(views: Array, scroll: Vector2i) -> void:
	if Main.hide_particles:
		views = []
	var shown := {}
	var quads: Array = []
	for view: Dictionary in views:
		if view.get("gpu", false):
			if not view["slave"]:
				var system := _gpu_system(view["definition"])
				if system != null:
					var p: Vector2 = view["position"]
					system.position = Vector2(p.x - scroll.x, -p.y - scroll.y) - position
					system.show_state(view)
					shown[system] = true
		else:
			quads.append(view)
	for system: VillageParticles2D in _gpu.values():
		if system != null and not shown.has(system):
			system.show_state({})
	_show_quads(quads, scroll)


## The legacy path of show_systems: the quads of the views.
func _show_quads(views: Array, scroll: Vector2i) -> void:
	var base := get_canvas_item()
	var offset := Transform2D(0.0, -Vector2(scroll) - position)
	var used := 0
	for view: Dictionary in views:
		if view.is_empty():
			continue
		var image: Texture2D = view.get("image")
		if image != null:
			var image_item := _item(used, base, null)
			used += 1
			RenderingServer.canvas_item_add_set_transform(image_item, offset)
			RenderingServer.canvas_item_add_texture_rect(image_item,
					Rect2(Vector2(view["image_at"]), image.get_size()), image.get_rid(), false,
					view.get("image_color", Color.WHITE))
		var corners: PackedVector2Array = view["corners"]
		var texture: Texture2D = view["texture"]
		if corners.is_empty() or texture == null:
			continue
		var item := _item(used, base, _additive() if view["additive"] else null)
		used += 1
		RenderingServer.canvas_item_add_set_transform(item, offset)
		_add_quads(item, corners, view["colors"], texture)
	for i in range(used, _items.size()):
		RenderingServer.canvas_item_clear(_items[i])


## The same triangles as the legacy GL_QUADS (vertices 0 1 2 and 0 2 3 of
## each quad), with the quad's texture coordinates.
func _add_quads(item: RID, corners: PackedVector2Array, colors: PackedColorArray,
		texture: Texture2D) -> void:
	var quads := corners.size() / 4
	var points := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	points.resize(quads * 6)
	cols.resize(quads * 6)
	uvs.resize(quads * 6)
	var quad_uv: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	var order: Array[int] = [0, 1, 2, 0, 2, 3]
	for q in quads:
		for k in 6:
			var c: int = q * 4 + order[k]
			points[q * 6 + k] = corners[c]
			cols[q * 6 + k] = colors[c]
			uvs[q * 6 + k] = quad_uv[order[k]]
	var indices := PackedInt32Array()
	indices.resize(points.size())
	for i in points.size():
		indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(item, indices, points, cols, uvs,
			PackedInt32Array(), PackedFloat32Array(), texture.get_rid())


## The generated system of the definition, instanced as a child on first use.
func _gpu_system(definition: String) -> VillageParticles2D:
	if not _gpu.has(definition):
		var scene := VillageParticles2D.scene_for(definition)
		var system: VillageParticles2D = scene.instantiate() if scene != null else null
		if system != null:
			add_child(system)
		_gpu[definition] = system
	return _gpu[definition]


func _item(index: int, parent: RID, material: Material) -> RID:
	if index == _items.size():
		var rid := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(rid, parent)
		_items.append(rid)
	var item := _items[index]
	RenderingServer.canvas_item_clear(item)
	RenderingServer.canvas_item_set_draw_index(item, index)
	RenderingServer.canvas_item_set_material(item, material.get_rid() if material != null else RID())
	return item


func _additive() -> CanvasItemMaterial:
	if _add_material == null:
		_add_material = CanvasItemMaterial.new()
		_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_material


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for rid in _items:
			RenderingServer.free_rid(rid)
		_items.clear()


## The marker, in the editor and with Debug > Visible Collision Shapes
## (--debug-collisions).
func _draw() -> void:
	if not (Engine.is_editor_hint() or get_tree().debug_collisions_hint):
		return
	var color := Color(1.0, 0.5, 0.0)
	draw_arc(Vector2.ZERO, 12, 0.0, TAU, 16, color, 2.0)
	draw_line(Vector2(0, -4), Vector2(0, -28), color, 2.0)
