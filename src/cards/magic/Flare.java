/*
 * Classname: Flare.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;


/**
 * This class represents the Flare magic in the game. A Flare is a strong
 * version of the fire magic.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Flare extends PowerMagic {

	private static final String[] SHORT_INFO = {"Powerful fire magic", ""};
	private static final String[] SOUNDS = {SoundMap.MAGICS_FLARE};
	private static final int[] DELAYS = {450};
	
	/**
	 * This method sets the element to fire.
	 */
	@Override
	protected void setElement() {
		element = FIRE_ELEMENT;
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
				"The blazing fires of the Flare was created by the three Zodiacs of",
				"fire Aries, Leo and Sagittarius. A flare could turn even a massive",
				"block of ice into a tidal wave rendering any ice defense useless."};
	}
	
	public boolean canBeMerged() {
		return false;
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
		return Flare.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setValue(AnimSettings.NR_PARTICLES, 1500);
		settings.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, -6));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, 0, -12));
		settings.setValue(AnimSettings.SPEED, 0);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 0);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, -.03f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, -.018f);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, 0, 0));
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 5);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .08f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .08f);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.PARTICLES_DESTROYED);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.FLARE_EMITTER_TYPE);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 30);
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, 0);
		psp.add(new ParticleSystem(settings), 0);
		return psp;
	}
}
