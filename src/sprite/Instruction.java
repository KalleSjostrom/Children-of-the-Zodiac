/*
 * Classname: Instruction.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package sprite;

import info.Values;

/**
 * Objects of this class is a instruction for a animated object like
 * a villager. Where it should go, if it should stand still and so on.
 * 
 * @author     Kalle Sjöström
 * @version    0.7.0 - 13 May 2008
 */
public class Instruction {

	public static final int SLOWEST = 0;
	public static final int SLOW = 1;
	public static final int FAST = 2;
	public static final int FASTEST = 3;
	
	private static final float[] SPEED = 
		new float[]{.03f, .05f, .07f, .1f, .12f};
	private static final float[] TIME_MODIFICATOR = 
		new float[]{.4f, .6f, .8f, 1, 1.2f, 1.4f};
	
	private float tempDist;
	private float speed = .05f;
	private int distance;
	private int inDir;
	private int inExtraDir;
	private int speedIndex;
	private boolean moving;
	private boolean dialog = false;

	/**
	 * Creates the instruction which is used during a dialog in the village
	 * story mode.
	 * 
	 * @param dir the direction of the villager.
	 */
	public Instruction(int dir) {
		inDir = dir;
		dialog = true;
		moving = false;
	}

	/**
	 * Constructs a new instruction with the given values.
	 * The direction parameter is taken as a string. This is because there
	 * can be multiple directions. The string "12" consist of "1" = right
	 * and "2" = down, so this direction is south east.
	 * The arguments 11, 22, 13 and so on is not a valid direction, there are 
	 * only n, nw, w, sw, s, se, e, ne and north.
	 * 
	 * @param dir the direction of the villager.
	 * @param standStill true if the villager should stand still.
	 * @param dist the distance to travel,
	 * (or time if the villager stands still).
	 * @param speed the speed.
	 */
	public Instruction(
			String dir, boolean standStill, int dist, int speed) {
		if (dir.length() > 1) {
			inDir = Integer.parseInt(dir.substring(0, 1));
			inExtraDir = Integer.parseInt(dir.substring(1));
		} else {
			inDir = Integer.parseInt(dir);
			inExtraDir = -1;
		}
		moving = !standStill;
		distance = dist;
		speedIndex = Math.abs(speed);
		this.speed = (speed < 0 ? -1 : 1) * SPEED[speedIndex];
		reset();
	}

	/**
	 * This method changes the given time so that the animation that follows
	 * this instruction moves slower or faster. This, to make sure that the
	 * villager also moves the legs faster when running.
	 * 
	 * @param elapsedTime the time to modify.
	 * @return the modified time.
	 */
	public int modifyTime(int elapsedTime) {
		return modifyTime(elapsedTime, speedIndex);
	}

	/**
	 * This method changes the given time so that the animation that follows
	 * this instruction moves slower or faster. This, to make sure that the
	 * villager also moves the legs faster when running.
	 * 
	 * @param elapsedTime the time to modify.
	 * @param speed the speed to modify after, can be either of the values in
	 * this class: .SLOWEST, .SLOW, .FAST, .FASTEST. 
	 * @return the modified time.
	 */
	public static int modifyTime(float elapsedTime, int speed) {
		return Math.round(TIME_MODIFICATOR[speed] * elapsedTime);
	}

	/**
	 * Resets the instruction.
	 */
	public void reset() {
		tempDist = distance;
	}

	/**
	 * Gets the direction stored in this instruction.
	 * 
	 * @return the direction.
	 */
	public int getDirection() {
		return inDir;
	}

	/**
	 * Gets the extra direction stored in this instruction.
	 * The extra direction is used to store an additional direction
	 * so that it is possible to walk both left and up for example, which 
	 * will result in a north west diagonal movement.
	 * 
	 * @return the extra direction.
	 */
	public int getExtraDirection() {
		return inExtraDir;
	}

	/**
	 * Gets the speed stored in this instruction.
	 * 
	 * @return the speed.
	 */
	public float getSpeed() {
		return speed;
	}

	/**
	 * Checks if this instruction is to move.
	 * 
	 * @return true if the instruction is to move.
	 */
	public boolean isMoving() {
		return moving;
	}

	/**
	 * Checks if this instruction is a dialog.
	 * 
	 * @return true if the instruction is a dialog.
	 */
	public boolean isDialog() {
		return dialog;
	}

	/**
	 * Decrements the temporary distance.
	 */
	public void decrementDistance() {
		tempDist -= Math.abs(speed) * Values.LOGIC_INTERVAL;
	}

	/**
	 * Gets the distance left to walk.
	 * 
	 * @return the distance left to walk.
	 */
	public float getDistanceLeft() {
		return tempDist;
	}

	/**
	 * Gets the distance to walk.
	 * 
	 * @return the distance to walk.
	 */
	public int getDistance() {
		return distance;
	}

	public void resetDistance() {
		tempDist = 0;
	}
}
