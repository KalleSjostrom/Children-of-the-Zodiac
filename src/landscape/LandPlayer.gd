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


## Bridge (phase 4.1 step B, docs/ARCHITECTURE.md section 13): draw(g, x, y)
## without the drawing, for the player view of a world map or airship scene
## (WorldMapScene.show_player): [image path, x, y] where drawSprite would
## draw the image (without x and y: the same rounding as draw(g)), keeping
## what drawSprite sets (place_sprite).
func place_view(x = null, y = null):
	if x == null:
		return place_view(J.round(pos[Values.X] - getWidth() / 2),
				J.round(pos[Values.Y] - 9 * getHeight() / 10))
	return [place_sprite(x, y), x, y]


## Sets this players x and y position.
func setXandY(x, y):
	pos = Values.createNormalFloatPoint(x, y)
