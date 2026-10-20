class_name VillageScene
extends Node2D
## The scene of a village: a place in maps/Village. Every place scene
## inherits scenes/villages/VillageScene.tscn (this layout):
## scenes/villages/<Place>/<Place>.tscn holds what all the place's .vil
## variants share (background, roofs and treetops, common obstacles), and
## one inherited scene per variant ("<Place> - 0.tscn",
## "<Place> at Night - 1.tscn", named after the .vil file) adds that
## variant's doors, signs, loot, villagers, particle systems and buildings.
## tools/import/vil_to_scene.gd makes them from the .vil files.
##
## Coordinates are village pixels: 1 unit = 1 pixel, origin at the
## background's top-left, y down, as in the legacy code (cutscenes, saves and
## Cheater jumps use them).
##
## Step A (data, docs/MODERNIZATION_PLAN.md 6.3): VillageLoader.load builds
## the legacy village from the variant scene (load_into) instead of parsing
## the .vil file.
##
## Step B (presentation, 6.4): the same scene then draws the village while
## the legacy objects stay in charge. Every frame, where the legacy code drew
## the world, Village.draw_scene (or VillageStoryTimeLine.draw_scene in a
## cutscene) hands the scene what that drawing would have drawn: show_view,
## show_bottom, show_actors and show_top, in this order. Colours and alpha
## thresholds are the legacy GL state (glColor and the alpha test) of each
## part. The scene keeps no reference to its village: legacy sprites are
## named by their keys in the village's sprite maps (get_instance_id()).

const SCENE_DIR := "res://scenes/villages/"
const VILLAGE_MAPS := "res://maps/Village/"
const ALPHA_TEST := preload("res://scenes/common/alpha_test.gdshader")
const ACTOR_VIEW := preload("res://scenes/common/ActorView.tscn")
const PARTICLES := preload("res://scenes/common/particles/LegacyParticles2D.tscn")
const STORY_IMAGE := preload("res://scenes/common/StoryImage.tscn")

## The place: its maps/Village folder and main.bank name.
@export var place_name := ""
## The background line's folder, "_" read as a space (VillageLoader.folderName).
@export var folder_name := ""
## The village name used for Database keys of doors and loot (folder_name up
## to a "--").
@export var village_name := ""
## Folder of the background images and the top layer (res/Village/<folder>).
@export var background_folder := ""
## False when the background line marks the variant as night: the night
## images and the night layer are used.
@export var day := true
## The background image's name, when it is not the folder's name.
@export var extra_name := ""
## The village's size in pixels (back w h).
@export var size := Vector2i.ZERO
## The size the background tiles cover (back as=w:h, else size).
@export var actual_size := Vector2i.ZERO
## The back line's optional number (DoubleBackground ignores it while
## USE_CUT is set).
@export var back_extra := 0
## Shift of the background tiles (an offset line), if has_tile_offset.
@export var has_tile_offset := false
@export var tile_offset := Vector2i.ZERO
## An inside place: no fade when the player comes back to it.
@export var inside := false
## Music of the variant ("" for the place's music in main.bank).
@export var music := ""
## The landscape node the village exits to, if not "land<place>".
@export var land_name := ""
## Wind for the smoke particles: force x, y, z and turbulence. Without
## has_wind the previous village's wind stays, as in the legacy loader.
@export var has_wind := false
@export var wind_force: PackedFloat64Array = [0.0, 0.0, 0.0]
@export var wind_turbulence := 0.0
## The night layer is res/Village/standardOvernight.png, which is fixed on
## the screen; a village's own night layer scrolls with it.
@export var night_screen_fixed := false
## The buildings the doors lead to.
@export var buildings: Array[VillageBuilding] = []

static var _alpha_materials := {}

var _bound := false
var _ground: Node2D
var _background: Sprite2D
var _actors: Node2D
var _overhead: Node2D
var _night: Sprite2D
var _effects: Node2D
var _camera: Camera2D
var _background_texture: Texture2D
var _background_position := Vector2.ZERO
var _scroll := Vector2i.ZERO
var _views := {} # legacy sprite key -> its node in Actors (ActorView or LegacyParticles2D)
var _systems := {} # legacy particle system key -> the LegacyParticles2D built with it
var _story_image: StoryImage


## The scene for the .vil file at vil_path (res://maps/Village/<Place>/<file>.vil,
## as GameResourceLoader resolves it), or "" when the place is not converted.
static func path_for(vil_path: String) -> String:
	if not vil_path.begins_with(VILLAGE_MAPS):
		return ""
	var path := SCENE_DIR + vil_path.trim_prefix(VILLAGE_MAPS).get_basename() + ".tscn"
	return path if ResourceLoader.exists(path) else ""


## Fills the legacy village loader vl (a VillageLoader that has its infoMap
## and startPos) as VillageLoaderMapLoader does for the .vil file. The
## commands of a .vil file always come in this order (background, back,
## offset, start, o, wind, particlesystem, then the rest), which the loader
## depends on: the player needs the background, the obstacles the player,
## the particles the wind. tools/import/verify_villages.gd checks that both
## ways build the same objects.
func load_into(vl) -> void:
	vl.folderName = folder_name
	vl.villageName = village_name
	var night_layer := not day
	vl.backgroundWidth = size.x
	vl.backgroundHeight = size.y
	vl.actualWidth = actual_size.x
	vl.actualHeight = actual_size.y
	if extra_name != "":
		vl.background = DoubleBackground.new(size.x, size.y, actual_size.x, actual_size.y)
		if DoubleBackground.USE_CUT:
			vl.background.init(background_folder, extra_name, night_layer)
		else:
			vl.background.init(background_folder, extra_name, night_layer, back_extra)
	else:
		vl.loadImages(background_folder, night_layer, back_extra)
	if has_tile_offset:
		vl.background.setOffset(tile_offset.x, tile_offset.y)
	if inside:
		vl.inside = true
	if music != "":
		vl.infoMap["music"] = music
	if land_name != "":
		vl.infoMap["landname"] = "land" + land_name

	for spawn: VillageSpawn in _nodes($Spawns, VillageSpawn):
		if spawn.number == -1:
			if vl.player == null:
				_init_player_pos(vl, spawn)
		elif spawn.number == vl.startPos:
			_init_player_pos(vl, spawn)

	for shape: CollisionShape2D in _nodes($Obstacles, CollisionShape2D):
		var r := obstacle_rect(shape)
		vl.obstacleHandler.addObstacle(Values.createNormalPoint(r.position.x, r.position.y),
				Values.createNormalPoint(r.end.x, r.end.y), vl.player.getHeight(), vl.player.getWidth())

	if has_wind:
		var force := Vector3f.new()
		for i in 3:
			force.set_(i, wind_force[i])
		BodiesParticleSystem.setWind(force, wind_turbulence)

	var villager_layer_systems := {} # LegacyParticles2D -> Array of legacy systems
	var particle_nodes: Array[LegacyParticles2D] = []
	for layer_node: Node in [$Ground, $Actors, $Effects]:
		for p: LegacyParticles2D in _nodes(layer_node, LegacyParticles2D):
			particle_nodes.append(p)
	particle_nodes.sort_custom(func(a: LegacyParticles2D, b: LegacyParticles2D) -> bool:
		return a.build_order < b.build_order)
	var loader = null
	var loader_line := -1
	for node in particle_nodes:
		if node.line != loader_line:
			loader = SystemLoader.getLoader()
			loader_line = node.line
		var system: Array = loader.buildSystem(node.system_name)
		node.system_keys.clear()
		for p in system:
			p.setName(node.system_name)
			p.setActive(node.start_active)
			p.setActivateStatus(node.activation_status)
			node.system_keys.append(p.get_instance_id())
		if node.layer == DoubleBackground.VILLAGER_LAYER:
			villager_layer_systems[node] = system
		else:
			for p in system:
				vl.background.addSystem(p, node.layer)
		for p in system:
			p.warmUp()

	for door: VillageDoor in _nodes($Doors, VillageDoor):
		var d = StoreDoor.new(Array(door.kinds), Array(door.targets), int(door.position.x),
				int(door.position.y), door.radius, Array(door.directions), door.fade, vl.villageName)
		d.setToPos(null if door.to_pos.is_empty() else Array(door.to_pos))
		d.setActivateStatus(door.activation_status)
		if not door.sign_lines.is_empty():
			var s := Sign.new()
			for line in door.sign_lines:
				s.addText(line)
			d.setSign(s)
		if door.hole:
			vl.holeDoors.append(d)
		else:
			vl.doors.append(d)

	for sign: VillageSign in _nodes($Signs, VillageSign):
		var s := Sign.new(int(sign.position.x), int(sign.position.y), sign.radius, Array(sign.directions))
		for i in sign.lines.size():
			s.addText(sign.lines[i])
			if sign.listed[i]:
				vl.signs.append(s)

	for loot: VillageLoot in _nodes($Loot, VillageLoot):
		var loot_name: String = str(vl.villageName) + loot.loot_name
		if Database.getStatusFor(loot_name) != Loot.TAKEN:
			var pos := Values.createNormalPoint(int(loot.position.x), int(loot.position.y))
			var l := Loot.new(loot_name, Array(loot.directions), pos, int(loot.content_type),
					_loot_content(loot), loot.triggers.duplicate())
			l.contentName = loot.content_name
			vl.loots.append(l)
		for line in loot.lines:
			if vl.loots.size() > 0:
				vl.loots[vl.loots.size() - 1].addString(line)

	for b in buildings:
		vl.buildingInfo[b.store_name] = {"storeName": b.store_name, "background": b.background,
			"keeper": b.keeper, "name": b.keeper_name, "firstLine": b.first_line,
			"secondLine": b.second_line, "music": b.music, "villageName": vl.villageName,
			"folderName": vl.folderName}

	for node in $Actors.get_children():
		if node is LegacyParticles2D and villager_layer_systems.has(node):
			for p in villager_layer_systems[node]:
				vl.sprites[p.get_instance_id()] = p
		elif node is ActorView:
			_load_actor(vl, node)


## The rectangle of an obstacle (the original "o x1 y1 x2 y2", not inflated).
static func obstacle_rect(shape: CollisionShape2D) -> Rect2i:
	var s := (shape.shape as RectangleShape2D).size
	var top_left := shape.position - s / 2.0
	return Rect2i(Vector2i(roundi(top_left.x), roundi(top_left.y)), Vector2i(roundi(s.x), roundi(s.y)))


## VillageLoaderMapLoader.initPlayerPos for the spawn.
func _init_player_pos(vl, spawn: VillageSpawn) -> void:
	var x := int(spawn.position.x)
	var y := int(spawn.position.y)
	vl.BACK_POS = [vl.backgroundHeight, vl.backgroundWidth]
	var pos: Array = Values.createNormalFloatPoint(x, y)
	if vl.obstacleHandler == null:
		vl.obstacleHandler = ObstacleHandler.new(vl.BACK_POS)
	vl.player = Player.new(pos, spawn.facing)
	var screen_width: int = Values.ORIGINAL_RESOLUTION[Values.X]
	var screen_height: int = Values.ORIGINAL_RESOLUTION[Values.Y]
	var background_x: int = x - screen_width / 2
	var background_y: int = y - screen_height / 2
	if background_x < 0:
		background_x = 0
	elif background_x > vl.backgroundWidth - screen_width:
		background_x = vl.backgroundWidth - screen_width
	if background_y < 0:
		background_y = 0
	elif background_y > vl.backgroundHeight - screen_height:
		background_y = vl.backgroundHeight - screen_height
	vl.background.setPos(Values.X, -1 * background_x)
	vl.background.setPos(Values.Y, -1 * background_y)
	vl.backgroundHeight -= vl.player.getHeight()
	vl.backgroundWidth -= vl.player.getWidth()


## Loot.createContent for the loot's typed content.
func _loot_content(loot: VillageLoot) -> Variant:
	var content_name := loot.content_name.replace("_", " ")
	match loot.content_type:
		VillageLoot.ContentType.GOLD:
			return loot.amount
		VillageLoot.ContentType.ITEM:
			return Items.Item.new(content_name, loot.amount)
		VillageLoot.ContentType.CARD:
			return Card.createCard(content_name, loot.card_level, loot.all_cards)
		VillageLoot.ContentType.EQUIPMENT:
			return EquipmentFactory.getEquipment(content_name)
		VillageLoot.ContentType.LIFE:
			return loot.life
	return null


## The villager or animated object of a "villager" / "animObj" line.
func _load_actor(vl, view: ActorView) -> void:
	view.sprite_key = 0
	match view.role:
		ActorView.Role.VILLAGER:
			var status: int = Database.getStatusFor(view.villager_name)
			if status == -1:
				print("VillageLoader: could not find: " + view.villager_name
						+ " in the database. Using default value!")
				status = 1
				Database.addStatus(view.villager_name, status)
			if view.statuses.is_empty() or view.statuses.has(status):
				var v := Villager.new(view.villager_name, view.villager_folder, status)
				vl.sprites[v.get_instance_id()] = v
				view.sprite_key = v.get_instance_id()
		ActorView.Role.ANIMATED_OBJECT:
			var pos := Values.createNormalPoint(int(view.position.x), int(view.position.y))
			var ao := AnimatedObjects.new(vl.folderName, view.object_name, pos, view.image_count)
			vl.sprites[ao.get_instance_id()] = ao
			view.sprite_key = ao.get_instance_id()


## The children of parent that are of type, in order.
static func _nodes(parent: Node, type: Variant) -> Array:
	return parent.get_children().filter(func(n: Node) -> bool: return is_instance_of(n, type))


# ---------------------------------------------------------------------------
# Step B: drawing what the legacy code would draw
# ---------------------------------------------------------------------------

## The frame's view: scroll is the screen position of the village's origin
## (DoubleBackground.pos, truncated as the legacy drawing does); a cutscene
## zooms by zoom around zoom_center (screen pixels), as its
## translate/scale/translate does.
func show_view(scroll: Vector2i, zoom: float, zoom_center: Vector2) -> void:
	_bind()
	visible = true
	_scroll = scroll
	_camera.zoom = Vector2(zoom, zoom)
	_camera.position = Vector2(-scroll) + zoom_center * (1.0 - 1.0 / zoom)
	if _camera.is_inside_tree():
		_camera.force_update_scroll()
	if night_screen_fixed:
		_night.position = Vector2(-scroll)


## Draws nothing of the village this frame (a cutscene's draw pause).
func show_nothing() -> void:
	visible = false


## DoubleBackground.drawBottom: the bottom layer particle systems ([key,
## view] entries, see LegacyParticles2D.show_systems), then the tiles, tinted
## color and alpha tested with alpha_ref; or instead the image extra at the
## origin (a cutscene's village background), without the bottom systems.
func show_bottom(extra: Texture2D, systems: Array, color: Color, alpha_ref: float) -> void:
	_bind()
	_ground.visible = extra == null
	_show_systems(_ground, systems)
	_background.texture = extra if extra != null else _background_texture
	_background.position = Vector2.ZERO if extra != null else _background_position
	_background.modulate = color
	_background.material = alpha_material(alpha_ref)


## The sprites of Village.drawBottom and a cutscene's images and actors, in
## draw order: ["sprite", key, texture, position, color, alpha_ref],
## ["particles", key, view] or ["image", texture, position, scale, color,
## alpha_ref] (positions in village pixels, keys as in the legacy sprite
## maps). The order is the legacy sort's (equal y and the special sort keys
## of particle systems and cutscene props included), so Actors does not
## y-sort while it mirrors. Actors not listed are hidden.
func show_actors(entries: Array) -> void:
	_bind()
	var order: Array[Node] = []
	for e: Array in entries:
		match e[0]:
			"sprite":
				var view: ActorView = _actor_view(e[1])
				view.show_frame(e[2], e[3])
				view.modulate = e[4]
				view.material = alpha_material(e[5])
				order.append(view)
			"particles":
				var node: LegacyParticles2D = _actor_particles(e[1])
				node.show_systems([e[2]], _scroll)
				order.append(node)
			"image":
				var image: StoryImage = _story_image_node()
				image.show_image(e[1], e[2], e[3])
				image.modulate = e[4]
				image.material = alpha_material(e[5])
				order.append(image)
	var shown := {}
	for node in order:
		shown[node] = true
	for child in _actors.get_children():
		if not shown.has(child):
			if child is LegacyParticles2D:
				child.show_systems([], _scroll)
			else:
				child.visible = false
	for i in order.size():
		if order[i].get_index() != i:
			_actors.move_child(order[i], i)


## DoubleBackground.drawTop: the roofs and treetops (if top; alpha tested
## with 0.9 by the Overhead material) and the night layer (if night_shown;
## alpha test 0), tinted, then the upper and weather particle systems.
## pieces says for each top layer piece whether to draw it; empty: all.
func show_top(top: bool, pieces: Array, overhead_color: Color, night_shown: bool,
		night_color: Color, systems: Array) -> void:
	_bind()
	_overhead.visible = top
	_overhead.modulate = overhead_color
	var i := 0
	for piece in _overhead.get_children():
		piece.visible = pieces.is_empty() or (i < pieces.size() and pieces[i])
		i += 1
	_night.visible = night_shown and _night.texture != null
	_night.modulate = night_color
	_show_systems(_effects, systems)


## A material for the legacy alpha test glAlphaFunc(GL_GREATER, alpha_ref)
## (alpha_test.gdshader); null (the default blending, no test) for -1.
static func alpha_material(alpha_ref: float) -> Material:
	if alpha_ref < 0.0:
		return null
	if not _alpha_materials.has(alpha_ref):
		var m := ShaderMaterial.new()
		m.shader = ALPHA_TEST
		m.set_shader_parameter("alpha_ref", alpha_ref)
		_alpha_materials[alpha_ref] = m
	return _alpha_materials[alpha_ref]


## Looks up the layer nodes and the actors and systems that load_into bound
## to legacy objects (the first frame is handed over before the scene enters
## the tree, so not in _ready).
func _bind() -> void:
	if _bound:
		return
	_bound = true
	_ground = $Ground
	_background = $Background
	_actors = $Actors
	_overhead = $Overhead
	_night = $Night
	_effects = $Effects
	_camera = $Camera
	_actors.y_sort_enabled = false
	_background_texture = _background.texture
	_background_position = _background.position
	for child in _actors.get_children():
		if child is ActorView and child.sprite_key != 0:
			_views[child.sprite_key] = child
	for layer: Node in [_ground, _actors, _effects]:
		for child: LegacyParticles2D in _nodes(layer, LegacyParticles2D):
			for key in child.system_keys:
				_systems[key] = child


## The view of the legacy sprite key: the scene's villager or animated object
## built with it, or a new one (party members, cutscene actors).
func _actor_view(key: int) -> ActorView:
	var view: ActorView = _views.get(key)
	if view == null:
		view = ACTOR_VIEW.instantiate()
		view.name = "Runtime"
		view.sprite_key = key
		_actors.add_child(view, true)
		_views[key] = view
	return view


## The node for the particle system key in the Actors layer: its own node
## from the scene, or a new one (a cutscene's system, or the second system of
## a name, since each system is sorted on its own).
func _actor_particles(key: int) -> LegacyParticles2D:
	var node: LegacyParticles2D = _views.get(key)
	if node == null:
		node = _systems.get(key)
		if node == null or node.get_parent() != _actors or _views.values().has(node):
			node = PARTICLES.instantiate()
			node.name = "Runtime"
			_actors.add_child(node, true)
		_views[key] = node
	return node


## Hands each particle node of layer the views of its systems ([key, view]
## entries in draw order); nodes without an entry draw nothing.
func _show_systems(layer: Node2D, systems: Array) -> void:
	var views := {}
	for entry: Array in systems:
		var node: LegacyParticles2D = _systems.get(entry[0])
		if node == null:
			node = PARTICLES.instantiate()
			node.name = "Runtime"
			node.system_keys.append(entry[0])
			layer.add_child(node, true)
			_systems[entry[0]] = node
		if not views.has(node):
			views[node] = []
		views[node].append(entry[1])
	for child: LegacyParticles2D in _nodes(layer, LegacyParticles2D):
		child.show_systems(views.get(child, []), _scroll)


func _story_image_node() -> StoryImage:
	if _story_image == null:
		_story_image = STORY_IMAGE.instantiate()
		_actors.add_child(_story_image)
	return _story_image
