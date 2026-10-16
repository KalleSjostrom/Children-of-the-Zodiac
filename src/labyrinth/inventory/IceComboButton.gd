class_name IceComboButton
extends ComboButton
## Port of labyrinth.inventory.IceComboButton: the note combination buttons
## in the ice temple.


func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, buttons = null, openDoor = null, imageNr = null, sound = null) -> void:
	super(node, dir, nrOfTexs, image, status, buttons, openDoor, imageNr)
	delayTime = 1500
	self.sound = sound
	doneSound = SoundMap.LABYRINTH_NOTES_DONE


func getComboMapImage():
	return LabyrinthMap.notes[status]
