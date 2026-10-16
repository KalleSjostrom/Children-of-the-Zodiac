class_name LevelUpBar
extends RefCounted
## Port of battle.bars.LevelUpBar: the bar displaying the current experience
## relative to the limit to the next level (used after battle).

static var bar = null
var percent: float = 0.0


## Lazily creates the image name list (Java: static final initializer).
static func _getBar() -> Array:
	if bar == null:
		bar = [
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "emptyBar.png"),
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "blueBar.png"),
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "overlay.png")
		]
	return bar


## Initiates the drawings of the level up bar.
func draw(g, x, y, canLevelUp):
	var b: Array = _getBar()
	var p: float = percent
	if not canLevelUp:
		g.setImageColor(1, 0, 0, 1)
		p = 1
	g.drawImage(b[0], x, y, 200, 20, 1.0, 1.0)
	g.drawImage(b[1], x, y, 200, 20, 1.0, p)
	g.drawImage(b[2], x, y, 200, 20, 1.0, p)
	g.setColor(1)


## Java: static draw(Graphics g, int x, int y, float p1, float p2, float scale).
static func drawStatic(g, x, y, p1, p2, scale):
	var b: Array = _getBar()
	g.drawImage(b[0], x, y, 200, 20, float(scale), 1.0)
	g.setColor(1)
	g.drawImage(b[1], x, y, 200, 20, float(scale), 0.0, float(p1))
	g.setColor(0, 1, 0, 1)
	g.drawImage(b[1], x, y, 200, 20, float(scale), float(p1), float(p2))
	g.setColor(1)
	g.drawImage(b[2], x, y, 200, 20, float(scale), 0.0, float(p2))
	g.setColor(1)


## Updates the level up bar with the given progress (0 to 1).
func update(progress):
	percent = progress
