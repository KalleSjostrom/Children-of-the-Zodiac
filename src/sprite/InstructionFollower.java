/*
 * Classname: InstructionFollower.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/10/2008
 */
package sprite;

import info.Values;

/**
 * This class is a sprite which follows instructions.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 09 Oct 2008
 */
public abstract class InstructionFollower extends Sprite {

	protected Instructions instructions;
	protected Instruction instruction;
	protected boolean storyDialog;
	
	protected Instructions currentInstructions;
	private int destination;
	private boolean start = true;

	/**
	 * Creates a new sprite which will follow instructions.
	 * Examples of such sprites are villagers and actors.
	 */
	public InstructionFollower() {
		instructions = new Instructions();
		currentInstructions = instructions;
	}

	/**
	 * Creates a new sprite which will follow instructions. Examples of such 
	 * sprites are villagers and actors. The instructions is gotten from the
	 * file with the given name and path.
	 * 
	 * @param path the path to the file containing the instructions.
	 * @param filename the name of the file containing the instructions.
	 */
	/*
	public InstructionFollower(String path, String filename) {
		instructions = new Instructions(path, filename);
		currentInstructions = instructions;
		instruction = currentInstructions.getInstruction(0);
	}
	*/

	/**
	 * This method updates this instruction follower.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since the last
	 * call to this method.
	 */
	public void update(int elapsedTime) {
		super.update(instruction.modifyTime(elapsedTime));
	}

	/**
	 * Sets the current instruction from the list of instructions
	 * with the given index. This will overwrite the current instruction
	 * with the new one with the given index.
	 * 
	 * @param index the index of the instruction to load.
	 */
	protected void setInstructions(int index) {
		instruction = currentInstructions.getInstruction(index);
		setAttributes(false);
	}

	/**
	 * Checks the instructions for any changes.
	 * 
	 * @param reset true if the instructions should be reseted.
	 */
	protected void checkInstructions(boolean reset) {
		if (currentInstructions.isDone()) {
			if (start) {
				currentInstructions = instructions;
				start = false;
			}
			return;
		}
		int ans = currentInstructions.checkInstruction(reset);
		switch (ans) {
		case 1 : 
			setAttributes(true); 
			break;
		case 2 : 
			if (reset) {
				setAttributes(true);
			}
			break;
		}
	}

	/**
	 * This method resets the instruction follower so that the sprite will
	 * move according to the first written instruction in the file.
	 */
	public void reset() {
		instructions.reset();
		currentInstructions = instructions;
		setAttributes(true);
	}

	/**
	 * Sets the attributes in the current instruction.
	 * 
	 * @param setInstructions true if this method should set the instructions
	 * before setting the attributes, or use the attributes in the 
	 * current instruction.
	 */
	private void setAttributes(boolean setInstructions) {
		if (setInstructions) {
			instruction = currentInstructions.getInstruction();
		}
		speed = instruction.getSpeed();
		moving = instruction.isMoving();
		direction = instruction.getDirection();
		destination = Math.round(
				pos[direction % 2] + 
				(instruction.getDistance() * Values.DIRECTIONS[direction]));
		setImages();
	}

	/**
	 * This method moves the instruction follower.
	 *  
	 * @param reset true if the instruction follower should be reseted if
	 * the last instruction is done.
	 * @param elapsedTime the amount of time that has elapsed since the last call
	 * to this method.
	 * 
	 * @see #reset()
	 */
	protected void move(boolean reset, float elapsedTime) {
		checkInstructions(reset);
		move(speed * elapsedTime, direction);
		int extra = instruction.getExtraDirection();
		if (extra != -1) {
			move(speed * elapsedTime, extra);
		}
	}

	/**
	 * Moves the instruction follower the given distance in the
	 * given direction.
	 * 
	 * @param distance the distance to move the sprite.
	 * @param direction the direction in which to move the sprite.
	 */
	private void move(float distance, int direction) {
		if (isMoving()) {
			int i = direction % 2;
			if (Math.abs(distance) >= Math.abs(pos[i] - destination)) {
				pos[i] = destination;
				currentInstructions.getInstruction().resetDistance();
			} else {
				pos[i] += distance * Values.DIRECTIONS[direction];
			}
		}
	}
}
