/*
 * Classname: AbstractParticleSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;

import com.jogamp.opengl.GL2;

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
public class SphereParticleSystem extends ParticleSystem {

	/**
	 * Creates a new system that contains of nrOfParticles amount of
	 * particles with the given color. This will set up the movement
	 * vector of the system, the vector that the origin of the system
	 * will follow.
	 * 
	 * @param nrOfParticles the number of particles of the system
	 * @param color the color of the particles.
	 */
	public SphereParticleSystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
	}

	public SphereParticleSystem(AnimSettings settings) {
		super(settings);
	}

	@Override
	public Particle createParticle() {
		return new SphereParticle(super.getColor(), settings, this);
	}

	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		if (destroyed) {
			for (Particle p : particles) {
				p.kill();
			}
		}
	}

	@Override
	public void start(Graphics g) {
		GL2 gl = Graphics.gl2;
		gl.glPushMatrix();
//		g.checkError();
		gl.glPushAttrib(GL2.GL_LIGHTING_BIT);
		gl.glLightfv(GL2.GL_LIGHT2, GL2.GL_POSITION, new float[]{0, 2, 0, 1} , 0);

		gl.glDisable(GL2.GL_TEXTURE_2D);
		gl.glEnable(GL2.GL_LIGHTING);
		gl.glDisable(GL2.GL_LIGHT0);
		gl.glDisable(GL2.GL_LIGHT1);


		gl.glEnable(GL2.GL_LIGHT2);
		float[] zero = new float[]{0, 0, 0, 0};
		float[] one = new float[]{1, 1, 1, 1};
		gl.glLightfv(GL2.GL_LIGHT2, GL2.GL_AMBIENT, zero, 0);
		gl.glLightfv(GL2.GL_LIGHT2, GL2.GL_DIFFUSE, one, 0);
		gl.glLightfv(GL2.GL_LIGHT2, GL2.GL_SPECULAR, one, 0);
		
		float[] dif = new float[]{.2f, 0, .2f, 1};
		gl.glColor4f(0, 0, 0, 1);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_AMBIENT, zero, 0);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_DIFFUSE, dif, 0);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_SPECULAR, one, 0);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_EMISSION, zero, 0);
		gl.glMaterialf(GL2.GL_FRONT, GL2.GL_SHININESS, 100.0f);
	}

	@Override
	public void draw(float dt, Graphics g) {
		for (Particle p : particles) {
			p.drawParticle(g, false);
		}
	}

	@Override
	public void end(Graphics g) {
		GL2 gl = Graphics.gl2;
		gl.glPopAttrib();
		gl.glPopMatrix();
	}
}
