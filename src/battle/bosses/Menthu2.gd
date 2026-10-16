class_name Menthu2
extends BattleBoss
## Port of battle.bosses.Menthu2.


func _init(enemy = null) -> void:
	super(enemy)


func kill():
	Graphics.setFadeImage(Values.res + "test.png")
	currentList = 5


func continueBattleMusic():
	return true
