/*
 * Classname: Colliding.java
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
 * This class represents the Colliding magic in the game. The Colliding magic 
 * is a strong version of the earth magic.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Colliding extends PowerMagic {

	private static final String[] SHORT_INFO = {"Powerful earth magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_COLLIDING};
	private static final int[] DELAYS = {200};
	
	/**
	 * This method sets the element to earth.
	 */
	@Override
	protected void setElement() {
		element = EARTH_ELEMENT;
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
				"Tremling earth is called forth by Taurus, Virgo and Capricorn.",
				"The earth will rapture and the foes that stand in the way will",
				"gasp for air as they are swallowed whole by the raging quake."};
	}
	
	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Colliding.getStaticAnimation(info);
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
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, .05f);
		float size = 1.2f;
		settings.setValue(AnimSettings.SPEED, 7);
		settings.setValue(AnimSettings.SIZE, .4f * size);
		settings.setValue(AnimSettings.NR_PARTICLES, 150);
		settings.setValue(AnimSettings.PARTICLE_MASS, .1f);
		Vector3f temp = new Vector3f(.3f, .3f, .3f).multLocal(size);
		settings.setVector(AnimSettings.POSITION_NOISE, temp);
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 14);
		// RESET VELOCITY ON IMPACT
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, -.1f, 0));
		settings.setValue(AnimSettings.COLOR, EARTH_ELEMENT);
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		settings.setValue(AnimSettings.NR_TEXTURES, 3);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JONAS_ROUND);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JONAS_ROUND_2);
		settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.ROUND);
		settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.SHARP);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0);
		settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, true);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 1);
		settings.setValue(AnimSettings.LIFE_MULTIPLIER, .18f);
		settings.setBoolean(AnimSettings.DESTROY_CAMERA_SHAKE, true);
		settings.setBoolean(AnimSettings.DESTROY_ENEMY_SHAKE, true);
		
		settings.setVector(AnimSettings.SOURCE, new Vector3f(-4, 3, -5.9f));
		
		psp.add(new ParticleSystem(settings), 0);
		settings.getVector(AnimSettings.SOURCE).x = 4;
		psp.add(new ParticleSystem(settings), 0);
		
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
		settings.setValue(AnimSettings.SIZE, .3f * size);
		settings.setValue(AnimSettings.NR_PARTICLES, 100);
		settings.setVector(AnimSettings.POSITION_NOISE, 
				new Vector3f(.55f, .55f, .55f).multLocal(size));
		
		settings.getVector(AnimSettings.SOURCE).x = -4;
		psp.add(new ParticleSystem(settings, info.getEnemy()), 0);
		settings.getVector(AnimSettings.SOURCE).x = 4;
		psp.add(new ParticleSystem(settings, info.getEnemy()), 0);
		return psp;
	}
}
