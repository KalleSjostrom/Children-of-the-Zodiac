class_name WeaponStoreFactory
extends AbstractFactory
## Port of factories.WeaponStoreFactory: all the equipment stores in the game
## (singleton, created lazily on first use).

static var storeFactory = null
var bank = {}
var current = ""


func _init() -> void:
	parseFile("stores.bank")


## Gets the only StoreFactory object.
static func getStoreFactory():
	if storeFactory == null:
		storeFactory = WeaponStoreFactory.new()
	return storeFactory


## Gets the first equipment with the given name from the given list, or null.
func getEquipmentByName(list, name):
	for i in range(list.size()):
		if list[i].getName() == name:
			return list[i]
	return null


func getRightHandFor(storeName):
	return bank.get(storeName).rightHand


func getArmorsFor(storeName):
	return bank.get(storeName).armors


func getLeftHandFor(storeName):
	return bank.get(storeName).leftHand


func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "store":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		bank[name] = Store.new()
		current = name
	elif command == "rightHand":
		bank.get(current).rightHand.append(get_(tokenizer))
	elif command == "leftHand":
		bank.get(current).leftHand.append(get_(tokenizer))
	elif command == "body":
		bank.get(current).armors.append(get_(tokenizer))


func get_(tokenizer):
	var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
	var ae = EquipmentFactory.getEquipment(name)
	return ae


## A store with three lists: right hand, left hand and armors.
class Store extends RefCounted:
	var rightHand = []
	var leftHand = []
	var armors = []
