class_name Chest
extends Inventory
## Port of labyrinth.inventory.Chest.
##
## This class is the inventory chest. An inventory is a thing in the
## labyrinth, that the player can find. If the player finds the node where
## this inventory resides, the Database class is called to find out whether
## the chest has been opened or not.

const GOLD = 0
const EQUIPMENT = 1
const CARD = 2
const ITEM = 3
var name = ""
var itemInfo = null
var type: int = 0


## Creates a new chest from the given information.
## contentType: one of Chest.GOLD, .EQUIPMENT, .CARD, .ITEM. contentName: the
## name of the content (amount of gold if contentType is GOLD). info: a string
## array containing the information about the content.
func _init(node = null, dir = null, nrOfTexs = null, image = null, contentType = null, contentName = null, info = null, status = null) -> void:
	super(node, dir, nrOfTexs, image, status)
	var st: int = 0 if status == null else status
	type = 0 if contentType == null else contentType
	name = contentName
	itemInfo = info
	if images.size() > 1:
		currentTex = st
		if st == -1:
			currentTex = 0
	else:
		currentTex = 0


func setSettings():
	scale = BattleValues.CARD_SCALE
	info = getSettings()
	heightOffset = info.getHeightOffset()
	zOff = info.getZOffset()
	scale2 = info.getScale()


## Opens the chest. This method starts the animation for this chest and
## updates the database, if the chest has not already been opened.
func activate(labyrinth):
	var st: int = Database.getStatusFor(dataBaseName)
	if st == 0:
		if images.size() > 1:
			currentTex = 1
		execute(labyrinth)
		Database.addStatus(dataBaseName, 1)


func getMapImage():
	var st: int = Database.getStatusFor(dataBaseName)
	if st == -1:
		st = 0
		Database.addStatus(dataBaseName, 0)
	return LabyrinthMap.chest[st]


## Gives the player the content of the chest and calls the labyrinth's
## drawDialog() to explain to the player what has been received.
func execute(labyrinth):
	var one: String
	var two: String
	SoundPlayer.playSound(info.getSoundEffect())
	match type:
		GOLD:
			var amount: int = J.parseInt(name)
			Load.getPartyItems().addGold(amount)
			one = "You found " + str(amount) + " gold coins!"
			two = ""
			labyrinth.drawDialog(one, two)
		EQUIPMENT:
			name = name.replace("_", " ")
			var ae = EquipmentFactory.getEquipment(name)
			Load.addEquipment(ae)
			one = "You found " + name + "!"
			two = ""
			labyrinth.drawDialog(one, two)
		CARD:
			var level: int = J.parseInt(itemInfo[0])
			var all := false
			if itemInfo.size() > 1:
				all = J.parseBoolean(itemInfo[1])
			var c = Card.createCard(name, level, all)
			Load.getPartyItems().addCard(c)
			one = "You received the card " + c.getName() + "!"
			var ds := DialogSequence.new(one, "")
			var l := Loot.new("", null, null, Loot.CARD, c, null)
			ds.setGift(l)
			labyrinth.drawDialog(ds)
		ITEM:
			name = name.replace("_", " ")
			Load.getPartyItems().addItem(name, 1)
			one = "You received the item " + name + "!"
			two = ""
			labyrinth.drawDialog(one, two)


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true


func useMaterial():
	return true
