/*
 * Classname: Wind.java
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
import particleSystem.equations.CircularWave;
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;


/**
 * This class represents the Wind magic in the game. The Wind magic 
 * is a basic magic with wind attribute.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Wind extends Magic {

	public static final String[] SHORT_INFO = {"Wind magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_WIND, SoundMap.MAGICS_WIND, SoundMap.MAGICS_WIND};
	private static final int[] DELAYS = {500, 200, 200};
	
	/**
	 * This method sets the element to fire.
	 */
	protected void setElement() {
		element = WIND_ELEMENT;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"Even a slow breeze will turn into a full-blown gale when releasing the power",
				"of this card. Wind is one of natures most mighty forces, ", 
				"which could deal immense damage to defenses made of earth."};
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
		info.setLevel(getLevel());
		return Wind.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
//		int level = new Random().nextInt(3) + 1;
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings def = AnimationSettingsFactory.getDefault();
		def.getVector(AnimSettings.SOURCE).z = 0;
		def.setValue(AnimSettings.SIZE, .13f);
		def.setValue(AnimSettings.SPEED, 15f);
		if (info.isOnEnemy()) {
			def.getVector(AnimSettings.TARGET).z = -14;
			def.getVector(AnimSettings.SOURCE).y = -1.7f;
		} else {
			Vector3f source = info.getEnemy().getTempSource();
			def.setVector(AnimSettings.TARGET, new Vector3f(0, -.5f, 0));
			def.setVector(AnimSettings.SOURCE,  source == null ? new Vector3f(0, 0, -7) : source);
			def.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
		}
		float period = .225f * 3;
		float radius = .25f;
		
		int color = WIND_ELEMENT;
		
		AnimSettings settings = AnimationSettingsFactory.getCircleWave(def, color, 0);
		
		Card.setSourceTargetVectorToLength(14, settings);

		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(0, .001f, 0));
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .03f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .01f);
		settings.setValue(AnimSettings.NR_PARTICLES, 600);
		
		CircularWave wave = new CircularWave(period, radius, 0, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		
		wave = new CircularWave(period, radius, (float) Math.PI / 2, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new CircularWave(period, radius, (float) Math.PI, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new CircularWave(period, radius, 3 * (float) Math.PI / 2f, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 0);
		if (info.getLevel() == 1) {
			return psp;
		}
		
		radius = .5f;
		settings.setValue(AnimSettings.NR_PARTICLES, 1000);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .07f);
		
		wave = new CircularWave(period, radius, 0, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 200);
		
		wave = new CircularWave(period, radius, (float) Math.PI / 2, true);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 200);
		
		wave = new CircularWave(period, radius, (float) Math.PI, true);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 200);
		
		wave = new CircularWave(period, radius, 3 * (float) Math.PI / 2f, true);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 200);
		
		if (info.getLevel() == 2) {
			return psp;
		}
		
		radius = .75f;
		settings.setValue(AnimSettings.NR_PARTICLES, 1500);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .03f);
		
		wave = new CircularWave(period, radius, 0, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 400);
		
		wave = new CircularWave(period, radius, (float) Math.PI / 2, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 400);
		
		wave = new CircularWave(period, radius, (float) Math.PI, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 400);
		
		wave = new CircularWave(period, radius, 3 * (float) Math.PI / 2f, false);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		psp.add(new ParticleSystem(settings), 400);

		return psp;
	}
}
