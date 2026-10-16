class_name Armor
extends AbstractEquipment
## Port of equipment.Armor: an armor (defense and slots).


## Constructs a new armor from the given attributes, name and slot numbers
## (0 for attack slots, 1 for magic and 2 for support slots).
func _init(stat = null, name = null, slotNumbers = null) -> void:
	super(stat, name)
	loadImage(Values.MenuImages, "armor.png")
	createWeaponArray(slots, slotNumbers)
