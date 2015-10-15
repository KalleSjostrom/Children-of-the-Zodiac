/*
 * Classname: BattleQueue.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle;

import java.util.ArrayList;

import character.Creature;

/**
 * This a queue in which creatures can be stored. It is used in the battle
 * when a creatures is ready to fight. If more than one creature is ready
 * this queue is used to store these creatures.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 21 July 2008
 */
public class BattleQueue {

	private ArrayList<Creature> queue = new ArrayList<Creature>();

	/**
	 * Gets the first creature in the queue,
	 * returns it and deletes it.
	 * 
	 * @return c the creature whose first in the queue.
	 */
	public Creature dequeue() {
		Creature c = null;
		if (!isEmpty()) {
			c = queue.get(0);
			queue.remove(0);
		}
		return c;
	}

	/**
	 * Enqueues a creature to the queue.
	 * 
	 * @param c the creature.
	 */
	public void enqueue(Creature c) {
		queue.add(c);
	}

	/**
	 * Checks if the queue is empty.
	 * 
	 * @return true if the queue is empty.
	 */
	public boolean isEmpty() {
		return queue.size() == 0;
	}

	/**
	 * This method sets all the creatures in the queue to active
	 * or not active depending on the given value.
	 * 
	 * @param active true if this method should activate the creatures.
	 */
	public void setActive(boolean active) {
		for (int i = 0; i < queue.size(); i++) {
			queue.get(i).setActive(active);
		}
	}
}
