class_name EnemyAttackEffect
extends RefCounted
## Port of battle.enemy.EnemyAttackEffect: an extra effect of an enemy attack
## (element change, drain, heal, boosts, dialog ...).

var name = null
var valuei: int = 0
var valuef: float = 0.0
var values = null
var dialog = null


static func createEffects(instructions):
	var effectList: Array = []
	var effects: Array = J.split(instructions, "--")
	for s0 in effects:
		var s: String = s0
		s = s.replace("(", "")
		s = s.replace(")", "")
		var args: Array = Parser.getArgument(s)
		var command: String = args[0]
		var val: String = args[1]
		var eae := EnemyAttackEffect.new()
		if command == "ChangeElement":
			eae.name = "Element Change"
			eae.valuei = J.parseInt(val)
		elif command == "Drain":
			eae.name = "Drain"
			eae.valuef = J.parseFloat(val)
		elif command == "Heal":
			eae.name = "Heal"
			eae.valuef = J.parseFloat(val)
		elif command == "Renew":
			eae.name = "Renew"
			eae.valuef = J.parseFloat(val)
		elif command == "Death":
			eae.name = "Death"
			eae.valuef = J.parseFloat(val)
		elif command == "Dispel":
			eae.name = "Dispel"
			eae.valuef = J.parseFloat(val)
		elif command == "DownTo":
			eae.name = "DownTo"
			eae.valuei = J.parseInt(val)
		elif command == "cardPref":
			eae.name = "cardPref"
			var temp: Array = J.split(val, ";")
			eae.values = temp[0]
			eae.valuei = J.parseInt(temp[1])
		elif command == "showDialog":
			eae.name = "dialog"
			eae.dialog = J.split(val, ";")
		elif command == "changeMusic":
			eae.name = "music"
			eae.values = val
		elif command.begins_with("Boost"):
			command = command.replace("Boost", "")
			var temp: Array = J.split(val, ";")
			eae.name = "Boost "
			eae.valuei = J.parseInt(temp[0])
			eae.valuef = J.parseFloat(temp[1])
			if command == "Mag":
				eae.name += "Magic Attack "
			elif command == "Off":
				eae.name += "Attack "
			elif command == "Sup":
				eae.name += "Support "
			elif command == "MagDef":
				eae.name += "Magic Defense "
			elif command == "Def":
				eae.name += "Defense "
			elif command == "Speed" or command == "Agility":
				eae.name += "Agility "
			elif command == "Hp":
				eae.name += "Hp "
			elif command == "All":
				eae.name += "All Status "
			eae.name += ("Up!" if eae.valuef > 0 else "Down!")
		effectList.append(eae)
	return effectList


func getName():
	return name


func getValuei():
	return valuei


func getValuef():
	return valuef


func getValues():
	return values


func _to_string():
	return str(name)


func getDialog():
	return dialog
