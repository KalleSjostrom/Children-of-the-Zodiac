class_name EquipmentFactory
extends AbstractFactory
## Port of factories.EquipmentFactory: a bank with all the equipment in the
## game (singleton, created lazily on first use).

var bank = {}
static var factory = null


func _init() -> void:
	parseFile("equipment.bank")


static func _getFactory():
	if factory == null:
		factory = EquipmentFactory.new()
	return factory


## Gets the equipment with the specified name.
static func getEquipment(name):
	var ae = _getFactory().bank.get(name)
	if ae == null:
		push_error("There are no equipment with the name " + str(name) + " in the equipment factory")
		GameCore.exitGame()
	return ae


func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "w" or command == "s" or command == "a":
		var stat: Array = J.array(11, 0.0)
		var name = null
		var slots = null
		while tokenizer.hasMoreElements():
			var s: Array = Parser.getArgument(tokenizer.nextToken())
			var o = parse(s[0], s[1], stat)
			if o is String:
				name = o
			elif o is Array:
				slots = o
		var ae = null
		if command == "w":
			ae = Weapon.new(stat, name, slots)
		elif command == "s":
			ae = Shield.new(stat, name, slots)
		elif command == "a":
			ae = Armor.new(stat, name, slots)
		bank[name] = ae


func parse(command, value, stat):
	var o = null
	if command == "for":
		stat[AbstractEquipment.FOR_WHOM] = float(J.parseInt(value))
	elif command == "defense":
		stat[AbstractEquipment.DEFENSE] = J.parseInt(value) / 100.0
	elif command == "magicDefense":
		stat[AbstractEquipment.MAGIC_DEFENSE] = J.parseInt(value) / 100.0
	elif command == "agility":
		stat[AbstractEquipment.AGILITY] = J.parseInt(value) / 100.0
	elif command == "evade":
		stat[AbstractEquipment.EVADE] = J.parseInt(value) / 100.0
	elif command == "hit":
		stat[AbstractEquipment.HIT] = J.parseInt(value) / 100.0
	elif command == "attack":
		stat[AbstractEquipment.ATTACK] = J.parseInt(value) / 100.0
	elif command == "magicAttack":
		stat[AbstractEquipment.MAGIC_ATTACK] = J.parseInt(value) / 100.0
	elif command == "supportAttack":
		stat[AbstractEquipment.SUPPORT_ATTACK] = J.parseInt(value) / 100.0
	elif command == "price":
		stat[AbstractEquipment.PRICE] = float(J.parseInt(value))
	elif command == "name":
		o = Organizer.convertKeepCase(value)
	elif command == "slots":
		var v: Array = J.split(value, ":")
		if not (v.size() == 1 and v[0] == "_"):
			var slots: Array = J.array(v.size(), 0)
			for i in range(v.size()):
				slots[i] = J.parseInt(v[i])
			o = slots
		else:
			o = []
	return o
