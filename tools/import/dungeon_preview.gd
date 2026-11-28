extends SceneTree
## Renders a dungeon floor scene as the editor shows it (DungeonFloor built
## with GL's default state, the objects' Views, the editor markers of the
## objects, doors and marks), for checking a conversion without opening the
## editor. Windowed (a renderer is needed), from the project root:
##
##   godot --path . --script res://tools/import/dungeon_preview.gd -- <scene> <out>
##
## Writes <out>_rig.png (from the scene's Rig camera: the first door, the
## legacy projection) and <out>_top.png (from above, orthographic, the whole
## floor; the roofs face down and are culled from there). <scene> may be a
## path outside the project.
##
## A launcher: the code is dungeon_preview_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/import/dungeon_preview_job.gd").new()
	_job.run(self)


func _process(delta: float) -> bool:
	return _job._process(delta)
