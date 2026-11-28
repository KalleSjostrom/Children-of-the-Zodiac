extends SceneTree
## Lists what a village place has that a remake must keep (the
## village-remake skill, step 1): per variant scene its doors, signs, loot,
## spawns, villagers (start and walk from their .char files), animated
## objects and particle systems; the obstacle groups of its .vil file (the
## comments name buildings; saved in obstacle_groups.json when the .vil files
## were deleted); the cutscenes that take place in it, with their
## actors' paths; the doors of other places that return into it (to_pos);
## the places named "<Place> - ...".
##
## godot --headless --path . --script res://tools/village_remake/remake_inventory.gd -- <Place> <out dir>
##
## Writes <out dir>/inventory.txt (numbered), inventory.json and
## inventory.png (the place's background at half size, every item marked
## with its number). Changes nothing else.
##
## A launcher: the code is remake_inventory_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/village_remake/remake_inventory_job.gd").new()
	_job.run(self)
