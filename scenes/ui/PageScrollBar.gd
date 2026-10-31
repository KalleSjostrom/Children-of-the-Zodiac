extends Control
## A scroll bar (phase 4.2 step B, docs/ARCHITECTURE.md section 14), as the
## legacy MenuScrollBar draws it, its images at 0.4 of their size: the top
## triangle, the ball at the place of the list's cursor or the deck's line,
## the bottom triangle. The legacy MenuScrollBar keeps its place (its lazy
## init); each frame its twin (MenuScrollBar.place_bar) hands this node the
## images where they would have been drawn: inside a MenuList (a list in a
## bounding box that overflows it) and on its own (the deck page's decks; the
## card store's later).

@onready var _parts: Array[TextureRect] = [$Top, $Ball, $Bottom]


## images: the top triangle, the ball and the bottom triangle, [texture,
## rect, tint] each (Graphics.place_image; [] for one that is not drawn). mat
## is the material of the legacy drawing (Graphics.canvas_material).
func show_bar(images: Array, mat: Material) -> void:
	material = mat
	for i in _parts.size():
		var image: Array = images[i] if i < images.size() else []
		var part := _parts[i]
		part.visible = not image.is_empty()
		if part.visible:
			var rect: Rect2i = image[1]
			part.texture = image[0]
			part.position = Vector2(rect.position)
			part.size = Vector2(rect.size)
			part.self_modulate = image[2]
