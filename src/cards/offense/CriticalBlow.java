/*
 * Classname: CriticalBlow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import particleSystem.ParticleSystemPacket;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The critical blow card is a battle card with one addition, the chance of a
 * critical hit is greatly increased.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class CriticalBlow extends Card {
	
	private static String[] shortInfo = {"Attack + increased chance","for critical hit"};
	private int lastAttacker;

	/**
	 * This method is called to calculate the effect of a "critical blow"-card
	 * being used by the attacker on the given target. A critical blow increases
	 * the chance to make a critical blow (three times as hard).
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	@Override
	public HitElement use(Creature target, Character attacker) {
		return attack(
				target, attacker, getEffectChanceToHit() + CRITICAL_PRECENT);
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
		return SPECIAL_ATTACK;
	}
	
	/**
	 * This method returns the probability that this card would be effective. 
	 * The returned value is an array containing the separate probability for
	 * each level of the card. If the actual card has level two and is used 
	 * in battle it would only hit if </br> <code> 
	 * (Math.random <= getChanceToHit()) </code> </br> is true. The 
	 * getChanceToHit() method returns the array created by this method.
	 * 
	 * @return the probability that this card would be effective.
	 */
	@Override
	protected float[] createEffectChancePercent() {
		return STANDARD_EFFECT_CHANCE;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	@Override
	protected String[] createTextInfo() {
		return new String[]{
				"A sword forged by the great blacksmith from the ancient times,",
				"especially made to cut critical wounds on the target. This card",
				"releases the essence of the devastating edge from the past."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Chance for critical hit: " + Math.round((getEffectChanceToHit() + CRITICAL_PRECENT) * 100) + " %");
	}

	@Override
	public String[] getVeryShortInfo() {
		return shortInfo;
	}

	public void playSound() {
		String s = BattleCard.SOUNDS[lastAttacker];
		int[] i = getSoundEffectDelay();
		BattleCard.playBattleSound(s, i[0]);
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		Character attacker = info.getAttacker();
		if (attacker != null) {
			lastAttacker = attacker.getIndex();
		}
		return BattleCard.getStaticAnimation(info);
	}
}
