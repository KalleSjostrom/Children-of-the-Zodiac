/*
 * Classname: AbstractCard.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/01/2008
 */
package cards;

import graphics.GraphicHelp;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.awt.image.BufferedImage;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This class stores information about a card,
 * such as name, position, level and so on.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 24 Jan 2008
 */
public abstract class AbstractCard implements Comparable<Card> {
	
	public static final int NO_ELEMENT = 0;
	public static final int FIRE_ELEMENT = 1;
	public static final int ICE_ELEMENT = 2;
	public static final int WIND_ELEMENT = 3;
	public static final int EARTH_ELEMENT = 4;
	public static final int NR_ELEMENT_MODES = 5;
	public static final int CRITICAL_INCREASE = 2;
	public static final int ELEMENT_INCREASE = 2;
	
	public static final int TURNS_TO_BOOST_MANY = 2;
	public static final int TURNS_TO_BOOST_FEW = 1;
	
	protected static final float CRITICAL_PRECENT = .03f;
	protected static final float[] EMPTY = {0, 0, 0};
	
	protected static final float[] STANDARD_ATTACK = {1.5f, 1.8f, 2.1f};
	protected static final float[] STANDARD_ATTACK_HIGH = {2.1f, 2.4f, 2.7f};
	protected static final float[] STANDARD_ATTACK_LOW = {1.2f, 1.5f, 1.8f};
	protected static final float[] STANDARD_ATTACK_LV4 = {3f, 3f, 3f};
	
	protected static final float[] SPECIAL_ATTACK = {1.65f, 1.95f, 2.25f};
	
	protected static final float[] STANDARD_BOOST = {.25f, .3f, .35f};
	protected static final float[] STANDARD_BOOST_LOW = {.15f, .2f, .25f};
	
	protected static final float[] STANDARD_SUPORT= {1.7f, 2f, 2.3f};
	protected static final float[] STANDARD_SUPORT_LOW= {1.4f, 1.7f, 2f};
	
	protected static final float[] STANDARD_EFFECT_CHANCE = {.4f, .7f, 1f};
	
	protected static final float[] STANDARD_CHANCE = {.4f, .7f, 1f};
	protected static final float[] STANDARD_CHANCE_LOW = {.2f, .4f, 6f};
	protected static final float[] RESURRECT_CURE = {.7f, 1.4f, 2.1f};
	
	public static final int OFFENSE = 0;
	public static final int MAGIC = 1;
	public static final int SUPPORT = 2;
	public static final int NEUTRAL = 3;
	
	public static final int NORMAL = 0;
	public static final int GRAY = 1;
	
	private static final int BASE = 0;
	private static final int BALL = 1;
	
	protected int element;
	protected int level;
	protected int type;
	protected boolean all;

	private String[][] images= new String[2][2];
	private String[] info;
	private String name;
	
	private final float[] PERCENT = createAttackPercent();
	private final float[] EFFECT_CHANCE_PERCENT = createEffectChancePercent();
	private int price = 0;
	private int slotType = -1;
	
	/**
	 * Initiates a new card with the given information.
	 * 
	 * @see battle.Combo
	 * 
	 * @param nr the number of the card (which combo icon this card has).
	 * the different numbers that are available is found in the 
	 * battle.Combo class.
	 * @param level the level of the card.
	 * @param all true if this card should be an all card (hit on all enemies).
	 * @param price 
	 * @param type2 
	 */
	protected void init(int level, boolean all, int type, int price) {
		String name = getSimpleName();
		this.name = getNameWithSpaces(name);
		this.all = all;
		setLevel(level);
		setImage();
		setElement();
		this.type = type;
		this.price = price;
		
		createSortingValue();
		info = createInfo();
		createShortInfo();
	}
	
	protected String getSimpleName() {
		return getClass().getSimpleName();
	}

	//////////////////////
	//     CREATORS     //
	//////////////////////
	
	/**
	 * Puts together the information about this card.
	 * 
	 * @return the string array containing the information about this card.
	 */
	private String[] createInfo() {
		String[] info = new String[4];
		String singleAll = isAll() ? " (all)" : "(single)";
		info[0] = getName() + " - Level: " + getLevel() + "   " + singleAll;
		String[] text = createTextInfo();
		info[1] = text[0];
		info[2] = text[1];
		info[3] = text[2];
		return info;
	}
	
	/**
	 * Creates the chance percent of this card. If this method is not 
	 * overridden the chance percent will be set to 1, 1, 1. The chance
	 * percent is the stored chance of a successful hit.
	 * 
	 * @return the chance for a successful hit.
	 */
	protected float[] createCheancePercent() {
		return new float[]{1, 1, 1};
	}

	protected float[] createEffectChancePercent() {
		return new float[]{1, 1, 1};
	}
	
	/**
	 * Copies this card and returns the copy
	 * 
	 * @return a copy of this card.
	 */
	public Card copyCard() {
		return Card.createCard(
				getClass().getName(), level, all, type, price);
	}
	
	///////////////////////
	//  DRAWING METHODS  //
	///////////////////////

	/**
	 * Draws the card on the given graphics.
	 * 
	 * @param g the graphics3D used.
	 * @param Xpos the x position to draw the card.
	 * @param Ypos the y position to draw the card.
	 */
	public void drawCard(Graphics g, int x, int y) {
		drawCard(g, x, y, .7f);
	}

	public void drawCard(Graphics g, int x, int y, float size) {
		drawCard(g, x, y, size, NORMAL, level);
	}
	
	/**
	 * Draws the card on the given graphics in black and white.
	 * 
	 * @param g the graphics3D used.
	 * @param x the x position to draw the card.
	 * @param y the y position to draw the card.
	 */
	public void drawGrayCard(Graphics g, int x, int y) {
		drawCard(g, x, y, .7f);
	}
	
	public void drawGrayCard(Graphics g, int x, int y, float size) {
		drawCard(g, x, y, size, GRAY, level);
	}
	
	/**
	 * Draws the card on the given graphics.
	 * 
	 * @param g the graphics3D used.
	 * @param x the x position to draw the card.
	 * @param y the y position to draw the card.
	 * @param size the size or scale in which to draw the card.  
	 */
	public void drawCard(Graphics g, int x, int y, float size, int type, int level) {
		g.drawImage(images[type][BASE], x, y, size);
		y += size * 25;
		if (level == 1) {
			g.drawImage(images[type][BALL], x + (size * 65), y, size);
		} else if (level == 2) {
			g.drawImage(images[type][BALL], x + (size * 50), y, size);
			g.drawImage(images[type][BALL], x + (size * 80), y, size);
		} else if (level == 3) {
			g.drawImage(images[type][BALL], x + (size * 40), y, size);
			g.drawImage(images[type][BALL], x + (size * 65), y, size);
			g.drawImage(images[type][BALL], x + (size * 90), y, size);
		}
	}

	///////////////////////
	// GETTERS & SETTERS //
	///////////////////////

	public String getGrayImage(int type) {
		return images[GRAY][type];
	}
	
	public String getImage(int type) {
		return images[NORMAL][type];
	}
	
	/**
	 * Gets the cards level.
	 * 
	 * @return int level.
	 */
	public int getLevel() {
		return level;
	}

	/**
	 * Creates the attack percent. This is the amount of percent that this card
	 * should boost the attackers attack. If the attacker attacks with say 17 
	 * in attack and the attack percent is 140 % (1.4f). The attack will be a
	 * total of 23.8 => 24. The created percent is not, however, a single value
	 * but three. One for each level of the card. So a normal battle card could
	 * have 120 % boost for level 1, 160 % boost for level 2 and 300 % boost for 
	 * level 3, for example.
	 *  
	 * @return the list of attack percentage.
	 */
	public float getAttackPercent() {
		return PERCENT[level - 1];
	}
	
	protected float getEffectChanceToHit() {
		return EFFECT_CHANCE_PERCENT[level - 1];
	}

	/**
	 * Gets the type of the card. Could be either of Slot.ATTACK, Slot.MAGIC
	 * or Slot.SUPPORT.
	 * 
	 * @see equipment.Slot#ATTACK
	 * @see equipment.Slot#MAGIC
	 * @see equipment.Slot#SUPPORT
	 * 
	 * @return the type of the card.
	 */
	public int getType() {
		if (type == NEUTRAL && slotType != -1) {
			return slotType;
		}
		return type;
	}
	
	public void putInSlot(int kind) {
		slotType = kind;
	}
	
	public void reset() {
		slotType = -1;
	}
	
	/**
	 * Checks if this card is an all-card 
	 * (takes damage on all enemies).
	 * 
	 * @return true if this card is an all-card. 
	 */
	public boolean isAll() {
		return all;
	}
	
	/**
	 * Converts the given name that follow the java method naming convention 
	 * in normal readable form. This means that the name HerbOfVitality will
	 * become Herb Of Vitality.
	 * 
	 * @param name the name to convert.
	 * @return the converted name.
	 */
	private static String getNameWithSpaces(String name) {
		Pattern p = Pattern.compile("[A-Z]");
		Matcher m = p.matcher(name);
		StringBuffer sb = new StringBuffer();
		int i = 0;
		
		while (m.find(1)) {
			i = m.start();
			String found = name.substring(0, i);
			name = name.substring(i);
			if (found.length() != 0) {
				sb.append(found + " ");
			}
			m = p.matcher(name);
		}
		sb.append(name);
		return sb.toString();
	}
	
	/**
	 * Gets the name of the card. This is the name to display for the player
	 * I.e not cards.neutral.TheElementOfEarth but only The Element Of Earth.
	 * 
	 * @return the name of the card.
	 */
	public String getName() {
		return name;
	}

	/**
	 * Gets the cards element. This is either FIRE_ELEMENT, ICE, 
	 * EARTH, WIND, or NO_ELEMENT at all.
	 * 
	 * @return the element of the card.
	 */
	public int getElement() {
		return element;
	}
	
	/**
	 * Gets the information about this card. This is not only the name
	 * but the three line "story" about the card as well as the combo text.
	 * 
	 * @return the information about this card.
	 */
	public String[] getInfo() {
		return info;
	}

	/**
	 * Sets the element of this card. If this method is not overridden
	 * the element will be set to the default element NO_ELEMENT, which
	 * is no element at all, or neutral element in other words.
	 */
	protected void setElement() {
		element = NO_ELEMENT;
	}

	/**
	 * Sets the cards image.
	 */
	public void setImage() {
		setImage(name, BASE);
		setImage(all ? "blueball" : "ball", BALL);
	}
	
	private void setImage(String name, int type) {
		BufferedImage im = ImageHandler.getImage(Values.Cards, name + ".png");
		BufferedImage gray = GraphicHelp.toGrayScale(im);
		images[NORMAL][type] = ImageHandler.addPermanentlyConvertNow(
				Values.Cards + name + ".png", im);
		images[GRAY][type] = ImageHandler.addPermanentlyConvertNow(
				Values.Cards + name + "gray.png", gray);
		
	}

	/**
	 * Sets the cards level.
	 *
	 * @param level the level to set.
	 */
	public void setLevel(int level) {
		this.level = level;
	}

	/**
	 * Gets the price of this specific card.
	 * 
	 * @return the price of this card.
	 */
	public final int getPrice() {
		return price;
	}
	
	//////////////////////
	// ABSTRACT METHODS //
	//////////////////////
	/**
	 * Creates the information about this card.
	 * 
	 * @return the information about this card.
	 */
	protected abstract String[] createTextInfo();
	
	/**
	 * Creates the array containing the attacking strength of this card.
	 * 
	 * @return the attack percent of this card.
	 */
	protected abstract float[] createAttackPercent();
	
	/**
	 * Creates the value to compare with other cards when sorting.
	 */
	protected abstract void createSortingValue();
	
	protected abstract void createShortInfo();
	public abstract String[] getVeryShortInfo();
}
