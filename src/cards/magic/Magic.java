/*
 * Classname: Magic.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import battle.HitElement;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * This class combines the shared price grouping for the magic cards.
 * All these cards should have the same price regardless of element.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public abstract class Magic extends Card {

	/**
	 * This method lets the attacker attack the target with this card. 
	 * 
	 * @param target the target of the attack.
	 * @param attacker the attacker.
	 * @return the HitElement containing the information about the attack.
	 */
	@Override
	public HitElement use(Creature target, Character attacker) {
		return attack(target, attacker);
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
	@Override
	protected float[] createAttackPercent() {
		return STANDARD_ATTACK;
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + (Math.round(getAttackPercent() * 100)) + " %");
	}
}
