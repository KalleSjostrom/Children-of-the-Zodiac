/*
 * Classname: MagicSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package weather;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.ArrayList;
import java.util.Arrays;

import com.jogamp.opengl.GL2;

import labyrinth.LabyrinthPlayer;
import villages.utils.SortingElement;

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
public abstract class WeatherSystem {
	
	private final int NR_OF_PARTICLES = getNumberOfParticles();
	private final String particleTexture = 
		ImageHandler.addPermanentlyLoadNow(
				Values.ParticleSystemsImages + getTextureName());
	
	private WeatherParticle[] particlesx;
	private WeatherParticle[] particlesz;
	private Texture tex;
	private boolean hasInited;
	private float[] force = getForce();
	private ArrayList<WeatherParticle> list = new ArrayList<WeatherParticle>();
	
	public WeatherSystem() {
		SortingElement[] x = new SortingElement[NR_OF_PARTICLES];
		SortingElement[] z = new SortingElement[NR_OF_PARTICLES];
		particlesx = new WeatherParticle[NR_OF_PARTICLES];
		particlesz = new WeatherParticle[NR_OF_PARTICLES];
		WeatherParticle[] particles = new WeatherParticle[NR_OF_PARTICLES];
		
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			particles[i] = getParticle();
			x[i] = new SortingElement(particles[i].pos[0], i);
			z[i] = new SortingElement(particles[i].pos[2], i);
		}
		Arrays.sort(x);
		Arrays.sort(z);
		for (int i = 0; i < NR_OF_PARTICLES; i++) {
			particlesx[i] = particles[x[i].getIndex()];
			particlesz[i] = particles[z[i].getIndex()];
		}
	}
	

	/**
	 * This method updates the system. It checks if the system
	 * has reached its destination and if so, it destroys the
	 * system. 
	 */
	public void update() {
		for (WeatherParticle p : particlesx) {
			p.update(force);
		}
	}
	
	public void draw(Graphics g, LabyrinthPlayer player, boolean front) {
		if (!hasInited) {
			tex = ImageHandler.getTexture(particleTexture).getTexture();
			hasInited = true;
		}
		g.setBlendFunc(GL2.GL_ONE);
		setup(g);
		tex.bind(g.getGL());
		g.beginQuads();
		if (!front) {
			int dir = Values.angleToDirection2(player.getDirection());
			switch (dir) {
			case 0 : loop(g, particlesz, player); break;
			case 1 : loopBackwards(g, particlesx, player); break;
			case 2 : loopBackwards(g, particlesz, player); break;
			case 3 : loop(g, particlesx, player); break;
			}
		} else {
			for (WeatherParticle p : list) {
				p.drawParticle(
						g, player.getDirection(), player.getLocation(), player.isMoving(), true);
			}
		}
		g.end();

		g.setBlendFunc(GL2.GL_ONE_MINUS_SRC_ALPHA);
		g.setAlphaFunc(.1f);
	}
	
	private void loop(Graphics g, WeatherParticle[] particles, LabyrinthPlayer player) {
		list.clear();
		for (WeatherParticle p : particles) {
			if (p.drawParticle(
					g, player.getDirection(), player.getLocation(), player.isMoving(), false)) {
				list.add(p);
			}
		}
	}
	
	private void loopBackwards(Graphics g, WeatherParticle[] particles, LabyrinthPlayer player) {
		list.clear();
		for (int i = NR_OF_PARTICLES - 1; i >= 0; i--) {
			if (particles[i].drawParticle(
					g, player.getDirection(), player.getLocation(), player.isMoving(), false)) {
				list.add(particles[i]);
			}
		}
	}

	protected void setup(Graphics g) {
		// Override to implement effect.
	}
	
	protected abstract int getNumberOfParticles();
	protected abstract String getTextureName();
	protected abstract WeatherParticle getParticle();
	protected abstract float[] getForce();
}