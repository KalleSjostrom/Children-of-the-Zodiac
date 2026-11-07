extends Control
## A level-up bar (phase 4.2 step B, docs/ARCHITECTURE.md section 14): the
## images of the legacy LevelUpBar, each drawn over the part of the bar it
## covers (GameTexture.drawPart: the left part of an image, its percent of
## the width; drawPartRange: a range of it; Graphics.place_image_part). The
## legacy LevelUpBar keeps the percentages; its twin hands this node the
## parts where they would have been drawn. The Church's bless page shows one
## per character (LevelUpBar.place_static: the empty bar, the blue bar up to
## the low mark in white and from the low to the high mark in green, the
## overlay up to the high mark); a battle's level-up screen can show
## LevelUpBar.draw's (the empty bar, the blue bar and the overlay up to the
## experience) the same way.
##
## Each part is the legacy drawing's quad: its corners and texture
## coordinates as GameTexture.drawPart and drawPartRange emit them, drawn as
## the same two triangles (as EmotionBubble). A TextureRect with an
## AtlasTexture of the part's region drew the bars' antialiased left ends up
## to 5/255 apart (plan 9.2, "Results of the stores").

## The parts last shown: [texture, rect, uv ([u left, u right, v top, v
## bottom]), tint] each.
var _parts: Array = []


## parts: [texture, rect (the quad), uv (its texture coordinates: [u left, u
## right, v top, v bottom]), tint] each
## (Graphics.place_image_part; [] for one drawn nowhere), in drawing order.
## mat: the material of the legacy drawing (Graphics.canvas_material), null
## to use the parent's.
func show_parts(parts: Array, mat: Material = null) -> void:
	if mat != null:
		material = mat
	if parts != _parts:
		_parts = parts
		queue_redraw()


func _draw() -> void:
	for part: Array in _parts:
		if part.is_empty():
			continue
		var r: Rect2i = part[1]
		# A quad without width or height (a mark at 0) draws nothing.
		if r.size.x <= 0 or r.size.y <= 0:
			continue
		var uv: Array = part[2]
		var x := float(r.position.x)
		var y := float(r.position.y)
		var xw := float(r.end.x)
		var yh := float(r.end.y)
		# The corners in the legacy order (drawip, drawipp): bottom-left,
		# bottom-right, top-right, top-left; GL_QUADS as 0-1-2, 0-2-3.
		var corners: Array[Vector2] = [Vector2(x, yh), Vector2(xw, yh), Vector2(xw, y), Vector2(x, y)]
		var uvs: Array[Vector2] = [Vector2(uv[0], uv[3]), Vector2(uv[1], uv[3]), Vector2(uv[1], uv[2]),
				Vector2(uv[0], uv[2])]
		var points := PackedVector2Array()
		var tex_uvs := PackedVector2Array()
		var colors := PackedColorArray()
		for i: int in [0, 1, 2, 0, 2, 3]:
			points.append(corners[i])
			tex_uvs.append(uvs[i])
			colors.append(part[3])
		var texture: Texture2D = part[0]
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(),
				PackedInt32Array([0, 1, 2, 3, 4, 5]), points, colors, tex_uvs, PackedInt32Array(),
				PackedFloat32Array(), texture.get_rid())
