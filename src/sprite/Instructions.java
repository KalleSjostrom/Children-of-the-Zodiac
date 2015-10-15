/*
 * Classname: Instructions.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package sprite;

import java.util.ArrayList;
import java.util.StringTokenizer;

/**
 * Objects of this class is a instruction for a animated object like
 * a villager. Where it should go, if it should stand still and so on.
 * 
 * @author     Kalle Sjšstršm
 * @version    0.7.0 - 13 May 2008
 */
public class Instructions {

	private ArrayList<Instruction> instructions = new ArrayList<Instruction>();
	public int index = 0;
	
	/**
	 * Creates an empty set of instructions.
	 */
	public Instructions() {
		// Empty default constructor.
	}

	/**
	 * This method implements the parseFile() method in the AbstractMapLoader.
	 * It does nothing. 
	 * 
	 * @param filename the name of the file to parse.
	 */
	protected void parseFile(String filename) {
		// Does nothing
	}

	/**
	 * Adds the given instruction to the list.
	 * 
	 * @param instruction the instruction to add.
	 */
	public void add(Instruction instruction) {
		instructions.add(instruction);
	}

	/**
	 * Gets the instruction with the given index.
	 * 
	 * @param index of the instruction.
	 * @return the instruction with the given index.
	 */
	public Instruction getInstruction(int index) {
		return instructions.get(index);
	}

	/**
	 * Gets the instruction with the current index.
	 * 
	 * @return the instruction at the current index.
	 */
	public Instruction getInstruction() {
		return getInstruction(index);
	}

	/**
	 * Advances the instructions one step.
	 * 
	 * @param reset true if this method should reset the instructions
	 * so that it starts over at the top of the list.
	 * @return true if the list has been reseted.
	 */
	public boolean advanceInstruction(boolean reset) {
		instructions.get(index).reset();
		index++;
		if (index >= instructions.size()) {
			if (reset) {
				index = 0;
			}
			return true;
		}
		return false;
	}

	/**
	 * Resets the instructions.
	 */
	public void reset() {
		getInstruction(index).reset();
		index = 0;
	}

	/**
	 * Checks the instructions. 
	 * 
	 * @param reset true if this method should reset the instructions
	 * so that it starts over at the top of the list.
	 * @return 2, 1 or 0. 2 means that the instructions has been reseted,
	 * 1 means that the current instructions has been changed to the next one,
	 * 0 means that nothing has happened.
	 */
	public int checkInstruction(boolean reset) {
		Instruction i = instructions.get(index);
		if (i.getDistanceLeft() <= 0) {
			return advanceInstruction(reset) ? 2 : 1;
		}
		i.decrementDistance();
		return 0;
	}
	
	/**
	 * This method executes the command sent. This method also takes a 
	 * StringTokenizer with the rest of the information concerning the 
	 * command.
	 * 
	 * @param command the command to execute.
	 * @param tok the StringTokenizer containing additional information.
	 */
	public void executeCommand(String command, StringTokenizer tok) {
		if (command.equals("in")) {
			String angle = tok.nextToken();
			String firstCommand = tok.nextToken();
			if (!firstCommand.equals("dialog")) {
				int distance = Integer.parseInt(firstCommand);
				boolean stopped = Boolean.parseBoolean(tok.nextToken());
				int speed = tok.hasMoreTokens() ? Integer.parseInt(tok.nextToken()) : 1;
				instructions.add(new Instruction(angle, stopped, distance, speed));
			} else {
				instructions.add(new Instruction(Integer.parseInt(angle)));
			}
		} 
	}

	/**
	 * Checks if there are more instructions in this set of instructions.
	 * 
	 * @return true if there are more instructions.
	 */
	public boolean isDone() {
		return index >= instructions.size();
	}

	public void check() {
		int[] test = new int[4];
		for (Instruction i : instructions) {
			test[i.getDirection()] += i.isMoving() ? i.getDistance() : 0;
		}
		if ((test[0] - test[2]) + (test[1] - test[3]) != 0) {
			System.exit(0);
		}
	}
}
