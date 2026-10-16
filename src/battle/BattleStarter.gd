class_name BattleStarter
extends RefCounted
## Port of battle.BattleStarter (Java interface). Implementing classes
## (BossBattleArea, Labyrinth, ...) do not extend this; callers use duck typing
## (has_method("leaveBattle")).


func exitDialog():
	pass

func drawDialog(dialog):
	pass

func leaveBattle():
	pass

func gameOver():
	pass

func exit(next, fadeBattleMusic):
	pass

func notifySwitchMusic(music, fadeSpeed):
	pass

func overwriteStarterMusic(music, oggPlayer):
	pass
