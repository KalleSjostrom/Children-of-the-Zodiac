class_name Loot
extends RefCounted
## Port of villages.utils.Loot: something (gold, an item, a card, an
## equipment or life) that the player can find in a village (or get as a
## gift from a villager).

const GOLD = 0
const ITEM = 1
const CARD = 2
const EQUIPMENT = 3
const LIFE = 4
const TAKEN = 1
const AVAILABLE = 0
var position = null
var content = null
var name = null
var contentName = null
var text = [null, null]
var type: int = 0
var playerDir = null
var triggers = null


## Java overloads:
##   Loot(String name, int type, Object content)
##   Loot(String name, int[] dir, int[] position, int type, Object content,
##        HashMap<String, Integer> triggers)
func _init(p_name = null, dir = null, p_position = null, p_type = null, p_content = null,
		p_triggers = null) -> void:
	if dir is int:
		# Loot(name, type, content)
		name = p_name
		type = dir
		content = p_position
		return
	name = p_name
	playerDir = dir
	position = p_position
	type = 0 if p_type == null else int(p_type)
	content = p_content
	triggers = p_triggers


## Adds a string to this loot's message (shown when the loot is found).
func addString(s):
	if text[0] == null:
		text[0] = s
	else:
		text[1] = s


## Checks if the given position is less than 35 pixels away from the loot.
func isInRange(pos):
	var dist := J.round(Vector2(position[Values.X], position[Values.Y]).distance_to(
			Vector2(pos[Values.X], pos[Values.Y])))
	return dist < 35


func getContent():
	return content


func getType():
	return type


func checkPlayerDir(dir):
	var found := false
	var i := 0
	while i < playerDir.size() and not found:
		found = playerDir[i] == dir
		i += 1
	return found


## Removes the loot from the database (it can not be found twice).
func takeLoot():
	Database.addStatus(name, TAKEN)
	Database.addStatus(triggers)


func decrementStatus():
	var status: int = Database.getStatusFor(name)
	if status <= AVAILABLE:
		return true
	elif status != TAKEN:
		status -= 1
		if status == 1:
			status = AVAILABLE
		Database.addStatus(name, status)
	return false


## Gets the line (0 or 1) of the loot's message.
func getLine(i):
	return text[i]


## Creates a loot from the information in the given tokenizer.
static func getLoot(tok, villageName):
	var l = null
	var lootName: String = str(villageName) + tok.nextToken()
	var status: int = Database.getStatusFor(lootName)
	if status != TAKEN:
		var x := J.parseInt(tok.nextToken())
		var y := J.parseInt(tok.nextToken())
		var pos := Values.createNormalPoint(x, y)
		var pDir = Loot.convert(tok.nextToken())
		var cName: String = tok.nextToken()
		var trigs := {}
		if cName.begins_with("trigger="):
			cName = cName.replace("trigger=", "")
			var triggerStrings := J.split(cName, "--")
			for s in triggerStrings:
				var temp := J.split(s, ":")
				trigs[temp[0]] = J.parseInt(temp[1])
			cName = tok.nextToken()

		var t := J.parseInt(tok.nextToken())
		var c = Loot.createContent(cName, t, tok)
		l = Loot.new(lootName, pDir, pos, t, c, trigs)
		l.contentName = cName
	return l


static func convert(dir):
	var dirs := J.split(dir, ";")
	var pDirs := J.array(dirs.size(), 0)
	for i in pDirs.size():
		pDirs[i] = J.parseInt(dirs[i])
	return pDirs


## Creates the content (the actual object) of a loot.
static func createContent(p_contentName, p_type, tok):
	var c = null
	var cName: String = String(p_contentName).replace("_", " ")
	match int(p_type):
		GOLD:
			c = J.parseInt(cName)
		ITEM:
			var amount := 1
			if tok.hasMoreTokens():
				amount = J.parseInt(tok.nextToken())
			c = Items.Item.new(cName, amount)
		CARD:
			var level := J.parseInt(tok.nextToken())
			var all := false
			if tok.hasMoreTokens():
				all = J.parseBoolean(tok.nextToken())
			c = Card.createCard(cName, level, all)
		EQUIPMENT:
			c = EquipmentFactory.getEquipment(cName)
		LIFE:
			c = J.parseFloat(cName)
	return c


func getContentName():
	return contentName


func setContentName(p_name):
	contentName = p_name
