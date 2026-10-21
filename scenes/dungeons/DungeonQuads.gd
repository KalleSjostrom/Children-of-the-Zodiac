class_name DungeonQuads
extends RefCounted
## Records the quads a legacy draw emits, for a scene node that draws them in
## its place (step B, docs/ARCHITECTURE.md section 10): it stands in for
## Graphics in the legacy geometry code (Inventory._drawQuad,
## LabyrinthNode.drawOneWall and drawOneFloor), takes the vertices with the
## current texture coordinate, normal and colour as GL would, and passes the
## state calls on to the real Graphics, so that the GL state they leave is
## the legacy drawing's. eye_space gives the vertices as Graphics._emitTriangles
## transforms them (by the modelview, on the CPU), so that a mesh at the
## camera's origin draws them to the bit (DungeonWeather.set_quads).

var vertices := PackedVector3Array()
var uvs := PackedVector2Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var _g: Graphics
var _uv := Vector2.ZERO
var _normal := Vector3(0, 0, 1)


func _init(g: Graphics) -> void:
	_g = g
	_uv = g.current_tex_coord()
	_normal = g.current_normal()


## The arrays in eye space: the vertices and normals transformed by the
## current modelview as Graphics does it.
func eye_space() -> Dictionary:
	var mv := _g.getModelView()
	var n := PackedVector3Array()
	n.resize(normals.size())
	for i in normals.size():
		n[i] = mv.basis * normals[i]
	return {"vertices": mv * vertices, "uvs": uvs, "normals": n, "colors": colors}


# The part of the GL API that the geometry code calls.

func getGL() -> DungeonQuads:
	return self


func glNormal3f(x: float, y: float, z: float) -> void:
	_normal = Vector3(x, y, z)
	_g.glNormal3f(x, y, z)


func glTexCoord2f(u: float, v: float) -> void:
	_uv = Vector2(u, v)
	_g.glTexCoord2f(u, v)


func glTexCoord2i(u: int, v: int) -> void:
	_uv = Vector2(u, v)
	_g.glTexCoord2i(u, v)


func glVertex3f(x: float, y: float, z: float) -> void:
	vertices.append(Vector3(x, y, z))
	uvs.append(_uv)
	normals.append(_normal)
	colors.append(_g.getCurrentColor())
