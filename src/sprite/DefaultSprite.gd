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

## Java: draw(Graphics g, int x, int y). draw(g) is inherited from Sprite.
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
		return
	super.drawAtPosition(g, int(pos[Values.X]) + x, int(pos[Values.Y]) + y)

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
