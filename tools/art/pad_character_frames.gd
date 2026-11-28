extends SceneTree
## Plan A of docs/VILLAGER_SPRITES_PLAN.md: every frame of a character set
## (tools/art/character_sets.gd) becomes a 36x56 image, the cell size the
## code already assumes (Sprite.STANDARD_WIDTH/HEIGHT). A smaller frame is
## blitted at (0, 0) into a transparent 36x56 RGBA8 image: a 36x55 frame
## gets an empty row at the bottom, a sitting villager (26x40) empty columns
## at the right and rows at the bottom, so the picture stays where it was
## (the anchor is the top-left corner). Frames that are already 36x56 are
## not touched, so a second run changes nothing. The .import files stay as
## they are (same path, uid and settings); reimport afterwards:
##
##   godot --headless --path . --script res://tools/art/pad_character_frames.gd -- [--dry-run]
##   godot --headless --path . --import
##
## Prints every set it changes (or would change, with --dry-run) and a
## summary. Every padded frame is read back and checked: its top-left part
## must be the old frame, pixel for pixel, and the rest transparent. Exit
## code 0 if every frame is 36x56 (or would be) and every check passed.
##
## A launcher: the code is pad_character_frames_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/art/pad_character_frames_job.gd").new()
	_job.run(self)
