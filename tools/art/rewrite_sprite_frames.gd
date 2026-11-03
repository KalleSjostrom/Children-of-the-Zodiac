extends SceneTree
## Plan B of docs/VILLAGER_SPRITES_PLAN.md: points the village SpriteFrames
## (resources/sprite_frames/**/*.tres, the ActorViews' frames) at the
## character sheets. Every frame texture that is a frame file of a set with a
## sheet (tools/art/pack_character_sheets.gd; CharacterSheet.frame_number)
## becomes an AtlasTexture sub-resource of the sheet: frame n's cell
## (CharacterSheet.cell). Everything else stays: the animations (up, right, down,
## left: 4 frames each, 150 ms, looped, as the removed converter wrote them),
## their order and durations, the other textures (animated objects, single
## frames), the four empty SpriteFrames. A file without such a frame is not
## saved, so a second run changes nothing. Run after the sheets are imported
## and before their frame files are deleted:
##
##   godot --headless --path . --script res://tools/art/rewrite_sprite_frames.gd -- [--dry-run]
##
## Prints every file it changes and a summary; exit code 0 if all went well.

const FRAMES_DIR := "res://resources/sprite_frames"


func _init() -> void:
	var dry_run := OS.get_cmdline_user_args().has("--dry-run")
	var errors: Array[String] = []
	var files: Array[String] = []
	_find(FRAMES_DIR, files)
	var changed := 0
	var frames_changed := 0
	for path in files:
		var frames := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SpriteFrames
		if frames == null:
			errors.append(path + ": not a SpriteFrames")
			continue
		var n := 0
		for anim in frames.get_animation_names():
			for i in frames.get_frame_count(anim):
				var t := frames.get_frame_texture(anim, i)
				if t == null or t is AtlasTexture:
					continue
				var atlas := _sheet_frame(t.resource_path)
				if atlas == null:
					continue
				frames.set_frame(anim, i, atlas, frames.get_frame_duration(anim, i))
				n += 1
		if n == 0:
			continue
		print("%s%s: %d frames" % ["(dry run) " if dry_run else "", path, n])
		changed += 1
		frames_changed += n
		if not dry_run and ResourceSaver.save(frames, path) != OK:
			errors.append(path + ": cannot be saved")
	print("%d of %d SpriteFrames %s (%d frames)" % [changed, files.size(),
			"to rewrite" if dry_run else "rewritten", frames_changed])
	for e in errors:
		printerr(e)
	quit(1 if not errors.is_empty() else 0)


## The cell of a frame file's sheet, or null when its set has no sheet.
func _sheet_frame(frame_path: String) -> AtlasTexture:
	var n := CharacterSheet.frame_number(frame_path)
	if n == 0:
		return null
	var sheet := CharacterSheet.sheet_path(frame_path.get_base_dir())
	if not ResourceLoader.exists(sheet):
		return null
	return CharacterSheet.cell(ResourceLoader.load(sheet), n)


func _find(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.get_extension() == "tres":
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_find(dir + "/" + d, out)
