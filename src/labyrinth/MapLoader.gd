class_name MapLoader
extends AbstractMapLoader
## Port of labyrinth.MapLoader: the state a .map labyrinth file gave (nodes,
## inventory, textures, light/fog/material settings). The floors are scenes
## since phase 2 (DungeonScene.load_into fills the loader as parsing the file
## did); the .map files and their parse are deleted (plan 7.9).

const FOG = 0
const LIGHT_0 = 1
const LIGHT_1 = 2
const MATERIAL = 3
const INV_MATERIAL = 4
const SKY = 5
const SETTING_VALUE_SIZE = 6
const USE_CARPET_FLOOR = 6
const USE_PILLAR_WALLS = 7
const USE_SNOW = 8
const USE_FIRE = 9
const USE_RAIN = 10
const SETTING_SIZE = 11
const FLOOR = 0
const WALL = 1
const ROOF = 2
const CARPET_FLOOR = 3
const PILLAR_WALLS = 4
var labyrinthName = ""
var mission = null
var map = null
var stepsToBattle = [13, 20]
var settingValues = J.array(SETTING_VALUE_SIZE, null)
var settings = null
var textures = null
var battleMusic = ["Battle", "Fight the Demons"]
static var textureNorm = null
const FOG_RED = 0
const FOG_GREEN = 1
const FOG_BLUE = 2
const FOG_ALPHA = 3
const FOG_DENSITY = 4
const FOG_START = 5
const FOG_END = 6
const LIGHT_AMBIENT = 0
const LIGHT_DIFFUSE = 4
const LIGHT_SPECULAR = 8
const LIGHT_POSITION = 12
const LIGHT_ATTENUATION = 16
const MATERIAL_AMBIENT = 0
const MATERIAL_DIFFUSE = 4
const MATERIAL_SPECULAR = 8
const MATERIAL_EMISSION = 12
const MATERIAL_SHININESS = 16
const SKY_TOP_COLOR = 0
const SKY_BOTTOM_COLOR = 4

func _init(name = null) -> void:
	stepsToBattle[1] -= stepsToBattle[0]
	labyrinthName = name
	InventoryDoor.resetStatic()
	map = LabyrinthMap.new()
	textures = []
	settings = J.array(SETTING_SIZE, false)
	textureNorm = J.array2d(5, 2, 0)
	# Phase 2 (docs/ARCHITECTURE.md section 10): the floor is built from its
	# scene, which replays what parsing the file did. A floor without a scene
	# stays empty, as a missing file left it.
	var scene = dungeon_scene_for(name)
	if scene == null:
		push_error("MapLoader: no scene for the floor " + str(name))
		return
	scene.load_into(self)
	scene.free()


## Bridge (phase 2, docs/ARCHITECTURE.md section 10): a new instance of the
## scene of the floor name ("<Area>--<Floor>.map", in any case; DungeonScene),
## or null when it has none.
func dungeon_scene_for(name):
	var path := DungeonScene.path_for(str(name))
	if path == "":
		return null
	return (ResourceLoader.load(path) as PackedScene).instantiate()

func getMap():
	return map

func addTexture(path):
	var tex := LabyrinthTexture.new(path)
	textures.append(tex)

func getRenderer():
	var renderer := LabyrinthRenderer.new(textures)
	renderer.setMap(map)
	renderer.setSettings(settings, settingValues)
	return renderer

func getStepsToBattle():
	return stepsToBattle

func getMission():
	return mission

func getBattleMusic():
	return battleMusic
