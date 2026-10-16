class_name Memorytaur
extends BattleBoss
## Port of battle.bosses.Memorytaur: a boss that keeps the battle music playing.


func _init(enemy = null) -> void:
	super(enemy)


func continueBattleMusic():
	return true
