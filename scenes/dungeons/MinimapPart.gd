class_name MinimapPart
extends MeshInstance3D
## A part of the labyrinth's minimap drawn with one material (phase 3, dev
## only: --minimap-node; docs/ARCHITECTURE.md section 12): the two dark
## disks, the compass, the visited cells of one image, the yellow arrow. The legacy MapRenderer stays
## in charge (its slide, the cells, the angle) and makes its drawing's GL
## state changes and geometry; its primitives are kept instead of drawn
## (Graphics.begin_capture_3d) and each batch is one of these nodes, in the
## frame's 3D chunk where the batch would have been drawn (Graphics.show_node:
## the floor's world, or a battle's SubViewport after its 2D), at the camera's
## origin, so its eye-space vertices are drawn as the legacy batches were.


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_use_aabb_center = false
	extra_cull_margin = 16384.0


## The batch: triangles in eye space (vertices, texture coordinates,
## colours, normals) drawn with mat (GLBackend's material of the legacy
## render state).
func show_batch(mat: Material, vertices: PackedVector3Array, uvs: PackedVector2Array,
		colors: PackedColorArray, normals: PackedVector3Array) -> void:
	var am := mesh as ArrayMesh
	if am == null:
		am = ArrayMesh.new()
		mesh = am
	am.clear_surfaces()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_NORMAL] = normals
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, mat)
	transform = Transform3D.IDENTITY
	visible = true
