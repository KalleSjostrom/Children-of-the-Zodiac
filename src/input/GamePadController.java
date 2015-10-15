/*
 * Classname: GamePadController.java
 * 
 * Version information: 0.7.0
 *
 * Date: 15/05/2008
 */
package input;

import net.java.games.input.Component;
import net.java.games.input.Controller;

/**
 * This class represents a game pad controller.
 *
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 15 May 2008
 */
public class GamePadController {

	protected static final int NUM_BUTTONS = 16;
	protected static final int NUM_COMPASS_DIRS = 9;

	private Controller controller;
	private Component[] comps;

	private int xIndex;
	private int yIndex;
	private int[] buttonsIdx;
	private boolean[] buttons = new boolean[NUM_BUTTONS];

	/**
	 * Creates a new game pad controller.
	 */
	protected GamePadController() {
		ce = new DefaultControllerEnvironment();
		Controller[] cs = ce.getControllers();
		controller = findGamePad(cs);
		findCompIndices(controller);
	}

	/**
	 * Checks if there are any game pad controllers registered.
	 * 
	 * @return true if there are any game pads registered.
	 */
	static DefaultControllerEnvironment ce;
	static boolean areThereAnyPads;
	
	public static boolean areThereAnyGamePadControllers() {
		boolean changed = false;
		if (ce == null) {
			ce = new DefaultControllerEnvironment();
			changed = true;
		} else {
			changed = ce.check();
		}
		if (changed) {
			Controller[] cs = ce.getControllers();
			Controller controller = findGamePad(cs);
			areThereAnyPads = controller != null;
		}
		return areThereAnyPads;
	}
	
	/**
	 * Search the array of controllers until a suitable game pad
	 * controller is found (i.e. of type GAMEPAD).
	 * 
	 * @param cs the array of controllers.
	 * @return the first game pad controller in the given list.
	 * Null if there are no game pads in the given list.
	 */
	private static Controller findGamePad(Controller[] cs) {
		for (int i = 0; i < cs.length; i++) {
			if (cs[i].getType() == Controller.Type.GAMEPAD ||
					(cs[i].getType() == Controller.Type.STICK)) {
				return cs[i];
			}
		}
		return null;
	}


	/**
	 * Store the indices for the analog sticks axes 
	 * (x, y) and (z, rz), POV hat, and
	 * button components of the controller.
	 * 
	 * @param controller the controller to search in.
	 */
	private void findCompIndices(Controller controller) {
		comps = controller.getComponents();
		xIndex = findCompIndex(comps, Component.Identifier.Axis.X);
		yIndex = findCompIndex(comps, Component.Identifier.Axis.Y);
		findButtons(comps);
	}

	/**
	 * Search through comps[] for id, returning the corresponding 
	 * array index, or -1.
	 * 
	 * @param comps the list of components to search through.
	 * @param id the id of the component to get.
	 * @return the index of the component with the given id.
	 */
	private int findCompIndex(Component[] comps, Component.Identifier id) {
		Component c;
		for (int i = 0; i < comps.length; i++) {
			c = comps[i];
			if ((c.getIdentifier() == id) && !c.isRelative()) {
				return i;
			}
		}
		return -1;
	}

	/**
	 * Search through comps[] for NUM_BUTTONS buttons, storing
	 * their indices in buttonsIdx[]. Ignore excessive buttons.
	 * If there aren't enough buttons, then fill the empty spots in
	 * buttonsIdx[] with -1's.
	 * 
	 * @param comps the list of components.
	 */
	private void findButtons(Component[] comps) {
		buttonsIdx = new int[NUM_BUTTONS];
		int numButtons = 0;
		Component c;

		for (int i = 0; i < comps.length; i++) {
			c = comps[i];
			if (isButton(c)) {
				buttonsIdx[numButtons] = i;
				numButtons++;
			}
		}
		while (numButtons < NUM_BUTTONS) {
			buttonsIdx[numButtons] = -1;
			numButtons++;
		}
	}

	/**
	 * Return true if the component is a digital/absolute button, and
	 * its identifier name ends with "Button" (i.e. the
	 * identifier class is Component.Identifier.Button).
	 *
	 * @param c the component to check
	 * @return true if the component is a button.
	 */
	private boolean isButton(Component c) {
		if (!c.isAnalog() && !c.isRelative()) {
			String className = c.getIdentifier().getClass().getName();
			if (className.endsWith("Button"))
				return true;
		}
		return false;
	}

	/**
	 * Update the component values in the controller.
	 */
	protected boolean poll() {
		return controller.poll();
	}

	/**
	 * Return the (x,y) analog stick compass direction.
	 * 
	 * @return the integer array containing the compass direction of 
	 * the analog stick. 
	 */
	protected int[] getXYStickDir() {
		if ((xIndex == -1) || (yIndex == -1)) {
			return new int[2];
		}
		return getCompassDir(xIndex, yIndex);
	}

	/**
	 * Gets the compass direction as a integer array.
	 *  
	 * @param xA the index of the component that represents the x axis of 
	 * the compass analog stick.
	 * @param yA the index of the component that represents the y axis of 
	 * the compass analog stick.
	 * @return the direction of the analog stick.
	 */
	private int[] getCompassDir(int xA, int yA) {
		float xCoord = comps[xA].getPollData();
		float yCoord = comps[yA].getPollData();
		int xc = Math.round(xCoord);
		int yc = Math.round(yCoord);
		int[] returnDir = {-1, -1};

		if (yc != 0) {
			returnDir[1] = yc + 1;
		}
		if (xc != 0) {
			returnDir[0] = Math.abs(xc - 2);
		}
		return returnDir;
	}

	/**
	 * Return all the buttons in a single array. Each button value is
	 * a boolean.
	 *
	 * @return an array of booleans where each boolean represents if the
	 * button is pressed or not.
	 */
	protected boolean[] getButtons() {
		float value;
		for (int i = 0; i < NUM_BUTTONS; i++) {
			value = comps[buttonsIdx[i]].getPollData();
			buttons[i] = value != 0.0f;
		}
		return buttons;
	}
}