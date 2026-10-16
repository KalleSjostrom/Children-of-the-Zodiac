class_name Weapon
extends AbstractEquipment
## Port of equipment.Weapon: a weapon with a list of slots that the player
## can put cards in when battling.

# Java: getImage("offense.png") = ImageHandler.addPermanentlyLoadOnUse(...),
# which returns the name. The textures are not loaded from the static
# initializer here (see PORTING.md section 6); ImageHandler loads them on use.
static var OFFENSE_IMAGE = Values.BattleImages + "offense.png"
static var DEFENSE_IMAGE = Values.BattleImages + "defense.png"


## Creates a new weapon with the given attributes, name and slot numbers
## (0 for attack slots, 1 for magic and 2 for support slots).
func _init(stat = null, name = null, slotNumbers = null) -> void:
	super(stat, name)
	createWeaponArray(slots, slotNumbers)
	loadImage(Values.MenuImages, "weapon.png")


## Java: private static getImage(name) (renamed: an instance method has the
## same name). Gets the image with the given name from the battle images.
static func getImageStatic(name):
	return ImageHandler.addPermanentlyLoadOnUse(Values.BattleImages + name)
