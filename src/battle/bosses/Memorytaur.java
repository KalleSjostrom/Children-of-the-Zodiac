/*
 * Classname: Boss.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle.bosses;

import character.Enemy;

/**
 * This is a special kind of battle enemy and is used when battling a boss.
 * This class is not done, because it is not decided what should happen when
 * battling bosses.
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 21 July 2008
 */
public class Memorytaur extends Boss {

	/**
	 * Creates a new boss from the given enemy.
	 * 
	 * @param enemy the enemy to wrap as a boss.
	 */
	public Memorytaur(Enemy enemy) {
		super(enemy);
	}
	
	public boolean continueBattleMusic() {
		return true;
	}
}
