/*
 * Classname: Horizontal.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import graphics.Graphics;
import info.Values;

import com.jogamp.opengl.GL2;

/**
 * This class stores the location of a node in the labyrinth.
 * A node is one step, and the location is used to draw either the
 * floor or the ceiling in the labyrinth.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 24 May 2008
 */
public class Horizontal {
	
	public static final int STRAIGHT = 0;
	public static final int HOOK = 1;
	public static final int TCROSS = 2;
	public static final int CROSS = 3;
	public static final int END = 4;

	private float[] coord;
	private int direction;
	private int rotation;

	/**
	 * Creates a new storage object and set the location 
	 * to the given values.
	 * 
	 * @param x the x location to store.
	 * @param z the z location to store.
	 */
	public Horizontal(float x, float z) {
		coord = new float[]{x, z};
	}

	/**
	 * Draws a square at the location stored in this object on the given GL
	 * at the given height. It uses the location as the bottom left corner
	 * and then draws the corners of the square in counter clockwise order
	 * with Node.DISTANCE as distance between the corners. The square will
	 * be drawn with the last bound texture. The normal of the square is not
	 * set here, it must be set externally. This is because all the 
	 * floor/ceiling have the same normal and it is sufficient to set it  
	 * before drawing the floor/ceiling.
	 * 
	 * @param gl the GL to draw on.
	 * @param height the height where to draw the square.
	 * @param width the width of the square to draw.
	 * @param direction the direction this horizontal must be to be drawn.
	 * If the given direction does not correspond to the previously set  
	 * direction(set with setStraight, setHook and so on), it will not get 
	 * drawn.
	 */
	public void draw(Graphics g, float height, float width, int direction) {
		float x = coord[0] - 2;
		float z = coord[1] + 2;
		GL2 gl = Graphics.gl2;
		if (this.direction == direction) { 
			if (rotation == Values.UP) {
				gl.glTexCoord2f(0, 1); gl.glVertex3f(x, height, z);
				gl.glTexCoord2f(1, 1); gl.glVertex3f(x + width, height, z);
				gl.glTexCoord2f(1, 0); gl.glVertex3f(x + width, height, z - width);
				gl.glTexCoord2f(0, 0); gl.glVertex3f(x, height, z - width);
			} else if (rotation == Values.RIGHT) {
				gl.glTexCoord2f(0, 0); gl.glVertex3f(x, height, z);
				gl.glTexCoord2f(0, 1); gl.glVertex3f(x + width, height, z);
				gl.glTexCoord2f(1, 1); gl.glVertex3f(x + width, height, z - width);
				gl.glTexCoord2f(1, 0); gl.glVertex3f(x, height, z - width);
			} else if (rotation == Values.DOWN) {
				gl.glTexCoord2f(1, 0); gl.glVertex3f(x, height, z);
				gl.glTexCoord2f(0, 0); gl.glVertex3f(x + width, height, z);
				gl.glTexCoord2f(0, 1); gl.glVertex3f(x + width, height, z - width);
				gl.glTexCoord2f(1, 1); gl.glVertex3f(x, height, z - width);
			} else if (rotation == Values.LEFT) {
				gl.glTexCoord2f(1, 1); gl.glVertex3f(x, height, z);
				gl.glTexCoord2f(1, 0); gl.glVertex3f(x + width, height, z);
				gl.glTexCoord2f(0, 0); gl.glVertex3f(x + width, height, z - width);
				gl.glTexCoord2f(0, 1); gl.glVertex3f(x, height, z - width);
			}
		}
	}

	/**
	 * This method sets the straight texture which goes up to down
	 * or right to left. The given value is the sum of the neighbors 
	 * directions, so up to down is 2 and right to left is 4. This method
	 * just divides this sum with four to get the rotation of the texture.
	 * 
	 * @param sum the sum of the neighbors directions.
	 * @param offset the amount to offset the direction with. This is used 
	 * so that the set direction can be used as index in the texture array
	 * when this horizontal should be drawn.
	 */
	public void setStraight(int sum, int offset) {
		direction = STRAIGHT + offset;
		rotation = sum / 4;
	}

	/**
	 * This method sets the hook texture which goes up to right,
	 * right to down, down to left or left to up. The given value
	 * is the sum of the neighbors directions, so up to right is
	 * 1, right to down is 3 and so on. This method just divides 
	 * this sum with two to get the rotation of the texture.
	 * 
	 * @param sum the sum of the neighbors directions.
	 * @param offset the amount to offset the direction with. This is used 
	 * so that the set direction can be used as index in the texture array
	 * when this horizontal should be drawn.
	 */
	public void setHook(int sum, int offset) {
		direction = HOOK + offset;
		rotation = sum / 2;
	}

	/**
	 * This method sets the T-Cross texture which goes up to right and left,
	 * left to up and down and so on. The given value is the sum of the 
	 * neighbors directions.
	 * 
	 * @param sum the sum of the neighbors directions.
	 * @param offset the amount to offset the direction with. This is used 
	 * so that the set direction can be used as index in the texture array
	 * when this horizontal should be drawn.
	 */
	public void setTCross(int sum, int offset) {
		direction = TCROSS + offset;
		sum += sum == 3 ? 4 : 0;
		rotation = sum - 4;
	}

	/**
	 * This method sets the Cross texture which goes in all directions.
	 * The rotation is set to UP. The given value is the sum of the 
	 * neighbors directions.
	 * 
	 * @param offset the amount to offset the direction with. This is used 
	 * so that the set direction can be used as index in the texture array
	 * when this horizontal should be drawn.
	 */
	public void setCross(int offset) {
		direction = CROSS + offset;
		rotation = Values.UP;
	}
	
	/**
	 * This method sets the End texture which marks a dead end.
	 * The rotation is set to sum. The given value is the sum of the 
	 * neighbors directions.
	 * 
	 * @param sum the sum of the neighbors directions.
	 * @param offset the amount to offset the direction with. This is used 
	 * so that the set direction can be used as index in the texture array
	 * when this horizontal should be drawn.
	 */
	public void setEnd(int sum, int offset) {
		direction = END + offset;
		rotation = sum;
	}

	/**
	 * Gets the direction of the horizontal texture.
	 * The direction is either of Horizontal.STRAIGHT, 
	 * .HOOK, .TCROSS, .CROSS.
	 * 
	 * @return the direction of this Horizontal.
	 */
	public int getDirection() {
		return direction;
	}

	/**
	 * Gets the rotation of the horizontal texture.
	 * The rotation is either of Values.UP, .RIGHT, .DOWN and .LEFT. 
	 * These values corresponds to north, east, south and west.
	 * 
	 * @return the rotation of this Horizontal.
	 */
	public int getRotation() {
		return rotation;
	}
}
