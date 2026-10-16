class_name Shield
extends AbstractEquipment
## Port of equipment.Shield: a left hand equipment (accessory).


## Constructs a new shield from the given attributes, name and slot numbers
## (0 for attack slots, 1 for magic and 2 for support slots).
func _init(attributes = null, name = null, slotNumbers = null) -> void:
	super(attributes, name)
	loadImage(Values.MenuImages, "lefthand.png")
	createWeaponArray(slots, slotNumbers)
