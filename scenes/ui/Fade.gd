extends Control
## The fade over the frame (phase 3 step B, docs/ARCHITECTURE.md section 12),
## on the Transition layer: the quad of the legacy Graphics.fadeOldSchool, a
## colour (fade to black or white) or the image of Graphics.setFadeImage, at
## the alpha 1 - fade value of the frame. The legacy Fadeable keeps the fade
## value and its timing; the frame's drawing hands this node the quad
## (Graphics.show_fade) where it would have drawn it.

@onready var _colour: ColorRect = $Colour
@onready var _image: TextureRect = $Image


## A colour over the whole screen (its alpha the fade's); mat is the material
## of the legacy drawing (its blending and alpha test, Graphics.canvas_material).
func show_colour(colour: Color, mat: Material) -> void:
	material = mat
	_image.visible = false
	_colour.visible = true
	_colour.color = colour


## An image at the top left corner, in tint (its alpha the fade's).
func show_image(texture: Texture2D, tint: Color, mat: Material) -> void:
	material = mat
	_colour.visible = false
	_image.visible = true
	_image.texture = texture
	_image.self_modulate = tint
