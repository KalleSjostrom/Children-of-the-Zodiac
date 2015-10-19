/*
 * Classname: Boss.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle.bosses;

import graphics.Graphics;
import info.Values;
import character.Enemy;

/**
 * This is a special kind of battle enemy and is used when battling a boss.
 * This class is not done, because it is not decided what should happen when
 * battling bosses.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 21 July 2008
 */
public class Menthu1 extends Boss {

	/**
	 * Creates a new boss from the given enemy.
	 * 
	 * @param enemy the enemy to wrap as a boss.
	 */
	public Menthu1(Enemy enemy) {
		super(enemy);
	}

	public void kill() {
		Graphics.setFadeImage(Values.res + "test.png");
		currentList = 5;
	}
	
	public boolean continueBattleMusic() {
		return true;
	}
}
