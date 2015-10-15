/*
 * Classname: Shield.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import info.Values;

/**
 * This class represents a shield. A shield can be used as additional defense 
 * by the characters in the game. It has ordinary defense, magic defense and 
 * a speed value indicating the decrease in agility that will take place
 * if a character equips a shield.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Shield extends AbstractEquipment {

	/**
	 * Constructs a new shield from the specified values.
	 * 
	 * @param attributes the array of attributes associated with the shield.
	 * @param name the name of the shield.
	 * @param slotNumbers an array containing the numeric representation of 
	 * the slots. 0 for attack slots, 1 for magic and 2 for support slots.
	 */
	public Shield(float[] attributes, String name, int[] slotNumbers) {
		super(attributes, name);
		loadImage(Values.MenuImages, "lefthand.png");
		createWeaponArray(slots, slotNumbers);
	}
}
