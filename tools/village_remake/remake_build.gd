extends SceneTree
## Builds a village remake from its layout (the village-remake skill, step 4):
## res://proto/villages/<remake>/layout.json -> the place's scenes, its
## background and overhead pieces, the views of it (another place that shows
## part of it, as Alares - Celis does Alares at night), and the cutscene
## copies. VillageRemake loads them with --village=<remake>.
##
## godot --headless --path . --script res://tools/village_remake/remake_build.gd -- <remake>
## godot --headless --path . --import      (then: the new PNGs get .import files)
##
## Every scene is the default scene's text with:
## * the background, the overhead pieces and the obstacles replaced (the base
##   scene of the place and of each view; variants lose theirs);
## * each door, sign, loot, spawn, actor and particle system moved to its
##   layout "features" entry, keyed "<parent>/<node name without its number>"
##   ("Doors/Inn", "Actors/Uri"): [x, y] moves it, null drops it, a villager's
##   {"pos": [x, y], "walk": [...]} also gives its walk (left out: its .char
##   walk). A feature without an entry stops the build: nothing is left at
##   its old place by accident;
## * a night layer (a view's or the place's "night": {"windows": [[x1, y1,
##   x2, y2], ...], "glows": [...]}) in place of the default one: light
##   around each window and glow; a view's windows also get lit glass in its
##   background and its overhead pieces (a night view, like the default
##   Alares - Celis at Night.png). A window's rect is its panes (inside the
##   frame, x2 and y2 excluded).
## Writes under ROOT/<remake>/ only, and lists what it wrote.
##
## A launcher: the code is remake_build_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/village_remake/remake_build_job.gd").new()
	_job.run(self)
