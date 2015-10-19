/*
 * Classname: TheElementOfWind.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.neutral;

/**
 * The element of wind card will change the targets offensive and defensive 
 * element to wind.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class TheElementOfWind extends Elements {
	
	/**
	 * This method sets the element to wind.
	 */
	protected void setElement() {
		element = WIND_ELEMENT;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"Libra and Gemini sought to conseal their powers in this card. To",
				"use it, one must comprehend the dangers of throwing caution into",
				"the wind and trusting it blindly when earth itself starts to tremble."};
	}
	
	protected String getSimpleName() {
		return "WindElement";
	}
}
