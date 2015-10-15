package bodies.particles;

import settings.ParticleSettings;
import bodies.Vector3f;
import bodies.system.SystemLoader;

import commands.GravityCommand;

public class SmokeParticle extends Particle {
	
	private static final Vector3f force = new Vector3f(0, GravityCommand.DEFAULT_GRAVITY, 0);
	private boolean turned = false;
	private float max;

	public SmokeParticle(ParticleSettings settings) {
		super(settings);
	}
	
	protected void executeCommand(String command, String value) {
		if (command.equals("max")) {
			max = SystemLoader.getValueFromInterval(value);
		}
	}

	@Override
	public Vector3f getDefaultForce() {
		return force.clone().multLocal(getMass());
	}
	
	protected float modifySize(float size) {
//		return (3 * (1 - life) + 1) * 2 * size;
		life = Math.min(life, 1);
		if (!turned) {
			return (1 + life) * size;
		}
		return (1.5f * (max - life) + (1 + max)) * size;
	}

	protected float getFadeValue() {
		return (float) (Math.random() / 200f) + .001f;
	}
	
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		life += fadeValue;
		life += turned ? -fadeValue : 2 * fadeValue;
		if (life >= max) {
			turned = true;
		}
	}
	
	public void reset() {
		super.reset();
		life = .001f;
		turned = false;
	}
	
	@Override
	protected float modifyFadeValue(float fadeValue) {
		if (getParent() != null) {
			Vector3f pPos = getEmitPosition();
//			fadeValue += Math.pow(getPosition().distance(pPos) / 30, 1.2f) / 20000f;
			fadeValue += (getPosition().distance(pPos) / 10000f) * fadeValue; // Math.pow( / 30, 1.2f) / 20000f;
//			fadeValue += getPosition().distanceSquared(pPos) / 10000f;
		}
		return fadeValue;
	}
}
