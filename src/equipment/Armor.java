/*
 * Classname: Armor.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/01/2008
 */
package equipment;

import info.Values;

/**
 * This class stores information about an armor.
 * An armor is not only defense but also in charge of the special slot.
 * The special slot is the way to execute any special skills that may 
 * be equipped on the current armor.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 24 Jan 2008
 */
public class Armor extends AbstractEquipment {

	/**
	 * Constructs a new armor from the specified values.
	 * 
	 * @param stat the array of attributes associated with the armor.
	 * @param name the name of the armor.
	 * @param slotNumbers an array containing the numeric representation of 
	 * the slots. 0 for attack slots, 1 for magic and 2 for support slots.
	 */
	public Armor(float[] stat, String name, int[] slotNumbers) {
		super(stat, name);
		loadImage(Values.MenuImages, "armor.png");
		createWeaponArray(slots, slotNumbers);
	}
}
