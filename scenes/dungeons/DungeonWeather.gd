class_name DungeonWeather
extends Node3D
## The rain or snow of a dungeon floor (useRain, useSnow), until a GPU
## particle preset can match it (decision 6, docs/MODERNIZATION_PLAN.md
## section 13): the legacy simulation (WeatherSystem, 10 000 particles in
## GDScript) stays in charge, and this node draws the quads its draw would
## draw, one mesh per pass and frame: the back pass and the front pass (the
## particles close to the camera, drawn again; over a battle the legacy code
## draws it). Labyrinth hands it the quads every frame
## (WeatherSystem.place_particles) with the GL render state they are drawn
## in. The vertices are in eye space (transformed by the legacy modelview,
## as GLBackend does), so the mesh needs no transform of its own.
##
## set_quads draws a save point's particles the same way (DungeonSavePoint).

var _meshes := {}


## Shows one pass (&"back", &"front"): quads of 4 vertices each, with their
## texture coordinates and colours.
func show_pass(pass_name: StringName, vertices: PackedVector3Array, uvs: PackedVector2Array,
		colors: PackedColorArray, material: Material, sorting_offset: float) -> void:
	set_quads(_mesh(pass_name), vertices, uvs, colors, PackedVector3Array(), material, sorting_offset)


## Hides a pass (the front pass during a battle).
func hide_pass(pass_name: StringName) -> void:
	if _meshes.has(pass_name):
		_meshes[pass_name].visible = false


## Draws quads (GL_QUADS, eye space) with mi: one surface, the triangles 0 1 2
## and 0 2 3 of each quad, as Graphics._triangulate makes them; normals may
## be empty (unlit). mi is placed at the camera's origin (top level, the
## identity) and never culled.
static func set_quads(mi: MeshInstance3D, vertices: PackedVector3Array, uvs: PackedVector2Array,
		colors: PackedColorArray, normals: PackedVector3Array, material: Material, sorting_offset: float) -> void:
	if vertices.is_empty():
		mi.visible = false
		return
	var quads := vertices.size() / 4
	var indices := PackedInt32Array()
	indices.resize(quads * 6)
	for q in quads:
		var i := q * 4
		var k := q * 6
		indices[k] = i
		indices[k + 1] = i + 1
		indices[k + 2] = i + 2
		indices[k + 3] = i
		indices[k + 4] = i + 2
		indices[k + 5] = i + 3
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


func _mesh(pass_name: StringName) -> MeshInstance3D:
	var mi: MeshInstance3D = _meshes.get(pass_name)
	if mi == null:
		mi = MeshInstance3D.new()
		mi.name = String(pass_name).capitalize()
		add_child(mi)
		_meshes[pass_name] = mi
	return mi
