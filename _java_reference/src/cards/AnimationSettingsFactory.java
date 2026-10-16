package cards;

import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleValues;
import particleSystem.drawable.SwordBackground;
import particleSystem.equations.CircularWave;
import settings.AnimSettings;
import bodies.Vector3f;

public class AnimationSettingsFactory {
	
	public static final int DEFAULT = 0;
	public static final int WAVE = 1;

	public static AnimSettings getDefault() {
		AnimSettings settings = new AnimSettings();
		settings.setValue(AnimSettings.SIZE, .2f);
		settings.setValue(AnimSettings.SYSTEM_MASS, 1);
		settings.setValue(AnimSettings.MASS_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.SIZE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.LIFE_MULTIPLIER, 1);
		settings.setValue(AnimSettings.PARTICLE_MASS, .01f);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_LESS_TARGET_Z);
		settings.setValue(AnimSettings.SPEED, 3);
		settings.setValue(AnimSettings.NR_PARTICLES, 400);
		settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT);
		settings.setVector(AnimSettings.SOURCE, new Vector3f((float)(Math.random()-.5f)*2, -1, 0));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, -.5f, -6));
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .02f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .02f);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEFAULT_EMITTER_TYPE);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.1f, .1f, .1f));
		settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 0);
		settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, false);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 50);
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DESTROYED);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .01f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .006f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 1f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, .05f);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, 0);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, -.01f, 0));
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
//		settings.setVector(AnimSettings.COLLISION_VECTOR, null);
		
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		return settings;
	}
	
	public static AnimSettings getDefaultNoFade() {
		AnimSettings settings = getDefault();
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		return settings;
	}
	
	public static AnimSettings getDefaultSword() {
		AnimSettings settings = new AnimSettings();
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DEAD);
		settings.setValue(AnimSettings.SIZE, .1f);
		settings.setValue(AnimSettings.SYSTEM_MASS, 1);
		settings.setValue(AnimSettings.LIFE_MULTIPLIER, 1);
		settings.setValue(AnimSettings.PARTICLE_MASS, .01f);
		settings.setValue(AnimSettings.SPEED, 8);
		settings.setValue(AnimSettings.NR_PARTICLES, 1000);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_GRAY);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.CHECK_DISTANCE);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setVector(AnimSettings.SOURCE, new Vector3f(-.5f, .5f, -4));
		settings.setVector(AnimSettings.TARGET, new Vector3f(.5f, -.5f, -4));
		
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .2f);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
		settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 0);
		settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, false);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .08f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 1f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .02f);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, 0, 0));
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
		SwordBackground sb = new SwordBackground(
				settings.getVector(AnimSettings.SOURCE), settings.getVector(AnimSettings.TARGET));
		settings.setSystemDrawable(AnimSettings.SYSTEM_DRAWABLE, sb);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		return settings;
	}
	
	public static AnimSettings getCircleWave(AnimSettings settings, int color, float phase) {
//		settings.getVector(AnimSettings.SOURCE).y += -5f;
		settings.setValue(AnimSettings.NR_PARTICLES, 150);
		settings.setValue(AnimSettings.COLOR, color);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .15f);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 2);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2);
		
		CircularWave wave = new CircularWave(.6f, .5f, phase, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);

		return settings;
	}
}
