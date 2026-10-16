class_name Menthu1
extends BattleBoss
## Port of battle.bosses.Menthu1.


func _init(enemy = null) -> void:
	super(enemy)


func kill():
	Graphics.setFadeImage(Values.res + "test.png")
	currentList = 5


func continueBattleMusic():
	return true
