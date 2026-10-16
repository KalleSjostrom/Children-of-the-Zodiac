class_name RiddleDoor
extends HinderDoor
## Port of labyrinth.inventory.RiddleDoor: a hinder door that is opened by
## solving a riddle (the notes in the ice temple).

var showingDialog_: bool = false


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, nextPlace = null, vStartPos = null) -> void:
	super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos)


## Exits the given labyrinth, enters the door and sets the next place in the
## labyrinth by calling setNextPlace() with nextPlace as argument.
func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = Values.angleToDirection(lab.getPlayerAngle())
	if playerDir == dir:
		status = Database.getStatusFor(dataBaseName)
		if checkIfOpen():
			enter(lab)
		else:
			if not showingDialog_:
				lab.drawDialog("The door is shut tight, but music echoes", "down the silent great hall when the door is touched.")
				SoundPlayer.playSound(SoundMap.LABYRINTH_NOTES)
			showingDialog_ = not showingDialog_
