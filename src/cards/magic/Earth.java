/*
 * Classname: Earth.java
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
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;


/**
 * This class represents the Earth magic in the game. The Earth magic 
 * is a basic magic with earth attribute.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Earth extends Magic {
	
	private static final String[] SHORT_INFO = {"Earth magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_EARTH, SoundMap.MAGICS_EARTH, SoundMap.MAGICS_EARTH};
	private static final int[] DELAYS = {295, 200, 200};
	
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
				"The element of the earth itself, the gaia, which all the living walk",
				"upon is containied in this card. The earth will crush all enemies",
				"under its immense weight, putting out their last breath of air."};
	}
	
	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		info.setLevel(getLevel());
		return Earth.getStaticAnimation(info);
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
		if (info.isOnEnemy()) {
			settings.setVector(AnimSettings.SOURCE, new Vector3f((float)(Math.random()-.5f)*2, 3, -5.9f));
			settings.setBoolean(AnimSettings.DESTROY_ENEMY_SHAKE, true);
		} else {
			Vector3f source = info.getEnemy().getTempSource();
			settings.setVector(AnimSettings.SOURCE, source);
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, -1f, -3));
			settings.setBoolean(AnimSettings.DESTROY_CAMERA_SHAKE, true);
			settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
		}
		
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .05f);
		settings.setValue(AnimSettings.SPEED, 4);
		settings.setValue(AnimSettings.SIZE, .2f);
		settings.setValue(AnimSettings.LIFE_MULTIPLIER, .1f);
		settings.setValue(AnimSettings.NR_PARTICLES, 400);
		settings.setValue(AnimSettings.PARTICLE_MASS, .1f);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.15f, .15f, .15f));
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
//		int level = 3;
		Card.setTargetSourceVectorToLength(4, settings);
		float distance = 1;
		switch (info.getLevel()) {
		case 3:
			settings.getVector(AnimSettings.SOURCE).x -= distance;
			psp.add(new ParticleSystem(settings), 200);
			settings.getVector(AnimSettings.SOURCE).x += distance;
		case 2:
			settings.getVector(AnimSettings.SOURCE).x += distance;
			psp.add(new ParticleSystem(settings), 100);
			settings.getVector(AnimSettings.SOURCE).x -= distance;
		case 1:
			psp.add(new ParticleSystem(settings), 0);
		}
		
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
		settings.setValue(AnimSettings.SIZE, .15f);
		settings.setValue(AnimSettings.NR_PARTICLES, 100);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.275f, .275f, .275f));
		switch (info.getLevel()) {
		case 3:
			settings.getVector(AnimSettings.SOURCE).x -= distance;
			psp.add(new ParticleSystem(settings, info.getEnemy()), 200);
			settings.getVector(AnimSettings.SOURCE).x += distance;
		case 2:
			settings.getVector(AnimSettings.SOURCE).x += distance;
			psp.add(new ParticleSystem(settings, info.getEnemy()), 100);
			settings.getVector(AnimSettings.SOURCE).x -= distance;
		case 1:
			psp.add(new ParticleSystem(settings, info.getEnemy()), 0);
		}
		return psp;
	}
}
