class_name AbstractEquipment
extends RefCounted
## Port of equipment.AbstractEquipment: the superclass of the equipments in
## the game (armors, shields and weapons).

const FOR_WHOM = 0
const DEFENSE = 1
const MAGIC_DEFENSE = 2
const AGILITY = 3
const EVADE = 4
const HIT = 5
const ATTACK = 6
const MAGIC_ATTACK = 7
const SUPPORT_ATTACK = 8
const PRICE = 9

var image: String = ""
var name = ""
var info: Array = J.array(3, null)
var slots: Array = []
var attribute = null # float[]
var number: int = 1
var equip: bool = false


## Sets the attribute array and name.
func _init(attribute = null, name = null) -> void:
	self.attribute = attribute
	self.name = name


## Loads the image with the given path and name.
func loadImage(path, p_name):
	image = path + p_name
	ImageHandler.addToCurrentLoadOnUse(image)


## Copies this equipment and returns the copy.
func copy():
	# Java created a float[8] here (it would throw for longer attribute
	# arrays); the size is extended to the attribute length to avoid that.
	var att: Array = J.array(maxi(8, attribute.size()), 0.0)
	for i in attribute.size():
		att[i] = attribute[i]
	var inf: Array = J.array(info.size(), null)
	for i in info.size():
		inf[i] = info[i]
	var ae = AbstractEquipment.new(att, name)
	ae.info = inf
	ae.image = image
	return ae


## Adds the given string to the info array at the given row.
func addInfo(s, row):
	info[row] = s


## Increases the number (amount owned) of this equipment.
func addNumber():
	number += 1


## Decreases the number (amount owned) of this equipment.
func subtractNumber():
	number -= 1


func setNumber(nr):
	number = nr


func getName():
	return name


## Gets the index of the character this equipment is for.
func getForWhom():
	return int(attribute[FOR_WHOM])


func getImage():
	return image


func getAttack():
	return attribute[ATTACK]


func getMagic():
	return attribute[MAGIC_ATTACK]


func getSupport():
	return attribute[SUPPORT_ATTACK]


func getPrice():
	return int(attribute[PRICE])


func getHit():
	return attribute[HIT]


func getDefense():
	return attribute[DEFENSE]


func getAgility():
	return attribute[AGILITY]


func getEvade():
	return attribute[EVADE]


func getMagicDefense():
	return attribute[MAGIC_DEFENSE]


func isEquiped():
	return equip


func setEquiped(p_equip):
	equip = p_equip


func getNumber():
	return number


## Gets the attribute with the given index (one of the constants above).
func getAttribute(att):
	return attribute[att] if att < attribute.size() else 0.0


## Gets the info row i (there are three rows).
func getInfo(i):
	if i < info.size():
		return info[i]
	return ""


func getSlots():
	return slots


## Creates slots from the given int array and stores them in the given list.
## 0 for attack slots, 1 for magic slots and 2 for support slots.
func createWeaponArray(list, slot):
	if slot == null:
		return
	for i in slot.size():
		var inf: int = slot[i]
		var n: String = ImageHandler.addToCurrentLoadOnUse(
				Values.MenuImages + str(inf) + "slot.png")
		var im: Image = ImageHandler.getImage(n)
		list.append(Slot.new(n, im, inf))


## Gets an array containing the difference of the attributes of the given
## equipments (equipment.attributes[i] - equipped.attributes[i]) scaled with
## the attributes of the given character.
static func getChange(c, equipment, equipped):
	var change: Array = J.array(9, 0)
	for i in range(1, change.size()):
		var base: int = c.getAttribute(i)
		change[i] = J.round(
			(0.0 if equipment == null else (equipment.attribute[i] * base)) -
			(0.0 if equipped == null else (equipped.attribute[i] * base)))
	return change


func isFor(character):
	return attribute[FOR_WHOM] == character.getIndex()
