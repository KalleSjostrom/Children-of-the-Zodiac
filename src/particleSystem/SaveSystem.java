/*
 * Classname: MagicSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.Arrays;

import com.jogamp.opengl.GL2;

import villages.utils.SortingElement;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class represents a system of magic particles. Such as system
 * is used in battle when the player uses fire, ice, earth and so on.
 * It will send out a ball of magic that will explode upon hitting the
 * target.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SaveSystem {
	
	protected static final float[] COLOR = new float[]{1, 1, 1};
	
	private static final int NR_OF_PARTICLES = 2000;
	private boolean hasInited;
	private Texture tex;
	private static final String particleTexture = 
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + "particle.png");
	
	public static float[] pos;
	
	private SaveParticle[] particlesx;
	private SaveParticle[] particlesz;
	
	public SaveSystem(float x, float z) {
		pos = new float[]{x, z};
		SortingElement[] Xlist = new SortingElement[NR_OF_PARTICLES];
		SortingElement[] Zlist = new SortingElement[NR_OF_PARTICLES];
		particlesx = new SaveParticle[NR_OF_PARTICLES];
		particlesz = new SaveParticle[NR_OF_PARTICLES];
		SaveParticle[] particles = new SaveParticle[NR_OF_PARTICLES];
		
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			particles[i] = new SaveParticle();
			Xlist[i] = new SortingElement(particles[i].getPos(0), i);
			Zlist[i] = new SortingElement(particles[i].getPos(2), i);
		}
		Arrays.sort(Xlist);
		Arrays.sort(Zlist);
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			particlesx[i] = particles[Xlist[i].getIndex()];
			particlesz[i] = particles[Zlist[i].getIndex()];
		}
	}
	
	/**
	 * This method updates the system. It checks if the system
	 * has reached its destination and if so, it destroys the
	 * system. 
	 */
	public void update() {
		for (SaveParticle p : particlesx) {
			p.update();
		}
	}

	private void loop(Graphics g, SaveParticle[] particles, int dir) {
		for (SaveParticle p : particles) {
			p.drawParticle(g, dir);
		}
	}

	private void loopBackwards(Graphics g, SaveParticle[] particles, int dir) {
		for (int i = NR_OF_PARTICLES - 1; i >= 0; i--) {
			particles[i].drawParticle(g, dir);
		}
	}
	
	public void draw(Graphics g, int dir) {
		if (!hasInited) {
			tex = ImageHandler.getTexture(particleTexture).getTexture();
			hasInited = true;
		}
		
	
		g.setBlendFunc(GL2.GL_ONE);
		g.setAlphaTestEnabled(true);
		g.setAlphaFunc(0);
		tex.bind(Graphics.gl);
		g.beginQuads();
		if (dir > -135 && dir < -45) { // 0
			loop(g, particlesz, 0);
		} else if (dir > -45 && dir < 45) { // 1
			loopBackwards(g, particlesx, 1);
		} else if (dir > 45 && dir < 135) {
			loopBackwards(g, particlesz, 2);
		} else if (dir > 135 || dir < -135) { // 3
			loop(g, particlesx, 3);
		}
		g.end();
		g.setBlendFunc(GL2.GL_ONE_MINUS_SRC_ALPHA);
		g.setAlphaFunc(.1f);
	}
}