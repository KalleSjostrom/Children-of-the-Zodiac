class_name Memorysalmonman
extends BattleBoss
## Port of battle.bosses.Memorysalmonman: a boss that keeps the battle music playing.


func _init(enemy = null) -> void:
	super(enemy)


func continueBattleMusic():
	return true
