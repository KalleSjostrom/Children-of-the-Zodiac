/*
 * Classname: Slot.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import graphics.GraphicHelp;
import graphics.ImageHandler;

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.StringTokenizer;

import cards.Card;

/**
 * This class manages the slots in the weapon.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Slot {

	public static final int DISTANCE = 50;
	public static final int ATTACK = 0;
	public static final int MAGIC = 1;
	public static final int SUPPORT = 2;
	public static final int NO_TYPE = -1;
	
	private String image;
	private String smallImage;
	private Card card;
	private int type;

	/**
	 * Constructs a slot with the given information.
	 * 
	 * @param name the image.
	 * @param im the image of the slot.
	 * @param type the type of the slot.
	 */
	public Slot(String name, BufferedImage im, int type) {
		image = name;
		BufferedImage smallerImage = GraphicHelp.scaleImage(im, .6f);
		smallImage = "small" + name;
		ImageHandler.addPermanentlyConvertNow(smallImage, smallerImage);
		this.type = type;
	}

	/**
	 * Checks if this slot does not contain a card.
	 * 
	 * @return true if this slot is empty, (has no card).
	 */
	public boolean hasNoCard() {
		return card == null;
	}

	/**
	 * Gets the card in this slot.
	 * 
	 * @return the card in this slot.
	 */
	public Card getCard() {
		return card;
	}

	/**
	 * Gets the name of this slots small image (used in the menu).
	 * 
	 * @return the small image.
	 */
	public String getSmallImage() {
		return smallImage;
	}
	
	/**
	 * Gets the name of this slots image (used in battle).
	 * 
	 * @return the name of the image.
	 */
	public String getImage() {
		return image;
	}

	/**
	 * Gets the integer value that represents which kind (type) of slot
	 * this is. The different values that can be returned are 
	 * Slot.ATTACK, .MAGIC, .SUPPORT.
	 * 
	 * @return the type of this slot.
	 */
	public int getType() {
		return type;
	}
	
	/**
	 * This method creates an array of integers from the given tokenizer
	 * which will represents a list of slots. The returned array is used
	 * to create the list of actual slots that the player can use in battle.
	 * The returned array contains the numeric representation of the slots. 
	 * 0 for attack slots, 1 for magic and 2 for support slots.
	 * 
	 * @param tokenizer the tokenizer to extract information from.
	 * @return an array containing the numeric representation of the slots.
	 */
	public static int[] getSlots(StringTokenizer tokenizer) {
		int size = Integer.parseInt(tokenizer.nextToken());
		int[] slots = new int[size];
		for (int i = 0; i < size; i++) {
			slots[i] = Integer.parseInt(tokenizer.nextToken());
		}
		return slots;
	}

	/**
	 * Merges the slots in the two given equipments.
	 * 
	 * @param first the first equipment.
	 * @param second the second equipment.
	 * @return the merged list of slots.
	 */
	public static ArrayList<Slot> merge(AbstractEquipment first, AbstractEquipment second) {
		ArrayList<Slot> slots = new ArrayList<Slot>();
		if (first != null) {
			slots.addAll(first.getSlots());
		}
		if (second != null) {
			slots.addAll(second.getSlots());
		}
		return slots;
	}

	/**
	 * Merges the given lists of slots into one list.
	 * 
	 * @param s1 the first list of slots.
	 * @param s2 the second list of slots.
	 * @return the merged list of slots.
	 */
	public static ArrayList<Slot> merge(ArrayList<Slot> s1,
			ArrayList<Slot> s2) {
		ArrayList<Slot> slots = new ArrayList<Slot>();
		slots.addAll(s1);
		slots.addAll(s2);
		return slots;
	}
}
