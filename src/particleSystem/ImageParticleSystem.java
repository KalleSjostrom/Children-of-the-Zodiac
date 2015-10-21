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

/**
 * This class contains some common methods for a particle system.
 * A particle system is used to illustrate fire or smoke or
 * something like that.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class ImageParticleSystem extends ParticleSystem {

	private int currentImage = 0;
	private boolean hasStarted = false;
	
	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public ImageParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
	}

	public ImageParticleSystem(AnimSettings settings) {
		super(settings);
	}
	
	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
	}
	
	@Override
	public void start(Graphics g) {}

	@Override
	public void end(Graphics g) {}
	
	@Override
	public void draw(float dt, Graphics g) {
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
				private float fadeSpeed = .05f;
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
					int open = 180;
//					int open = 2300;
					int close = 100;
					Values.sleep(500);
					for (int i = 0; i < 4; i++) {
						currentImage = 1;
						Values.sleep(open);
						currentImage = 2;
						Values.sleep(close);
					}
					currentImage = 1;
					Values.sleep(open);
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
		
		bindTexture(g, currentImage);
		g.beginQuads();
		particles.get(0).drawParticle(g, additiveColoring);
		g.end();
	}
}
