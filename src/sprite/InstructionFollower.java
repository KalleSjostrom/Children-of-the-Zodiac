/*
 * Classname: InstructionFollower.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/10/2008
 */
package sprite;

import java.util.ArrayList;

import info.Values;

/**
 * This class is a sprite which follows instructions.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 09 Oct 2008
 */
public abstract class InstructionFollower extends Sprite {

	protected ArrayList<Instruction> instructions = new ArrayList<Instruction>();
	protected Instruction instruction;

	private int destination;
	private int index = 0;

	public void update(float dt) {
		super.update(instruction.modifyTime(dt));
	}
	
	private void setInstruction() {
		instruction = instructions.get(index);
		speed = instruction.speed;
		moving = instruction.moving;
		direction = instruction.direction;
		destination = Math.round(
				pos[direction % 2] + 
				(instruction.distance * Values.DIRECTIONS[direction]));
	}

	protected void setInstructions(int index) {
		this.index = index;
		setInstruction();
	}
	
	public void reset() {
		instructions.get(index).reset();
		index = 0;
		setInstruction();
	}

	protected void move(boolean reset, float dt) {
		if (index < instructions.size()) {
			Instruction i = instructions.get(index);
			if (i.distanceLeft <= 0) {
				instructions.get(index).reset();
				index++;
				if (index >= instructions.size()) {
					if (reset) {
						index = 0;
						setInstruction();
					}
				} else
					setInstruction();
			} else {
				i.decrementDistance(dt);
			}
		}

		move(speed * dt, direction);
		int extra = instruction.extraDirection;
		if (extra != -1) {
			move(speed * dt, extra);
		}
	}
	
	private void move(float distance, int direction) {
		if (moving) {
			int i = direction % 2;
			if (Math.abs(distance) >= Math.abs(pos[i] - destination)) {
				pos[i] = destination;
				instructions.get(index).resetDistance();
			} else {
				pos[i] += distance * Values.DIRECTIONS[direction];
			}
		}
	}
	
	static public class Instruction {

		public static final int SLOWEST = 0;
		public static final int SLOW = 1;
		public static final int FAST = 2;
		public static final int FASTEST = 3;
		
		private static final float[] SPEED = new float[]{.03f, .05f, .07f, .1f, .12f};
		private static final float[] TIME_MODIFICATOR = new float[]{.4f, .6f, .8f, 1, 1.2f, 1.4f};

		public int direction;
		public boolean moving;
		
		private float distanceLeft;
		private float speed = 50.0f;
		private int distance;
		private int extraDirection;
		private int speedIndex;

		public Instruction(int dir) {
			direction = dir;
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
		public Instruction(String dir, boolean standStill, int dist, int speed) {
			if (dir.length() > 1) {
				direction = Integer.parseInt(dir.substring(0, 1));
				extraDirection = Integer.parseInt(dir.substring(1));
			} else {
				direction = Integer.parseInt(dir);
				extraDirection = -1;
			}
			moving = !standStill;
			distance = dist;
			speedIndex = Math.abs(speed);
			this.speed = (speed < 0 ? -1 : 1) * SPEED[speedIndex];
			reset();
		}

		public float modifyTime(float dt) {
			return modifyTime(dt, speedIndex);
		}
		public static float modifyTime(float dt, int speed) {
			return TIME_MODIFICATOR[speed] * dt;
		}
		public void reset() {
			distanceLeft = distance;
		}
		public void decrementDistance(float dt) {
			distanceLeft -= Math.abs(speed) * dt;
		}
		public void resetDistance() {
			distanceLeft = 0;
		}
	}
}
