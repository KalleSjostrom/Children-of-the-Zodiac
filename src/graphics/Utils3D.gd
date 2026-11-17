class_name Utils3D
extends RefCounted
## Port of graphics.Utils3D: static helpers for drawing textures as quads in 3D.
## Texture coordinates follow the JOGL convention (see GameTexture.TextureCoords).


static func _draw3D(g: Graphics, tc, x: Array, y: Array, z: Array) -> void:
	var gl := g.getGL()
	gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x[0], y[0], z[0])
	gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x[1], y[0], z[0])
	gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x[1], y[1], z[1])
	gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x[0], y[1], z[1])


static func _draw3DPercent(g: Graphics, tc, percent: float, x: Array, y: Array,
		z: Array, length: float) -> void:
	var gl := g.getGL()
	gl.glTexCoord2f(tc.left(), tc.bottom())
	gl.glVertex3f(x[0], y[0], z[0])
	gl.glTexCoord2f(tc.right() * percent, tc.bottom())
	var xs: float = x[0] + length * percent
	gl.glVertex3f(xs, y[0], z[0])
	gl.glTexCoord2f(tc.right() * percent, tc.top())
	gl.glVertex3f(xs, y[1], z[1])
	gl.glTexCoord2f(tc.left(), tc.top())
	gl.glVertex3f(x[0], y[1], z[1])


static func _draw3DY(g: Graphics, tc, percent: float, x: Array, y: Array, z: Array,
		length: float) -> void:
	var gl := g.getGL()
	var ys: float = y[1] - length * percent
	gl.glTexCoord2f(tc.left(), tc.bottom() * percent)
	gl.glVertex3f(x[0], ys, z[0])
	gl.glTexCoord2f(tc.right(), tc.bottom() * percent)
	gl.glVertex3f(x[1], ys, z[0])
	gl.glTexCoord2f(tc.right(), tc.top())
	gl.glVertex3f(x[1], y[1], z[1])
	gl.glTexCoord2f(tc.left(), tc.top())
	gl.glVertex3f(x[0], y[1], z[1])


static func _draw3DBackside(g: Graphics, tc, x: Array, y: Array, z: Array) -> void:
	var gl := g.getGL()
	gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x[0], y[1], z[1])
	gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x[1], y[1], z[1])
	gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x[1], y[0], z[0])
	gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x[0], y[0], z[0])


## Java overloads:
##   draw3D(Graphics g, TextureCoords tc, float[][] coordList)  (no begin/end)
##   draw3D(Graphics g, Texture texture, float[][] coordList)   (binds, begin/end)
##   draw3D(Graphics|GL2 g, Texture tex, float x, float y, float z, float size)
static func draw3D(g: Graphics, tex, a, b = null, c = null, d = null) -> void:
	if b != null:
		_draw3DSquare(g, tex, a, b, c, d)
	elif tex is GameTexture:
		tex.bind(g)
		g.beginQuads()
		_draw3D(g, tex.getImageTexCoords(), a[0], a[1], a[2])
		g.end()
	else:
		_draw3D(g, tex, a[0], a[1], a[2])


static func _draw3DSquare(g: Graphics, tex: GameTexture, x: float, y: float, z: float, size: float) -> void:
	var tc := tex.getImageTexCoords()
	var hs := size / 2.0
	var gl := g.getGL()
	tex.bind(gl)
	gl.glBegin(Graphics.GL_QUADS)
	gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x - hs, y - hs, z)
	gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x + hs, y - hs, z)
	gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x + hs, y + hs, z)
	gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x - hs, y + hs, z)
	gl.glEnd()


static func draw3DwithHW(g: Graphics, tex: GameTexture, x: float, y: float, z: float, size: float) -> void:
	var tc := tex.getImageTexCoords()
	var h := tex.getHeight() * size * tc.bottom()
	var w := tex.getWidth() * size
	var gl := g.getGL()
	tex.bind(gl)
	gl.glBegin(Graphics.GL_QUADS)
	gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x - w, y - h, z)
	gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x + w, y - h, z)
	gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x + w, y + h, z)
	gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x - w, y + h, z)
	gl.glEnd()


static func draw3DBackside(g: Graphics, tex: GameTexture, coordList: Array) -> void:
	tex.bind(g)
	g.beginQuads()
	_draw3DBackside(g, tex.getImageTexCoords(), coordList[0], coordList[1], coordList[2])
	g.end()


static func draw3DPart(g: Graphics, tex: GameTexture, coordList: Array, percent: float, width: float) -> void:
	tex.bind(g)
	g.beginQuads()
	_draw3DPercent(g, tex.getImageTexCoords(), percent, coordList[0], coordList[1], coordList[2], width)
	g.end()


## Bridge (phase 4.4's rollout, part 2, step B, docs/ARCHITECTURE.md section
## 15): draw3D(g, texture, coordList) without the drawing: the texture's bind
## and the quad as its batch would hold it (Graphics.place_quad).
static func place_3d(g: Graphics, tex: GameTexture, coordList: Array) -> Dictionary:
	tex.bind(g)
	return place_3d_coords(g, tex.getImageTexCoords(), coordList)


## Bridge (phase 4.4's rollout, part 2): draw3D(g, texCoords, coordList)
## without the drawing (no bind: the texture bound before is drawn with these
## coordinates); the quad as Graphics.place_quad gives it.
static func place_3d_coords(g: Graphics, tc, coordList: Array) -> Dictionary:
	var x: Array = coordList[0]
	var y: Array = coordList[1]
	var z: Array = coordList[2]
	return g.place_quad(
			PackedVector3Array([Vector3(x[0], y[0], z[0]), Vector3(x[1], y[0], z[0]),
				Vector3(x[1], y[1], z[1]), Vector3(x[0], y[1], z[1])]),
			PackedVector2Array([Vector2(tc.left(), tc.bottom()), Vector2(tc.right(), tc.bottom()),
				Vector2(tc.right(), tc.top()), Vector2(tc.left(), tc.top())]))


## Bridge (phase 4.4's rollout, part 2): draw3DPart without the drawing: the
## bind and the quad to the percent of the width (Graphics.place_quad).
static func place_3d_part(g: Graphics, tex: GameTexture, coordList: Array, percent: float,
		width: float) -> Dictionary:
	tex.bind(g)
	var tc := tex.getImageTexCoords()
	var x: Array = coordList[0]
	var y: Array = coordList[1]
	var z: Array = coordList[2]
	var xs: float = x[0] + width * percent
	return g.place_quad(
			PackedVector3Array([Vector3(x[0], y[0], z[0]), Vector3(xs, y[0], z[0]),
				Vector3(xs, y[1], z[1]), Vector3(x[0], y[1], z[1])]),
			PackedVector2Array([Vector2(tc.left(), tc.bottom()), Vector2(tc.right() * percent, tc.bottom()),
				Vector2(tc.right() * percent, tc.top()), Vector2(tc.left(), tc.top())]))


static func draw2DPart(gl: Graphics, tex: GameTexture, x: int, y: int, height: int, width: int, percent: float) -> void:
	tex.bind(gl)
	gl.glBegin(Graphics.GL_QUADS)
	var tc := tex.getImageTexCoords()
	var xs := J.round(x + width * percent)
	var ys := J.round(y + height)
	gl.glTexCoord2f(tc.left(), tc.top())
	gl.glVertex2i(x, y)
	gl.glTexCoord2f(tc.right() * percent, tc.top())
	gl.glVertex2i(xs, y)
	gl.glTexCoord2f(tc.right() * percent, tc.bottom())
	gl.glVertex2i(xs, ys)
	gl.glTexCoord2f(tc.left(), tc.bottom())
	gl.glVertex2i(x, ys)
	gl.glEnd()


static func draw3DPartY(g: Graphics, tex: GameTexture, coordList: Array, percent: float, height: float) -> void:
	tex.bind(g)
	g.beginQuads()
	_draw3DY(g, tex.getImageTexCoords(), percent, coordList[0], coordList[1], coordList[2], height)
	g.end()


static func calcDistance(firstPoint: Array, secondPoint: Array, size: int) -> float:
	var sum := 0.0
	for i in size:
		sum += pow(firstPoint[i] - secondPoint[i], 2)
	return sqrt(sum)


static func createVector(basePoint: Array, headPoint: Array) -> Array:
	var vector: Array = []
	vector.resize(basePoint.size())
	for i in basePoint.size():
		vector[i] = headPoint[i] - basePoint[i]
	return vector
