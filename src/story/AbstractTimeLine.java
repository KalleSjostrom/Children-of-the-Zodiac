/*
 * Classname: AbstractTimeLine.java
 * 
 * Version information: 0.7.0
 *
 * Date: 04/10/2008
 */
package story;

import java.util.ArrayList;
import java.util.concurrent.Semaphore;

/**
 * This class represents a time line. A time line can be used in story
 * sequences when actors, images, text and so on should be displayed
 * at different times. The time is counted in micro seconds and images
 * and text can be faded.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 04 Oct 2008
 */
public abstract class AbstractTimeLine extends Fadeable {
	
	// RUNNING
	protected static final int DIALOG = 1;
	protected static final int NORMAL = 3; // Running also
	
	// WAITING
	protected static final int WAITING_FOR_INPUT = 0;
	protected static final int WAITING_FOR_ACTORS = 2;
	protected static final int DIALOG_WAITING_FOR_ACTORS = 4;
	
	protected static final int NOT_DONE = 0; 
	protected static final int TIME_LINE_DONE = 1;
	protected static final int INPUT_DONE = 2;
	protected static final int ALL_DONE = 3;

	protected static final int RUNNING = 1;
	
	protected ArrayList<TimeLineEvent> info;
	protected int doneMode = NOT_DONE;
	protected int nextInitTime;
	protected int nextStopTime;
	protected int currentTime;
	
	private Semaphore modeAccess = new Semaphore(1);
	protected int mode = NORMAL;
	private boolean searchingForDialog;
	
	/**
	 * This method updates the time line. The given time is the amount 
	 * of time that has elapsed since this method was last called.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since this
	 * method was last called.
	 */
	public void update(int elapsedTime) {
		if (mode % 2 == RUNNING) {
			if (searchingForDialog) { // SHOULD INIT
				if (currentTime >= nextInitTime) {
					setNextStartTime();
					searchingForDialog = false;
				}
			} else {
				if (currentTime >= nextStopTime) {
					setNextStopTime();
					searchingForDialog = true;
				}
			}
//			if (Math.abs(currentTime - nextInitTime) < elapsedTime) {
//				currentTime = nextInitTime;
//				setNextStartTime();
//			} else if (Math.abs(currentTime - nextStopTime) < elapsedTime) {
//				currentTime = nextStopTime;
//				setNextStopTime();
//			}
			currentTime += elapsedTime;
			if (info.size() > 0) {
				TimeLineEvent tli = info.get(0); 
				while (currentTime >= tli.getTime()) {
					executeCommand(tli);
					info.remove(0);
					if (info.size() > 0) {
						tli = info.get(0);
					} else {
						break;
					}
				}
			}
		}
	}
	
	/**
	 * Sets the given mode as the new mode. This method is fully concurrent
	 * with the help of semaphores.
	 * 
	 * @param newMode the mode to set.
	 */
	public void setMode(int newMode) {
		try {
			modeAccess.acquire();
			mode = newMode;
			modeAccess.release();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Gets the current mode. This method is fully concurrent with the help of
	 * semaphores.
	 * 
	 * @return the current mode.
	 */
	public int getMode() {
		int m = -1000;
		try {
			modeAccess.acquire();
			m = mode;
			modeAccess.release();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		return m;
	}
	
	/**
	 * Compares the given mode with the current one and returns true if they 
	 * are the same. This method is fully concurrent with the help of 
	 * semaphores.
	 * 
	 * @param compareMode the mode to compare the current mode with.
	 * @return true if the given compareMode is the same as the current mode.
	 */
	public boolean compareMode(int compareMode) {
		boolean same = false;
		try {
			modeAccess.acquire();
			same = mode == compareMode;
			modeAccess.release();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		return same;
	}

	/**
	 * This method sets the next initiating time. The next time
	 * that some story element should be initiated.
	 */
	protected abstract void setNextStartTime();
	
	/**
	 * This method sets the next stop time. The stop time
	 * that some story element should be end.
	 */
	protected abstract void setNextStopTime();
	
	/**
	 * Executes the command in the given information. 
	 * 
	 * @param info the information to execute.
	 */
	protected abstract void executeCommand(TimeLineEvent info);
}
