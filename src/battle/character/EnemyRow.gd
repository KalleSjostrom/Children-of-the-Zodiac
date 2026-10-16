class_name EnemyRow
extends CreatureRow
## Port of battle.character.EnemyRow: the enemies in a row.
## Port note: Java's getPos() (float[]) is getRowPos() (see CreatureRow).

var enemies = null


func _init(enemies = null) -> void:
	super(1)
	self.enemies = enemies
	setLimit(true)
	setMovementSpeed(true)
	instantHide()


func getCreatureList():
	return enemies


func getSide():
	return BattleProgressBar.RIGHT


func getPos(p_axis: int):
	return super(p_axis)


func getRowPos():
	return BattleValues.ENEMY_ROW_POSITION


func translateCreature(g):
	g.translate(0, BattleValues.DISTANCE_BETWEEN_ENEMIES, 0)


## Removes the dead enemies from this row.
func check():
	var i: int = 0
	while i < enemies.size():
		if not enemies[i].isAlive():
			J.removeAt(enemies, i)
			i -= 1
		i += 1
	check3DCreatures()


func checkDead():
	for i in enemies.size():
		if not enemies[i].isAlive():
			var sound: String = enemies[i].getDieSound()
			SoundPlayer.playSound(Values.BattleSoundEffects + "Monster/" + sound + ".wav")


func drawBack(g):
	var yBottom: float = -0.89
	var yTop: float = 0.16
	var xRight: float = 0.18
	var xLeft: float = -0.22
	var dist: float = absf(yTop - yBottom) / 4.0
	var d: float = creatures3D.size() * dist
	yBottom = yTop - d

	g.drawGradient(
			Vector3f.ZERO, BACK_ALPHA_TOP, BACK_ALPHA_BOTTOM, xRight,
			xLeft, yBottom, yTop, false, true)

	g.setColor(1)
