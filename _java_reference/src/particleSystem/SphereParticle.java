/*
 * Classname: AbstractParticle.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;

import com.jogamp.opengl.glu.GLU;
import com.jogamp.opengl.glu.GLUquadric;

import settings.AnimSettings;
import bodies.PointBody;
import bodies.Vector3f;

/**
 * This class contains some common methods for a particle.
 * 
 * @author		Kalle Sj�str�m
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SphereParticle extends Particle {
	
	private static final GLU glu = new GLU();
	private static final GLUquadric quad = glu.gluNewQuadric();
	private boolean alive = true;
	
	/**
	 * Creates a new particle with the given color and gravity.
	 * 
	 * @param color the color of the particle.
	 * @param body 
	 */
	public SphereParticle(float[] color, AnimSettings settings, PointBody body) {
		super(color, settings, body);
	}
	
	@Override
	public boolean isAlive() {
		return alive;
	}
	
	@Override
	public void kill() {
		super.kill();
		alive = false;
	}

	/**
	 * This method draws the particle on the given GL.
	 * 
	 * @param gl the GL to draw on.
	 * @param additiveColoring 
	 */
	@Override
	protected void drawParticle(Graphics g, boolean additiveColoring) {
		Vector3f pos = getPosition();
		if (pos.z >= -6) { // TODO: Change to enemy depth.
			g.translate(pos);
			glu.gluSphere(quad, size, 50, 50);
			g.translateBack(pos);
		}
	}
}
