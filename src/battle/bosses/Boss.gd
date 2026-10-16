class_name BattleBoss
extends BattleEnemy
## Port of battle.bosses.Boss: a special kind of battle enemy used when
## battling a boss.

var dialogs = null
var battleDialog = null
var script_ = null
var triggers = null
var items = null


## Creates a new boss from the given enemy (character.Enemy).
func _init(enemy = null) -> void:
	super(enemy)
	dialogs = enemy.getDialog()
	script_ = enemy.getScript()
	battleDialog = script_.getDialog()
	triggers = enemy.getTriggers()
	items = enemy.getItems()


## Triggers the consequences of defeating a boss.
func trigger():
	Database.addStatus(triggers)
	Load.getPartyItems().addItems(items)


func makeMove(lifePercent):
	return EnemyLogic.makeMove(script_.getMove(lifePercent))


func setDialog(i, d = null):
	dialogs.set_(i, d)


func wantsToTalk(i):
	if battleDialog != null:
		dialogs.set_(i, battleDialog)
	return dialogs.wantsToTalk(i) if dialogs != null else false


## Java overloads: next(int i) and next() (uses the current round).
func next(i = null):
	if i == null:
		return dialogs.get_(rounds)
	return dialogs.get_(i)


func continueBattleMusic():
	return false
