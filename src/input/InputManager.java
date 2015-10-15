/*
 * Classname: InputManager.java
 * 
 * Version information: 0.7.0
 *
 * Date: 17/05/2008
 */
package input;

import input.GameAction.GameActions;

import java.util.ArrayList;
import java.util.Iterator;

import organizer.GameMode;

/**
 * This abstract class is an abstraction of an input manager. It manages
 * input in some for, like key board or game pads. It basically contains
 * a list of game actions and a method for mapping them to certain key
 * codes.
 *
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 17 May 2008
 */
public abstract class InputManager {

	protected static final int NORMAL = 0;
	protected static final int CHEATING = 1;
	protected GameAction[] keyActions;
	protected int mode = NORMAL;
	protected StringBuffer cheat = new StringBuffer();
	protected int value = 0; 

	/**
	 * Maps the given game action to the given key code.
	 * The key code is used as index in the list of key actions.
	 * 
	 * @param gameAction the game action to map.
	 * @param keyCode the key code to map the game action to.
	 */
	public void mapToKey(GameAction gameAction, int keyCode) {
		keyActions[keyCode] = gameAction;
	}
	
	public abstract void reset();

	/**
	 * Resets all the game actions in the list.
	 */
	public void resetAllGameActions() {
		for (int i = 0; i < keyActions.length; i++) {
			if (keyActions[i] != null) {
				keyActions[i].reset();
			}
		}
	}
	
	/**
	 * Checks the special button select has been pressed. 
	 * This is specially handled because it activates the cheater.
	 * 
	 * @return true if the select button has been pressed (Space).
	 */
	public boolean hasSelectDownBeenPressed() {
		boolean pressed = 
			keyActions[GameMode.SELECT].isPressedDontReset() && 
			keyActions[GameMode.DOWN].isPressedDontReset();
		return pressed;
	}
	
	public boolean hasSelectBeenPressed() {
		return keyActions[GameMode.SELECT].isPressed();
	}

	/**
	 * Checks the special button start has been pressed. 
	 * This is specially handled because it pauses the game.
	 * 
	 * @return true if the start button has been pressed (Enter).
	 */
	public boolean hasStartBeenPressed() {
		return keyActions[GameMode.START].isPressed();
	}

	/**
	 * This method gets the list of GameActions associated with the
	 * current input device. 
	 * 
	 * @return the list of GameActions.
	 */
	public GameAction[] getGameActions() {
		return keyActions;
	}

	/**
	 * Creates new GameActions and maps the buttons of the current input 
	 * device to these GameActions.
	 */
	public abstract void createGameActions();
	public abstract boolean isActive();
	public void exit() {}

	public boolean isCheating() {
		return mode == CHEATING;
	}
	
	public String getCheat() {
		return cheat.toString();
	}
		
	public static class InputManagers {
		
		private ArrayList<InputManager> managers = new ArrayList<InputManager>();

		public void addInputManager(InputManager man) {
			managers.add(man);
		}
		
		public boolean hasStartBeenPressed() {
			boolean startPressed = false;
			for (InputManager im : managers) {
				startPressed = startPressed || im.hasStartBeenPressed();
			}
			return startPressed;
		}
		
		public boolean hasSelectDownBeenPressed() {
			boolean selectPressed = false;
			for (InputManager im : managers) {
				selectPressed = selectPressed || im.hasSelectDownBeenPressed();
			}
			return selectPressed;
		}
		
		public boolean hasSelectBeenPressed() {
			boolean selectPressed = false;
			for (InputManager im : managers) {
				selectPressed = selectPressed || im.hasSelectBeenPressed();
			}
			return selectPressed;
		}

		public void createGameActions() {
			for (InputManager im : managers) {
				im.createGameActions();
			}
		}
		
		public GameActions[] getGameActions() {
			GameActions[] gas = new GameActions[GameMode.NUMBER_OF_BUTTONS];
			for (InputManager im : managers) {
				GameAction[] g = im.getGameActions();
				for (int i = 0; i < GameMode.NUMBER_OF_BUTTONS; i++) {
					GameActions ga = gas[i];
					if (ga == null) {
						ga = new GameActions();
						gas[i] = ga;
					}
					ga.addGameAction(g[i]);
				}
			}
			return gas;
		}

		public void resetAllGameActions() {
			for (InputManager im : managers) {
				im.resetAllGameActions();
			}
		}

		public void reset() {
			for (InputManager im : managers) {
				if (im instanceof InputGamePadManager) {
					((InputGamePadManager) im).reset();
				}
			}
		}

		public boolean connectionLost() {
			boolean isActive = true;
			for (InputManager im : managers) {
				isActive = isActive && im.isActive();
			}
			return !isActive;
		}

		public void disconnectGamePad() {
			Iterator<InputManager> it = managers.iterator();
			while (it.hasNext()) {
				InputManager im = it.next();
				if (im instanceof InputGamePadManager) {
					it.remove();
				}
			}
		}
		
		public void exit() {
			Iterator<InputManager> it = managers.iterator();
			while (it.hasNext()) {
				InputManager im = it.next();
				im.exit();
			}
		}

		public boolean isKeyBoardManager() {
			boolean found = false;
			for (int i = 0; i < managers.size() && !found; i++) {
				found = managers.get(i) instanceof InputKeyBoardManager;
			}
			return found;
		}
		
		public boolean isGamePadManager() {
			boolean found = false;
			for (int i = 0; i < managers.size() && !found; i++) {
				found = managers.get(i) instanceof InputGamePadManager;
			}
			return found;
		}
	}
}
