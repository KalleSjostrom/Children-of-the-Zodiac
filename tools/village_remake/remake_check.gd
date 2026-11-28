extends SceneTree
## Checks a built village remake (the village-remake skill, step 5) with the
## legacy collision (remake_lib.inflate / reachable: ObstacleHandler's
## arithmetic) from the first spawn of its first variant:
## * every spawn and return point (entries_to) is free and reachable;
## * every door, sign and loot can be reached in its range, every villager
##   talked to (range 30, Villager.checkTalkable);
## * every villager's walk ends where it starts and runs clear of obstacles
##   and inside the village;
## * where the village can be left (the edges reached);
## * every cutscene actor's path (the remake's copy of the cutscene, the
##   villagers at their remake starts, the party beside the villager whose
##   dialog runs it) runs clear of obstacles (a warning: actors pass through
##   anything, but it shows).
##
## godot --headless --path . --script res://tools/village_remake/remake_check.gd -- <remake>
##
## Prints the report and writes report/check.txt and report/check.png (the
## background; red: where the feet can't go; green dots: where they can;
## blue: the overhead pieces; doors yellow, signs cyan, loot magenta, spawns
## white, villagers orange with their walks green, cutscene paths blue; all
## at the feet, a position + (18, 54), numbered as in check.txt). Exit code
## 1 when something fails.
##
## A launcher: the code is remake_check_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/village_remake/remake_check_job.gd").new()
	_job.run(self)
