/*
 * Classname: Slow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import particleSystem.SlowParticleSystem;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The slow card will cause the target to act less often. The progress bar will
 * fill up more slowly.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Slow extends Card {

	public static final String[] SHORT_INFO = {"Enemy agility down", ""};
	public static final String TEXT = "Agility down!";
	
	/**
	 * This method is called to calculate the effect of a "slow"-card
	 * being used by the attacker on the given target. This card will
	 * cause the targets progress bar to increase more slowly.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	@Override
	public HitElement use(Creature target, Character attacker) {
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			target.boostSpeed(TURNS_TO_BOOST_MANY, -getAttackPercent());
			he = new HitElement(this, -1, HitElement.NORMAL, TEXT);
		}
		return he;
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
		return STANDARD_BOOST;
	}
	
	/**
	 * Creates the chance percent. 
	 *  
	 * @return the list of chance percentage.
	 */
	protected float[] createEffectChancePercent() {
		return new float[]{.9f, .95f, 1f};
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
				"Chronos, the deity of time, turning the great wheel of the Zodiac",
				"is called upon with the power containied in this card. Chronos will",
				"take the form of Aeon and turn time slower for the foes before him."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Lowers enemy's speed with " + Math.round(getAttackPercent() * 100) + " %");
	}
	
	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Slow.getStaticAnimation(info);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefaultNoFade();
		
		if (info.isOnEnemy()) {
			settings.setValue(AnimSettings.SIZE, 1f);
			settings.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, -4));
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, 0, -4.5f));
		} else {
			settings.setValue(AnimSettings.SIZE, .4f);
			Vector3f s = info.getEnemy().getTempSource();
			
			settings.setVector(AnimSettings.SOURCE, new Vector3f(s.x, s.y, s.z + .5f));
			settings.setVector(AnimSettings.TARGET, new Vector3f(s.x, s.y, s.z));
		}
		
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE);
		settings.setValue(AnimSettings.NR_PARTICLES, 1);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.ZERO);
		settings.setValue(AnimSettings.SPEED, 0);
		settings.setValue(AnimSettings.NR_TEXTURES, 3);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.CLOCK);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.CLOCK_HOUR);
		settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.CLOCK_MINUTE);
		psp.add(new SlowParticleSystem(settings), 0);
		return psp;
	}
}