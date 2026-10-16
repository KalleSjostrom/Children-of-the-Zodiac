class_name GameEventListener
extends RefCounted
## Port of organizer.GameEventListener (the JOGL GLEventListener).
## Keeps the projection mode of the frame (2D or 3D) and gives access to the
## Graphics object. The frame loop itself lives in Main.gd.

enum renderMode { RENDER_2D, RENDER_3D }

static var g: Graphics
static var mode := renderMode.RENDER_2D


## Switches to the 3D projection immediately (and loads identity).
static func set3DNow(p_g: Graphics) -> void:
	p_g.setRenderModeNow(false)


## Switches to the 2D projection immediately (and loads identity).
static func set2DNow(p_g: Graphics) -> void:
	p_g.setRenderModeNow(true)


## Sets the projection used at the start of each frame to 3D.
static func set3D() -> void:
	mode = renderMode.RENDER_3D


## Sets the projection used at the start of each frame to 2D.
static func set2D() -> void:
	mode = renderMode.RENDER_2D


static func is3D() -> bool:
	return mode == renderMode.RENDER_3D


static func getG() -> Graphics:
	return g
