/*
 * Classname: AbstractParticleSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import info.Values;

import java.util.Iterator;

import settings.AnimSettings;
import battle.enemy.BattleEnemy;
import bodies.Vector3f;

/**
 * This class contains some common methods for a particle system.
 * A particle system is used to illustrate fire or smoke or
 * something like that.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class FlameParticleSystem extends ParticleSystem {

	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public FlameParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
	}

	public FlameParticleSystem(AnimSettings settings) {
		super(settings);
	}
	
	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
	}

	protected void create(int nrOfParticles, AnimSettings settings) {
		super.create(nrOfParticles, settings);
		// For burning man
		float dt = 1.0f/60.0f;
		for (int i = 0; i < 200; i++) {
			super.update(dt);
			particlesLeft = particlesDestroyed = 0;
			emitter.update(this, dt);
			Iterator<Particle> it = particles.iterator();
			while (it.hasNext()) {
				Particle p = it.next();
				Vector3f g = getGravity();
				if (g != null) {
					Vector3f f = new Vector3f(g);
					f.x = (float) (f.x * (Math.random() - .5f));
					p.addForce(f);
				} else {
					p.addForce(g);
				}
				p.update(dt, this);
				if (!p.isAlive()) {
					it.remove();
					particlePool.push(p);
				}
				particlesLeft += p.isAlive() ? 1 : 0;
				if (!destroyed) {
					particlesDestroyed += p.isDestroyed() ? 1 : 0;
				}
			}
			emitter.update(this, dt);
		}
	}
}
