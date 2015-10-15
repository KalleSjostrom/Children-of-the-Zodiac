/*
 * Classname: SnowSystem.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package battleBacks;

import bodies.Vector3f;


/**
 * This class represents a system of magic particles. Such as system
 * is used in battle when the player uses fire, ice, earth and so on.
 * It will send out a ball of magic that will explode upon hitting the
 * target.
 * 
 * @author		Kalle Sjšstršm
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SnowSystem extends BattleSystem {
	
	private static final Vector3f FORCE = new Vector3f(0, -.003f, 0);
	
	@Override
	protected BattleParticle getParticle() {
		return new SnowParticle();
	}

	@Override
	protected String getTextureName() {
		return "snowparticle.png";
	}

	@Override
	protected int getNumberOfParticles() {
		return 1000;
	}
	
	protected Vector3f getForce() {
		return FORCE;
	}
}