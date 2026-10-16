class_name LandPlayer
extends Sprite
## Port of landscape.LandPlayer: the player walking around the landscape.


func init(g = null):
	loadImages(Values.VillageImages + "Characters/", "Kin")


## Java overloads: draw(Graphics g) and draw(Graphics g, int x, int y).
func draw(g, x = null, y = null):
	if x == null:
		draw(g, J.round(pos[Values.X] - getWidth() / 2),
				J.round(pos[Values.Y] - 9 * getHeight() / 10))
	else:
		super.drawAtPosition(g, x, y)


## Sets this players x and y position.
func setXandY(x, y):
	pos = Values.createNormalFloatPoint(x, y)
