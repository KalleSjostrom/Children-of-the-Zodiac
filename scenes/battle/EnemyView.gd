class_name EnemyView
extends MeshInstance3D
## The battle's enemy (phase 4.4's rollout, step B; docs/ARCHITECTURE.md
## section 15): its frame as a textured quad, or while an effect slices it the
## slice's two quads (the top one sliding), drawn in the battle's 3D chunk and
## batch slot where the legacy drawing put the enemy's batch
## (Graphics.show_node): the floor scene's world in a labyrinth, a SubViewport
## in a boss area. The node stays at the chunk camera's origin and its corners
## are in eye space, as the legacy batch's vertices are, so it draws the same
## pixels.
##
## The legacy BattleEnemy stays in charge of the frame, the colour, the shake
## and rise, the hide timer and the slice's per-draw steps; its twins
## (BattleEnemy._show_frame, _show_slice) make the drawing's state changes and
## hand this node what it would have drawn, with GLBackend's material for the
## GL render state (decision 2's exact look: the texture, the blending, the
## alpha test, the depth test and write, the fog).

## A quad's two triangles, as Graphics triangulates GL_QUADS.
const QUAD_TRIANGLES: Array[int] = [0, 1, 2, 0, 2, 3]


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_use_aabb_center = false
	extra_cull_margin = 16384.0


## Shows quads: corners holds four eye-space corners per quad, in the order
## the legacy drawing emits them, uvs their texture coordinates; every vertex
## has the colour and the eye-space normal given; mat is the material of the
## legacy render state (Graphics.material_3d).
func show_quads(mat: Material, corners: PackedVector3Array, uvs: PackedVector2Array,
		color: Color, normal: Vector3) -> void:
	var count: int = corners.size() / 4 * QUAD_TRIANGLES.size()
	var vertices := PackedVector3Array()
	var tex_coords := PackedVector2Array()
	vertices.resize(count)
	tex_coords.resize(count)
	var k := 0
	for quad in corners.size() / 4:
		for corner in QUAD_TRIANGLES:
			vertices[k] = corners[quad * 4 + corner]
			tex_coords[k] = uvs[quad * 4 + corner]
			k += 1
	var colors := PackedColorArray()
	colors.resize(count)
	colors.fill(color)
	var normals := PackedVector3Array()
	normals.resize(count)
	normals.fill(normal)

	var am := mesh as ArrayMesh
	if am == null:
		am = ArrayMesh.new()
		mesh = am
	am.clear_surfaces()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = tex_coords
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_NORMAL] = normals
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, mat)
	transform = Transform3D.IDENTITY
	visible = true
