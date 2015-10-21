/*
 * Classname: LabyrinthPlayer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import graphics.Graphics;

/**
 * LabyrinthPlayer manages the movement in the labyrinth. It has methods
 * for turning and moving to a given position. It also updates the view
 * so that the screen shows where the player is looking. This results in
 * a first person view.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 24 May 2008.
 */
public class LabyrinthPlayer {
	
	public static final int LEFT_TURN = -1;
	public static final int RIGHT_TURN = 1;
	
	private static final float TURN_SPEED = 2.0f;
	private static final float MOVE_SPEED = 2.0f;
	
	public float[] pos = new float[3];

	private Position position;
	private Camera camera;
	private boolean moving = false;
	private boolean turning = false;
	
	private float turnProgress;
	private float moveProgress;
	
	private float srcAngle;
	private float destAngle;
	private float angle;
	private int dir;
	private float from;
	private float to;
	private Node node;
	private Labyrinth labyrinth;

	/**
	 * Creates a new labyrinth player which manages the position of the player
	 * and the camera view.
	 * 
	 * @param pos the starting position of the player. 
	 */
	public LabyrinthPlayer(Position pos) {
		position = pos;
		turnProgress = 0;
		camera = new Camera();
		camera.updatePosition(position);
	}

	/**
	 * This method initiates the movement to the given position. This method
	 * must be called before the player should start moving. To make the player
	 * move all the way to the given position the player must be updated
	 * with the update() method.
	 * 
	 * @param pos the position to move to.
	 */
	protected void moveTo(Node n, Labyrinth lab) {
		Position pos = n.getPos();
		labyrinth = lab;
		node = n;
		moving = true;
		moveProgress = 0.0f;
		float fromX = position.getX();
		float fromZ = position.getZ();
		float toX = pos.getX();
		float toZ = pos.getZ();
		float xDif = Math.abs(fromX - toX);
		if (xDif > 1) {
			// turnDir = (int) ((toX - fromX) / Math.abs(toX - fromX));
			from = fromX;
			to = toX;
			dir = Position.X;
		} else {
			// turnDir = (int) ((toZ - fromZ) / Math.abs(toZ - fromZ));
			from = fromZ;
			to = toZ;
			dir = Position.Z;
		}
	}

	/**
	 * This method initiates the turning sequence to the given angle. It 
	 * turns the player in the direction of turnDir which is either
	 * left or right. To make the player turn all the way to the given 
	 * angle the player must be updated with the update() method.
	 * 
	 * @param angle the angle to turn to. This means that after the 
	 * turning sequence is done this angle is the angle in which the player
	 * is looking. (measured in degrees).
	 * @param turnDir the direction of the turn. This could be TURN_LEFT 
	 * or TURN_RIGHT.
	 */
	protected void turnYTo(float angle, int turnDir) {
		turning = true;
		turnProgress = 0;
		srcAngle = position.getAngle();
		destAngle = this.angle = angle;

		if (srcAngle < 0 && Math.round(destAngle) == 180) {
			destAngle *= -1;
		} else if (destAngle < 0 && Math.round(srcAngle) == 180) {
			srcAngle *= -1;
		}
	}
	
	private static float slerp(float a, float b, float t) {
		t = 3*t*t - 2*t*t*t;
		return a + (b-a)*t;
	}

	/**
	 * This method updates the player on its way to the specified position. 
	 * To specify a position, the moveTo() method must be called with a 
	 * position object representing where to move the player.
	 * 
	 * @param elapsedTime the amount of time that has passes since this method
	 * was last called. 
	 */
	private void move(float dt) {
		moveProgress += MOVE_SPEED * dt;
		if (moveProgress < 1.0f) {
			float p = slerp(from, to, moveProgress);
			position.setValue(dir, p);
			camera.updatePosition(position);
		} else {
			from = to;
			position.setValue(dir, to);
			camera.updatePosition(position);
			moving = false;
			node.visit();
			node.arrive(labyrinth);
		}
	}
	
	float limit = 24.5f;

	/**
	 * This method updates the player on its way to the specified angle. 
	 * To specify a angle to turn to, the turnTo() method must be called 
	 * with an angle and a direction.
	 * 
	 * @param elapsedTime the amount of time that has passes since this method
	 * was last called. 
	 */
	private void turn(float dt) {
		turnProgress += TURN_SPEED * dt;
		System.out.println(turnProgress);
		if (turnProgress < 1.0f) {
			float angle = slerp(srcAngle, destAngle, turnProgress);
			position.setAngle(angle);
			camera.updatePosition(position);
		} else {
			position.setAngle(angle);
			camera.updatePosition(position);
			turning = false;
		}
	}
	
	public float get() {
		return Math.abs(from - to) / Node.DISTANCE;
	}

	/**
	 * Checks if the player is currently moving.
	 * 
	 * @return true if the player is moving.
	 */
	public boolean isMoving() {
		return moving || turning;
	}
	
	public boolean isMovingForward() {
		return moving;
	}

	/**
	 * This method checks if the player is turning.
	 * 
	 * @return true if the player is turning.
	 */
	protected boolean isTurning() {
		return turning;
	}

	/**
	 * Updates the player. If the isMoving() method returns true, this method
	 * will continue moving the player to the specified location.
	 * 
	 * @param elapsedTime the amount of time that has passes since this method
	 * was last called. 
	 */
	protected void update(float dt) {
		if (turning) {
			turn(dt);
		} else {
			move(dt);
		}
	}

	/**
	 * This method makes the given GL turn the view to the players view.
	 * 
	 * @param g the GL object to turn so that the screen displays 
	 * the players view.
	 */
	protected void lookAt(Graphics g) {
		camera.lookAt(g);
	}

	/**
	 * Gets the direction (angle) of the player.
	 * 
	 * @return the direction that the player is looking in.
	 */
	public int getDirection() {
		return (int) position.getAngle();
	}

	public float[] getLocation() {
		return position.getLocation();
	}
}
