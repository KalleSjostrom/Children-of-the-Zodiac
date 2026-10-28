@tool
class_name DungeonScene
extends Node3D
## The scene of a dungeon floor: a .map file of maps/Labyrinth. Every floor
## scene, scenes/dungeons/<Area>/<Floor>.tscn, inherits
## scenes/dungeons/DungeonScene.tscn (this layout):
##
##   Layout (DungeonFloor)        the walls, floors and roofs, built from its
##                                DungeonLayout (resources/dungeon_layouts/)
##                                and the style's textures
##   Environment (WorldEnvironment) the clear colour background; no Godot fog
##                                or light: the dungeon shader does both
##   Objects                      the "inv" lines in file order (DungeonObject
##                                scenes of scenes/dungeon_objects/)
##   Weather                      the rain or snow (DungeonWeather)
##   Rig / Camera                 the player's eyes: Camera3D with the legacy
##                                projection (fov 45, near 1, far 75); in the
##                                editor at the first door
##
## tools/import/map_to_scene.gd makes them from the .map files. Coordinates
## are the legacy dungeon units: 4 per cell, a cell's centre at
## DungeonCell.center, floors at y -2 and roofs at +2; saves, the console's
## teleport and AutoPlay name cells by their addresses.
##
## Step A (data, docs/MODERNIZATION_PLAN.md 7.4): MapLoader builds the floor
## from this scene (load_into) instead of parsing the .map file, for
## Labyrinth.init and for Load's saved floor maps: the same objects in the
## same order, the same Database reads and the same static state.
##
## Step B (presentation, 7.5): a new instance of the scene draws the floor
## (Labyrinth.create_scene) while the legacy objects stay in charge. Every
## frame, where the legacy code drew, Labyrinth hands the scene what that
## drawing would have drawn: show_view (the camera: LabyrinthPlayer's
## modelview), begin_objects / show_object / end_objects (each object's view,
## in the legacy draw order) and show_weather; show_floor once, with the GL state the walls' display list
## would have been compiled in. The scene keeps no reference to the
## Labyrinth (it is freed with it); legacy objects are named by their
## database names. The legacy 3D drawing of the frame (a battle, the minimap)
## goes under legacy_root, into this scene's 3D world (GLBackend.scene_3d).
##
## The camera mirrors the legacy view the way the legacy drawing applies it:
## the camera stays at the origin and the floor (Layout, Objects) gets the
## legacy modelview as its transform, as GLBackend's chunks do (a camera at
## the origin, the walls' display list drawn with the modelview). So the
## walls, the eye-space meshes of the weather and the save points, and the
## legacy batches go through the same transforms, to the bit, as in the
## legacy drawing; inverting the view into a moving camera would round
## differently. Step C turns it around (a camera rig that moves).

const SCENE_DIR := "res://scenes/dungeons/"
## Sorting offsets: Godot draws transparent instances by distance minus
## sorting_offset. The walls come first, then the objects' batches in the
## legacy draw order, then the weather's back and front pass, as the legacy
## drawing submitted them; GLBackend's batches in the scene follow (from 1e6).
const SORT_STEP := 1000.0

## The .map file's name, as main.bank names it ("Forest of Reil--Forest
## Path.map"); the floor's Database names start with it.
@export var map_name := ""
## The look: textures, light, material, fog, sky, enemy colour, weather.
@export var style: DungeonStyle
## Random battles start after min..max steps (the "steps" line; min -1: no
## battles). MapLoader keeps [min, max - min].
@export var steps_to_battle := Vector2i(13, 20)
## The battle music and the boss battle music (the "battleMusic" line).
@export var battle_music: PackedStringArray = ["Battle", "Fight the Demons"]
## The floor's mission (the "mission" line; MissionFactory): its class in
## labyrinth/mission, its name in the Database (converted), and its entries
## as MapLoader keeps them ("trigger&&<name>&&<value>", "dialog&&<speaker>&&
## <text>", "extranext&&<status>&&<place>"), in order.
@export var has_mission := false
@export var mission_kind := ""
@export var mission_name := ""
@export var mission_entries: PackedStringArray = []

var _run_time := false
var _views := {} # database name -> DungeonObject
var _legacy: Node3D
# The objects' quads of this frame, batched as GLBackend batches them:
# [material, vertices, uvs, colours, normals] per batch, and the meshes that
# draw them.
var _batches: Array = []
var _batch_meshes: Array[MeshInstance3D] = []
var _batch_root: Node3D
# The objects' GPU particle nodes shown so far (save points).
var _particle_views: Array[QuadParticles3D] = []


func _ready() -> void:
	var floor_node := get_node_or_null(^"Layout") as DungeonFloor
	if floor_node != null and Engine.is_editor_hint():
		floor_node.build(style)
		# The sky (eye space) as the Rig's camera sees it.
		var cam := get_node_or_null(^"Rig/Camera") as Node3D
		if cam != null:
			floor_node.set_sky_camera(cam.global_transform)


## Reports in the log that a floor's run-time scene is freed (with its
## Labyrinth mode), for the parity runs.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _run_time:
		print("DungeonScene: freed %s" % map_name)


## Step B: the node the frame's legacy 3D drawing goes into
## (Graphics.use_scene_3d): at the origin, where the camera is, so that its
## eye-space batches are drawn as GLBackend draws them.
func legacy_root() -> Node3D:
	_set_up()
	return _legacy


## Step B, at the floor's first frame: builds the walls in the GL state the
## legacy display list would be compiled in (DungeonFloor.build); returns the
## state the compile leaves.
func show_floor(gl: Dictionary) -> Dictionary:
	_set_up()
	return ($Layout as DungeonFloor).build(style, gl)


## Step B, every frame: the camera. modelview is the legacy view
## (Camera.lookAt: LabyrinthPlayer's interpolated position and angle and the
## battle's shake), applied to the floor while the camera stays at the
## origin (see the class description).
func show_view(modelview: Transform3D) -> void:
	_set_up()
	($Layout as Node3D).transform = modelview
	($Objects as Node3D).transform = modelview
	# The GPU weather is in the floor's units (the legacy quads are in eye
	# space, top level).
	($Weather as Node3D).transform = modelview


## Step B, every frame, before the objects (Graph.show_inventory). GPU
## particles of objects (save points) that the legacy code does not draw this
## frame stand still, hidden, as the legacy particles do.
func begin_objects() -> void:
	_set_up()
	_batches.clear()
	for p: QuadParticles3D in _particle_views:
		p.show_state({}, style)


## Step B, every frame: an object's view, as its legacy draw would draw it
## (Inventory.place_view), in the legacy draw order. Its quad (or its
## particles) joins the frame's batches: a quad with the material of the
## previous one extends that batch, as GLBackend's chunks merge them, so that
## the objects are drawn by the same draws as in the legacy drawing (one
## instance per object rounds some wall pixels 1/255 differently, seen in
## the Tunnel). The object's node mirrors the view (DungeonObject.show_view).
## inv is read, not kept.
func show_object(inv, view: Dictionary) -> void:
	var o: DungeonObject = _views.get(inv.getDatabaseName())
	if o != null:
		o.show_view(inv, view)
	if not view.get("visible", false):
		return
	if view.has("particles") and view.particles.get("gpu", false):
		# The GPU path (SaveSystem.place_gpu): the object's particle node draws
		# in the slot of the legacy quads' batch.
		var p: QuadParticles3D = o.show_particles(view.particles, style) if o is DungeonSavePoint else null
		if p != null:
			if not _particle_views.has(p):
				_particle_views.append(p)
			if view.particles.shown:
				_batches.append([null, p])
		return
	var q: Dictionary = view.particles if view.has("particles") else view.get("quad", {})
	var st: Dictionary = q.state if view.has("particles") else view.state
	if q.is_empty() or q.vertices.is_empty():
		return
	var m := DungeonMaterials.material(st, style)
	var normals: PackedVector3Array = q.get("normals", PackedVector3Array())
	if not _batches.is_empty():
		var last: Array = _batches.back()
		# GLBackend counts the triangles' vertices: 6 per quad.
		if last[0] == m and (last[1].size() + q.vertices.size()) / 4 * 6 < GLBackend.MAX_SURFACE_VERTS:
			last[1] = last[1] + q.vertices
			last[2] = last[2] + q.uvs
			last[3] = last[3] + q.colors
			last[4] = last[4] + normals
			return
	_batches.append([m, q.vertices, q.uvs, q.colors, normals])


## Step B, every frame, after the objects: draws the frame's batches.
func end_objects() -> void:
	while _batch_meshes.size() < _batches.size():
		var mi := MeshInstance3D.new()
		mi.name = "Batch%d" % _batch_meshes.size()
		_batch_root.add_child(mi)
		_batch_meshes.append(mi)
	for i in _batch_meshes.size():
		if i < _batches.size() and _batches[i][0] == null:
			# A particle node's slot.
			(_batches[i][1] as QuadParticles3D).sorting_offset = (i + 1) * SORT_STEP
			_batch_meshes[i].visible = false
		elif i < _batches.size():
			var b: Array = _batches[i]
			var normals: PackedVector3Array = b[4]
			if normals.size() != b[1].size():
				normals = PackedVector3Array()
			DungeonWeather.set_quads(_batch_meshes[i], b[1], b[2], b[3], normals, b[0], (i + 1) * SORT_STEP)
		else:
			_batch_meshes[i].visible = false


## Step B, every frame: a weather pass (&"back" or &"front"), the quads of
## WeatherSystem.place_particles, or on the GPU path its state
## (WeatherSystem.place_gpu). slot: the sorting offset of the front pass over
## a battle or riddle, among the 3D bridge's batches (NAN: after the
## objects).
func show_weather(pass_name: StringName, quads: Dictionary, slot := NAN) -> void:
	var offset: float = ($Objects.get_child_count() + (2 if pass_name == &"front" else 1)) * SORT_STEP
	if not is_nan(slot):
		offset = slot
	var weather := $Weather as DungeonWeather
	if quads.get("gpu", false):
		weather.show_gpu(pass_name, quads, style, offset)
		return
	weather.show_pass(pass_name, quads.vertices, quads.uvs, quads.colors,
			DungeonMaterials.material(quads.state, style), offset)


## Step B: hides a weather pass (the front pass during a battle: the legacy
## code draws it over the battle).
func hide_weather(pass_name: StringName) -> void:
	($Weather as DungeonWeather).hide_pass(pass_name)


## The run-time parts: the objects by name, the current camera, the node of
## the legacy 3D drawing. Labyrinth calls the scene in its first frame,
## before Main adds it to the tree, so this does not wait for _ready.
func _set_up() -> void:
	if _run_time:
		return
	_run_time = true
	for o: DungeonObject in $Objects.get_children():
		_views[o.database_name] = o
		# Only what the legacy drawing draws this frame is shown.
		o.hide_view()
	var rig := $Rig as Node3D
	rig.transform = Transform3D.IDENTITY
	($Rig/Camera as Camera3D).current = true
	_legacy = Node3D.new()
	_legacy.name = "Legacy"
	add_child(_legacy)
	_batch_root = Node3D.new()
	_batch_root.name = "ObjectBatches"
	add_child(_batch_root)


## The scene made from the .map file at map_path (a res:// path, as
## GameResourceLoader.resolve gives it), or "" when the floor is not
## converted: scenes/dungeons/<Area>/<Floor>.tscn for <Area>--<Floor>.map.
static func path_for(map_path: String, scene_dir := SCENE_DIR) -> String:
	var base := map_path.get_file().get_basename()
	if not base.contains("--"):
		return ""
	var path := scene_dir.path_join(base.get_slice("--", 0)).path_join(base.get_slice("--", 1) + ".tscn")
	return path if ResourceLoader.exists(path) else ""


## Step A: fills a new legacy MapLoader (its constructor's state: an empty
## LabyrinthMap, no textures, MapLoader.textureNorm reset) as parsing the
## .map file would: the map's nodes with their links, walls, floors, roofs
## and carpets, the texture list and slot ranges, the look settings, steps,
## battle music, mission, the enemy colour, and the objects, created in file
## order (their constructors read the Database as the parser's did).
func load_into(loader) -> void:
	Parser.reset()
	var layout: DungeonLayout = ($Layout as DungeonFloor).layout
	var map = loader.map
	map.setSize(layout.size)
	loader.stepsToBattle = [steps_to_battle.x, steps_to_battle.y - steps_to_battle.x]
	loader.settings = style.legacy_flags()
	loader.settingValues = style.legacy_settings()
	if style.has_enemy_color:
		BattleEnemy.setColorStatic(style.legacy_enemy_color())
	for t in style.texture_names:
		loader.addTexture(t)
	MapLoader.textureNorm = style.legacy_texture_norm()
	map.setMapPos([layout.map_pos.x, layout.map_pos.y])
	if not battle_music.is_empty():
		loader.battleMusic = Array(battle_music)
	if has_mission:
		loader.mission = [mission_kind, mission_name] + Array(mission_entries)
	_load_nodes(map, layout)
	for o in $Objects.get_children():
		var inv: Inventory = (o as DungeonObject).create_inventory(map, loader.labyrinthName)
		if inv != null:
			map.putInventory(inv.getDatabaseName(), inv)


## The legacy nodes, in the layout's order, as the "dir" lines, mapEnd's
## sort and the "wall", "floor" and "roof" lines left them.
func _load_nodes(map, layout: DungeonLayout) -> void:
	for c in layout.cells:
		map.put(c.address, LabyrinthNode.new(c.address))
	var last = null
	for c in layout.cells:
		var n = map.getNode(c.address)
		for d in 4:
			if c.neighbours[d] != -1:
				n.neighbors[d] = map.getNode(c.neighbours[d])
		n.nrOfNeighbors = c.neighbour_count()
		n.walls = Array(c.walls)
		n.floor = c.floor
		n.roof = c.roof
		if c.has_carpet:
			var carpet := Horizontal.new(n.getPos().getX(), n.getPos().getZ())
			carpet.direction = c.carpet_slot
			carpet.rotation = c.carpet_rotation
			n.carpetFloor = carpet
		last = n
	# mapEnd's sort leaves PillarWalls on the last node it gave pillar walls.
	if style.pillar_walls and last != null:
		PillarWalls.node = last
