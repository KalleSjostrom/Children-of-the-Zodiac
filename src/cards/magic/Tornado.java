/*
 * Classname: Tornado.java
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
import particleSystem.equations.WhirlWind;
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;


/**
 * This class represents the Tornado magic in the game. A Tornado is a strong
 * version of the wind magic.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Tornado extends PowerMagic {
	
	public static final String[] SHORT_INFO = {"Powerful wind magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_TORNADO};
	private static final int[] DELAYS = {0};
	
	/**
	 * This method sets the element to wind.
	 */
	@Override
	protected void setElement() {
		element = WIND_ELEMENT;
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
				"Gemini, Libra and Aquarius forged their immense power into",
				"this card. When this power is set free, the tornado will blow away",
				"even foes that stand fast, especially those hiding behind earth."};
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
		return Tornado.getStaticAnimation(info);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setValue(AnimSettings.SIZE, .18f);
		settings.setValue(AnimSettings.SPEED, 2f);
		
		settings.setVector(AnimSettings.SOURCE, new Vector3f(0, -2, -6));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, 3, -6));

		float period = .225f;
		float radius = .25f;
		
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Y_GREATER_TARGET_Y);
		settings.setValue(AnimSettings.COLOR, WIND_ELEMENT);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .04f);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);

		Vector3f source = settings.getVector(AnimSettings.SOURCE);
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(0, .002f, 0));
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .03f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .01f);
		settings.setValue(AnimSettings.NR_PARTICLES, 1500);
		float total = ParticleSystem.calcTotalTime(settings);
		WhirlWind wave = new WhirlWind(period, radius, 0, source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);

		wave = new WhirlWind(period, radius, (float) Math.PI, source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);
		
		period = .225f * 3;
		radius = .2f;

		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE);
		settings.setValue(AnimSettings.SIZE, .07f);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .03f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .01f);
		settings.setValue(AnimSettings.NR_PARTICLES, 25);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * 3f);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.STONE);
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, -.05f, 0));
		
		total = ParticleSystem.calcTotalTime(settings);
		
		wave = new WhirlWind(period, radius, (float) 0, source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(0, new ParticleSystem(settings), 0);
		
		wave = new WhirlWind(period, radius, (float) (Math.PI) / 2, source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(0, new ParticleSystem(settings), 0);

		wave = new WhirlWind(period, radius, (float) (Math.PI), source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(0, new ParticleSystem(settings), 0);

		wave = new WhirlWind(period, radius, (float) (3*Math.PI) / 2, source, true, total);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(0, new ParticleSystem(settings, info.getEnemy()), 0);
		return psp;
	}
}
