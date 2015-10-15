/*
 * Classname: WeaponModeIcon.java
 * 
 * Version information: 0.7s.0
 *
 * Date: 15/09/2008
 */
package battle.equipment;

import info.BattleValues;
import equipment.Weapon;

/**
 * This class has only one function and that is to display which mode
 * the player is in when battling. These mode is GLWeapon.OFFENSE_MODE 
 * or .DEFENSE_MODE. It shows a different image for these two cases.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 15 Sep 2008
 */
public class WeaponModeIcon extends GLSlot {

	/**
	 * Creates a new WeaponModeIcon
	 * 
	 * @param x the x coordinate for the icon.
	 */
	public WeaponModeIcon(float x) {
		super(null, null, x);
	}

	/**
	 * This method loads the textures to be used.
	 */
	protected void loadTextures() {
		loadTexture(Weapon.OFFENSE_IMAGE, 0);
		loadTexture(Weapon.DEFENSE_IMAGE, 1);
		setSize(0, BattleValues.WEAPON_MODE_ICON_SCALE);
	}
}
