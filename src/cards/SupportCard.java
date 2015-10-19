/*
 * Classname: SupportCard.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards;

import java.util.logging.*;

import battle.HitElement;
import character.Character;
import equipment.Slot;

/**
 * This class is a generalization of all the support cards in the game.
 * Its only purpose is that it creates means to separate a support card
 * from an other card. One could easily check which type of card it is
 * by check if the card is an instance of SupportCard or not. All the cards
 * that should be put in the support slot in battle must extend this class.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public abstract class SupportCard extends Card {
	
	private static Logger logger = Logger.getLogger("SupportCard");

	private final float[] BOOST_PERCENT = createBoostPercent();
	
	/**
	 * Gets the amount of percent to boost some characteristics.
	 * 
	 * @return the boost percentage.
	 */
	protected float getBoostPercent() {
		return BOOST_PERCENT[level - 1];
	}
	
	/**
	 * Gets the amount of percent to boost the target attribute with.
	 * 
	 * @param per the attack percent of the card.
	 * @param support the total support offense of the attacker.
	 * @param targetAttribute the target attribute to boost.
	 * @return the amount of percent to boost the target attribute with.
	 */
	protected float getBoost(float per, int support, int targetAttribute) {
		float boost = per * support;
		return boost / targetAttribute;
	}

	/**
	 * This method is called to calculate the effect of a "cure"-card
	 * being used by the attacker. This card will cure the one that the
	 * hand (in battle) is currently pointing at.
	 * 
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement cure(Character attacker) {
		return cure(attacker, "");
	}

	/**
	 * This method will carry out a cure effect on the one that the hand 
	 * (in battle) is currently pointing at.The given string effect will 
	 * be displayed to the player when battling.
	 * 
	 * @param attacker the attacking creature. the one who hits.
	 * @param effect a message to display to the player.
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement cure(Character attacker, String effect) {
		int baseAttack = attacker.getBattleAttack(Slot.SUPPORT);
		int cureAmount = Math.round(baseAttack * getAttackPercent());
		int hitType = HitElement.NORMAL;
		logger.log(Level.FINE, "Support for " + attacker.getName() + ": " + baseAttack);
		logger.log(Level.FINE, "Card percent: " + getAttackPercent());
		logger.log(Level.FINE, "Amount cured: " + cureAmount);
		return new HitElement(this, cureAmount, hitType, effect);
	}
	
	/**
	 * Creates the boost percent of this card. If this method is not 
	 * overridden the boost percent will be set to 0, 0, 0. The boost
	 * percent is the stored percent to boost the attack with.
	 * 
	 * @return the boost of the attack.
	 */
	protected float[] createBoostPercent() {
		return new float[]{0, 0, 0};
	}
}
