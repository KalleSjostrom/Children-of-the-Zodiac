extends Control
## An emotion bubble ("!", "?", "zzz" …) over an actor (phase 3 step B,
## docs/ARCHITECTURE.md section 12), on the UI layer, as the legacy
## Sprite.drawEmotions draws it: the first legacy 2D after the village (over
## its actors, roofs, night layer and particles), under the overlays drawn
## after it. The legacy sprite keeps the emotion and its shake; each frame the
## village or the cutscene hands each bubble the legacy drawing would draw to
## one of these nodes (Graphics.show_ui), in the legacy order.
##
## The bubble is the legacy drawing's quad: its corners on the screen as the
## legacy drawing transforms them (a cutscene's zoom scales them), drawn as
## two triangles. A TextureRect under the zoom's transform (or the village
## camera's) rounds the corners differently: up to 2/255 on a few pixels of
## the zoomed bubbles (plan 8.3).

## The texture coordinates of the quad's corners (GameTexture's: v = 0 at the
## image's top), in the corners' order.
const UVS: PackedVector2Array = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]

var _texture: Texture2D
var _corners := PackedVector2Array()
var _tint := Color.WHITE


## texture on the quad corners (screen pixels: its bottom-left, bottom-right,
## top-right and top-left corner, as the legacy drawing emits them) in tint
## (the legacy current colour); mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_bubble(texture: Texture2D, corners: PackedVector2Array, tint: Color,
		mat: Material) -> void:
	material = mat
	_texture = texture
	_corners = corners
	_tint = tint
	queue_redraw()


func _draw() -> void:
	if _texture == null or _corners.size() != 4:
		return
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for i: int in [0, 1, 2, 0, 2, 3]:
		points.append(_corners[i])
		uvs.append(UVS[i])
		colors.append(_tint)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(),
			PackedInt32Array([0, 1, 2, 3, 4, 5]), points, colors, uvs, PackedInt32Array(),
			PackedFloat32Array(), _texture.get_rid())
