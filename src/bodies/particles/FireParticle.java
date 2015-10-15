package bodies.particles;

import settings.ParticleSettings;
import bodies.Vector3f;

import commands.GravityCommand;

public class FireParticle extends Particle {
	
	private static final Vector3f force = new Vector3f(0, GravityCommand.DEFAULT_GRAVITY, 0);
	
	public FireParticle(ParticleSettings settings) {
		super(settings);
	}

	@Override
	public Vector3f getDefaultForce() {
		return force.clone().multLocal(getMass());
	}

	@Override
	protected float modifyFadeValue(float fadeValue) {
		if (getParent() != null) {
			Vector3f pPos = getEmitPosition();
			fadeValue += Math.pow(getPosition().distanceSquared(pPos) / 300, 3) / getFadeArg();
		}
		return fadeValue;
	}
}
