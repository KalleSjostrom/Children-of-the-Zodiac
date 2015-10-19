/*
 * Classname: InputGamePadManager.java
 * 
 * Version information: 0.7.0
 *
 * Date: 17/05/2008
 */
package input;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.Timer;

import organizer.GameMode;

/**
 * This class manages the game pad, if any is used. It maps game actions to 
 * keys, polls the game pad and "presses" or "releases" the game actions.
 * It uses the Timer class to poll with delay DELAY, which currently is
 * 40 micro seconds. 
 *
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 17 May 2008
 */
public class InputGamePadManager extends InputManager {

	private GamePadController gpController = new GamePadController();
	private final int NUM_KEY_CODES = 16;
	private final int DELAY = 40;
	private Timer timer;
	private boolean active = true;

	/**
	 * Creates a new game pad manager. It creates the game action list
	 * with 17 buttons total. The game does not use more than this, because
	 * it replicates the PlayStation 2 game pad.
	 */
	public InputGamePadManager() {
		keyActions = new GameAction[NUM_KEY_CODES];
		startPolling();
	}
	
	public void reset() {
		gpController = new GamePadController();
		active = true;
		startPolling();
	}

	/**
	 * This method is called when a key is pressed. The given key code
	 * is used as index in the list of key actions which is created 
	 * in the constructor.
	 * 
	 * @param keyCode the code representing the button.
	 */
	private void keyPressed(int keyCode) {
		GameAction gameAction = keyActions[keyCode];
		if (gameAction != null) {
			gameAction.press();
		}
	}

	/**
	 * This method is called when a key is released. The given key code
	 * is used as index in the list of key actions which is created 
	 * in the constructor.
	 * 
	 * @param keyCode the code representing the button.
	 */
	private void keyReleased(int keyCode) {
		GameAction gameAction = keyActions[keyCode];
		if (gameAction != null) {
			gameAction.release();
		}
	}

	/**
	 * Set up a timer which is activated every DELAY milliseconds
	 * and polls the game pad.
	 */
	private void startPolling() {
		ActionListener poller = new ActionListener() {
			
			public void actionPerformed(ActionEvent e) {
				if (active = gpController.poll()) {
					boolean[] buttons = gpController.getButtons();
					int[] compassDir = gpController.getXYStickDir();
					
					for (int i = 0; i < compassDir.length; i++) {
						buttons[compassDir[i] + GameMode.UP] = 
							compassDir[i] != -1;
					}
					for (int i = 0; i < buttons.length; i++) {
						if (buttons[i]) {
							keyPressed(i);
						} else {
							keyReleased(i);
						}
					}
				} else {
					timer.stop();
				}
			}
		};
		timer = new Timer(DELAY, poller);
		timer.start();
	}
	
	@Override
	public boolean isActive() {
		return active;
	}
	
	/**
	 * This method creates GameMode.NUMBER_OF_BUTTONS number of GameActions
	 * and stores them in the list.
	 */
	public void createGameActions() {
		for (int i = 0; i < GameMode.NUMBER_OF_BUTTONS; i++) {
			keyActions[i] = new GameAction(GameAction.DETECT_INITAL_PRESS_ONLY);
			mapToKey(keyActions[i], i);
		}
	}
}
