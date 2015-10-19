/*
 * Classname: Fadeable.java
 * 
 * Version information: 0.7.0
 *
 * Date: 04/10/2008
 */
package story;

import info.Values;

/**
 * This class contains some method that handles fading of graphics.
 * It is possible to set fade in / out speeds. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 04 Oct 2008
 */
public abstract class Fadeable {
	
	public boolean fadein;
	public boolean fadeout;
	public float fadeValue;
	public float fadeOutSpeed = .03f;
	public float fadeInSpeed = .03f;
	
	/**
	 * Sets the speed of the fade out.
	 * 
	 * @param speed the speed of the fade out.
	 */
	public void setFadeOutSpeed(float speed) {
		fadeOutSpeed = speed;
	}
	
	/**
	 * Sets the speed of the fade in.
	 * 
	 * @param speed the speed of the fade in.
	 */
	protected void setFadeInSpeed(float speed) {
		fadeInSpeed = speed;
	}
	
	/**
	 * Sets the fade in and fade out speed.
	 * 
	 * @param speed the speed of the fade in / out.
	 */
	protected void setFadeSpeed(float speed) {
		fadeOutSpeed = fadeInSpeed = speed;
	}

	protected void updateFadeValue() {
		if (fadein) {
			fadeIn();
		} else if (fadeout) {
			fadeOut();
		}
	}

	protected void fadeIn() {
		if (fadeValue < 1) {
			fadeValue += fadeInSpeed;
		} else {
			fadeValue = 1;
			fadein = false;
		}
	}

	protected void fadeOut() {
		if (fadeValue > 0) {
			fadeValue -= fadeOutSpeed;
		} else {
			fadeValue = 0;
			fadeout = false;
		}
	}
	
	/**
	 * Checks if the given event contains a fade in or fade out. If either of
	 * these exists in the given event, appropriate actions are taken to make
	 * the text fade.
	 *  
	 * @param info the information about the event.
	 */
	protected void checkFade(TimeLineEvent info) {
		if (info.isFade()) {
			float fadeInTime = info.getInfo(TimeLineEvent.FADE_TIME);
			setFadeSpeed((1 / fadeInTime) * Values.INTERVAL); // Update in draw...
			fadein = info.getType() == TimeLineEvent.TYPE_FADE_IN;
			fadeValue = fadein ? 0 : 1;
			fadeout = !fadein;
		} else if (info.getType() == TimeLineEvent.TYPE_NO_FADE) {
			fadein = fadeout = false;
			fadeValue = 1;
		}
	}
}
