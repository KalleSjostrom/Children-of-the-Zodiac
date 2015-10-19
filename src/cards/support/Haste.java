/*
 * Classname: Haste.java
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

/**
 * The haste card is played to boost agility (speed).
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class Haste extends SupportCard {
	
	private static final String[] SHORT_INFO = {"Agility up", ""};
	public static final String TEXT = "Agility up!";
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_HASTE};
	private static final int[] DELAYS = {0};
	
	/**
	 * This method is called to calculate the effect of a "haste"-card
	 * being used by the attacker on the given target. This card will
	 * cause the targets progress bar to increase faster.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		target.boostSpeed(TURNS_TO_BOOST_MANY, getBoostPercent());
		return new HitElement(this, -1, HitElement.NORMAL, TEXT);
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
	 * this card is to boost the speed and not to actually attack.
	 *  
	 * @return the list of attack percentage.
	 */
	protected float[] createAttackPercent() {
		return new float[]{0, 0, 0};
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
		return STANDARD_BOOST;// new float[]{.3f, .45f, .6f};
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"Chronos, the deity of time, turning the great wheel of the Zodiac",
				"is called upon with the power containied in this card. Chronos will",
				"escalate time itself and therefore aid the target in battle."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Boosts speed: " + Math.round(getBoostPercent() * 100) + " %");
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
