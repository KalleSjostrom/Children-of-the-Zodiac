/*
 * Classname: SnowSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package weather;

import graphics.Graphics;

/**
 * This class represents a system of magic particles. Such as system
 * is used in battle when the player uses fire, ice, earth and so on.
 * It will send out a ball of magic that will explode upon hitting the
 * target.
 * 
 * @author		Kalle Sjšstršm
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SnowSystem extends WeatherSystem {
	
	@Override
	protected WeatherParticle getParticle() {
		return new SnowParticle();
	}

	@Override
	protected String getTextureName() {
		return "snowparticle.png";
	}

	@Override
	protected int getNumberOfParticles() {
		return 10000;
	}
	
	@Override
	protected void setup(Graphics g) {
		g.setAlphaTestEnabled(true);
		g.setAlphaFunc(0);
	}
	
	@Override
	protected float[] getForce() {
		return new float[]{0, -.003f, 0};
	}
}