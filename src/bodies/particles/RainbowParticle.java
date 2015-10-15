package bodies.particles;

import settings.ParticleSettings;
import bodies.Vector3f;

import commands.GravityCommand;

public class RainbowParticle extends Particle {
	
	private static final Vector3f force = 
		new Vector3f(0, GravityCommand.DEFAULT_GRAVITY, 0);
	
	public RainbowParticle(ParticleSettings settings) {
		super(settings);
	}
	
	public void reset() {
		super.reset();
		rgb[0] = (float) Math.random();
		rgb[1] = (float) Math.random();
		rgb[2] = (float) Math.random();
	}

	@Override
	public Vector3f getDefaultForce() {
		return force.clone().multLocal(getMass());
	}

	@Override
	protected float modifyFadeValue(float fadeValue) {
		if (getParent() != null) {
			Vector3f pPos = getEmitPosition();
			fadeValue += Math.pow(getPosition().distanceSquared(pPos) / 1000, 3) / getFadeArg();
		}
		return fadeValue;
	}
}
