class_name PartyMember
extends Sprite
## Port of villages.utils.PartyMember: the party members walking in a
## straight line behind the player in the village.

var currentPos = Position.new(0, 0, 0)

func _init(name = null) -> void:
	self.name = name
	loadPermImages(Values.VillageImages + "Characters/", name)


## Updates the current position to the given one. If the direction has
## changed since the last update, the animation images are changed.
func updatePos(p):
	if p.getDirection() != currentPos.getDirection():
		setImages(p.getDirection())
	currentPos = p


## Java: standStill() is overridden; the other overloads are inherited.
func standStill(dir = null, anim = null, ia = null):
	if dir == null:
		super.standStill(currentPos.getDirection())
	else:
		super.standStill(dir, anim, ia)


## Java: move() is overridden; the other overloads are inherited.
func move(dir = null, anim = null, ia = null):
	if dir == null:
		super.move(currentPos.getDirection())
	else:
		super.move(dir, anim, ia)


func getPosition():
	return currentPos


func setCurrentPos(position):
	currentPos = position


func getY():
	return currentPos.getY()


func getX():
	return currentPos.getX()


## Java overloads: draw(Graphics) (inherited) and draw(Graphics, int, int).
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
		return
	super.drawAtPosition(g, x, y)


func getPosAsFloatArray():
	return currentPos.getPosAsFloatArray()


func getMemberPos():
	pos[Values.X] = currentPos.getX()
	pos[Values.Y] = currentPos.getY()
	return pos
