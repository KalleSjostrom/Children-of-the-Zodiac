/*
 * Classname: GameAction.java
 * 
 * Version information: 0.7.0
 *
 * Date: 15/05/2008
 */
package input;

import java.util.ArrayList;

/**
 * The GameAction class is an abstract to a user-initiated
 * action, like jumping or moving. GameActions can be mapped
 * to keys or the mouse with the InputManager.
 *
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 15 May 2008
 */
public class GameAction {

	/**
	 * The normal behavior of the GameAction 
	 */
	public static final int NORMAL = 0;
	public static final int DETECT_INITAL_PRESS_ONLY = 1;
	public static final int DETECT_AS_KEY_LISTENER = 2;

	private static final int STATE_RELEASED = 0;
	private static final int STATE_PRESSED = 1;
	private static final int STATE_WAITING_FOR_RELEASE = 2;

	private int behavior;
	private int amount;
	private int state;

	private boolean add;
	private Thread thread;
	private int prevBehavior;

	/**
	 * Create a new GameAction with the specified behavior.
	 * 
	 * @param behavior the input behavior.
	 */
	public GameAction(int behavior) {
		changeBehavior(behavior);
	}

	/**
	 * Changes the behavior to the given behavior.
	 * 
	 * @param behavior the behavior to change to.
	 */
	public void changeBehavior(int behavior) {
		prevBehavior = this.behavior;
		this.behavior = behavior;
		reset();
	}
	
	public void changeBehaviorBack() {
		int temp = this.behavior;
		this.behavior = prevBehavior;
		prevBehavior = temp;
		reset();
	}

	/**
	 * Resets this GameAction so that it appears like it hasn't
	 * been pressed.
	 */
	public void reset() {
		amount = 0;
	}

	/**
	 * Signals that the key was pressed a specified number of times.
	 */
	protected synchronized void press() {
		if (state == STATE_RELEASED) {
			amount++;
			if (behavior == DETECT_AS_KEY_LISTENER) {
				startThread(480);
			}
		}
		if (state != STATE_WAITING_FOR_RELEASE) {
			if (behavior != DETECT_INITAL_PRESS_ONLY) {
				if (behavior == DETECT_AS_KEY_LISTENER && add) {
					amount++;
					add = false;
					startThread(90);
				} else if (behavior == NORMAL) {
					amount++;
				}
			}
			state = STATE_PRESSED;
		}
	}

	/**
	 * Starts a thread which will sleep for the given amount of milliseconds
	 * and then set a flag to true indicating that the given amount 
	 * of time as passed. 
	 * 
	 * @param time the time to sleep before setting the value.
	 */
	private void startThread(final int time) {
		thread  = new Thread() {
			public void run() {
				try {
					Thread.sleep(time);
					add = true;
				} catch (InterruptedException e) {
					// Ignore
				}
			}
		};
		thread.start();
	}

	/**
	 * Signals that the key was released
	 */
	public synchronized void release() {
		state = STATE_RELEASED;
		add = false;
		amount = 0;
		if (thread != null && thread.isAlive()) {
			thread.interrupt();
		}
	}


	/**
	 * Returns whether the key was pressed or not since last checked,
	 * and updates the amount of time it was pressed.
	 * 
	 * @return true if this game action is pressed.
	 */
	public synchronized boolean isPressed() {
		return (getAmount() != 0);
	}

	/**
	 * Returns whether the key was pressed or not since last checked.
	 * 
	 * @return true if this game action is pressed.
	 */
	public synchronized boolean isPressedDontReset() {
		return state != STATE_RELEASED;
	}
	
	/**
	 * Returns whether the key is released.
	 * 
	 * @return true if this game action is released.
	 */
	public synchronized boolean isReleased() {
		return !isPressed();
	}

	/**
	 * For keys, this is the number of times the key was
	 * pressed since it was last checked.
	 * 
	 * @return the amount of times the key was pressed.
	 */
	public synchronized int getAmount() {
		int retVal = amount;
		if (retVal != 0) {
			if (state == STATE_RELEASED) {
				amount = 0;
			} else if (behavior == DETECT_INITAL_PRESS_ONLY) {
				state = STATE_WAITING_FOR_RELEASE;
				amount = 0;
			} else if (behavior == DETECT_AS_KEY_LISTENER) {
				amount--;
			}
		}
		return retVal;
	}
	
	public static class GameActions {
		
		private ArrayList<GameAction> gameActions = new ArrayList<GameAction>();

		public void addGameAction(GameAction ga) {
			gameActions.add(ga);
		}

		public void changeBehavior(int detectionMode) {
			for (GameAction ga : gameActions) {
				ga.changeBehavior(detectionMode);
			}
		}
		
		public void changeBehaviorBack() {
			for (GameAction ga : gameActions) {
				ga.changeBehaviorBack();
			}
		}

		public void release() {
			for (GameAction ga : gameActions) {
				ga.release();
			}
		}
		
		public void reset() {
			for (GameAction ga : gameActions) {
				ga.reset();
			}
		}

		public boolean isPressed() {
			boolean isPressed = false;
			for (GameAction ga : gameActions) {
				isPressed = isPressed || ga.isPressed();
			}
			return isPressed;
		}

		public boolean isPressedDontReset() {
			boolean isPressed = false;
			for (GameAction ga : gameActions) {
				isPressed = isPressed || ga.isPressedDontReset();
			}
			return isPressed;
		}

		public boolean isReleased() {
			boolean isReleased = false;
			for (GameAction ga : gameActions) {
				isReleased = isReleased || ga.isReleased();
			}
			return isReleased;
		}
	}
}
