class_name IceButton
extends InventoryButton
## Port of labyrinth.inventory.IceButton: a button (note) in the ice temple
## that plays the given sound when activated.


func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, hinder = null, sound = null) -> void:
	super(node, dir, nrOfTexs, image, status, hinder)
	message = "Already activated."
	self.sound = sound


func getMapImage():
	return LabyrinthMap.notes[status]
