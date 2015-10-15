/*
 * Classname: Obstacle.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/02/2008
 */
package villages.utils;

import info.Values;

/**
 * This class represents a obstacle in a village, it has positions and methods for 
 * checking collisions with the obstacle.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 09 Feb 2008
 */
public class Obstacle {

	protected int[] topLeft;
	protected int[] bottomRight;

	/**
	 * The constructor of Obstacle
	 * 
	 * @param tl the position of the top left corner.
	 * @param br the position of the bottom right corner.
	 */
	protected Obstacle(int[] tl, int[] br) {
		topLeft = tl;
		bottomRight = br;
	}

	/**
	 * Checks the players position against the obstacles to 
	 * see if a collision has occurred.
	 * 
	 * @param p the position of the player.
	 * @return true if a collision has occurred.
	 */
	protected boolean checkCollision(float x, float y, int dir) {
		return y >= topLeft[Values.Y] && y <= bottomRight[Values.Y] && 
				x >= topLeft[Values.X] && x <= bottomRight[Values.X];
	}
}

