/*
 * Classname: Position.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/05/2008
 */
package labyrinth;


/**
 * This class stores a player position. It has both a location and also
 * an angle or direction.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 May 2008
 */
public class Position {
	
	public static final int X = 0;
	public static final int Z = 1;

	private float[] location;
	private int[] position;
	private double angle;

	/**
	 * Creates a new Position with the given values.
	 * 
	 * @param x the x value to store in this position.
	 * @param z the z value to store in this position.
	 */
	public Position(int x, int z) {
		position = new int[]{x, z};
		x = x * Node.DISTANCE + Node.DISTANCE / 2;
		z = z * Node.DISTANCE - Node.DISTANCE / 2;
		location = new float[]{x, z};
	}

	/**
	 * Creates a new Position with the given values.
	 * 
	 * @param x the x value to store in this position.
	 * @param z the z value to store in this position.
	 * @param a the angle to store.
	 */
	public Position(float x, float z, double a) {
		location = new float[]{x, z};
		angle = a;
	}

	/**
	 * Gets the x coordinate for this position.
	 * 
	 * @return the x location.
	 */
	public float getX() {
		return location[X];
	}

	/**
	 * Gets the z coordinate for this position.
	 * 
	 * @return the z location.
	 */
	public float getZ() {
		return location[Z];
	}
	
	public float[] getLocation() {
		return location;
	}

	public int getSimpleX() {
		return position[X];
	}
	
	public int getSimpleY() {
		return position[Z];
	}

	/**
	 * Gets the angle for this position.
	 * 
	 * @return the angle.
	 */
	public float getAngle() {
		return (float) angle;
	}

	/**
	 * Gets the x or z coordinate depending on the given axis.
	 * The axis can be Position.X or Position.Z.
	 * 
	 * @param axis the coordinate to get.
	 * @return the axis coordinate of the position. 
	 */
	public float getValue(int axis) {
		return axis == X ? getX() : getZ();
	}

	/**
	 * Sets the x or z coordinate depending on the given axis.
	 * The axis can be Position.X or Position.Z.
	 * 
	 * @param axis the axis of the coordinate to set.
	 * @param value the value to set.
	 */
	public void setValue(int axis, float value) {
		location[axis] = value;
	}

	/**
	 * Sets the angle of the position.
	 * 
	 * @param a the angle to set.
	 */
	public void setAngle(double a) {
		angle = a;
	}
}
