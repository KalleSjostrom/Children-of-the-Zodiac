class_name BodySystem
extends Sprite
## Port of bodies.system.BodySystem: a sprite holding a set of bodies.

var bodies = Bodies.new()


func _init() -> void:
	animImages = []


func getBodies():
	return bodies


func addBody(b):
	return bodies.add(b)


## Java: the empty draw(Graphics g, int x, int y) override; draw(Graphics g)
## (x == null) is inherited from Sprite.
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
