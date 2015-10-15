/*
 * Classname: MagicSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package battleBacks;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.Arrays;

import com.jogamp.opengl.GL2;

import villages.utils.SortingElement;
import bodies.Vector3f;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class represents a system of magic particles. Such as system
 * is used in battle when the player uses fire, ice, earth and so on.
 * It will send out a ball of magic that will explode upon hitting the
 * target.
 * 
 * @author		Kalle Sj�str�m
 * @version 	0.7.0 - 01 Oct 2008
 */
public abstract class BattleSystem {
	
	private final int NR_OF_PARTICLES = getNumberOfParticles();
	private final String particleTexture = 
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + getTextureName());
	
	private BattleParticle[] particles;
	private Texture tex;
	private boolean hasInited;
	private Vector3f force = getForce();
	
	public BattleSystem() {
		SortingElement[] s = new SortingElement[NR_OF_PARTICLES];
		particles = new BattleParticle[NR_OF_PARTICLES];
		BattleParticle[] temp = new BattleParticle[NR_OF_PARTICLES];
		
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			temp[i] = getParticle();
			s[i] = new SortingElement(temp[i].pos.z, i);
		}
		Arrays.sort(s);
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			particles[i] = temp[s[i].getIndex()];
		}
	}

	/**
	 * This method updates the system. It checks if the system
	 * has reached its destination and if so, it destroys the
	 * system. 
	 */
	public void update() {
		for (BattleParticle p : particles) {
			p.update(force);
		}
	}
	private static final float[] DUMMY_POS = new float[2];
	
	public void draw(Graphics g, boolean front) {
		if (!hasInited) {
			tex = ImageHandler.getTexture(particleTexture).getTexture();
			hasInited = true;
		}
		g.beginBlend(false);
		g.setBlendFunc(GL2.GL_ONE);
		
		tex.bind(g.getGL());
		g.beginQuads();
		for (BattleParticle p : particles) {
			p.drawParticle(
					g, 0, DUMMY_POS, false, false);
		}
		g.end();
		g.endBlend();
	}

	protected void setup(GL2 gl) {
		// Override to implement effect.
	}
	
	protected abstract int getNumberOfParticles();
	protected abstract String getTextureName();
	protected abstract BattleParticle getParticle();
	protected abstract Vector3f getForce();
}