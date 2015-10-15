/*
 * Classname: Weapon.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import graphics.ImageHandler;
import info.Values;

/**
 * This class represents a weapon in the game. The class extends the 
 * abstract equipment but has a lot of additional information including
 * whether the weapon is two handed or not. It also has a list of slots
 * that the player can put cards in when battling.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Weapon extends AbstractEquipment {

	public static final String OFFENSE_IMAGE = getImage("offense.png");
	public static final String DEFENSE_IMAGE = getImage("defense.png");
	
	/**
	 * Creates a new weapon with the given attributes and name. It also
	 * sets whether it is two handed or not and the list of slots.
	 * 
	 * @param stat the attributes of the weapon.
	 * @param name the name of the weapon.
	 * @param slotNumbers an array containing the numeric representation of 
	 * the slots. 0 for attack slots, 1 for magic and 2 for support slots.
	 */
	public Weapon(float[] stat, String name, int[] slotNumbers) {
		super(stat, name);
		createWeaponArray(slots, slotNumbers);
		loadImage(Values.MenuImages, "weapon.png");
	}

	/**
	 * Gets the image with the given name from the folder "BattleImages"
	 * 
	 * @param name the name of the image to load.
	 * @return the image with the given name.
	 */
	private static String getImage(String name) {
		return ImageHandler.addPermanentlyLoadOnUse(
				Values.BattleImages + name);
	}
}