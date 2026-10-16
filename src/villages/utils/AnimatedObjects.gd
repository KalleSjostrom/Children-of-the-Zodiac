class_name AnimatedObjects
extends Sprite
## Port of villages.utils.AnimatedObjects: animates objects in the village,
## for example the fountain in the grass village.


## Creates an animated object with the given name and position. The name of
## the object is the prefix name of the image series that should be animated.
func _init(path = null, name = null, pos = null, size = null) -> void:
	self.pos = Values.convertToFloatArray(pos)
	loadImages(Values.VillageImages + path + "/animobj/", name, size)
	move()


## Java overloads: draw(Graphics) (inherited) and draw(Graphics, int x, int y).
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
		return
	super.drawAtPosition(g, int(pos[Values.X]) + x, int(pos[Values.Y]) + y)
