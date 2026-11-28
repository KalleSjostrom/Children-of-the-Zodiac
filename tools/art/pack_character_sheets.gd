extends SceneTree
## Plan B of docs/VILLAGER_SPRITES_PLAN.md: one sprite sheet per walking
## character (tools/art/character_sets.gd: a set of 16 frames) in place of
## its frame files. <set folder>/<Name>_sheet.png has the layout of
## CharacterSheet (scenes/common/CharacterSheet.gd): 4 columns (the walk
## frames) by 4 rows (up, right, down, left: files 1-4, 5-8, 9-12, 13-16),
## 36x56 cells at a 40x60 pitch, 160x240. The 2 px gutter around a cell
## holds copies of the cell's edge pixels (extrude): linear filtering at the
## cell's edge then samples the edge, as clamp-to-edge does for a frame file.
## The frames must be 36x56 (plan A, pad_character_frames.gd).
##
##   godot --headless --path . --script res://tools/art/pack_character_sheets.gd -- [--dry-run] [--delete-frames]
##   godot --headless --path . --import
##
## For each set that still has its frame files: writes the sheet (unless one
## with the same pixels is there: a second run changes nothing) and, when it
## has none, an .import like the frames' (lossless, no mipmaps,
## fix_alpha_border: the [params] of frame 1's .import; the importer adds
## the uid). Then checks that every frame round-trips: its cell cut out of
## the written sheet equals the frame file, pixel for pixel, and the gutter
## is the cells' extruded edges. --delete-frames then deletes the frame files
## of every set that passed, with their .import files (rewrite the
## SpriteFrames first: tools/art/rewrite_sprite_frames.gd). Sets of 1-3
## frames stay single images.
##
## A sheet whose frame files are gone is the source (edited in place): its
## gutter is extruded again from its cells when it is not their edges any
## more, and left alone otherwise. Exit code 0 if every set passed.
##
## A launcher: the code is pack_character_sheets_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/art/pack_character_sheets_job.gd").new()
	_job.run(self)
