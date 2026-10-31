extends Control
## The thumbnail of the menu column (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14), as StartPage.drawScreenShot draws it: the screenshot of the
## mode the menu was opened from (taken by MenuStarter.checkMenu, the frame
## before, scaled to 183 x 137), then res/Menu/frame.png over it. The start,
## map, tutorial and status pages show it.

@onready var _shot: TextureRect = $Shot
@onready var _frame: TextureRect = $Frame


## shot and frame as Graphics.place_image places them ([]: not drawn, a menu
## opened from a mode without a screenshot); mat is the material of the
## legacy drawing (Graphics.canvas_material).
func show_thumbnail(shot: Array, frame: Array, mat: Material) -> void:
	material = mat
	_show(_shot, shot)
	_show(_frame, frame)


func _show(rect: TextureRect, image: Array) -> void:
	rect.visible = not image.is_empty()
	if rect.visible:
		var r: Rect2i = image[1]
		rect.texture = image[0]
		rect.position = Vector2(r.position)
		rect.size = Vector2(r.size)
		rect.self_modulate = image[2]
