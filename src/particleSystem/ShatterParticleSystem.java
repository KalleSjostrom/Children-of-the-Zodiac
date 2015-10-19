/*
 * Classname: AbstractParticleSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;
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
public class ShatterParticleSystem extends ParticleSystem {

	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public ShatterParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
	}

	public ShatterParticleSystem(AnimSettings settings) {
		super(settings);
	}

	protected Particle createParticle(float[] c, AnimSettings settings) {
		return new Particle(c, settings, this);
	}
	
	@Override
	public void start(Graphics g) {}

	@Override
	public void end(Graphics g) {}
	
	@Override
	public void draw(Graphics g) {
		if (!hasInited) {
			loadGLTextures();
			hasInited  = true;
		}
		
		bindTexture(g, 0);
		g.beginQuads();
		for (Particle p : particles) {
			p.drawParticle(g, additiveColoring);
		}
		g.end();
	}
}
