/*
 * Classname: ProtectingBarrier.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.support;

import info.SoundMap;
import particleSystem.ParticleSystemPacket;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import cards.SupportCard;
import character.Character;
import character.Creature;
import equipment.Slot;

/**
 * The protecting barrier card is played to boost magic defense.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class ProtectingBarrier extends SupportCard {
	
	private static final String[] SHORT_INFO = {"Magic defense up", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_STATUS_UP};
	private static final int[] DELAYS = {0};
	

	public HitElement use(Creature target, Character attacker) {
		float boost = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT);
		target.boostMagicDefense(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.MAGIC_DEFENSE)));
		return new HitElement(this, -1, HitElement.NORMAL, "Magic Defense Up!");
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
	 * This method creates an array containing only 0, 0, 0 because the use of
	 * this card is to boost the magic defense and not to actually attack.
	 *  
	 * @return the list of attack percentage.
	 */
	protected float[] createAttackPercent() {
		return EMPTY;
	}
	
	/**
	 * Creates the boost percentage. This is the amount of percent that this 
	 * card should increase the attackers support. If the attacker casts this
	 * card with say 17 in support and the boost percent is 40 % (.4f). The
	 * boost will be a total of 6.8 => 7. The created percent is not, however,
	 * a single value but three. One for each level of the card. So a focus 
	 * card could have 40 % boost for level 1, 70 % boost for level 2 and 100 %
	 * boost for level 3, for example.
	 *  
	 * @return the list of attack percentage.
	 */
	protected float[] createBoostPercent() {
		return STANDARD_BOOST;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The armor of the Zodiac was forged in ancient times, before even",
				"the Tenjins walked upon the green earth. This magic armor will",
				"surely keep the bearer safe and sound for any kin of the black arts."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Boosts magic def: " + Math.round(getBoostPercent() * 100) + " %");
	}

	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	protected String[] getSoundEffect() {
		return SOUNDS;
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return DELAYS;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Cure.getStaticAnimation(info);
	}
}
