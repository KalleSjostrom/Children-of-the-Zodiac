/*
 * Classname: HitElement.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/05/2008
 */
package battle;

import cards.AbstractCard;
import cards.Card;

/**
 * Creates a new HitElement containing information about an attack
 * in battle. An attack, in this case, is all the possible things
 * a character can do, including black magic, support magic and
 * regular attacks.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 May 2008
 */
public class HitElement {

	public static final int NORMAL = 0;
	public static final int CRIT = 1;
	public static final int MISS = 2;
	public static final int IMMUNE = 3;

	private Card card;
	private String[] addEffect = new String[4];
	private HitElement cureElem = null;
	private int[] attackValue = new int[]{-2, -2, -2, -2};
	private int[] effect = new int[4];
	private int target;

	/**
	 * Creates a new hit element based on the given information. The card is 
	 * the one used in the attack. 
	 * 
	 * @param c the card used in the attack.
	 * @param attack the damage on the target.
	 * @param effect represents the type of the attack, these types can be
	 * HitElement.NORMAL, CRIT or MISS.
	 * @param additionalEffect a string representing an additional effect such
	 * as Crush! or Drained 20 Hp! or whatever.
	 */
	public HitElement(Card c, int attack, int effect, String additionalEffect) {
		card = c;
		attackValue[0] = attack;
		addEffect[0] = additionalEffect;
		
		this.effect[0] = effect;
		switch (effect) {
		case CRIT:
			addEffect[0] = "Critical Hit!";
			break;
		case MISS:
			addEffect[0] = "Miss!";
			break;
		case IMMUNE:
			addEffect[0] = "Immune!";
			break;
		}
	}

	/**
	 * Creates a new hit element based on the given information.
	 * 
	 * @param attack the damage on the target.
	 * @param additionalEffect a string representing an additional effect such
	 * as Crush! or Drained 20 Hp! or whatever.
	 */
	public HitElement(int attack, String additionalEffect) {
		attackValue[0] = attack;
		addEffect[0] = additionalEffect;
		effect[0] = 0;
	}

	/**
	 * Merges the given element with this hit element.
	 * 
	 * @param elem the hit element to merge with.
	 */
	public void merge(HitElement elem) {
		int index = 0;
		boolean found = false;
		for (int i = 1; i < attackValue.length && !found; i++) {
			found = attackValue[i] == -2;
			index = i;
		}
		attackValue[index] = elem.attackValue[0];
		addEffect[index] = elem.getEffectText(0);
		effect[index] = elem.effect[0];
		if (cureElem != null) {
			cureElem.attackValue[0] += elem.getCureElement().getAttackDamage();
		}
	}
	
	public void cureMerge(HitElement tempCure) {
		attackValue[0] += tempCure.getAttackDamage();
	}

	/**
	 * This method adds a damage value to the effect string.
	 * The effect string is like "Critical hit" for example.
	 * This method add the given value to the string so that the
	 * resulting string is "Critical hit 362".
	 * 
	 * @param damage the damage value to add.
	 */
	public void addToEffect(int damage) {
		if (effect[0] != MISS && effect[0] != IMMUNE) {
			addEffect[0] += " " + damage;
		}
	}

	/**
	 * This method checks if this hit element is an attack on every target
	 * in a party. This means all the enemies or all the party members.
	 * 
	 * @return true if the attack is on every target in a party.
	 */
	public boolean onAll() {
		return attackValue[1] != -2;
	}

	/**
	 * Calculates the number of targets that this element hit.
	 * 
	 * @return the number of targets that this element attack.
	 */
	public int size() {
		int size = 1;
		for (int i = 1; i < attackValue.length; i++) {
			size += attackValue[i] == -2 ? 0 : 1;
		}
		return size;
	}

	/**
	 * Checks if the card attacked with is a support card.
	 * 
	 * @return true if the card in this element is a support card.
	 */
	public boolean isSupport() {
		return card instanceof cards.SupportCard;
	}

	/**
	 * Creates a new hit element representing the given values.
	 * This extra hit element is used to store cure information
	 * when a drain card is used. A drain card will show information
	 * about the damage on the enemies but it must also show the
	 * amount cured on the character that played the card.
	 * 
	 * @param cure the amount to cure.
	 * @param effect the string effect that will be used. Like: "Drain: ".
	 */
	public void addCure(int cure, String effect) {
		cureElem = new HitElement(cure, effect);
	}

	/**
	 * Gets the extra cure element if any.
	 * 
	 * @return the extra hit element.
	 */
	public HitElement getCureElement() {
		return cureElem;
	}

	/**
	 * Gets the attack value of the given index. The given index is either 0, 
	 * 1, 2 or 3. The index 0 is always the attack value on the target. The 
	 * other indices are the rest of the creatures in the target team in order 
	 * when the target is removed. This means that if the player has targeted 
	 * the creature with index 1 in a list with 3 creatures: 
	 * 
	 * i == 0 is the target with index 1 (target index)
	 * i == 1 is the target with index 0 (first creature when target is removed)
	 * i == 2 is the target with index 2 (second creature when target is removed)
	 * 
	 * @param i the index of the attack damage to get.
	 * @return the attack damage with the given index.
	 */
	public int getAttackDamage(int i) {
		return attackValue[i] > 0 ? attackValue[i] : 0; 
	}
	
	/**
	 * Gets the attack value on the targeted enemy.
	 * 
	 * @return the attack value on the targeted enemy.
	 */
	public int getAttackDamage() {
		return getAttackDamage(0); 
	}
	
	public int getActuallAttackDamage() {
		return attackValue[0];
	}

	/**
	 * Gets the card played that resulted in this hit. 
	 * 
	 * @return the card in this hit element.
	 */
	public Card getCard() {
		return card;
	}

	/**
	 * Gets the text associated with this hit. This could be a string like
	 * "Crit" or "Drain". The given index is either 0, 1, 2 or 3. The index 
	 * 0 is always the attack value on the target. The other indices are the 
	 * rest of the creatures in the target team in order when the target is 
	 * removed. This means that if the player has targeted the creature with 
	 * index 1 in a list with 3 creatures: 
	 * 
	 * i == 0 is the target with index 1 (target index)
	 * i == 1 is the target with index 0 (first creature when target is removed)
	 * i == 2 is the target with index 2 (second creature when target is removed)
	 * 
	 * @param index the index of the attack damage to get.
	 * @return the text to display next to the damage made on the 
	 * target creature.
	 */
	public String getEffectText(int index) {
		return addEffect[index];
	}
	
	/**
	 * Checks if this hit is miss. The given index is either 0, 1, 2 or 3. The
	 * index 0 is always the attack value on the target. The other indices are
	 * the rest of the creatures in the target team in order when the target is 
	 * removed. This means that if the player has targeted the creature with 
	 * index 1 in a list with 3 creatures: 
	 * 
	 * i == 0 is the target with index 1 (target index)
	 * i == 1 is the target with index 0 (first creature when target is removed)
	 * i == 2 is the target with index 2 (second creature when target is removed)
	 * 
	 * @param index the index of target to check for miss.
	 * @return true if this element did miss the target.
	 */
	public boolean isMiss(int index) {
		return effect[index] == HitElement.MISS;
	}
	
	public boolean didHit() {
		return effect[0] != HitElement.MISS && effect[0] != HitElement.IMMUNE;
	}

	public boolean isCrit() {
		return effect[0] == HitElement.CRIT;
	}

	/**
	 * Gets the type of this hit element. This could either be Slot.ATTACK,
	 * Slot.MAGIC or Slot.SUPPORT.
	 * 
	 * @return the type of this hit element.
	 */
	public int getType() {
		return card.getType();
	}

	/**
	 * Gets the color of this hit element. The returned value is
	 * between 0 and ParticleValues.COLORS.length.
	 * 
	 * @return the color of this hit element.
	 */
	public int getColor() {
		int color = AbstractCard.NO_ELEMENT;
		if (card != null) {
			color = card.getElement();
		}
		return color;
	}

	public void setTest(int target) {
		this.target = target;
	}
	
	public int getTest() {
		return target;
	}
}
