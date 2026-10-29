extends Control
## A cutscene image drawn over the actors and their emotion bubbles (phase 3
## step B, docs/ARCHITECTURE.md section 12), as the legacy timeline draws it
## (VillageStoryTimeLine.drawTop, ImageSettings.draw): the cover-all, story
## and village images (on the UI layer, under the dialog) and the translucent
## image over the actors (on the Transition layer, over the cutscene's texts);
## a story image with its text back, the black band behind the texts at the
## bottom. The images under the actors are the village scene's StoryImage.
## The legacy timeline stays in charge of the image, its scroll, its fade and
## the zoom; each frame its drawing hands this node what it would have drawn
## (Graphics.show_ui).

@onready var _zoom: Node2D = $Zoom
@onready var _image: TextureRect = $Zoom/Image
@onready var _text_back: ColorRect = $TextBack


## texture over rect (screen pixels before the zoom: the quad drawImage
## draws, its far corner truncated to whole pixels), drawn through zoom (the
## cutscene's zoom, the legacy modelview), in tint; text_back: the black band
## in tint too, not zoomed. mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_image(texture: Texture2D, rect: Rect2i, zoom: Transform2D, tint: Color, text_back: bool,
		mat: Material) -> void:
	material = mat
	_zoom.transform = zoom
	_image.visible = texture != null
	_image.texture = texture
	_image.position = Vector2(rect.position)
	_image.size = Vector2(rect.size)
	_image.self_modulate = tint
	_text_back.visible = text_back
	_text_back.color = Color(0, 0, 0, tint.a)
