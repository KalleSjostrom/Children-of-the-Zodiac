extends SceneTree
## Renders a whole village scene (or any 2D scene) to a PNG, to check a
## conversion without the editor. Needs a window (rendering), so do not pass
## --headless; --debug-collisions also draws the obstacles and the markers of
## doors, signs, loot, spawns and particle systems, as the editor does:
##
##   godot --path . --debug-collisions --script res://tools/import/scene_preview.gd -- <scene.tscn> <out.png> [scale]
##
## The scene's own Camera2D is turned off; the image covers the
## VillageScene's size (or 1024x768), scaled by scale (default 1).
##
## A launcher: the code is scene_preview_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/import/scene_preview_job.gd").new()
	_job.run(self)
