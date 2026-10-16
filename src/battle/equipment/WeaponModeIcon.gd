class_name WeaponModeIcon
extends GLSlot
## Port of battle.equipment.WeaponModeIcon.
##
## Displays which mode the player is in when battling (GLWeapon.OFFENSE_MODE
## or DEFENSE_MODE). It shows a different image for these two cases.


## Creates a new WeaponModeIcon at the x coordinate x.
func _init(x = null) -> void:
	super(null, null, x)


## Loads the textures to be used.
func loadTextures():
	loadTexture(Weapon.OFFENSE_IMAGE, 0)
	loadTexture(Weapon.DEFENSE_IMAGE, 1)
	setSize(0, BattleValues.WEAPON_MODE_ICON_SCALE)
