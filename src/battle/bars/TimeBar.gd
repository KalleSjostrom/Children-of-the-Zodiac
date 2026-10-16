class_name TimeBar
extends BattleProgressBar
## Port of battle.bars.TimeBar: the bar displaying the time the player has
## to make a move in battle.

var side_: float = 0.0


## side: BattleProgressBar.RIGHT or BattleProgressBar.LEFT.
func _init(side = null) -> void:
	super(float(side) if side != null else 0.0)
	self.side_ = float(side) if side != null else 0.0
	size_ = 1 / 400.0


## Creates the coordinates for the time bar.
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	if saveW != null:
		super.createCoords(saveW)
		return
	createCoordList(1)
	var x: float = side_ + 0.2001
	var y: float = 0.0
	var z: float = 0.0
	createCoordFor(x, x + width, 0, X)
	createCoordFor(y, y + height - height / 4, 0, Y)
	createCoordFor(z, z, 0, Z)


## Updates the life meter (the Java body is commented out).
func update(progress = null):
	pass


## Java: draw(Graphics g) rotates and draws as a progress bar; the inherited
## draw(g, alpha, mode) is kept.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if alpha == null:
		g.rotate(90, 0, 0, 1)
		super.draw(g, 1.0, -1)
		return
	super.draw(g, alpha, angle)
