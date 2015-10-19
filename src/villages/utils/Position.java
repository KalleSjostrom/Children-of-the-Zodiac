/*
 * Classname: Position.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

/**
 * This class represents a position that a party member can have.
 * It consist of an x and y value as well as a direction.
 * 
 * @author 		Kalle Sjöström
 * @version     0.7.0 - 13 May 2008
 */
public class Position {

	private float x;
	private float y;
	private int direction;

	/**
	 * Creates a new position with the given parameters.
	 * 
	 * @param x the x value of the position.
	 * @param y the y value of the position.
	 * @param dir the direction.
	 */
	public Position(float x, float y, int dir) {
		this.x = x;
		this.y = y;
		this.direction = dir;
	}

	/**
	 * Gets the position object as an float array.
	 * 
	 * @return the position object as an float array.
	 */
	public float[] getPosAsFloatArray() {
		float[] pos = {y, x};
		return pos;
	}

	/**
	 * Gets the direction of this position.
	 * 
	 * @return the direction.
	 */
	public int getDirection() {
		return direction;
	}

	/**
	 * Gets the y position of this position object.
	 * 
	 * @return the y position.
	 */
	public float getY() {
		return y;
	}

	/**
	 * Gets the x position of this position object.
	 * 
	 * @return the x position.
	 */
	public float getX() {
		return x;
	}
}