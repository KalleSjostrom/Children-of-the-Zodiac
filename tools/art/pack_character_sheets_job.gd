extends RefCounted
## The code of pack_character_sheets.gd (its header has the usage), run by it once the
## autoloads are registered (docs/ARCHITECTURE.md section 17, "Tools").

const CharacterSets := preload("res://tools/art/character_sets.gd")


## The launcher's tree (its quit, root and frames).
var tree: SceneTree


## Runs the tool (the launcher's _initialize).
func run(p_tree: SceneTree) -> void:
	tree = p_tree
	var args := OS.get_cmdline_user_args()
	var dry_run := args.has("--dry-run")
	var delete_frames := args.has("--delete-frames")
	var errors: Array[String] = []
	var written := 0
	var same := 0
	var deleted := 0
	var sets := CharacterSets.find(errors)
	for s in sets:
		if not s.is_walking():
			continue
		var sheet_path := CharacterSheet.sheet_path(s.folder)
		var sheet := _build(s, errors)
		if sheet == null:
			continue
		var old: Image = null
		if FileAccess.file_exists(sheet_path):
			old = CharacterSets.load_rgba(sheet_path)
		var prefix := "(dry run) " if dry_run else ""
		if CharacterSets.same_pixels(old, sheet):
			same += 1
		else:
			print("%s%s: %s" % [prefix, CharacterSets.legacy_path(sheet_path),
					"rewritten" if old != null else "written"])
			written += 1
			if dry_run:
				continue
			if sheet.save_png(ProjectSettings.globalize_path(sheet_path)) != OK:
				errors.append(sheet_path + ": cannot be written")
				continue
		if not dry_run and not FileAccess.file_exists(sheet_path + ".import"):
			var error := _write_import(s.frames[0] + ".import", sheet_path + ".import")
			if error != "":
				errors.append(error)
				continue
		if dry_run:
			continue
		var error := _check_round_trip(s, sheet_path)
		if error != "":
			errors.append(error)
			continue
		if delete_frames:
			for path in s.frames:
				for f in [path, path + ".import"]:
					if FileAccess.file_exists(f) and DirAccess.remove_absolute(ProjectSettings.globalize_path(f)) != OK:
						errors.append(f + ": cannot be deleted")
			print("%s: %d frame files deleted" % [CharacterSets.legacy_path(s.folder), s.frames.size()])
			deleted += 1
	var extruded := _extrude_sheets_without_frames(sets, dry_run, errors)
	print("%d sheets %s, %d unchanged, frames of %d sets deleted, %d gutters %s" % [written,
			"to write" if dry_run else "written", same, deleted, extruded,
			"to extrude again" if dry_run else "extruded again"])
	for e in errors:
		printerr(e)
	tree.quit(1 if not errors.is_empty() else 0)


## The sheets of sets without frame files whose gutter is not their cells'
## edges (an edited sheet): extrudes them again. Returns how many.
func _extrude_sheets_without_frames(sets: Array, dry_run: bool, errors: Array[String]) -> int:
	var with_frames := {}
	for s in sets:
		with_frames[s.folder] = true
	var count := 0
	for folder in CharacterSets.set_folders():
		var sheet_path := CharacterSheet.sheet_path(folder)
		if with_frames.has(folder) or not FileAccess.file_exists(sheet_path):
			continue
		var sheet := CharacterSets.load_rgba(sheet_path)
		if sheet == null or sheet.get_size() != CharacterSheet.SIZE:
			errors.append("%s: not a %dx%d sheet" % [sheet_path, CharacterSheet.SIZE.x, CharacterSheet.SIZE.y])
			continue
		var fixed := sheet.duplicate() as Image
		extrude(fixed)
		if CharacterSets.same_pixels(fixed, sheet):
			continue
		print("%s%s: gutter extruded again" % ["(dry run) " if dry_run else "", CharacterSets.legacy_path(sheet_path)])
		count += 1
		if not dry_run and fixed.save_png(ProjectSettings.globalize_path(sheet_path)) != OK:
			errors.append(sheet_path + ": cannot be written")
	return count


## The sheet of a set, or null (an error) when a frame cannot be read or is
## not 36x56.
func _build(s, errors: Array[String]) -> Image:
	var sheet := Image.create_empty(CharacterSheet.SIZE.x, CharacterSheet.SIZE.y, false, Image.FORMAT_RGBA8)
	for i in s.frames.size():
		var frame := CharacterSets.load_rgba(s.frames[i])
		if frame == null or frame.get_size() != CharacterSheet.CELL:
			errors.append("%s: not a %dx%d frame (pad it first)" % [s.frames[i],
					CharacterSheet.CELL.x, CharacterSheet.CELL.y])
			return null
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, CharacterSheet.CELL), CharacterSheet.region(i + 1).position)
	extrude(sheet)
	return sheet


## Fills the gutter around every cell with copies of the cell's edge pixels:
## its left and right columns, then its top and bottom rows with them (the
## corners are the corner pixels).
static func extrude(sheet: Image) -> void:
	for n in range(1, CharacterSheet.FRAMES + 1):
		var r := CharacterSheet.region(n)
		var left := sheet.get_region(Rect2i(r.position.x, r.position.y, 1, r.size.y))
		var right := sheet.get_region(Rect2i(r.end.x - 1, r.position.y, 1, r.size.y))
		for g in range(1, CharacterSheet.GUTTER + 1):
			sheet.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i(r.position.x - g, r.position.y))
			sheet.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(r.end.x - 1 + g, r.position.y))
		var x := r.position.x - CharacterSheet.GUTTER
		var w := r.size.x + 2 * CharacterSheet.GUTTER
		var top := sheet.get_region(Rect2i(x, r.position.y, w, 1))
		var bottom := sheet.get_region(Rect2i(x, r.end.y - 1, w, 1))
		for g in range(1, CharacterSheet.GUTTER + 1):
			sheet.blit_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i(x, r.position.y - g))
			sheet.blit_rect(bottom, Rect2i(Vector2i.ZERO, bottom.get_size()), Vector2i(x, r.end.y - 1 + g))


## The sheet's .import: the importer and [params] of a frame's .import.
func _write_import(frame_import: String, sheet_import: String) -> String:
	var source := ConfigFile.new()
	if source.load(frame_import) != OK:
		return frame_import + ": cannot be read"
	var out := ConfigFile.new()
	out.set_value("remap", "importer", source.get_value("remap", "importer", "texture"))
	out.set_value("remap", "type", source.get_value("remap", "type", "CompressedTexture2D"))
	for key in source.get_section_keys("params"):
		out.set_value("params", key, source.get_value("params", key))
	if out.save(sheet_import) != OK:
		return sheet_import + ": cannot be written"
	return ""


## Checks the written sheet: every cell is its frame file, the gutter is the
## cells' extruded edges. Returns "" or an error.
func _check_round_trip(s, sheet_path: String) -> String:
	var sheet := CharacterSets.load_rgba(sheet_path)
	if sheet == null or sheet.get_size() != CharacterSheet.SIZE:
		return sheet_path + ": cannot be read back"
	var cells := Image.create_empty(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
	for i in s.frames.size():
		var region := CharacterSheet.region(i + 1)
		if not CharacterSets.same_pixels(sheet.get_region(region), CharacterSets.load_rgba(s.frames[i])):
			return "%s: frame %d does not round-trip (%s)" % [sheet_path, i + 1, s.frames[i]]
		cells.blit_rect(sheet, region, region.position)
	# The gutter must be the cells' edges: compare with the cells extruded again.
	extrude(cells)
	if not CharacterSets.same_pixels(cells, sheet):
		return sheet_path + ": the gutter is not the cells' extruded edges"
	return ""
