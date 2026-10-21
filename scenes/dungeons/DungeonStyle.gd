@tool
class_name DungeonStyle
extends Resource
## The look of dungeon floors: texture slots, light, material, fog, sky,
## enemy colour and weather, the "look" lines of a .map file. Floors of an
## area share a style where their lines agree (resources/dungeon_styles/
## <Area>.tres); a floor whose look differs has its own
## (<Area>--<Floor>.tres). tools/import/map_to_scene.gd writes them.
##
## Decision 2 (docs/MODERNIZATION_PLAN.md section 13): the fixed-function
## look is kept exactly. DungeonFloor and the object views use the dungeon
## shader (scenes/dungeons/dungeon_gl.gdshaderinc, GLBackend's) with these
## values, as LabyrinthRenderer.addLight, setMaterial and addFog set the GL
## state; step A rebuilds the legacy settings arrays from them
## (legacy_settings), which the legacy battle code still reads through the
## GL state.
##
## Colours and vectors are float32. The .map files write short decimals, so
## legacy_float reads each component back as the float64 the legacy loader
## parsed (7 decimals).

@export_group("Textures")
## The texture slots, as the .map file names them (relative to
## res/Labyrinth/: "Floors/forestfloor.jpg"), in file order: floorTex,
## wallTex and roofTex add one slot, SfloorTex five (carpet shapes), SwallTex
## four (pillar walls). LabyrinthTexture and ImageHandler use these names.
@export var texture_names: PackedStringArray = []
## The textures of the slots (texture_names resolved).
@export var textures: Array[Texture2D] = []
## The slot ranges [x, y) of each pass (the "normal" lines and the S*Tex
## offsets; MapLoader.textureNorm): floors, walls, roofs, carpet floors,
## pillar walls.
@export var floor_slots := Vector2i.ZERO
@export var wall_slots := Vector2i.ZERO
@export var roof_slots := Vector2i.ZERO
@export var carpet_slots := Vector2i.ZERO
@export var pillar_slots := Vector2i.ZERO
## SfloorTex: every cell has a carpet floor (DungeonCell.has_carpet).
@export var carpet_floors := false
## SwallTex: the walls are pillar walls (PillarWalls chose their slots).
@export var pillar_walls := false

@export_group("Light")
## light0 and light1: a GL light each (position w = 1: a point light; the
## position is in eye space, so 0;0;0;1 is a light at the camera). Unset
## values are 0, as in the legacy loader.
@export var light0 := false
@export var light0_position := Vector4.ZERO
@export var light0_ambient := Color(0, 0, 0, 0)
@export var light0_diffuse := Color(0, 0, 0, 0)
@export var light0_specular := Color(0, 0, 0, 0)
## Constant, linear and quadratic attenuation.
@export var light0_attenuation := Vector3.ZERO
@export var light1 := false
@export var light1_position := Vector4.ZERO
@export var light1_ambient := Color(0, 0, 0, 0)
@export var light1_diffuse := Color(0, 0, 0, 0)
@export var light1_specular := Color(0, 0, 0, 0)
@export var light1_attenuation := Vector3.ZERO

@export_group("Material")
## The material of the walls, floors and roofs (and, through the GL state,
## of the objects and the battle).
@export var material := false
@export var material_ambient := Color(0, 0, 0, 0)
@export var material_diffuse := Color(0, 0, 0, 0)
@export var material_specular := Color(0, 0, 0, 0)
@export var material_emission := Color(0, 0, 0, 0)
@export var material_shininess := 0.0
## invMaterial: read by the legacy loader but never applied (the objects use
## the floor's material); kept as data.
@export var inv_material := false
@export var inv_material_ambient := Color(0, 0, 0, 0)
@export var inv_material_diffuse := Color(0, 0, 0, 0)
@export var inv_material_specular := Color(0, 0, 0, 0)
@export var inv_material_emission := Color(0, 0, 0, 0)
@export var inv_material_shininess := 0.0

@export_group("Fog and sky")
## Exponential fog (GL_EXP) of this colour and density. start and end are
## parsed but unused (LabyrinthRenderer.addFog sets neither).
@export var fog := false
@export var fog_color := Color(0, 0, 0, 0)
@export var fog_density := 0.0
@export var fog_start := 0.0
@export var fog_end := 0.0
## A sky: the floors draw no roof, and LabyrinthRenderer.renderSky adds a
## gradient quad (top to bottom colour) to the walls' display list.
@export var sky := false
@export var sky_top := Color(0, 0, 0, 0)
@export var sky_bottom := Color(0, 0, 0, 0)

@export_group("Battle and weather")
## enemyColor: the tint of the enemies in battles (BattleEnemy.setColorStatic,
## at load). Without it the previous floor's tint stays, as in the legacy
## loader.
@export var has_enemy_color := false
@export var enemy_color := Color(0, 0, 0, 0)
## useSnow, useRain, useFire (LabyrinthRenderer.getWeatherSystem: snow wins;
## fire has no system).
@export var snow := false
@export var rain := false
@export var fire := false


## A float32 component read back as the float64 the legacy loader parsed
## from the .map file (its values have at most 7 decimals).
static func legacy_float(f: float) -> float:
	return String.num(f, 7).to_float()


static func _legacy_color(c: Color) -> Array:
	return [legacy_float(c.r), legacy_float(c.g), legacy_float(c.b), legacy_float(c.a)]


## MapLoader's settings (the 11 flags, MapLoader.FOG .. USE_RAIN) of this
## style.
func legacy_flags() -> Array:
	return [fog, light0, light1, material, inv_material, sky, carpet_floors, pillar_walls, snow, fire, rain]


## MapLoader's settingValues (fog, light0, light1, material, invMaterial,
## sky): the arrays the legacy loader fills, null where the line is absent.
func legacy_settings() -> Array:
	var values: Array = [null, null, null, null, null, null]
	if fog:
		values[0] = _legacy_color(fog_color) + [legacy_float(fog_density), legacy_float(fog_start), legacy_float(fog_end)]
	if light0:
		values[1] = _light_values(light0_ambient, light0_diffuse, light0_specular, light0_position, light0_attenuation)
	if light1:
		values[2] = _light_values(light1_ambient, light1_diffuse, light1_specular, light1_position, light1_attenuation)
	if material:
		values[3] = _material_values(material_ambient, material_diffuse, material_specular,
				material_emission, material_shininess)
	if inv_material:
		values[4] = _material_values(inv_material_ambient, inv_material_diffuse, inv_material_specular,
				inv_material_emission, inv_material_shininess)
	if sky:
		values[5] = _legacy_color(sky_top) + _legacy_color(sky_bottom) + _zeros(11)
	return values


## The slot ranges as MapLoader.textureNorm (floor, wall, roof, carpet,
## pillar; [from, to) each).
func legacy_texture_norm() -> Array:
	var out: Array = []
	for r: Vector2i in [floor_slots, wall_slots, roof_slots, carpet_slots, pillar_slots]:
		out.append([r.x, r.y])
	return out


## The enemy colour as BattleEnemy.setColorStatic receives it.
func legacy_enemy_color() -> Array:
	return _legacy_color(enemy_color)


static func _light_values(ambient: Color, diffuse: Color, specular: Color, position: Vector4,
		attenuation: Vector3) -> Array:
	return _legacy_color(ambient) + _legacy_color(diffuse) + _legacy_color(specular) \
			+ [legacy_float(position.x), legacy_float(position.y), legacy_float(position.z), legacy_float(position.w)] \
			+ [legacy_float(attenuation.x), legacy_float(attenuation.y), legacy_float(attenuation.z)]


static func _material_values(ambient: Color, diffuse: Color, specular: Color, emission: Color,
		shininess: float) -> Array:
	return _legacy_color(ambient) + _legacy_color(diffuse) + _legacy_color(specular) \
			+ _legacy_color(emission) + [legacy_float(shininess), 0.0, 0.0]


static func _zeros(n: int) -> Array:
	var a: Array = []
	a.resize(n)
	a.fill(0.0)
	return a
