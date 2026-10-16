class_name BossDialog
extends RefCounted
## Port of battle.bosses.BossDialog: the dialogs (BossesDialog) of a boss,
## keyed by round (or BEGINNING / ENEMY_DEAD / PARTY_DEAD).

const BEGINNING = 0
const ENEMY_DEAD = -1
const PARTY_DEAD = -2
var dialogs = {}
var nextPlace = null


func wantsToTalk(i):
	return dialogs.get(i) != null


## Java: get(int i). Returns the next DialogSequence of the dialog for i.
func get_(i):
	var dialog = dialogs.get(i)
	if dialog != null:
		return dialog.getNext()
	return null


## Java: set(int i, Dialog d).
func set_(i, d):
	dialogs[i] = d


func getNextPlace():
	return nextPlace


func setNesxtPlace(n):
	nextPlace = n
