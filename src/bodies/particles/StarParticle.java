package bodies.particles;

import graphics.GameTexture;
import graphics.Graphics;
import settings.ParticleSettings;
import bodies.Vector3f;

import commands.GravityCommand;

public class StarParticle extends Particle {
	
	private static final Vector3f force = new Vector3f(0, GravityCommand.DEFAULT_GRAVITY, 0);

	public StarParticle(ParticleSettings settings) {
		super(settings);
		rgb[0] = (float) (.5 + Math.random() / 2.0);
		rgb[1] = (float) (.5 + Math.random() / 2.0);
		rgb[2] = (float) (.5 + Math.random() / 2.0);
	}
	
	public void update(float elapsedTime) {
		if (Math.random() < .01f) {
		rgb[0] = (float) (.5 + Math.random() / 2.0);
		rgb[1] = (float) (.5 + Math.random() / 2.0);
		rgb[2] = (float) (.5 + Math.random() / 2.0);
		}
	}

	public void draw(Graphics g, GameTexture t, Vector3f pPos) {
		super.draw(g, t, Vector3f.ZERO);
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
		return true;
	}
}
