/*
 * Classname: AbstractEquipment.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import info.Values;
import info.Values.characters;

import java.awt.image.BufferedImage;
import java.util.ArrayList;

import character.Character;
import graphics.ImageHandler;

/**
 * This abstract class is the superclass to the equipments in the game.
 * The equipments is armors, shields, weapons and skills.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 25 Jan 2008
 */
public class AbstractEquipment {

	public static final int FOR_WHOM = 0;
	public static final int DEFENSE = 1;
	public static final int MAGIC_DEFENSE = 2;
	public static final int AGILITY = 3;
	public static final int EVADE = 4;
	public static final int HIT = 5;
	public static final int ATTACK = 6;
	public static final int MAGIC_ATTACK = 7;
	public static final int SUPPORT_ATTACK = 8;
	public static final int PRICE = 9;

	protected String image;
	protected String name;
	protected String[] info = new String[3];
	protected ArrayList<Slot> slots = new ArrayList<Slot>();
	protected float[] attribute;
	protected int number = 1;
	protected boolean equip;
	
	/**
	 * Sets the attribute array and name;
	 * 
	 * @param attribute the attribute for the equipment.
	 * @param name the name of the equipment.
	 */
	protected AbstractEquipment(float[] attribute, String name) {
		this.attribute = attribute;
		this.name = name;
	}

	/**
	 * Loads the image with the given path and name.
	 * 
	 * @param path the path to the image.
	 * @param name the name of the image.
	 */
	protected void loadImage(String path, String name) {
		image = path + name;
		ImageHandler.addToCurrentLoadOnUse(image);
	}

	/**
	 * Copies this equipment and returns the copy.
	 * 
	 * @return the copy of this equipment.
	 */
	protected AbstractEquipment copy() {
		float[] att = new float[8];
		for (int i = 0; i < attribute.length; i++) {
			att[i] = attribute[i];
		}
		String[] inf = new String[info.length];
		for (int i = 0; i < info.length; i++) {
			inf[i] = info[i];
		}
		AbstractEquipment ae = new AbstractEquipment(att, name);
		ae.info = inf;
		ae.image = image;
		return ae;
	}

	/**
	 * Adds the given string to the array at the given row.
	 *  
	 * @param s the string to add.
	 * @param row the row to add the string to.
	 */
	public void addInfo(String s, int row) {
		info[row] = s;
	}

	/**
	 * Increases the number of this equipment. The number is the amount of
	 * this equipment owned.
	 */
	public void addNumber() {
		number++;
	}
	
	/**
	 * Decreases the number of this equipment. The number is the amount of
	 * this equipment owned.
	 */
	public void subtractNumber() {
		number--;
	}
	
	public void setNumber(int nr) {
		number = nr;
	}

	/**
	 * Gets this equipments name.
	 * 
	 * @return name the name of this equipment.
	 */
	public String getName() {
		return name;
	}

	/**
	 * Gets the information about who this equipment is for. 
	 * The returned value is either Values.KIN, .CELIS, 
	 * .ZALZI or .BOREALIS.
	 * 
	 * @return the number associated with the character who this 
	 * equipment is for.
	 */
	public int getForWhom() {
		return (int) attribute[FOR_WHOM];
	}

	/**
	 * Gets the image of this equipment.
	 * 
	 * @return the image of this equipment.
	 */
	public String getImage() {
		return image;
	}
	
	/**
	 * Gets the attack of the equipment.
	 * 
	 * @return the attack of the equipment.
	 */
	public float getAttack() {
		return attribute[ATTACK];
	}
	
	/**
	 * Gets the magic attack of the equipment.
	 * 
	 * @return the magic attack of the equipment.
	 */
	public float getMagic() {
		return attribute[MAGIC_ATTACK];
	}
	
	/**
	 * Gets the support strength of the equipment.
	 * 
	 * @return the support value for the equipment.
	 */
	public float getSupport() {
		return attribute[SUPPORT_ATTACK];
	}
	
	/**
	 * Gets the price of this equipment.
	 * 
	 * @return gets the price of this equipment.
	 */
	public int getPrice() {
		return (int) attribute[PRICE];
	}
	
	/**
	 * Gets the hit of this equipment.
	 * 
	 * @return the hit.
	 */
	public float getHit() {
		return attribute[HIT];
	}
	
	/**
	 * Gets the defense of this equipment.
	 * 
	 * @return defense the defense of this equipment.
	 */
	public float getDefense() {
		return attribute[DEFENSE];
	}
	
	/**
	 * Gets the agility of this equipment. This effects
	 * the character who has this equipment equipped, in the way
	 * that this value is added to the characters agility.
	 * 
	 * @return the agility of this equipment.
	 */
	public float getAgility() {
		return attribute[AGILITY];
	}
	
	/**
	 * Gets the evade of this equipment. This effects
	 * the character who has this equipment equipped, in the way
	 * that this value is added to the characters evade.
	 * 
	 * @return the agility of this equipment.
	 */
	public float getEvade() {
		return attribute[EVADE];
	}

	/**
	 * Gets the magic defense of this equipment.
	 * 
	 * @return magicDefense the magic defense of this equipment.
	 */
	public float getMagicDefense() {
		return attribute[MAGIC_DEFENSE];
	}
	
	/**
	 * Checks if this equipment is equipped. This is used so that the 
	 * equip menu know which equipment is available to equip.
	 * The equip menu will list all the owned equipment that is not
	 * equipped.
	 * 
	 * @return true if this equipment is equipped.
	 */
	public boolean isEquiped() {
		return equip;
	}
	
	/**
	 * Sets this equipment as equipped if the given argument is true.
	 * This method will unequip this equipment if equip is false.
	 * 
	 * @param equip true if this method should equip this equipment.
	 */
	public void setEquiped(boolean equip) {
		this.equip = equip;
	}

	/**
	 * Gets the number of this equipment. The number is the amount of
	 * this kind of equipment that the party owns.
	 * 
	 * @return the number of this equipment.
	 */
	public int getNumber() {
		return number;
	}

	/**
	 * Gets the attribute that the given value represents.
	 * This could be either of this class' public static values.
	 * 
	 * @param att the attribute to get.
	 * @return the attribute of the given kind.
	 */
	public float getAttribute(int att) {
		return att < attribute.length ? attribute[att] : 0;
	}

	/**
	 * Gets the info concerning this equipment. The info contains of three 
	 * strings so there is no point of calling this method with more than 2 or
	 * less than 0 as parameters. The info about an armor is something like:
	 * The bloody armor is Dracula's Pyjamas which he wears every night..
	 * 
	 * @param i the number of the row in the info to get.
	 * @return the row with the specified number.
	 */
	public String getInfo(int i) {
		if (i < info.length) {
			return info[i];
		}
		return "";
	}
	
	/**
	 * Gets the list of slots residing in this equipment. This method
	 * should not be used on the equipment Shield because that class
	 * has no slots.
	 * 
	 * @return the list of slots in this equipment.
	 */
	public ArrayList<Slot> getSlots() {
		return slots;
	}
	
	/**
	 * This method creates slots from the given array and stores them in the
	 * given list.
	 * 
	 * @param list the list to store the slots in.
	 * @param slot a list of strings representing the name of the slots.
	 * 0 for attack slots, 1 for magic slots and 2 for support slots.
	 */
	protected void createWeaponArray(ArrayList<Slot> list, int[] slot) {
		for (int i = 0; i < slot.length; i++) {
			int info = slot[i];
			String name = ImageHandler.addToCurrentLoadOnUse(
					Values.MenuImages + info + "slot.png");
			
			BufferedImage im = ImageHandler.getImage(name);
			list.add(new Slot(name, im, info));
		}
	}

	/**
	 * This method gets an array containing the difference of the attributes
	 * in the given equipments. 
	 * It returns equipment.attributes[i] - equipped.attributes[i].
	 * @param c 
	 * 
	 * @param equipment the equipments that the player has selected 
	 * to see change.
	 * @param equipped the equipment that the player already has equipped.
	 * @return an array containing the difference of the two equipments.
	 */
	public static int[] getChange(
			Character c, AbstractEquipment equipment, AbstractEquipment equipped) {
		int[] change = new int[9];
		for (int i = 1; i < change.length; i++) {
			int base = c.getAttribute(i);
			change[i] = Math.round(
				(equipment == null ? 0 : (equipment.attribute[i] * base)) - 
				(equipped == null ? 0 : (equipped.attribute[i] * base))
			);
		}
		return change;
	}

	public boolean isFor(characters character) {
		return attribute[FOR_WHOM] == character.getIndex();
	}
}
