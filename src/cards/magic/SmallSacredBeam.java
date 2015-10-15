/*
 * Classname: SacredBeam.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The sacred beam card will both damage the target and cause open wound.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class SmallSacredBeam extends Card {
	
	private static final String[] SHORT_INFO = {"Powerful magic +", "chance of open wound"};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_SACRED_BEAM};
	private static final int[] DELAYS = {200};

	/**
	 * This method is called to calculate the effect of a "Sacred Beam"-card
	 * being used by the attacker on the given target. This card will hit
	 * the target with a beam of light causing the enemy to start bleeding
	 * and the life of the target will decrease some amount each turn for 
	 * three turns.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	@Override
	public HitElement use(Creature target, Character attacker) {
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			String fullName = "";
			String simpleName = "openwound";
			int ret = Card.checkPreferences3(
					target, attacker, null, false, this, fullName, simpleName);
			switch (ret) {
			case Card.IMMUNE:
				he = attack(target, attacker, "Immune!", true);
				break;
			case Card.HIT:
				target.openWound();
				he = attack(target, attacker, "Open wound!", true);
				break;
			case Card.MISS:
				he = attack(target, attacker, "Open wound failed!", true);
				break;

			default:
				break;
			}
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
		return STANDARD_ATTACK_LV4;
	}
	
	/**
	 * This method sets the element to fire.
	 */
	@Override
	protected void setElement() {
		element = NO_ELEMENT;
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
				"An extremely bright ray of light burns a hole in the very essence",
				"of night as it passes through the target. When the ray finally",
				"burns out, the foe is left painfully bleeding to death."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %, (causes Open Wound)");
	}
	
	@Override
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
		return SmallSacredBeam.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefaultNoFade();
		
		Vector3f source = info.getEnemy().getTempSource();
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, -.5f, -1.1f));
		settings.setVector(AnimSettings.SOURCE, source == null ? new Vector3f(0, 0, -6) : source);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_MULTIPLE_TIMES);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_GRAY);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.01f, .01f, .01f));
		
		settings.setValue(AnimSettings.SIZE, .1f);
		settings.setValue(AnimSettings.SPEED, 7);
		settings.setValue(AnimSettings.NR_PARTICLES, 500);

		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .05f);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		
		psp.add(new ParticleSystem(settings), 0);
		return psp;
	}
	
	protected String getSimpleName() {
		return "SacredBeam";
	}
}
