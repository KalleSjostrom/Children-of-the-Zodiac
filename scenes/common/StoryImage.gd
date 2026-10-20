class_name StoryImage
extends Sprite2D
## A cutscene image drawn between the sprites of a village scene's Actors
## layer: the "backflash" and "translucent under actor" image modes of
## story.VillageStoryTimeLine, which the legacy timeline draws after the
## village's own sprites and before its actors. The other image modes are
## drawn over the emotion bubbles, so they stay in the legacy overlay.
##
## Phase 1 step B: the timeline stays in charge; it shows the image with
## show_image every frame and hides it otherwise.


## Shows texture with its top-left corner at at (village pixels), scaled by
## image_scale.
func show_image(texture: Texture2D, at: Vector2i, image_scale: float) -> void:
	self.texture = texture
	position = Vector2(at)
	scale = Vector2(image_scale, image_scale)
	visible = texture != null
