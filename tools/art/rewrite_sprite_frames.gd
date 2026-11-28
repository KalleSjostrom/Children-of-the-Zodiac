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
##
## A launcher: the code is rewrite_sprite_frames_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/art/rewrite_sprite_frames_job.gd").new()
	_job.run(self)
