class_name DefaultSprite
extends Sprite
## Port of sprite.DefaultSprite. The static Java reset() is resetStatic().

const BOTTOM_LAYER = 0
const VILLAGER_LAYER = -1
const TOP_LAYER = 1
var layer: int = VILLAGER_LAYER
var offset: int = 0
static var OFFSET_COUNTER: int = 0

func _init(path = null) -> void:
	name = path

## Bridge (phase 1 step B): Java's draw(g, x, y) without drawing (see Sprite.place_view).
func place_view(x, y):
	var sx: int = int(pos[Values.X]) + x
	var sy: int = int(pos[Values.Y]) + y
	return [place_sprite(sx, sy), sx, sy]

func placeOnTopLevel():
	layer = TOP_LAYER

func placeOnBottomLevel():
	layer = BOTTOM_LAYER
	offset = OFFSET_COUNTER
	OFFSET_COUNTER += 1

func getY():
	var y: float = 0.0
	match layer:
		BOTTOM_LAYER:
			y = -10000 + offset
		VILLAGER_LAYER:
			y = super.getY()
		TOP_LAYER:
			y = 10000 - offset
	return y

static func resetStatic():
	OFFSET_COUNTER = 0
