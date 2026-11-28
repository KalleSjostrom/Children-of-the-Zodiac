extends RefCounted
## The code of pad_character_frames.gd (its header has the usage), run by it once the
## autoloads are registered (docs/ARCHITECTURE.md section 17, "Tools").

const CharacterSets := preload("res://tools/art/character_sets.gd")


## The launcher's tree (its quit, root and frames).
var tree: SceneTree


## Runs the tool (the launcher's _initialize).
func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var dry_run := OS.get_cmdline_user_args().has("--dry-run")
	var errors: Array[String] = []
	var sets := CharacterSets.find(errors)
	var changed_sets := 0
	var changed_frames := 0
	var kept := 0
	for s in sets:
		var sizes := {}
		var to_pad: PackedStringArray = []
		for path in s.frames:
			var size := CharacterSets.image_size(path)
			sizes[size] = true
			if size == CharacterSheet.CELL:
				kept += 1
			elif size.x <= CharacterSheet.CELL.x and size.y <= CharacterSheet.CELL.y:
				to_pad.append(path)
			else:
				errors.append("%s: %dx%d does not fit the cell" % [path, size.x, size.y])
		if sizes.size() > 1:
			errors.append("%s: frames of different sizes %s" % [s.folder, sizes.keys()])
		if to_pad.is_empty():
			continue
		var from: Vector2i = CharacterSets.image_size(to_pad[0])
		print("%s%s: %d frame%s %dx%d -> %dx%d" % ["(dry run) " if dry_run else "",
				CharacterSets.legacy_path(s.folder), to_pad.size(), "" if to_pad.size() == 1 else "s",
				from.x, from.y, CharacterSheet.CELL.x, CharacterSheet.CELL.y])
		changed_sets += 1
		changed_frames += to_pad.size()
		if dry_run:
			continue
		for path in to_pad:
			var error := _pad(path)
			if error != "":
				errors.append(error)
	print("%d sets, %d frames %s, %d frames already %dx%d" % [changed_sets, changed_frames,
			"to pad" if dry_run else "padded", kept, CharacterSheet.CELL.x, CharacterSheet.CELL.y])
	for e in errors:
		printerr(e)
	tree.quit(1 if not errors.is_empty() else 0)


## Pads one frame file in place and checks the result. Returns "" or an error.
func _pad(path: String) -> String:
	var file := ProjectSettings.globalize_path(path)
	var frame := CharacterSets.load_rgba(file)
	if frame == null:
		return path + ": cannot be read"
	var padded := Image.create_empty(CharacterSheet.CELL.x, CharacterSheet.CELL.y, false, Image.FORMAT_RGBA8)
	padded.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
	if padded.save_png(file) != OK:
		return path + ": cannot be written"
	var back := CharacterSets.load_rgba(file)
	if back == null or back.get_size() != CharacterSheet.CELL:
		return path + ": written image has the wrong size"
	if not CharacterSets.same_pixels(back.get_region(Rect2i(Vector2i.ZERO, frame.get_size())), frame):
		return path + ": written image differs from the frame"
	for y in CharacterSheet.CELL.y:
		for x in CharacterSheet.CELL.x:
			if (x >= frame.get_width() or y >= frame.get_height()) and back.get_pixel(x, y) != Color(0, 0, 0, 0):
				return path + ": padding is not transparent"
	return ""
