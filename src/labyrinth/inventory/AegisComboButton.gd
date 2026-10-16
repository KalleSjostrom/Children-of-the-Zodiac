class_name AegisComboButton
extends ComboButton
## Port of labyrinth.inventory.AegisComboButton: the aegis symbol buttons.


func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, buttons = null, openDoor = null, imageNr = null) -> void:
	super(node, dir, nrOfTexs, image, status, buttons, openDoor, imageNr)
	delayTime = 2500
	sound = SoundMap.LABYRINTH_ACTIVATE_SYMBOL
	doneSound = SoundMap.LABYRINTH_SECRET


func setSettings():
	scale = BattleValues.CARD_SCALE
	heightOffset = 0
	zOff = 1.99
	scale2 = 3


func getComboMapImage():
	if status == ON:
		return LabyrinthMap.aegisOn[imageNr]
	return LabyrinthMap.aegisOff[imageNr]
