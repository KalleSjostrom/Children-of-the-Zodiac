class_name ComboButton
extends InventoryButton
## Port of labyrinth.inventory.ComboButton (abstract): one of several buttons
## that must all be activated within a time limit to open doorToOpen.
## hinders holds the other ComboButtons of the combination.
##
## Port note: the Java threads are coroutines (await Scheduler.sleep) and
## Scheduler.after.

var doorToOpen = null
const NR_IMAGES = 2
var imageNr: int = 0
var delayTime: int = 0
var doneSound = ""


func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, buttons = null, openDoor = null, imageNr = null) -> void:
	super(node, dir, nrOfTexs, image, status, buttons)
	doorToOpen = openDoor
	self.imageNr = 0 if imageNr == null else imageNr


func getMapImage():
	return getComboMapImage()


func activate(labyrinth):
	if currentTex == 0:
		_activateAnimation()
		status = ON
		SoundPlayer.playSound(sound)
		Database.addStatus(dataBaseName, status)
		checkButtons()


## Java: the animation thread started by activate().
func _activateAnimation() -> void:
	while currentTex < NR_IMAGES - 1:
		currentTex += 1
		await Scheduler.sleep(200)


func reset(playSound):
	if status == ON:
		_resetAnimation(playSound)


## Java: the thread started by reset().
func _resetAnimation(playSound: bool) -> void:
	while currentTex < NR_IMAGES - 1:
		await Scheduler.sleep(200)
	await Scheduler.sleep(delayTime)
	while currentTex > 0:
		await Scheduler.sleep(200)
		currentTex -= 1
	if playSound:
		SoundPlayer.playSound(SoundMap.ERROR)
	status = 0
	Database.addStatus(dataBaseName, status)


func checkButtons():
	var foundError := false
	var i := 0
	while i < hinders.size() and not foundError:
		var button = hinders[i]
		foundError = button.status == OFF
		i += 1
	if foundError:
		for b in hinders:
			b.reset(false)
		reset(true)
	elif doorToOpen != null:
		doorToOpen.open()
		var ds = doneSound
		Scheduler.after(delayTime, func(): SoundPlayer.playSound(ds))


## (abstract)
func getComboMapImage():
	return null
