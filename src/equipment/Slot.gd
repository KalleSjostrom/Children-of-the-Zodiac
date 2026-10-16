class_name Slot
extends RefCounted
## Port of equipment.Slot: a slot in an equipment.

const DISTANCE = 50
const ATTACK = 0
const MAGIC = 1
const SUPPORT = 2
const NO_TYPE = -1

var image: String = ""
var smallImage: String = ""
var card = null
var type: int = 0


## Constructs a slot with the given image name, image and type.
func _init(name = null, im = null, type = null) -> void:
	image = "" if name == null else name
	var smallerImage: Image = GraphicHelp.scaleImage(im, 0.6)
	smallImage = "small" + image
	ImageHandler.addPermanentlyConvertNow(smallImage, smallerImage)
	if type != null:
		self.type = type


## Checks if this slot does not contain a card.
func hasNoCard():
	return card == null


func getCard():
	return card


## Gets the name of this slot's small image (used in the menu).
func getSmallImage():
	return smallImage


## Gets the name of this slot's image (used in battle).
func getImage():
	return image


## Gets the type of this slot (Slot.ATTACK, MAGIC or SUPPORT).
func getType():
	return type


## Creates an int array (the numeric representation of the slots) from the
## given tokenizer: the size followed by the slot types.
static func getSlots(tokenizer):
	var size: int = J.parseInt(tokenizer.nextToken())
	var slots: Array = J.array(size, 0)
	for i in size:
		slots[i] = J.parseInt(tokenizer.nextToken())
	return slots


## Java overloads: merge(AbstractEquipment first, AbstractEquipment second)
## and merge(ArrayList<Slot> s1, ArrayList<Slot> s2).
static func merge(first, second):
	var slots: Array = []
	if first is Array or second is Array:
		slots.append_array(first)
		slots.append_array(second)
		return slots
	if first != null:
		slots.append_array(first.getSlots())
	if second != null:
		slots.append_array(second.getSlots())
	return slots
