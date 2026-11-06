class_name DungeonWeather
extends Node3D
## The rain or snow of a dungeon floor (useRain, useSnow). The legacy
## WeatherSystem stays in charge; Labyrinth hands this node its two passes
## every frame: the back pass and the front pass (the particles close to the
## camera, drawn again; over a battle or riddle after the battle's batches).
##
## The passes are two instances of the weather's scene (WeatherParticles3D:
## Rain.tscn, Snow.tscn) with the same seed, which run in step (show_gpu; the
## dungeon particles phase); this node carries the legacy modelview, as
## Objects does. The legacy simulation (10 000 particles in GDScript) and its
## quads (--legacy=dungeon_particles) are removed (plan 7.9).
##
## set_quads draws quads of the legacy drawing in eye space (DungeonScene's
## object batches).

const SCENE_DIR := "res://scenes/common/particles/"

var _gpu := {} # pass name -> WeatherParticles3D
static var _indices := PackedInt32Array()


## The GPU path: shows a pass (&"back", &"front") from the state of
## WeatherSystem.place_particles, drawn at sorting_offset. The first call makes the
## pass's instance of the weather scene and starts it with the legacy seed.
func show_gpu(pass_name: StringName, state: Dictionary, style: DungeonStyle, sorting_offset: float) -> void:
	var p: WeatherParticles3D = _gpu.get(pass_name)
	if p == null:
		p = load(SCENE_DIR + String(state.scene) + ".tscn").instantiate()
		p.name = String(pass_name).capitalize()
		p.set_pass(pass_name)
		add_child(p)
		p.start(state.seed)
		_gpu[pass_name] = p
	p.sorting_offset = sorting_offset
	p.show_state(state, style)


## Draws quads (GL_QUADS, eye space) with mi: one surface, the triangles 0 1 2
## and 0 2 3 of each quad, as Graphics._triangulate makes them; normals may
## be empty (unlit). mi is placed at the camera's origin (top level, the
## identity) and never culled.
static func set_quads(mi: MeshInstance3D, vertices: PackedVector3Array, uvs: PackedVector2Array,
		colors: PackedColorArray, normals: PackedVector3Array, material: Material, sorting_offset: float) -> void:
	if vertices.is_empty():
		mi.visible = false
		return
	@warning_ignore("integer_division")
	var indices := _quad_indices(vertices.size() / 4)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	if not normals.is_empty():
		arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var am := mi.mesh as ArrayMesh
	if am == null:
		am = ArrayMesh.new()
		mi.mesh = am
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.sorting_use_aabb_center = false
		mi.extra_cull_margin = 16384.0
		mi.top_level = true
		mi.transform = Transform3D.IDENTITY
	am.clear_surfaces()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, material)
	mi.sorting_offset = sorting_offset
	mi.visible = true


## The triangles 0 1 2 and 0 2 3 of each of quads quads: a slice of an index
## array that grows to the most quads drawn so far (built once, not per
## frame: a pass of 10 000 particles can draw thousands).
static func _quad_indices(quads: int) -> PackedInt32Array:
	@warning_ignore("integer_division")
	var have: int = _indices.size() / 6
	if have < quads:
		_indices.resize(quads * 6)
		for q in range(have, quads):
			var i := q * 4
			var k := q * 6
			_indices[k] = i
			_indices[k + 1] = i + 1
			_indices[k + 2] = i + 2
			_indices[k + 3] = i
			_indices[k + 4] = i + 2
			_indices[k + 5] = i + 3
	return _indices.slice(0, quads * 6)
