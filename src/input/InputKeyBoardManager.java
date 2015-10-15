/*
 * Classname: InputKeyBoardManager.java
 * 
 * Version information: 0.7.0
 *
 * Date: 17/05/2008
 */
package input;

import factories.Save;

import java.awt.Component;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.util.Iterator;
import java.util.Map;

import java.util.logging.*;
import organizer.Cheater;
import organizer.GameCore;
import organizer.GameMode;
import organizer.Organizer;

/**
 * This class manages the input from the regular key board. It implements
 * the key listener and uses game actions to mark a button as pressed.
 *
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 17 May 2008
 */
public class InputKeyBoardManager extends InputManager implements KeyListener {

	private final int NUM_KEY_CODES = 600;
	
	private static Logger logger = Logger.getLogger("InputKeyBoardManager");

	/**
	 * Creates a new InputManager that listens to input from the
	 * specified component.
	 * 
	 * @param comp the component to listen to.
	 */
	public InputKeyBoardManager(Component comp) {
		comp.addKeyListener(this);
		comp.setFocusTraversalKeysEnabled(false);
		keyActions = new GameAction[NUM_KEY_CODES];
	}

	/**
	 * This method resets all the game actions so that they appear 
	 * to have never been pressed.
	 */
	public void resetAllGameActions() {
		for (int i = 0; i < keyActions.length; i++) {
			if (keyActions[i] != null) {
				keyActions[i].reset();
			}
		}
	}

	/**
	 * Gets the game action from the the given event. If the key event is
	 * not one of the declared game action buttons this method returns null.
	 * 
	 * @param e the key event to convert into a game action.
	 * @return the game action that represents the given key event.
	 */
	private GameAction getKeyAction(KeyEvent e) {
		int keyCode = e.getKeyCode();
		if (keyCode == KeyEvent.VK_M) {
			Map<Thread, StackTraceElement[]> map = Thread.getAllStackTraces();
			Iterator<Thread> it = map.keySet().iterator();
			logger.log(Level.FINE, "------------ New print ------------");
			logger.log(Level.FINE, "Size: " + map.size());
			while (it.hasNext()) {
				Thread key = it.next();
				StackTraceElement[] ste = map.get(key);
				logger.log(Level.FINE, "Thread: " + key.getName());
				for (int i = 0; i < ste.length; i++) {
					logger.log(Level.FINE, "\t" + ste[i]);
				}
			}
		} else if (keyCode == KeyEvent.VK_6) {
			saveEmergency(1);
		} else if (keyCode == KeyEvent.VK_7) {
			saveEmergency(2);
		} else if (keyCode == KeyEvent.VK_8) {
			saveEmergency(3);
		}
		if (keyCode < keyActions.length) {
			return keyActions[keyCode];
		}
		return null;
	}
	
	private void saveEmergency(int nr) {
		GameMode gm = Organizer.getOrganizer().getCurrentMode();
		if (gm != null) {
			Save.getSave().saveGame("E" + nr, gm.getName());
		}
	}

	/**
	 * Presses the game action represented by the given key event. 
	 * I.e. it calls the press() method for the game action.
	 * 
	 * @param e the key event.
	 */
	public void keyPressed(KeyEvent e) {
		if (mode == CHEATING) {
			if (e.getKeyCode() == KeyEvent.VK_BACK_SPACE) {
				cheat.deleteCharAt(cheat.length() - 1);
			} else {
				char c = e.getKeyChar();
				if (Character.isDefined(c) && c != KeyEvent.VK_ENTER) {
					cheat.append(c);
				}	
			}
			if (e.getKeyCode() == KeyEvent.VK_ENTER) {
				Cheater.doCheat(cheat.toString());
				mode = NORMAL;
			} else if (e.getKeyCode() == KeyEvent.VK_ESCAPE) {
				mode = NORMAL;
			} 
		} else {
			if (e.isShiftDown() && e.getKeyCode() == KeyEvent.VK_0) {
				mode = CHEATING;
				cheat = new StringBuffer();
				GameCore.enterCheat();
			}
			if (e.getKeyCode() == KeyEvent.VK_ESCAPE) {
				GameCore.exitGame();
			} else if (e.getKeyCode() == KeyEvent.VK_F) {
				GameCore.setFullScreen();
			}
			GameAction gameAction = getKeyAction(e);
			if (gameAction != null) {
				gameAction.press();
			}
			keyTyped(e);
		}
	}

	/**
	 * Released the game action represented by the given key event. 
	 * I.e. it calls the release() method for the game action.
	 * 
	 * @param e the key event.
	 */
	public void keyReleased(KeyEvent e) {
		GameAction gameAction = getKeyAction(e);
		if (gameAction != null) {
			gameAction.release();
		}
		keyTyped(e);
	}

	/**
	 * Implementation of the method KeyTyped in the KeyListener interface.
	 * It does nothing but consumes the given key event.
	 * 
	 * @param e the key event.
	 */
	public void keyTyped(KeyEvent e) {
		e.consume();
	}

	/**
	 * Create the game actions used in the game. It maps some buttons
	 * on the keyboard, to game specific game actions.
	 */
	public void createGameActions() {
		for (int i = 0; i <= GameMode.NUMBER_OF_BUTTONS; i++) {
			keyActions[i] = new GameAction(
					GameAction.DETECT_INITAL_PRESS_ONLY);
		}
		mapToKey(keyActions[GameMode.UP], KeyEvent.VK_UP);
		mapToKey(keyActions[GameMode.RIGHT], KeyEvent.VK_RIGHT);
		mapToKey(keyActions[GameMode.DOWN], KeyEvent.VK_DOWN);
		mapToKey(keyActions[GameMode.LEFT], KeyEvent.VK_LEFT);
		mapToKey(keyActions[GameMode.TRIANGLE], KeyEvent.VK_W);
		mapToKey(keyActions[GameMode.CIRCLE], KeyEvent.VK_D);
		mapToKey(keyActions[GameMode.CROSS], KeyEvent.VK_S);
		mapToKey(keyActions[GameMode.SQUARE], KeyEvent.VK_A);
		mapToKey(keyActions[GameMode.START], KeyEvent.VK_ENTER);
		mapToKey(keyActions[GameMode.SELECT], KeyEvent.VK_SPACE);
		mapToKey(keyActions[GameMode.R2], KeyEvent.VK_3);
		mapToKey(keyActions[GameMode.R1], KeyEvent.VK_E);
		mapToKey(keyActions[GameMode.L1], KeyEvent.VK_Q);
		mapToKey(keyActions[GameMode.L2], KeyEvent.VK_1);
	}

	@Override
	public boolean isActive() {
		return true;
	}

	@Override
	public void reset() {}
}
