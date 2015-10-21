/*
 * Classname: Ultima.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import particleSystem.ParticleSystem.InterpolationInfo;
import particleSystem.equations.UpDownSideWave;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The Ultima magic is extremely powerful magic with no element. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Ultima extends Card {

	public static final String[] SHORT_INFO = {"Powerful magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA, 
		SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA};
	private static final int[] DELAYS = {295, 200, 200, 200, 200};
	
	/**
	 * This method is called to calculate the effect of an "ultima"-card
	 * being used by the attacker on the given target. This card will
	 * attack the target with great force.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
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
		return STANDARD_ATTACK_LV4;
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
				"The forces of the universe gathers around the wielder of this card",
				"as the power of Ultima is released. This supreme power know no",
				"bounds and will surely disintegrate even the strongest of fiends."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
	}
	
	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}	
	
	public boolean canBeMerged() {
		return false;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Ultima.getStaticAnimation(info);
	}
	
	@Override
	protected String[] getSoundEffect() {
		return SOUNDS;
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return DELAYS;
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		
		Vector3f target;
		Vector3f source;
		if (info.isOnEnemy()) {
			target = new Vector3f(0, 0, -6);
			source = new Vector3f((float) (Math.random()-.5f) * 2, -.5f, 0);
		} else {
			source = info.getEnemy().getTempSource();
			source = source == null ? new Vector3f(0, 0, -7) : source;
			
			target = new Vector3f(0, -.5f, 0);
			settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
		}
		
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
		settings.setValue(AnimSettings.SIZE, .1f);
		settings.setValue(AnimSettings.SIZE_RANDOM_MULT, .3f);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0);
		settings.setValue(AnimSettings.SPEED, 5);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.3f, .3f, .3f));
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		settings.setVector(AnimSettings.TARGET, target);
		settings.setVector(AnimSettings.SOURCE, source);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 250);
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, 0.1f);

		InterpolationInfo info1 = ParticleSystem.calcInterpolationInfo(settings);
		
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK);
		float amlifier = Math.max((float) Math.random() + .3f, 1);
		UpDownSideWave wave1 = new UpDownSideWave(1f, amlifier, 0, info1, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1);
		psp.add(new ParticleSystem(settings), 0);

		wave1 = new UpDownSideWave(1f, amlifier, 0, info1, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1);
		psp.add(new ParticleSystem(settings), 200);
		
		wave1 = new UpDownSideWave(1f, amlifier, (float) Math.PI, info1, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1);
		psp.add(new ParticleSystem(settings), 400);
		
		wave1 = new UpDownSideWave(1f, amlifier, (float) Math.PI, info1, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1);
		psp.add(new ParticleSystem(settings), 600);
		
		wave1 = new UpDownSideWave(1f, amlifier, 0, info1, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1);
		psp.add(new ParticleSystem(settings), 800);
		
		return psp;
	}
}
