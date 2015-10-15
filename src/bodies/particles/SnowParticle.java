package bodies.particles;

import settings.ParticleSettings;
import bodies.Vector3f;

import commands.GravityCommand;

public class SnowParticle extends Particle {
	
	private static final Vector3f force = new Vector3f(0, GravityCommand.DEFAULT_GRAVITY, 0);
	private int height;

	public SnowParticle(ParticleSettings settings) {
		super(settings);
	}
	
	@Override
	protected void executeCommand(String command, String value) {
		if (command.equals("height")) {
			height = Integer.parseInt(value);
		}
	}

	@Override
	public Vector3f getDefaultForce() {
		return force.clone().multLocal(getMass());
	}

	@Override
	protected float modifyFadeValue(float fadeValue) {
		return 0;
	}
		
	public boolean isAlive() {
		return getPosition().y > -height;
	}
}
