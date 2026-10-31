extends Control
## The background of a menu page (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14), as AbstractPage.drawStandard draws it: res/Menu/back.jpg over
## the whole screen, then the menu pieces of the page's layout
## (res/Menu/Pieces/<n>.png at AbstractPage.pos[n], in the layout's order:
## pieces overlap, the later over the earlier). The legacy page keeps its
## layout (AbstractPage.page); each frame its twin hands this node what it
## would have drawn (Graphics.show_ui). The stores show it with their own
## pieces (their mask over Building.store) and no back.jpg.

@onready var _back: TextureRect = $Back
@onready var _pieces: Control = $Pieces


## back: back.jpg as Graphics.place_image places it ([]: none); pieces: the
## pieces in drawing order ([texture, rect, tint] each). mat is the material
## of the legacy drawing (Graphics.canvas_material).
func show_background(back: Array, pieces: Array, mat: Material) -> void:
	material = mat
	_back.visible = not back.is_empty()
	if _back.visible:
		var rect: Rect2i = back[1]
		_back.texture = back[0]
		_back.position = Vector2(rect.position)
		_back.size = Vector2(rect.size)
		_back.self_modulate = back[2]
	_pieces.show_images(pieces)
