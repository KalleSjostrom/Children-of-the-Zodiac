@tool
class_name DungeonFloor
extends Node3D
## The walls, floors and roofs of a dungeon floor, built from its
## DungeonLayout and the DungeonStyle's textures with SurfaceTool, in the
## editor and at run time (docs/MODERNIZATION_PLAN.md 7.1). The mesh is the
## one the legacy display list holds (Labyrinth.init3D: renderSky, then
## LabyrinthRenderer.draw), ported mechanically from LabyrinthNode.draw,
## drawOneWall and drawFloors/drawRoof, Horizontal.draw (carpet floors) and
## the pillar walls' slots (PillarWalls, chosen by the converter): the same
## vertices, texture coordinates, normals, colours and winding, in the same
## order, one surface per material in the order the display list made them.
##
## Like the display list it bakes the GL state it was compiled in: the
## current colour (the walls are tinted by it: the sky's bottom colour on a
## floor with a sky), the current normal (carpets set none), the alpha test
## and blending. build() takes that state; the editor uses GL's defaults.
## On a floor with a sky the gradient quad that renderSky adds is part of
## the mesh too, where the emulated display list put it: GLBackend bakes the
## vertices relative to the matrix at glNewList and does not record
## renderSky's glLoadIdentity, so the quad stands at world (-2..2, 0..0.827,
## -2) instead of filling the top of the view.

const FLOOR_HEIGHT := -2.0
const ROOF_HEIGHT := 2.0
const WIDTH := 4.0
## The passes of LabyrinthRenderer.draw (MapLoader.FLOOR ... PILLAR_WALLS).
const FLOOR := 0
const WALL := 1
const ROOF := 2
const CARPET := 3
const PILLAR := 4

## The cells to build.
@export var layout: DungeonLayout

var _mesh: MeshInstance3D
var _built := ""
# The display list's groups while building: material -> [vertices, normals,
# uvs, colours], and their order.
var _groups := {}
var _order: Array[ShaderMaterial] = []
var _normal := Vector3(0, 0, 1)
var _color := Color(1, 1, 1, 1)
var _uv := Vector2.ZERO
var _slot := -1
var _material: ShaderMaterial
var _left := {}


## Builds (or rebuilds) the mesh for style and the GL state of the legacy
## compile: "color", "normal" and "uv" (the current colour, normal and
## texture coordinate), and the render state keys of DungeonMaterials.state
## ("additive", "opaque", "alpha_func", "alpha_ref", "depth_test",
## "depth_write", "cull") as they were when the display list was made.
## Missing keys take GL's defaults. Returns the state the compile leaves:
## "color", "normal", "uv" and "slot" (the texture slot bound last, -1 for
## none).
func build(style: DungeonStyle, gl := {}) -> Dictionary:
	var key := "%d|%s" % [style.get_instance_id() if style else 0, var_to_str(gl)]
	if key == _built and is_instance_valid(_mesh):
		return _left
	_built = key
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Mesh"
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Sorted by its origin, as GLBackend's display list instance.
		_mesh.sorting_use_aabb_center = false
		add_child(_mesh, false, Node.INTERNAL_MODE_BACK)
	_mesh.mesh = null
	_color = gl.get("color", Color(1, 1, 1, 1))
	_normal = gl.get("normal", Vector3(0, 0, 1))
	_uv = gl.get("uv", Vector2.ZERO)
	_slot = -1
	_left = {"color": _color, "normal": _normal, "uv": _uv, "slot": _slot}
	if layout == null or style == null:
		return _left
	_groups.clear()
	_order.clear()
	var base := DungeonMaterials.state()
	for k in ["additive", "opaque", "alpha_func", "alpha_ref", "depth_test", "depth_write", "cull"]:
		if gl.has(k):
			base[k] = gl[k]
	base.fog = style.fog
	if style.sky:
		_sky(style, base)
		# renderSky turns the depth test and face culling on again.
		base.depth_test = true
		base.cull = 1
	_passes(style, base)
	var mesh := ArrayMesh.new()
	for m in _order:
		var g: Array = _groups[m]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var v: PackedVector3Array = g[0]
		var n: PackedVector3Array = g[1]
		var uv: PackedVector2Array = g[2]
		var c: PackedColorArray = g[3]
		for i in v.size():
			st.set_color(c[i])
			st.set_normal(n[i])
			st.set_uv(uv[i])
			st.add_vertex(v[i])
		st.set_material(m)
		st.commit(mesh)
	_mesh.mesh = mesh
	_groups.clear()
	_order.clear()
	_left = {"color": _color, "normal": _normal, "uv": _uv, "slot": _slot}
	return _left


## The materials of the mesh's surfaces, in order.
func surface_materials() -> Array[Material]:
	var out: Array[Material] = []
	if _mesh != null and _mesh.mesh != null:
		for i in _mesh.mesh.get_surface_count():
			out.append(_mesh.mesh.surface_get_material(i))
	return out


## LabyrinthRenderer.renderSky: the gradient quad, unlit and untextured,
## without depth test or culling.
func _sky(style: DungeonStyle, base: Dictionary) -> void:
	var st := base.duplicate()
	st.texture = null
	st.use_tex = false
	st.lit = false
	st.depth_test = false
	st.cull = 0
	_material = DungeonMaterials.material(st, style)
	# renderSky sets no texture coordinate: its vertices take the current one.
	_color = style.sky_top
	_vertex(_uv, Vector3(-2, 0.827, -2))
	_vertex(_uv, Vector3(2, 0.827, -2))
	_color = style.sky_bottom
	_vertex(_uv, Vector3(2, 0, -2))
	_vertex(_uv, Vector3(-2, 0, -2))


## LabyrinthRenderer.draw: the floors, roofs, walls, carpets and pillar
## walls, each pass texture slot by slot, each slot cell by cell.
func _passes(style: DungeonStyle, base: Dictionary) -> void:
	var slots: Array[Vector2i] = [style.floor_slots, style.wall_slots, style.roof_slots,
		style.carpet_slots, style.pillar_slots]
	for j in 5:
		var pass_index := j
		if j == WALL:
			pass_index = ROOF
		elif j == ROOF:
			pass_index = WALL
		var r: Vector2i = slots[pass_index]
		for i in range(r.x, r.y):
			var st := base.duplicate()
			st.texture = style.textures[i] if i < style.textures.size() else null
			st.use_tex = st.texture != null
			_material = DungeonMaterials.material(st, style)
			_slot = i
			for c in layout.cells:
				match pass_index:
					FLOOR, CARPET:
						_floor(c, i)
					WALL, PILLAR:
						_walls(c, i)
					ROOF:
						if not style.sky and i == c.roof:
							_horizontal(c, ROOF_HEIGHT)


## LabyrinthNode.drawFloors: the carpet (Horizontal.draw, no normal of its
## own) or the plain floor in this slot.
func _floor(c: DungeonCell, slot: int) -> void:
	if c.has_carpet:
		if c.carpet_slot == slot:
			_carpet(c)
	elif c.floor == slot:
		_horizontal(c, FLOOR_HEIGHT)


## LabyrinthNode.draw: the floor (height -2) or roof (+2) of a cell.
func _horizontal(c: DungeonCell, h: float) -> void:
	var p := c.center()
	var x := p.x - 2
	var z := p.z + 2
	if h == FLOOR_HEIGHT:
		_normal = Vector3(0, 1, 0)
		_vertex(Vector2(0, 1), Vector3(x, h, z))
		_vertex(Vector2(1, 1), Vector3(x + WIDTH, h, z))
		_vertex(Vector2(1, 0), Vector3(x + WIDTH, h, z - WIDTH))
		_vertex(Vector2(0, 0), Vector3(x, h, z - WIDTH))
	else:
		_normal = Vector3(0, -1, 0)
		_vertex(Vector2(0, 0), Vector3(x, h, z - WIDTH))
		_vertex(Vector2(1, 0), Vector3(x + WIDTH, h, z - WIDTH))
		_vertex(Vector2(1, 1), Vector3(x + WIDTH, h, z))
		_vertex(Vector2(0, 1), Vector3(x, h, z))


## Horizontal.draw(g, -2, 4, slot): a carpet floor turned by its rotation.
func _carpet(c: DungeonCell) -> void:
	var p := c.center()
	var x := p.x - 2
	var z := p.z + 2
	var h := FLOOR_HEIGHT
	var w := WIDTH
	match c.carpet_rotation:
		0:
			_vertex(Vector2(0, 1), Vector3(x, h, z))
			_vertex(Vector2(1, 1), Vector3(x + w, h, z))
			_vertex(Vector2(1, 0), Vector3(x + w, h, z - w))
			_vertex(Vector2(0, 0), Vector3(x, h, z - w))
		1:
			_vertex(Vector2(0, 0), Vector3(x, h, z))
			_vertex(Vector2(0, 1), Vector3(x + w, h, z))
			_vertex(Vector2(1, 1), Vector3(x + w, h, z - w))
			_vertex(Vector2(1, 0), Vector3(x, h, z - w))
		2:
			_vertex(Vector2(1, 0), Vector3(x, h, z))
			_vertex(Vector2(0, 0), Vector3(x + w, h, z))
			_vertex(Vector2(0, 1), Vector3(x + w, h, z - w))
			_vertex(Vector2(1, 1), Vector3(x, h, z - w))
		3:
			_vertex(Vector2(1, 1), Vector3(x, h, z))
			_vertex(Vector2(1, 0), Vector3(x + w, h, z))
			_vertex(Vector2(0, 0), Vector3(x + w, h, z - w))
			_vertex(Vector2(0, 1), Vector3(x, h, z - w))


## LabyrinthNode.drawWall: every wall of the cell in this slot.
func _walls(c: DungeonCell, slot: int) -> void:
	for d in 4:
		if c.walls[d] != -1 and c.walls[d] == slot:
			_wall(c, d)


## LabyrinthNode.drawOneWall (flip is always true there).
func _wall(c: DungeonCell, dir: int) -> void:
	var p := c.center()
	var x := p.x - 2
	var z := p.z + 2
	var f := FLOOR_HEIGHT
	var r := ROOF_HEIGHT
	var w := WIDTH
	match dir:
		0:
			_normal = Vector3(0, 0, -1)
			_vertex(Vector2(0, 1), Vector3(x, f, z))
			_vertex(Vector2(0, 0), Vector3(x, r, z))
			_vertex(Vector2(1, 0), Vector3(x + w, r, z))
			_vertex(Vector2(1, 1), Vector3(x + w, f, z))
		1:
			_normal = Vector3(1, 0, 0)
			_vertex(Vector2(0, 0), Vector3(x, r, z))
			_vertex(Vector2(0, 1), Vector3(x, f, z))
			_vertex(Vector2(1, 1), Vector3(x, f, z - w))
			_vertex(Vector2(1, 0), Vector3(x, r, z - w))
		2:
			_normal = Vector3(0, 0, 1)
			_vertex(Vector2(0, 0), Vector3(x, r, z - w))
			_vertex(Vector2(0, 1), Vector3(x, f, z - w))
			_vertex(Vector2(1, 1), Vector3(x + w, f, z - w))
			_vertex(Vector2(1, 0), Vector3(x + w, r, z - w))
		3:
			_normal = Vector3(-1, 0, 0)
			_vertex(Vector2(1, 0), Vector3(x + w, r, z - w))
			_vertex(Vector2(1, 1), Vector3(x + w, f, z - w))
			_vertex(Vector2(0, 1), Vector3(x + w, f, z))
			_vertex(Vector2(0, 0), Vector3(x + w, r, z))


# Quads come as 4 vertices; Graphics._triangulate makes them the triangles
# 0 1 2 and 0 2 3, in the display list's group of the current material.
var _quad: Array = []


func _vertex(uv: Vector2, pos: Vector3) -> void:
	_uv = uv
	_quad.append([pos, _normal, uv, _color])
	if _quad.size() < 4:
		return
	var g: Array = _groups.get(_material, [])
	if g.is_empty():
		g = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedColorArray()]
		_groups[_material] = g
		_order.append(_material)
	# Packed arrays are values: append to locals and store them back.
	var v: PackedVector3Array = g[0]
	var n: PackedVector3Array = g[1]
	var uvs: PackedVector2Array = g[2]
	var c: PackedColorArray = g[3]
	for k: int in [0, 1, 2, 0, 2, 3]:
		var q: Array = _quad[k]
		v.append(q[0])
		n.append(q[1])
		uvs.append(q[2])
		c.append(q[3])
	g[0] = v
	g[1] = n
	g[2] = uvs
	g[3] = c
	_quad.clear()
