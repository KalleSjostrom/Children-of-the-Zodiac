/*
 * Classname: AbstractParticleSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;
import info.Values;
import settings.AnimSettings;
import battle.enemy.BattleEnemy;
import bodies.Vector3f;

/**
 * This class contains some common methods for a particle system.
 * A particle system is used to illustrate fire or smoke or
 * something like that.
 * 
 * @author		Kalle Sj�str�m
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SlowParticleSystem extends ParticleSystem {

	private boolean hasStarted = false;
	private float hourTheta;
	private float minuteTheta;
	private float fadeSpeed = .05f;
	
	
	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public SlowParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
	}

	public SlowParticleSystem(AnimSettings settings) {
		super(settings);
	}
	
	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		hourTheta += 60f * elapsedTime;
		minuteTheta += 720f * elapsedTime;
	}
	
	@Override
	public void start(Graphics g) {}

	@Override
	public void end(Graphics g) {}

	@Override
	public void draw(Graphics g) {
		if (!hasInited) {
			loadGLTextures();
			hasInited = true;
		}
		if (!hasStarted) {
			hasStarted = true;
			for (Particle p : particles) {
				p.setLife(0.0001f);
			}
			new Thread() {
				@Override
				public void run() {
					boolean fadeingUp = true;
					while (fadeingUp) {
						for (Particle p : particles) {
							p.addLife(fadeSpeed);
							fadeingUp = p.getLife() < .5f;
						}
						Values.sleep(30);
					}
					Values.sleep(750);
					plainDestroy();
					boolean fadeingDown = true;
					fadeSpeed = .025f;
					while (fadeingDown) {
						for (Particle p : particles) {
							p.addLife(-fadeSpeed);
							fadeingDown = p.getLife() > 0;
						}
						Values.sleep(30);
					}
				}
			}.start();
		}
		g.push();
		g.translate(settings.getVector(AnimSettings.SOURCE));
		Particle p = particles.get(0);
		p.setPosition(new Vector3f());
		bindTexture(g, 0);
		g.beginQuads();
		float l = p.getLife();
		p.drawParticle(g, additiveColoring);
		g.end();
		p.setLife(l + .5f);
		g.pop();
		
		g.push();
		g.translate(settings.getVector(AnimSettings.SOURCE));
		
		g.rotate(hourTheta, 0, 0, 1); // For FPS = 60, angle+=2 for FPS = 30
		bindTexture(g, 1);
		g.beginQuads();
		p.drawParticle(g, additiveColoring);
		g.end();
		g.pop();
		
		g.push();
		g.translate(settings.getVector(AnimSettings.SOURCE));
		g.rotate(minuteTheta, 0, 0, 1);
		bindTexture(g, 2);
		g.beginQuads();
		p.drawParticle(g, additiveColoring);
		g.end();
		g.pop();
		
		p.setLife(l);
	}
}
