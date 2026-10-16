class_name BossesDialog
extends RefCounted
## Port of battle.bosses.Dialog: a list of dialog sequences shown one at a time.

var counter: int = 0
var dialog = null


func _init() -> void:
	dialog = []


func getNext():
	if counter < dialog.size():
		var seq = dialog[counter]
		counter += 1
		return seq
	return null


func add(seq):
	dialog.append(seq)
