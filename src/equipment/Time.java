/*
 * Classname: Time.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import organizer.GameCore;

/**
 * This class represents a clock which counts the minutes and hours 
 * that the player has played. 
 * 
 * @author 		Kalle Sjšstršm 
 * @version		0.7.0 - 25 Jan 2008
 */
public class Time {

	private int hours;
	private int min;
	private boolean updated;

	/**
	 * Creates a new clock with the initial values set to the given time.
	 * 
	 * @param hour the initial hour count.
	 * @param min the initial minute count.
	 */
	public Time(int hour, int min) {
		hours = hour;
		this.min = min;

		new Thread("Game Clock") {
			public void run() {
				boolean running = true;
				while(running) {
					int i = 60;
					while(i > 0) {
						try {
							Thread.sleep(1000);
						} catch(Exception e) {
							e.printStackTrace();
						}
						if (!GameCore.isPaused()) {
							i--;
						}
					}
					update();
				}
			}
		}.start();
	}

	/**
	 * Updates the clock
	 */
	public void update() {
		min++;
		if (min == 60) {
			min = 0;
			hours++;
		}
		updated = true;
	}

	/**
	 * Gets the current hour count.
	 * 
	 * @return the hours.
	 */
	public String getHours() {
		return getTime(hours);
	}

	/**
	 * Gets the current minute count.
	 * 
	 * @return the minute.
	 */
	public String getMin() {
		return getTime(min);
	}
	
	/**
	 * Gets the string representation of the given time. If the given time is
	 * less than 10, the string returned will be "0" + the given time. If it is
	 * 
	 * @param time the time to get the string representation for.
	 * @return the time as a string.
	 */
	public static String getTime(int time) {
		StringBuffer h = new StringBuffer();
		h.append(time < 10 ? "0" + time : time);
		return h.toString();
	}

	/**
	 * Gets the the time as a string. The format is hours minutes or 15 40.
	 * 
	 * @return the time as a string.
	 */
	public String toString() {
		return getHours() + " " + getMin();
	}

	/**
	 * This method checks if the clock has been updated. If the clock has been
	 * updated, this method will return false the second time it is called on 
	 * two consecutive calls.
	 * 
	 * @return true if the time needs to be updated.
	 */
	public boolean hasChanged() {
		boolean u = updated;
		updated = false;
		return u;
	}
}
