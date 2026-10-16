class_name Save
extends RefCounted
## Port of factories.Save: saves the game by writing a text file which Load
## can read. Files are written to SAVE_DIR (user://saves/<slot>.sav) instead
## of Values.lib; the format is the same as the original (LF line endings).

## Directory the save games are written to (and first read from by Load).
const SAVE_DIR = "user://saves/"
## Deterministic runs (J.deterministic) use their own directory, emptied by
## Main at start, so they neither read nor overwrite the player's saves.
const DETERMINISTIC_SAVE_DIR = "user://saves_deterministic/"


## The directory saves are written to and read from (see above).
static func saveDir() -> String:
	return DETERMINISTIC_SAVE_DIR if J.deterministic else SAVE_DIR

static var save = null
var place = ""
var visited = null


func _init() -> void:
	pass # Empty constructor.


## Gets the only save object available.
static func getSave():
	if save == null:
		save = Save.new()
	return save


## Java overloads: public saveGame(String saveSlot, String place) and the
## private saveGame(String filename) that writes the file.
func saveGame(saveSlot, place = null):
	if place != null:
		self.place = place
		visited = Visited.getVisited()
		saveGame(saveSlot)
		return
	var filename: String = saveSlot
	DirAccess.make_dir_recursive_absolute(saveDir())
	var writer := SaveWriter.new()
	writeHeader(writer)
	writeCharacters(writer, Load.getCharacters(), "character")
	writeCharacters(writer, Load.getExCharacters(), "exCharacter")
	writeBackPack(writer)
	writeMainDeck(writer)
	writeStatus(writer)
	writeVisited(writer)
	writeLabyrinthMap(writer)
	writeBestiary(writer)
	writer.println()
	writer.println("end")
	if not writer.writeTo(saveDir() + filename + ".sav"):
		push_error("Save: could not write " + saveDir() + filename + ".sav")


## Unused in the original (call commented out): writes an obfuscated copy
## of the given save file to <filename>.sav1.
func crypt(file, filename):
	var text: String = FileAccess.get_file_as_string(str(file))
	var writer := SaveWriter.new()
	var pos: int = 0
	while true:
		var buffer: Array = J.array(1024, 0)
		var cnt: int = mini(1024, text.length() - pos)
		if cnt <= 0:
			cnt = -1
		for i in range(maxi(cnt, 0)):
			buffer[i] = text.unicode_at(pos + i)
		# OggDecoder.swapChars(buffer, 0, cnt)
		var i2: int = 0
		while i2 < cnt:
			var tempByte: int = buffer[i2]
			buffer[i2] = buffer[i2 + 1]
			buffer[i2 + 1] = tempByte
			i2 += 2
		var sb: String = ""
		for i in range(buffer.size()):
			buffer[i] += 1
			sb += String.chr(buffer[i])
		writer.println(sb)
		if cnt <= 0:
			break
		pos += cnt
	writer.writeTo(saveDir() + str(filename) + ".sav1")


## Writes the start location.
func writeHeader(writer):
	writer.println("start " + String(place).replace(" ", "_"))


## Writes all the information about all the characters in the list
## (type is "character" or "exCharacter").
func writeCharacters(writer, list, type):
	for i in range(list.size()):
		var c = list[i]
		var name: String = c.getName()
		writer.print_(type + " " + name + " ")
		for j in range(c.getAttribute().size()):
			writer.print_(str(c.getAttribute(j)) + " ")
		writer.println()

		if c.getWeapon() != null:
			writer.println("rightHand " +
					String(c.getRightHandName()).replace(" ", "_") + " " + str(c.getWeapon().getNumber()))
		if c.getLeftHand() != null:
			writer.println("leftHand " +
					String(c.getLeftHandName()).replace(" ", "_") + " " + str(c.getLeftHand().getNumber()))
		if c.getArmor() != null:
			writer.println("armor " + String(c.getArmorName()).replace(" ", "_") + " " + str(c.getArmor().getNumber()))
		writer.println()
		writer.println("characterdeck")
		var d = c.getDeck()
		writeDeck(writer, d)
		writer.println()


## Writes down all the cards in the given deck.
func writeDeck(writer, d):
	for j in range(d.getCurrentDeckSize()):
		var card = d.getCard(j)
		writer.println("card " + ClassRegistry.getClassName(card) +
				" " + str(card.getLevel()) +
				" " + ("true" if card.isAll() else "false"))


## Writes all the information about the items and equipments in the backpack.
func writeBackPack(writer):
	var list: Array = Load.convertWeaponListToAbstractRemoveEquipped()
	for i in range(list.size()):
		writer.println("partyweapons " +
				String(list[i].getName()).replace(" ", "_") + " " + str(list[i].getNumber()))
	list = Load.convertShieldListToAbstractRemoveEquipped()
	for i in range(list.size()):
		writer.println("partyshields " +
				String(list[i].getName()).replace(" ", "_") + " " + str(list[i].getNumber()))
	list = Load.convertArmorListToAbstractRemoveEquipped()
	for i in range(list.size()):
		writer.println("partyarmors " +
				String(list[i].getName()).replace(" ", "_") + " " + str(list[i].getNumber()))
	var gold: int = Load.getPartyItems().getGold()
	var hours: String = Load.getTime().getHours()
	var p_min: String = Load.getTime().getMin()
	var steps: int = Load.getPartyItems().getSteps()
	var battles: int = Load.getPartyItems().getBattles()
	writer.println("info " + str(gold) + " " + hours + " " + p_min + " " + str(steps) + " " + str(battles))

	for i in range(Load.getPartyItems().itemSize()):
		var item = Load.getPartyItems().getItem(i)
		writer.println("item " + String(item.getName()).replace(" ", "_") + " " + str(item.getNr()))


## Writes all the cards in the main deck.
func writeMainDeck(writer):
	var d = Load.getPartyItems().getMainDeck()
	writer.println("maindeck")
	writeDeck(writer, d)


## Writes the status of all the characters, villagers, roads and so on.
func writeStatus(writer):
	Database.saveData(writer)


## Writes down all the visited nodes and roads.
func writeVisited(writer):
	for i in range(3):
		var zone: String = "world" + str(i) + ".map"
		for node in visited.getVnodes(zone):
			writer.println("visitedNodes " + zone + " " + String(node).replace(" ", "_"))
		for road in visited.getVroads(zone):
			writer.println("visitedRoads " + zone + " " + str(road))


func writeLabyrinthMap(writer):
	var info = Database.getVisitedLabyrinths()
	var keys = Database.getVisitedLabyrinthsList()
	var labName: String
	for key in keys:
		var labInfo = info.get(key)
		var floors = labInfo.getFloors()
		for j in range(floors.size()):
			var map = floors[j]
			labName = String(labInfo.getLabyrinthName()).replace(" ", "_")
			labName = labName + "--" + String(map.getName()).replace(" ", "_") + ".map"
			writer.println("labmap " + labName)
			var nodes = map.getNodes()
			for nk in nodes:
				var n = nodes.get(nk)
				writer.println("node " + str(n.getAddress()) + " "
						+ ("true" if n.isVisited() else "false") + " "
						+ ("true" if n.isSeen() else "false"))
	var l = Database.getLastVisitedLabyrinth()
	if l != null:
		writer.println("lastlab " + str(LabyrinthMap.convertForSave(l)))


## Writes all the information concerning the bestiary.
func writeBestiary(writer):
	var bestiary = Bestiary.getBestiary().getStats()
	for key in bestiary:
		var val = bestiary.get(key)
		var counter: int = val.getBattleCounter()
		var offset: int = val.getCounterOffset()
		var name: String = val.getEnemy().getDbName()
		writer.println("counter " + name + " " + str(counter) + " " + str(offset))


## Replacement for java.io.PrintWriter: collects the text and writes it to a
## file under user:// with FileAccess. Lines end with "\n".
class SaveWriter extends RefCounted:
	var text: String = ""

	## Java: print(String).
	func print_(s) -> void:
		text += str(s)

	## Java: println() and println(String).
	func println(s = null) -> void:
		if s != null:
			text += str(s)
		text += "\n"

	func writeTo(path: String) -> bool:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(text)
		f.close()
		return true
