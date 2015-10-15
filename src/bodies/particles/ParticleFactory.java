package bodies.particles;

import settings.ParticleSettings;
import bodies.Body;

public class ParticleFactory {

	public static final int FIRE_PARTICLE = 0;
	public static final int SMOKE_PARTICLE = 1;
	public static final int RAINBOW_PARTICLE = 3;
	public static final int SNOW_PARTICLE = 5;
	public static final int STAR_PARTICLE = 8;

	public static Body createParticle(int type, ParticleSettings settings) {
		Body b = null;
		switch (type) {
		case FIRE_PARTICLE:
			b = new FireParticle(settings);
			break;
		case SMOKE_PARTICLE:
			b = new SmokeParticle(settings);
			break;
		case SNOW_PARTICLE:
			b = new SnowParticle(settings);
			break;
		case STAR_PARTICLE:
			b = new StarParticle(settings);
			break;
		case RAINBOW_PARTICLE:
			b = new RainbowParticle(settings);
			break;
		default:
			break;
		}
		return b;
	}
}
