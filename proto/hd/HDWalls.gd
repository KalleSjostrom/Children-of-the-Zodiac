extends RefCounted
## The HD look's wall geometry (docs/LOOK_PROTOTYPES_PLAN.md 4.4 and 10.3).
## The legacy walls are single quads, flat and without thickness:
## * sun blockers: behind an outer wall nothing is drawn, so the daylight's
##   shadow map is empty there, and its soft-shadow filter, reaching past the
##   wall's foot and corners, let light in along them. A box behind every
##   outer wall casts shadows for the daylight only (BLOCKER_LAYER, which the
##   torch's shadow_caster_mask leaves out);
## * relief: a wall as a grid sunk behind its plane by its texture's height
##   map (white high: the stones' faces stay in the plane, the mortar sinks),
##   so the corridor keeps its size and what the objects draw on a wall (a
##   hinder door) stays in front. The relief fades out to the plane at the
##   floor, at the roof, and at a side that does not go on into a wall of the
##   same texture (a corner, a wall's end, a door), so the walls meet as the
##   flat quads did. Floors and roofs the same: sunk below the floor, above
##   the roof, faded out at a side that does not go on into the same texture
##   or has a wall on it. One mesh per texture and fade, sunk 1 unit deep; an
##   instance per quad, scaled to the depth (so resink changes it at once).
##   A hinder door, which the legacy drawing draws as a wall quad over the
##   wall it is on (or where there is none), can be relief too: wall_quad
##   gives its quad, and the look shows the instance of the image it shows.

## The render layer of the sun blockers (layer 20).
const BLOCKER_LAYER := 1 << 19
## How far the blockers reach behind a wall and below the floor.
const BLOCKER_DEPTH := 1.0
## The part of a quad's width or height over which the relief fades out.
const FADE := 0.06

static var _opaque_tops := {}


## The quads of a surface's arrays (as DungeonFloor builds them: not
## indexed, 6 vertices a quad, the legacy winding), drawn with tex: for each
## {top_left, top_right, bottom_left (where the texture's corners are),
## normal (into its cell), wall (a wall, not a floor or a roof), index (the
## quad's number in arrays), tex}.
static func quads(arrays: Array, tex: Texture2D) -> Array:
	var out := []
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in v.size() / 6:
		var q := i * 6
		var corners := {}
		for k: int in [q, q + 1, q + 2, q + 5]:
			corners[Vector2i(roundi(uv[k].x), roundi(uv[k].y))] = v[k]
		if corners.size() != 4:
			continue
		out.append({"top_left": corners[Vector2i(0, 0)], "top_right": corners[Vector2i(1, 0)],
			"bottom_left": corners[Vector2i(0, 1)], "normal": n[q], "wall": is_wall(arrays, i),
			"index": i, "tex": tex})
	return out


## The quad of the wall on side dir (Values.UP .. LEFT) of the cell at centre
## (DungeonCell.center), drawn with tex, as quads gives it for a wall that
## DungeonFloor._wall built (LabyrinthNode.drawOneWall): index -1.
static func wall_quad(centre: Vector3, dir: int, tex: Texture2D) -> Dictionary:
	var w := DungeonFloor.WIDTH
	# DungeonFloor._wall's corner of the cell, at the roof.
	var c := Vector3(centre.x - w * 0.5, DungeonFloor.ROOF_HEIGHT, centre.z + w * 0.5)
	var top_left: Vector3 = [c, c, c + Vector3(0, 0, -w), c + Vector3(w, 0, 0)][dir]
	var along: Vector3 = [Vector3(w, 0, 0), Vector3(0, 0, -w), Vector3(w, 0, 0), Vector3(0, 0, -w)][dir]
	return {"top_left": top_left, "top_right": top_left + along,
		"bottom_left": Vector3(top_left.x, DungeonFloor.FLOOR_HEIGHT, top_left.z),
		"normal": [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)][dir],
		"wall": true, "index": -1, "tex": tex}


## A quad's place (quads, wall_quad): where it is and which way it faces. A
## hinder door's quad has the place of the wall it covers.
static func place_key(q: Dictionary) -> String:
	return _side_key(q.top_left, q.normal)


## True when quad is a wall quad (its triangles' first normal is level).
static func is_wall(arrays: Array, quad: int) -> bool:
	return absf((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array)[quad * 6].y) <= 0.5


## The sun blockers for walls (quads, walls only) of a floor with cells at cells
## (DungeonCell.center()s): a box behind every wall with no cell behind it,
## from below the floor up to where its texture turns transparent (the
## forest's grass keeps its own shadow), reaching past the wall's ends where
## no cell is behind those either, so outer corners close. A wall drawn as
## relief (its tex in sunk: how deep) gets its box behind the relief; where a
## box ends at a corner it stops short of the relief of the wall around the
## corner, which sinks behind that wall's plane, into the box's way.
static func sun_blockers(walls: Array, cells: Array, sunk: Dictionary) -> MeshInstance3D:
	var taken := {}
	for c: Vector3 in cells:
		taken[_key(c)] = true
	var deepest := 0.0
	for depth: float in sunk.values():
		deepest = maxf(deepest, depth + 0.01)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var boxes := 0
	for w: Dictionary in walls:
		var tl: Vector3 = w.top_left
		var along: Vector3 = w.top_right - tl
		var up: Vector3 = tl - w.bottom_left
		var n: Vector3 = w.normal
		var middle := tl + along * 0.5 - up * 0.5
		if taken.has(_key(middle - n * 2.0)):
			continue
		var ax := along.normalized()
		var ay := up.normalized()
		var x0 := -BLOCKER_DEPTH if not taken.has(_key(middle - n * 2.0 - along)) else deepest
		var x1 := along.length() + (BLOCKER_DEPTH if not taken.has(_key(middle - n * 2.0 + along)) else -deepest)
		var y0 := -up.length() - BLOCKER_DEPTH
		var y1 := -up.length() * opaque_top(w.tex)
		var o := tl - n * (float(sunk.get(w.tex, 0.0)) + (0.01 if sunk.has(w.tex) else 0.0))
		_box(st, o + ax * x0 + ay * y0, ax * (x1 - x0), ay * (y1 - y0), -n * BLOCKER_DEPTH)
		boxes += 1
	if boxes == 0:
		return null
	var m := StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(m)
	var mi := MeshInstance3D.new()
	mi.name = "SunBlockers"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.layers = BLOCKER_LAYER
	return mi


## The relief for quads (quads: walls, floors, roofs; all of them in relief)
## among all_walls (every wall of the floor): a Node3D with an instance per
## quad (its children, in the order of quads) of its texture's relief mesh,
## in material_for(tex)'s material, the grid sunk by sunk[tex] (how deep) ×
## (1 - the height of height_for(tex)).
## On a floor with a roof (roofed) a wall's relief fades out at the top too.
static func relief(quads: Array, all_walls: Array, material_for: Callable, height_for: Callable,
		sunk: Dictionary, grid: int, roofed: bool) -> Node3D:
	# The quads' sides that go on into a quad of the same texture in the same
	# plane: a top left corner and the quad's normal -> its texture; the walls
	# that have a wall back to back with them; and the walls' top and bottom
	# edges, where a roof's or a floor's side ends.
	var sides := {}
	var backs := {}
	var edges := {}
	for w: Dictionary in quads:
		sides[_side_key(w.top_left, w.normal)] = w.tex
	for w: Dictionary in all_walls:
		backs[_back_key(w, 1.0)] = true
		var bl: Vector3 = w.bottom_left
		edges[_edge_key(w.top_left, w.top_right)] = true
		edges[_edge_key(bl, bl + w.top_right - w.top_left)] = true
	var root := Node3D.new()
	root.name = "Relief"
	var meshes := {}
	for w: Dictionary in quads:
		var tl: Vector3 = w.top_left
		var tr: Vector3 = w.top_right
		var bl: Vector3 = w.bottom_left
		var along := tr - tl
		var up := tl - bl
		var br := bl + along
		var size := Vector2(along.length(), up.length())
		# Where the relief fades out, [left, right, top, bottom]: at a side
		# that does not go on into a quad of the same texture, whose top left
		# corner is then one width or height on (the left side goes on if a
		# quad's top right corner is at this one's top left). A wall fades out
		# at the floor, and at the roof if there is one.
		var fades := [sides.get(_side_key(tl - along, w.normal)) != w.tex,
			sides.get(_side_key(tr, w.normal)) != w.tex, roofed, true]
		if not w.wall:
			# A floor or a roof fades out where a wall stands on a side too.
			fades = [fades[0] or edges.has(_edge_key(tl, bl)), fades[1] or edges.has(_edge_key(tr, br)),
				sides.get(_side_key(tl + up, w.normal)) != w.tex or edges.has(_edge_key(tl, tr)),
				sides.get(_side_key(tl - up, w.normal)) != w.tex or edges.has(_edge_key(bl, br))]
		var key := "%d|%s|%s" % [w.tex.get_instance_id(), size, fades]
		if not meshes.has(key):
			meshes[key] = _relief_mesh(height_for.call(w.tex), grid, size,
				material_for.call(w.tex), fades)
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[key]
		mi.set_meta(&"tex", w.tex)
		# Local x along the quad (u), y toward its top (-v), z toward the
		# cell, scaled to the depth; a quad whose basis is mirrored is drawn
		# with its faces turned (Godot does that for a transform with a
		# negative determinant).
		mi.transform = Transform3D(Basis(along / size.x, up / size.y, w.normal * _depth(sunk[w.tex])), tl)
		# Two walls back to back each sink into the other's side, where only
		# the back of the other is (culled); cast double-sided, that back would
		# shadow the relief in front of it. So such a wall casts from its face
		# only (the one of the two facing a light casts), a wall alone (and a
		# floor or a roof) from both sides.
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if w.wall and backs.has(_back_key(w, -1.0)) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		root.add_child(mi)
	return root


## Sinks the relief of root (relief) by sunk[tex] (how deep) at once.
static func resink(root: Node3D, sunk: Dictionary) -> void:
	for c in root.get_children():
		var mi := c as MeshInstance3D
		var b := mi.transform.basis
		mi.transform.basis = Basis(b.x, b.y, b.z.normalized() * _depth(sunk[mi.get_meta(&"tex")]))


## A relief's depth as the scale of its instances: never 0 (a flat basis).
static func _depth(depth: float) -> float:
	return maxf(depth, 0.0005)


## The v (0 at the top) below which tex is opaque in every row: 0 for an
## opaque texture.
static func opaque_top(tex: Texture2D) -> float:
	if _opaque_tops.has(tex):
		return _opaque_tops[tex]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	var top := 0.0
	if img.detect_alpha() != Image.ALPHA_NONE:
		img.convert(Image.FORMAT_RGBA8)
		img.resize(64, 256, Image.INTERPOLATE_NEAREST)
		for y in 256:
			for x in 64:
				if img.get_pixel(x, y).a < 0.5:
					top = (y + 1) / 256.0
					break
	_opaque_tops[tex] = top
	return top


## A quad of size (its width and height) as a grid of grid × grid cells in
## local space (x along the quad, y down from 0 to -height, z toward the
## cell), each vertex sunk behind the plane by 1 - its height (the instance
## scales it to the depth; the image wraps, so quads side by side meet), the
## relief faded out over FADE at the sides in fades ([left, right, top,
## bottom]). Its normals and tangents are the flat grid's: the normal map
## shades the stones, the relief only moves them.
static func _relief_mesh(height: Image, grid: int, size: Vector2, material: Material,
		fades: Array) -> ArrayMesh:
	var h := height.duplicate() as Image
	h.resize(grid, grid, Image.INTERPOLATE_CUBIC)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var row := grid + 1
	var sinks := PackedFloat32Array()
	for j in row:
		for i in row:
			var uv := Vector2(float(i) / grid, float(j) / grid)
			var fade := 1.0
			if fades[0]:
				fade *= smoothstep(0.0, FADE, uv.x)
			if fades[1]:
				fade *= smoothstep(0.0, FADE, 1.0 - uv.x)
			if fades[2]:
				fade *= smoothstep(0.0, FADE, uv.y)
			if fades[3]:
				fade *= smoothstep(0.0, FADE, 1.0 - uv.y)
			sinks.append((1.0 - h.get_pixel(i % grid, j % grid).r) * fade)
			st.set_normal(Vector3(0, 0, 1))
			st.set_uv(uv)
			st.add_vertex(Vector3(uv.x * size.x, -uv.y * size.y, 0.0))
	# Clockwise seen from the cell: Godot's front faces.
	for j in grid:
		for i in grid:
			var a := j * row + i
			for k: int in [a, a + 1, a + row + 1, a, a + row + 1, a + row]:
				st.add_index(k)
	st.generate_tangents()
	var arrays := st.commit_to_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for k in vertices.size():
		var v := vertices[k]
		v.z = -sinks[k]
		vertices[k] = v
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh


## Adds a box (corner o, edges a, b, c) to st, as 12 triangles.
static func _box(st: SurfaceTool, o: Vector3, a: Vector3, b: Vector3, c: Vector3) -> void:
	var p := [o, o + a, o + a + b, o + b, o + c, o + a + c, o + a + b + c, o + b + c]
	for f: Array in [[0, 1, 2, 3], [5, 4, 7, 6], [4, 0, 3, 7], [1, 5, 6, 2], [3, 2, 6, 7], [4, 5, 1, 0]]:
		for k: int in [f[0], f[1], f[2], f[0], f[2], f[3]]:
			st.add_vertex(p[k])


## A cell's key: the 4-unit square of the floor's grid that p is in (cell
## centres are at 4k + 2, mid-square).
static func _key(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / 4.0), floori(p.z / 4.0))


## A wall's key for finding a wall back to back with it: its middle and its
## normal times sign (-1: the key such a wall has).
static func _back_key(w: Dictionary, sign: float) -> String:
	var m: Vector3 = (w.top_right + w.bottom_left) * 0.5
	var n: Vector3 = w.normal * sign
	return "%d,%d,%d|%d,%d" % [roundi(m.x * 2.0), roundi(m.y * 2.0), roundi(m.z * 2.0),
		roundi(n.x), roundi(n.z)]


## A quad's key: its top left corner (on the grid, to the unit) and its
## normal.
static func _side_key(corner: Vector3, normal: Vector3) -> String:
	return "%d,%d,%d|%d,%d,%d" % [roundi(corner.x), roundi(corner.y), roundi(corner.z),
		roundi(normal.x), roundi(normal.y), roundi(normal.z)]


## An edge's key: its ends (on the grid), in either order.
static func _edge_key(a: Vector3, b: Vector3) -> String:
	return _side_key(a + b, Vector3.ZERO)
