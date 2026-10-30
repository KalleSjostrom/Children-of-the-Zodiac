class_name WorldMapScene
extends Node2D
## The scene of a world map or an airship map: one per file of
## maps/Landscape (world0.map West, world1.map East, world2.map North;
## land1.map and land2.map, the airship's map by its Database status
## "airship"). Every one inherits scenes/world_map/WorldMapScene.tscn (this
## layout); tools/import/world_to_scene.gd makes them from the .map files.
##
## Coordinates are screen pixels (the 1024 x 768 virtual screen): the maps do
## not scroll or zoom, and the legacy nodes, roads and sprites use them.
##
## Step A (data, docs/MODERNIZATION_PLAN.md 9.1): LandscapeLoader and
## AirLandscapeLoader build the legacy map from the scene (load_into) instead
## of parsing the .map file; --legacy=world_map and --legacy=airship keep the
## .map files.
##
## Step B (presentation): the same scene then draws the map while the legacy
## objects stay in charge of the state, the input and the timing (walking
## Road.movePlayer's points, the airship's velocity and wrap). Every frame,
## where the legacy drawing drew, Landscape.draw_scene (AirLandscape's)
## hands the scene what it would have drawn: show_background, show_roads,
## show_nodes, show_player and show_top, in this order, each with the colour
## and the material of the legacy GL state at that point
## (Graphics.getCurrentColor, Graphics.canvas_material). The scene keeps no
## reference to its mode. The name plate over it is a UI node
## (scenes/ui/NamePlate.tscn).

const SCENE_DIR := "res://scenes/world_map/"

## The .map file the scene was made from ("world0.map", "land1.map").
@export var map_file := ""
## The name the legacy loader's loadImages takes for the background: the
## world map's "background" line ("West": res/Landscape/West/West.jpg's
## tiles and the top layer of res/Landscape/West/top); on an airship map the
## image of res/Landscape/World it shows ("World1": the airship status's).
@export var background_name := ""
## An airship map (AirshipNode children, no roads, the airship as the
## player) rather than a world map.
@export var airship := false

var _bound := false
var _background: Sprite2D
var _roads: Node2D
var _nodes: Node2D
var _player: ActorView
var _overhead: Node2D
var _night: Sprite2D
var _road_of := {} # address -> WorldMapRoad (the first of an address)


## Reports in the log that a map's run-time scene (one that has drawn) is
## freed with its mode, for the parity runs.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _bound:
		print("WorldMapScene: freed %s" % map_file)


## The scene of the .map file map_file ("world0.map"), or "" when it has none.
static func path_for(p_map_file: String) -> String:
	var path := SCENE_DIR + p_map_file.get_basename() + ".tscn"
	return path if ResourceLoader.exists(path) else ""


## Fills the legacy loader as its map loader does for the .map file: a
## LandscapeLoader (LandscapeLoaderMapLoader: the background, the nodes, then
## the roads with their points; every world map file has this order) or, on
## an airship map, an AirLandscapeLoader (its background, then the nodes with
## their zones). The same constructors and Database reads in the same order.
## tools/import/verify_world_map.gd checks that both ways build the same
## objects.
func load_into(loader) -> void:
	Parser.reset()
	loader.loadImages(background_name)
	for child in $Nodes.get_children():
		var x := int(child.position.x)
		var y := int(child.position.y)
		if airship:
			var air_node := AirLandNode.new(x, y, child.kind, child.node_name)
			air_node.setZone(child.zone)
			loader.nodes.append(air_node)
		else:
			loader.nodes.append(LandscapeNode.new(x, y, child.kind, child.node_name))
	if airship:
		return
	for road: WorldMapRoad in $Roads.get_children():
		var source = loader.getNode(road.source)
		var destination = loader.getNode(road.destination)
		var closed: bool = Database.getStatusFor("road" + str(road.address)) == 0
		loader.loadRoad = Road.new(road.address, source, destination, closed)
		source.setRoad(road.direction_to_destination, loader.loadRoad, true)
		destination.setRoad(road.direction_to_source, loader.loadRoad, false)
		loader.roads.append(loader.loadRoad)
		for i in road.curve.point_count:
			var p := road.curve.get_point_position(i)
			loader.loadRoad.addCoordinates(int(p.x), int(p.y))
		if road.has_oc:
			loader.loadRoad.done()


## DoubleBackground.drawBottom: the background tiles, tinted color, drawn
## with the material mat.
func show_background(color: Color, mat: Material) -> void:
	_bind()
	_background.modulate = color
	_background.material = mat


## Road.drawRoad of the visited roads: the roads of addresses, in that order
## (Landscape.visitedRoads'); the others are hidden.
func show_roads(addresses: PackedInt32Array, color: Color, mat: Material) -> void:
	_bind()
	_roads.modulate = color
	_roads.material = mat
	var shown := {}
	var i := 0
	for address in addresses:
		var road: WorldMapRoad = _road_of.get(address)
		if road == null or shown.has(road):
			continue
		shown[road] = true
		road.visible = true
		if road.get_index() != i:
			_roads.move_child(road, i)
		i += 1
	for road in _roads.get_children():
		if not shown.has(road):
			road.visible = false


## LandscapeNode.draw of the visited nodes: the i-th node shows when
## visited[i] is true.
func show_nodes(visited: Array[bool], color: Color, mat: Material) -> void:
	_bind()
	_nodes.modulate = color
	_nodes.material = mat
	var i := 0
	for node in _nodes.get_children():
		node.visible = i < visited.size() and visited[i]
		i += 1


## LandPlayer.draw (the world map's player, or the airship): texture with
## its top-left corner at at (null: nothing).
func show_player(texture: Texture2D, at: Vector2i, color: Color, mat: Material) -> void:
	_bind()
	_player.show_frame(texture, at)
	_player.modulate = color
	_player.material = mat


## DoubleBackground.drawTop without sprites: every top layer piece, then,
## when night_shown, the night layer (scale 2; with the material of the
## alpha test drawTop sets before it).
func show_top(color: Color, mat: Material, night_shown: bool, night_color: Color,
		night_mat: Material) -> void:
	_bind()
	_overhead.modulate = color
	_overhead.material = mat
	_night.visible = night_shown and _night.texture != null
	_night.modulate = night_color
	_night.material = night_mat


## Looks up the layer nodes and the roads (the first frame is handed over
## before the scene enters the tree, so not in _ready).
func _bind() -> void:
	if _bound:
		return
	_bound = true
	_background = $Background
	_roads = $Roads
	_nodes = $Nodes
	_player = $Player
	_overhead = $Overhead
	_night = $Night
	for road: WorldMapRoad in _roads.get_children():
		if not _road_of.has(road.address):
			_road_of[road.address] = road
