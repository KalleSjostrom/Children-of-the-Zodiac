/*
 * Classname: ObstacleHandler.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

import info.Values;

import java.util.ArrayList;

/**
 * This class handles the obstacles in a village, it has positions and
 * methods for checking collisions with between obstacles.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 09 Feb 2008
 */
public class ObstacleHandler {
	
	private static final int TOP_LEFT = 0;
	private static final int BOTTOM_RIGHT = 1;
	private static final int WIDTH_HEIGHT = 2;

	private final int[][] boundingLines = new int[2][3];
	private ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();

	/**
	 * Creates a new obstacle handler based on the given information.
	 * 
	 * @param backRes the size of the village background.
	 */
	public ObstacleHandler(int[] backRes) {
		int[] res = Values.ORIGINAL_RESOLUTION; 
		for (int i = 0; i < 2; i++) {
			boundingLines[i][TOP_LEFT] = res[i] / 2;
			boundingLines[i][BOTTOM_RIGHT] = 
				backRes[i] - res[i] / 2;
			boundingLines[i][WIDTH_HEIGHT] = 
				boundingLines[i][BOTTOM_RIGHT] - boundingLines[i][TOP_LEFT];
		}
	}

	/**
	 * An obstacle could be a house or a tree or anything else the player can
	 * bump into. It creates the obstacle, checks which sector it belongs in
	 * and adds the obstacle to that sector. If the obstacle is in another
	 * sector too, it also adds the obstacle to that sector.
	 * 
	 * @param topLeft the integer array containing the position of the 
	 * top left corner of the obstacle.
	 * @param bottomRight the integer array containing the position of the 
	 * bottom right corner of the obstacle.
	 * @param playerHeight the height of the player image.
	 * @param playerWidth the width of the player image.
	 */
	public void addObstacle(int[] topLeft, int[] bottomRight, 
			int playerHeight, int playerWidth) {
		topLeft[Values.Y] -= playerHeight;
		bottomRight[Values.Y] -= 2.8f * playerHeight / 4f;
		topLeft[Values.X] -= 3 * playerWidth / 4f;
		bottomRight[Values.X] -= 0.9f * playerWidth / 4f;
		obstacles.add(new Obstacle(topLeft, bottomRight));
	}

	/**
	 * Checks if the given position is in the middle of the village.
	 * 
	 * @param pos the position to check.
	 * @param index Values.X if the position value should check 
	 * against x values or Values.Y to check against y values.
	 * @return true if the position is in the middle of the village.
	 */
	public boolean isInMiddle(float pos, int index) {
		return pos > boundingLines[index][TOP_LEFT] && 
		pos < boundingLines[index][BOTTOM_RIGHT];
	}

	/**
	 * Gets the backgrounds position.
	 * 
	 * @param pos the position to check.
	 * @param index Values.X if the position value should check 
	 * against x values or Values.Y to check against y values.
	 * @return the position of the background.
	 */
	public int getBackPos(float pos, int index) {
		return (int) (boundingLines[index][TOP_LEFT] - pos);
	}

	/**
	 * Checks if the obstacle represented the given position 
	 * has collided with any of the obstacles.
	 * 
	 * @param pos the position to check against the village obstacles.
	 * @param direction the direction that the object is traveling.
	 * @param velocity the velocity of the player.
	 */
	public boolean hasCollided(float x, float y, int direction) {
		boolean found = false;
		for (int i = 0; i < obstacles.size() && !found; i++) {
			Obstacle o = obstacles.get(i);
			if (o.checkCollision(x, y, direction)) {
				found = true;
			}
		}
		return found;
	}
}
