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
import bodies.Vector3f;
import cards.Card;

/**
 * This class contains some common methods for a particle system.
 * A particle system is used to illustrate fire or smoke or
 * something like that.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class EnemySystem extends ParticleSystem {
	
	private Vector3f color = new Vector3f();
	private float time;
	private int colorType;

	public EnemySystem(AnimSettings settings, BattleEnemy enemy) {
		super(settings, enemy);
		colorType = (int) settings.getValue(AnimSettings.COLOR);
		color = new Vector3f(1, 1, 1);
		enemy.cancelColorChange();
	}

	@Override
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		if (!isDestroyed()) {
			time += elapsedTime;
			float theta = (20f * time);
			double t = theta;
			float cos = (float) (Math.cos(t));
			
			switch (colorType) {
			case Card.FIRE_ELEMENT:
				color.y = cos / 3 + .6f; //source.x + cos;
				color.z = cos / 3 + .6f; //source.x + cos;
				break;
			case Card.ICE_ELEMENT:
				color.x = cos / 3 + .6f; //source.x + cos;
				color.y = cos / 3 + .6f; //source.x + cos;
				break;
			case Card.EARTH_ELEMENT:
				color.x = ((cos + 1) / 2) * .3f + .4f;
				color.y = ((cos + 1) / 2) * .18f + .34f;
				color.z = ((cos + 1) / 2) * .1f + .2f;
				break;
			case Card.WIND_ELEMENT:
				color.x = cos / 3 + .6f; //source.x + cos;
				color.z = cos / 3 + .6f; //source.x + cos;
				break;
			}
		}
	}
	
	@Override
	public void start(Graphics g) {}

	@Override
	public void end(Graphics g) {}
	
	@Override
	public void draw(float dt, Graphics g) {
		if (!destroyed) {
			if (getEnemy() != null) {
				BattleEnemy e = getEnemy();
				e.setColor(color);
			} else {
			}
		}
	}
	
	@Override
	public float[] getColor() {
		if (color == null) {
			color = new Vector3f(1, 1, 1);
		}
		return getEnemy().getSourceColor();
	}
}
