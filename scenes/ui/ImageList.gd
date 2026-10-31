extends Control
## Images whose number changes from frame to frame (a menu page's pieces, a
## character's slots, a deck's cards' balls): one TextureRect child per entry,
## made as needed and kept, in the order given (the legacy drawing's order).
## Each image covers its rect (the quad drawImage draws, Graphics.place_image).
## Children use the parent's material.


## Shows one image per entry and hides the others. An entry is [texture,
## rect, tint] (Graphics.place_image's), or [] for nothing.
func show_images(images: Array) -> void:
	var rects := get_children()
	var shown := 0
	for image: Array in images:
		if image.is_empty():
			continue
		var rect: TextureRect
		if shown < rects.size():
			rect = rects[shown]
		else:
			rect = TextureRect.new()
			rect.use_parent_material = true
			rect.mouse_filter = MOUSE_FILTER_IGNORE
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_SCALE
			add_child(rect)
		var r: Rect2i = image[1]
		rect.texture = image[0]
		rect.position = Vector2(r.position)
		rect.size = Vector2(r.size)
		rect.self_modulate = image[2]
		rect.visible = true
		shown += 1
	for i in range(shown, rects.size()):
		rects[i].visible = false


## Shows images in a row from the node's place, distance apart, each at its
## texture's size (a character's or an item's slots): [texture, tint] each,
## a null texture for an image that is not drawn (it keeps its place).
func show_row(images: Array, distance: int) -> void:
	var placed := []
	for i in images.size():
		var image: Array = images[i]
		if image[0] == null:
			continue
		var t: Texture2D = image[0]
		placed.append([t, Rect2i(i * distance, 0, t.get_width(), t.get_height()), image[1]])
	show_images(placed)
