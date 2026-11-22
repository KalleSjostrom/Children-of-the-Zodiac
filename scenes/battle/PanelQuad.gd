class_name PanelQuad
extends MeshInstance3D
## One legacy batch of quads (or triangles) of the battle's 3D (phase 4.4's
## rollout, parts 2 to 5, step B; docs/ARCHITECTURE.md section 15). The info
## panels: a row's
## gradient, or of a creature's panel its portrait, a part of its progress bar
## (the empty bar, the fill or the overlay to the percent), its info texture
## (name, "Elem:", life: the legacy Image as the texture), its element icon
## or a boost's card. The deck and the hand: a weapon slot's side or the mode
## icon, the hand's slots, the save slot, a card's picture, balls or back, the
## pointer, the deck's gradient, the target hand; the legend's gradient. The
## card effects that are not particles (part 5): Death's image, Slow's clock
## and each of its hands, and Demolish's lit spheres (triangles: up to three
## spheres of 15,000 vertices a batch). Each
## is a quad (or a batch's quads) in the battle's 3D chunk and in the batch
## slot of the legacy batch it replaces (Graphics.show_node), one instance
## per batch: the parts overlap, and surfaces of one instance would tie in
## Godot's transparent sort (as the floor's walls did, section 10). A batch of
## several quads (a card's balls, the hand's slots, the enemy row's gradient
## merged into the character row's when no character is drawn) is one node
## with all of them. The node stays at the chunk camera's origin and its
## corners are in eye space, as the legacy batch's vertices are (a card's or
## a slot's turn is in them; its back is the reverse winding, which the
## material's face culling hides or shows), so it draws the same pixels.
##
## The legacy objects (CreatureRow, Creature3D, BattleProgressBar; GLDeck,
## GLWeapon, GLSlot, GLCard, GLHand, Legend) keep the state, the slides, the
## turns, the bars' percent and the info texture's rebuild; their twins make
## the drawing's state changes and hand this node the quads they would have
## drawn (Utils3D.show_quad), with GLBackend's material for the GL render
## state (decision 2's exact look: the texture, the blending, the alpha test,
## the depth test and write, the face culling, the fog).

## A quad's two triangles, as Graphics triangulates GL_QUADS.
const QUAD_TRIANGLES: Array[int] = [0, 1, 2, 0, 2, 3]

## The batch queue_triangles was given this frame (its triangles may still
## grow), built at the end of the frame's processing.
var _pending := {}


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_use_aabb_center = false
	extra_cull_margin = 16384.0


## Shows quads: four eye-space corners per quad in the order the legacy
## drawing emits them, with their texture coordinates, colours (a gradient's
## differ) and eye-space normals, and the material of the legacy render state
## (Graphics.material_3d).
func show_quads(mat: Material, corners: PackedVector3Array, uvs: PackedVector2Array,
		colors: PackedColorArray, normals: PackedVector3Array) -> void:
	var count: int = corners.size() / 4 * QUAD_TRIANGLES.size()
	var vertices := PackedVector3Array()
	var tex_coords := PackedVector2Array()
	var vertex_colors := PackedColorArray()
	var vertex_normals := PackedVector3Array()
	vertices.resize(count)
	tex_coords.resize(count)
	vertex_colors.resize(count)
	vertex_normals.resize(count)
	var k := 0
	for quad in corners.size() / 4:
		for corner in QUAD_TRIANGLES:
			var i: int = quad * 4 + corner
			vertices[k] = corners[i]
			tex_coords[k] = uvs[i]
			vertex_colors[k] = colors[i]
			vertex_normals[k] = normals[i]
			k += 1
	show_triangles(mat, vertices, tex_coords, vertex_colors, vertex_normals)


## Shows triangles as the legacy batch holds them (three eye-space vertices
## each, in drawing order: Demolish's spheres, Graphics.begin_capture_3d),
## with their texture coordinates, colours and eye-space normals, in the
## material of the legacy render state.
func show_triangles(mat: Material, vertices: PackedVector3Array, uvs: PackedVector2Array,
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


## Shows a batch of triangles ({"mat", "v", "uv", "c", "n"}: a captured
## primitive, Utils3D.show_triangles) whose arrays may still grow this frame
## (the spheres merged into it), so its mesh is built once, when the frame's
## processing ends (a deferred call runs before the frame renders), not per
## merged sphere.
func queue_triangles(batch: Dictionary) -> void:
	if _pending.is_empty():
		_build_pending.call_deferred()
	_pending = batch
	transform = Transform3D.IDENTITY
	visible = true


func _build_pending() -> void:
	var b := _pending
	_pending = {}
	if not b.is_empty():
		show_triangles(b.mat, b.v, b.uv, b.c, b.n)
