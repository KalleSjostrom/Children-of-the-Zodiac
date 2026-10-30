extends Control
## The game over screen's picture (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14): the image of the party that lost
## (res/Title/GameOver<names>.jpg, 1024 x 768) at (0, 0), as the legacy
## GameOver draws it. The legacy GameOver stays in charge of the fade, the
## 22 s timer and the input; each frame its drawing hands this node the image
## (Graphics.show_ui).

@onready var _image: TextureRect = $Image


## The image (null: none, its file is missing) in tint; mat is the material
## of the legacy drawing (Graphics.canvas_material).
func show_image(image: Texture2D, tint: Color, mat: Material) -> void:
	_image.texture = image
	_image.visible = image != null
	_image.self_modulate = tint
	material = mat
