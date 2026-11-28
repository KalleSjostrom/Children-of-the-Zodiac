extends SceneTree
## Pictures for writing a remake's layout (the village-remake skill, steps 2
## and 3): a part of the village image, zoomed, with a coordinate grid
## (village pixels) and optionally the layout drawn over it, so that outlines
## and positions can be read off and checked.
##
## godot --headless --path . --script res://tools/village_remake/remake_view.gd -- <remake> <out.png> [options]
##   --rect=x,y,w,h   the part to show (village pixels; default: everything)
##   --zoom=n         nearest-neighbour zoom (default 1)
##   --grid=n         a line every n village pixels, every fifth one magenta and
##                    numbered with its coordinate (default 0: none)
##   --layout         draw the layout: object outlines (white), their overhead
##                    part (blue) and footprint (red), blocked regions (red
##                    outline), walkable regions (green outline), features
##                    (orange crosses at the feet, numbered in layout order:
##                    the numbers are printed), views (cyan rectangles)
##   --image=<path>   draw on this picture instead of the village image
##   --pieces         the overhead pieces as the build cuts them (trimmed) in
##                    full colour over the rest darkened: ground left in a
##                    piece shows bright
##   --players=x,y[,f];...  Kin with his feet at each x, y (frame f of his
##                    sheet: 1 facing up, the default, 9 facing down) under
##                    the overhead, as the game draws them: a player behind a
##                    tree, sign or roof is covered to the feet
##
## A launcher: the code is remake_view_job.gd, loaded in _initialize, after the
## autoloads are registered. A script that --script runs is compiled before
## them, and the game's classes name the Game autoload (docs/ARCHITECTURE.md
## section 17, "Tools").

var _job: RefCounted


func _initialize() -> void:
	_job = load("res://tools/village_remake/remake_view_job.gd").new()
	_job.run(self)
