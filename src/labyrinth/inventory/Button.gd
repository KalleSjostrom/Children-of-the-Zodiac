class_name InventoryButton
extends Inventory
## Port of labyrinth.inventory.Button.
##
## This class is the inventory button (lever). An inventory is a thing in the
## labyrinth, that the player can find. If the player finds the node where
## this inventory resides, the Database class is called to find out whether
## the button is pressed or not.
##
## Port note: the animation threads of countTo() are coroutines
## (await Scheduler.sleep).

var showingDialog: bool = false
var hinders = null
const OFF = 0
const ON = 1
const DEFAULT_SLEEP_TIME = 250
var message = ""
var nrOfTextures: int = 0
var sound = SoundMap.LABYRINTH_LEVER_PRESSED


## Creates a new button which will be found on the given node.
## hinder: the array containing the hinders to lock / unlock when pushing
## this button.
func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, hinder = null) -> void:
	super(node, dir, nrOfTexs, image, status)
	var nr: int = 0 if nrOfTexs == null else nrOfTexs
	var st: int = 0 if status == null else status
	hinders = hinder
	nrOfTextures = nr - 1
	currentTex = (nr - 1) if st == 1 else 0
	if st == -1:
		self.status = 0
	message = "The lever is already on!"


## Sets the settings for the button textures, such as scale, y position and
## z offset.
func setSettings():
	scale = BattleValues.CARD_SCALE
	info = getSettings()
	heightOffset = info.getHeightOffset()
	zOff = info.getZOffset()
	scale2 = info.getScale()


## Activates the button. This method starts the animation for this button and
## updates the database.
func activate(labyrinth):
	if currentTex == 0:
		SoundPlayer.playSound(sound)
		countTo(true, nrOfTextures, DEFAULT_SLEEP_TIME)
	elif currentTex == nrOfTextures:
		if not showingDialog:
			labyrinth.drawDialog(message, "")
		else:
			labyrinth.exitDialog()
		showingDialog = not showingDialog


func countTo(up, limit, sleepTime):
	_countToAnimation(up, limit, sleepTime)
	status = absi(status - 1)
	Database.addStatus(dataBaseName, status)
	updateDoorStatus(hinders, status)


## Java: the animation thread started by countTo().
func _countToAnimation(up: bool, limit: int, sleepTime: int) -> void:
	if up:
		while currentTex < limit:
			await Scheduler.sleep(sleepTime)
			currentTex += 1
	else:
		while currentTex > 0:
			currentTex -= 1
			await Scheduler.sleep(sleepTime)


static func updateDoorStatus(hinders, status):
	for i in hinders.size():
		if hinders[i] is InventoryDoor:
			hinders[i].setStatus(status)
		elif hinders[i] is DummyDoor:
			hinders[i].setStatus(status)
		elif hinders[i] is HinderDoor:
			hinders[i].setStatus(status)


func getMapImage():
	return LabyrinthMap.lever[status]


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
