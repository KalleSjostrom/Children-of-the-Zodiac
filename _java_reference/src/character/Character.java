/*
 * Classname: Character.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package character;

import factories.LevelFactory;
import graphics.ImageHandler;
import info.SoundMap;
import info.Values;
import info.Values.characters;

import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.util.HashMap;
import java.util.Iterator;

import menu.EquipPage;

import java.util.logging.*;

import sound.SoundPlayer;
import battle.equipment.GLDeck;
import cards.AbstractCard;
import equipment.AbstractEquipment;
import equipment.Armor;
import equipment.Deck;
import equipment.Slot;
import equipment.Weapon;

/**
 * This class represents a character in the game. A character is a creature 
 * which the player uses, in contrast with enemies (who also is a creature).
 * A character can equip weapons, armors, shields and a deck of cards.
 * These equipments can be changes via the menu in the game. Or via the 
 * text file where this information is gotten.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Character extends Creature {

	public static final int HAND_SIZE = 5;

	private static Logger logger = Logger.getLogger("Character");
	
	private Weapon rightHand;
	private AbstractEquipment leftHand;
	private Armor armor;
	private Deck deck = new Deck(this);
	private GLDeck deckGL;
	private String image;

	private int roundCounter = 0;
	private int element;

	private Values.characters charEnum;

	/**
	 * Creates a character with the specified name and attributes.
	 *  
	 * @param name the name of the character.
	 * @param attributes the integer array with attributes for this character.
	 * @param pic the name of the image to load.
	 */
	public Character(String name, float[] attributes, String pic) {
		super(name, attributes);
		if (name.equals("Kin")) {
			charEnum = Values.characters.KIN;
		} else if (name.equals("Celis")) {
			charEnum = Values.characters.CELIS;
		} else if (name.equals("Borealis")) {
			charEnum = Values.characters.BOREALIS;
		} else {
			charEnum = Values.characters.ZALZI;
		}
		image = pic;
		loadImage();
		initBattleDeck();
	}

	/**
	 * Loads the image with the specified name.
	 */
	private void loadImage() {
		BufferedImage im = ImageHandler.getImage(Values.MenuImages, image);
		Image frame = 
			ImageHandler.getImage(Values.MenuImages, "charframe.png");
		Graphics2D g = (Graphics2D) im.getGraphics();
		g.drawImage(frame, 0, 0, null);
		ImageHandler.addPermanentlyConvertNow(image, im);
	}

	/**
	 * This method initializes the battle deck. These initializations consists
	 * of setting the number of cards to be shown when battling, 
	 * (default is four) and makes some line calculation so that the menu hand
	 * will point at the correct card.
	 */
	private void initBattleDeck() {
		deck.setNrOfShownCards(4);
		deck.setLineLength(4);
	}

	/**
	 * Equips the given equipment of the given type.
	 * 
	 * @param ae the equipment to equip.
	 * @param playSound true if the equipment sound should be played.
	 */
	public void equip(AbstractEquipment ae, boolean playSound) {
		if (ae instanceof Armor) {
			equipArmor(ae, playSound);
		} else if (ae instanceof Weapon) {
			equipWeapon(ae, playSound);
		} else {
			equipLeftHand(ae, playSound);
		}
		ae.setEquiped(true);
	}

	/**
	 * Equips the given equipment as an armor.
	 * 
	 * @param ae the equipment to equip.
	 * @param playSound true if the equip sound should be played.
	 */
	private void equipArmor(AbstractEquipment ae, boolean playSound) {
		if (armor != null) {
			armor.setEquiped(false);
		}
		armor = (Armor) ae;
		armor.setEquiped(true);
		if (playSound) {
			SoundPlayer.playSound(SoundMap.MENU_EQUIP_ARMOR);
		}
	}
	
	/**
	 * Equips the given equipment as a weapon.
	 * 
	 * @param ae the equipment to equip.
	 * @param playSound true if the equip sound should be played.
	 */
	private void equipWeapon(AbstractEquipment ae, boolean playSound) {
		if (rightHand != null) {
			rightHand.setEquiped(false);
		}
		rightHand = (Weapon) ae;
		rightHand.setEquiped(true);
		if (playSound) {
			SoundPlayer.playSound(SoundMap.MENU_EQUIP_WEAPON);
		}
	}
	
	/**
	 * Equips the given equipment as a left hand equipment.
	 * 
	 * @param ae the equipment to equip.
	 * @param playSound true if the equip sound should be played.
	 */
	private void equipLeftHand(AbstractEquipment ae, boolean playSound) {
		if (leftHand != null) {
			leftHand.setEquiped(false);
		}
		leftHand = ae;
		leftHand.setEquiped(true);
		if (playSound) {
			SoundPlayer.playSound(SoundMap.MENU_EQUIP_SHIELD);
		}
	}

	/**
	 * This method unequips the equipment that the given mode represents.
	 * This mode can be either of EquipPage.ARMORS, EquipPage.LEFT_HAND or
	 * EquipPage.RIGHT_HAND.
	 * 
	 * @param mode the kind of equipment to unequip.
	 */
	public void unequip(int mode) {
		switch (mode) {
		case EquipPage.ARMORS : 
			if (armor != null) {
				armor.setEquiped(false);
				SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_ARMOR);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
			armor = null;
			break;
		case EquipPage.LEFT_HAND : 
			if (leftHand != null) {
				leftHand.setEquiped(false);
				SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_SHIELD);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
			leftHand = null;
			break;
		case EquipPage.RIGHT_HAND : 
			if (rightHand != null) {
				rightHand.setEquiped(false);
				SoundPlayer.playSound(SoundMap.MENU_UNEQUIP_WEAPON);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
			rightHand = null;
			break;
		}
	}

	/**
	 * Increases the level by one.
	 */
	public void levelUp() {
		setAttribute(LEVEL, getAttribute(LEVEL) + 1);
	}
	
	public static void levelUp(Character c) {
		logger.log(Level.FINE, "Level " + c.getAttribute(Creature.LEVEL));
		c.levelUp();
		logger.log(Level.FINE, "Level after " + c.getAttribute(Creature.LEVEL));

		HashMap<Integer, Integer> info = 
			LevelFactory.getLevelFor(
					c.getName(), c.getAttribute(Creature.LEVEL), 
					c.getAttribute(Creature.CLASS));
		
		c.setAttribute(
				Creature.EXP_LEFT_TO_NEXT_LEVEL,
				info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL));
		
		Iterator<Integer> it = info.keySet().iterator();
		while (it.hasNext()) {
			int attr = it.next();
			int newValue = info.get(attr);
			if (newValue != LevelFactory.NO_INCREASE) {
				c.setAttribute(attr, newValue);
			}
		}
		c.setAttribute(Creature.HP, c.getAttribute(Creature.MAX_HP));
	}


	/**
	 * Cures this character from the dead.
	 */
	public void cureFromDead() {
		resurrected = alive = true;
	}

	/**
	 * This method gets the total attack for this character. The given
	 * type represents which type of offense to return. The possible values
	 * for type is Slot.ATTACK, Slot.MAGIC and Slot.SUPPORT. This method should
	 * only be used from the battle, because any boosts are added 
	 * in this method.
	 * 
	 * @param type the kind of attack to return.
	 * @return the total offense value for the given type of attack.
	 */
	public int getBattleAttack(int type) {
		float att = 0;
		if (type == Slot.ATTACK) {
			att = Math.round(
					attackBoost.getCurrentBoost() * getTotalAttack());
		} else if (type == Slot.MAGIC) {
			att = Math.round(
					magicBoost.getCurrentBoost() * getTotalMagicAttack());
		} else if (type == Slot.SUPPORT) {
			att = getTotalSupport();
		}
		return Math.round(att);
	}

	/**
	 * This method gets the total defense for this character. The given
	 * type represents which type of defense to return. The possible values
	 * for type is Slot.ATTACK or Slot.MAGIC. This method should only be
	 * used from the battle, because any boosts are added in this method.
	 * 
	 * @param type the kind of defense to return.
	 * @return the total defense value for the given type of defense.
	 */
	public int getBattleDefense(int type) {
		float def = 0;
		if (type == Slot.ATTACK) {
			def = Math.round(
					defenseBoost.getCurrentBoost() * getTotalDefense());
		} else if (type == Slot.MAGIC) {
			def = Math.round(
					magicDefenseBoost.getCurrentBoost() * getTotalMagicDefense());
		}
		return Math.round(def);
	}

	/**
	 * Gets the total attack. This is the characters attack plus the equipped 
	 * weapons attack (if a weapon is equipped). This method does not add on
	 * any possible attack boost. So it might not represent the absolute total
	 * attack if the character currently is in battle. 
	 *  
	 * @return the total attack of this character.
	 */
	public int getTotalAttack() {
		float attack = getTotalTemplate(ATTACK);
		return Math.round(attack);
	}

	/**
	 * Gets the total magical attack. This is the characters magical attack 
	 * plus the equipped weapons magical attack (if a weapon is equipped).
	 * This method does not add on any possible magic boost. So it might 
	 * not represent the absolute total magic if the character currently 
	 * is in battle.
	 *  
	 * @return the total magical attack of this character.
	 */
	public int getTotalMagicAttack() {
		float magic = getTotalTemplate(MAGIC_ATTACK);
		return Math.round(magic);
	}

	/**
	 * Gets the total support attack. This is the characters support attack 
	 * plus the equipped weapons support attack (if a weapon is equipped).
	 *  
	 * @return the total support attack of this character.
	 */
	public int getTotalSupport() {
		float support = getTotalTemplate(SUPPORT_ATTACK);
		return Math.round(support);
	}

	/**
	 * Gets the total defense. This is the characters defense plus the equipped
	 * armors defense (if an armor is equipped) plus the shields defense 
	 * (if a shield is equipped). This method adds on the bonus for being in
	 * the defense mode. Note this so that this boost is not added when showing
	 * the player the characters status in the menu.
	 *  
	 * @return the total defense of this character.
	 */
	public int getTotalDefense() {
		float defense = getTotalTemplate(DEFENSE);
		defense = addDefenseMode(defense);
		return Math.round(defense);
	}

	/**
	 * Gets the total magical defense. This is the characters magical defense 
	 * plus the equipped armors magical defense (if an armor is equipped)
	 * plus the equipped shields magical defense (if a shield is equipped).
	 *  
	 * @return the total magical defense of this character.
	 */
	public int getTotalMagicDefense() {
		float totalMagicDefense = getTotalTemplate(MAGIC_DEFENSE);
		totalMagicDefense = addDefenseMode(totalMagicDefense);
		return Math.round(totalMagicDefense);
	}
	
	private float getTotalTemplate(int attrib) {
		int base = getAttribute(attrib);
		float total = base;
		if (leftHand != null) {
			total += leftHand.getAttribute(attrib) * base;
		}
		if (rightHand != null) {
			total += rightHand.getAttribute(attrib) * base;
		}
		if (armor != null && !tempCrushed) {
			total += armor.getAttribute(attrib) * base;
		}
		return total;
	}

	/**
	 * Adds the defense bonus if the character is in battle and has chosen
	 * the defense mode.
	 * 
	 * @param defense the defense before the bonus.
	 * @return the defense after the bonus has been added if the character is 
	 * in defense mode.
	 */
	public float addDefenseMode(float defense) {
		if (deckGL != null) {
			defense *= deckGL.isDefenseMode() ? 1.5f : 1;
		}
		return defense;
	}

	/**
	 * Gets the battle deck.
	 * 
	 * @return the battle deck
	 */
	public Deck getDeck() {
		return deck;
	}

	/**
	 * Gets the equipment from the right hand.
	 * This could be either a shield or a weapon.
	 * 
	 * @return the equipment in the left hand.
	 */
	public Weapon getWeapon() {
		return rightHand;
	}

	/**
	 * Gets the equipment from the left hand.
	 * This could be either a shield or a weapon.
	 * 
	 * @return the equipment in the left hand.
	 */
	public AbstractEquipment getLeftHand() {
		return leftHand;
	}

	/**
	 * Gets the equipped armor.
	 * 
	 * @return the equipped armor.
	 */
	public Armor getArmor() {
		return armor;
	}

	/**
	 * Gets the name of the equipment from the right hand,
	 * or the empty string if this character has something 
	 * in the right hand.
	 * 
	 * @return the name of the equipment in the right hand.
	 */
	public String getRightHandName() {
		if (rightHand != null) {
			return rightHand.getName();
		}
		return "";
	}

	/**
	 * Gets the name of the equipment from the left hand, 
	 * or the empty string if this character has something 
	 * in the left hand.
	 * 
	 * @return the name of the equipment in the left hand.
	 */
	public String getLeftHandName() {
		if (leftHand != null) {
			return leftHand.getName();
		}
		return "";
	}

	/**
	 * Gets the equipped armors name, or the empty string if this 
	 * character has no armor.
	 * 
	 * @return the name of the equipped armor, if any.
	 */
	public String getArmorName() {
		if (armor != null) {
			return armor.getName();
		}
		return "";
	}

	/**
	 * Gets the big image that is shown in the menu.
	 * 
	 * @return the big image.
	 */
	public String getImage() {
		return image;
	}

	/**
	 * Gets the size of the equipped deck.
	 * 
	 * @return the size of the deck.
	 */
	public int getDeckSize() {
		return deck.getDeckSize();
	}

	/**
	 * This method sets the GLDeck for this character. This deck 
	 * is the one drawn in 3D.
	 * 
	 * @param deck the GLDeck to set.
	 */
	public void set2DDeck(GLDeck deck) {
		deckGL = deck;
		deckGL.setNeedUpdate(true);
	}

	/**
	 * This method gets the GLDeck for this character. This deck 
	 * is the one drawn in 3D.
	 * 
	 * @return this characters GLDeck.
	 */
	public GLDeck get2DDeck() {
		if (deck.hasChanged()) {
			if (deckGL != null) {
				deckGL.update(this);
				deckGL.setNeedUpdate(true);
			}
			deck.resetChange();
		}
		return deckGL;
	}

	/**
	 * This method temporarily removes the armor for this character.
	 * 
	 * @return true if the armor where crushed.
	 */
	public int crushArmor() {
		return HAS_NO_ARMOR;
	}

	/**
	 * This method is called just after the player has played all the cards
	 * in the weapon slots and attacked. It resets some values as progress.
	 * 
	 * @param b 
	 */
	public void finishRound(boolean didAction) {
		logger.log(Level.FINE, "Finished round for " + name);
		if (didAction) {
			roundCounter++;
			logger.log(Level.FINE, "Did action, new round counter " + roundCounter);
		}
		resetSpeed();
		setTurn(false);
		updateBoosts();
	}

	/**
	 * This method gets the index of this character in the list of
	 * characters found in the Load class.
	 * 
	 * @return the index of this character.
	 */
	public int getIndex() {
		return charEnum.getIndex();
	}

	/**
	 * This method is called when the battle is exited.
	 * It removes any temporary element settings and removes
	 * any temporary armor crushes.
	 */
	public void resetBattleStats() {
		active = true;
		inTurn = false;
		roundCounter = 0;
		changeElementBack();
		resetTempValues();
		resetBoost();
	}

	/**
	 * Changes the element (temporary) for this characters.
	 * 
	 * @param element the element to change to. 
	 * (CardValues.FIRE_ELEMENT and so on.)
	 */
	public void changeElement(int element) {
		this.element = element;
	}

	/**
	 * Removes any temporary element changes for this characters.
	 */
	public void changeElementBack() {
		this.element = AbstractCard.NO_ELEMENT;
	}

	/**
	 * This method gets the element of the given equipment. If the given 
	 * equipment is null, the value AbstractCard.NO_ELEMENT is returned.
	 * 
	 * @param ae gets the element from the given equipment.
	 * @return the element the given equipment.
	 */
	public int getElement() {
		return element;
	}

	/**
	 * This method gets a string showing the given attribute.
	 * 
	 * @param attribute the attribute to get information about.
	 * @return a string telling the given attribute like so:
	 * "HP: 215" for example.
	 */
	public String get(int attribute) {
		int val = getTotal(attribute);
		String value = String.valueOf(val);
		if (val == LevelFactory.NO_INCREASE) {
			value = "-";
		}
		return getMap().get(attribute) + value;
	}

	/**
	 * This method gets the total value of the given attribute.
	 * This means that if this method is called with the attribute
	 * Creature.DEFENSE, the returned value is the characters defense
	 * + armor defense + shield defense + weapon defense.
	 * 
	 * @param att the attribute value to get.
	 * @return the total attribute value for the given attribute.
	 */
	public int getTotal(int att) {
		float attr = getAttribute(att);
		float total = attr;
		if (getWeapon() != null) {
			total += attr * getWeapon().getAttribute(att);
		} 
		if (getArmor() != null) {
			total += attr * getArmor().getAttribute(att);
		}
		if (getLeftHand() != null) {
			total += attr * getLeftHand().getAttribute(att);
		}
		return Math.round(total);
	}
	
	/**
	 * Gets the limit of experience to get to the current level of the 
	 * character. This is useful when calculating the experience bar shown
	 * on the spoils screen at the end of battle. This bar will show the 
	 * difference between the previous level limit and the next level limit.
	 *  
	 * @return the previous level limit.
	 */
	public int getExpToNextLevel() {
		int level = getAttribute(Creature.LEVEL);
		int cClass = getAttribute(Creature.CLASS);
		
		logger.log(Level.FINE, "getExpToNextLevel " + level + " " + cClass + " " + getName());
		HashMap<Integer, Integer> info = 
			LevelFactory.getLevelFor(getName(), level, cClass);
		return info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL);
	}
	
	public void setExpPercentOfNext(float p) {
		int toNext = getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL);
		int receivedExp = Math.round(p * toNext);
		setAttribute(Creature.EXPERIANCE, receivedExp);
		addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -receivedExp);
	}

	public String getNameFor(int i) {
		return getMap().get(i);
	}

	public boolean canLevelUp() {
		return getAttribute(EXP_LEFT_TO_NEXT_LEVEL) != LevelFactory.NO_INCREASE;
	}

	public int getRoundCounter() {
		return roundCounter;
	}

	public void setClass(int newClass) {
		int c = getAttribute(CLASS);
		if (c < newClass) {
			fullCure();
			setAttribute(CLASS, newClass);
			setAttribute(LEVEL, 1);
			HashMap<Integer, Integer> info = 
				LevelFactory.getLevelFor(name, 1, newClass);

			setAttribute(Creature.EXPERIANCE, 0);
			setAttribute(
					Creature.EXP_LEFT_TO_NEXT_LEVEL,
					info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL));

			Iterator<Integer> it = info.keySet().iterator();
			while (it.hasNext()) {
				int attr = it.next();
				int newValue = info.get(attr);
				if (newValue != LevelFactory.NO_INCREASE) {
					setAttribute(attr, newValue);
				}
			}
		}
	}

	public characters getEnum() {
		return charEnum;
	}
}
