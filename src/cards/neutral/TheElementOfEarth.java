/*
 * Classname: TheElementOfEarth.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.neutral;


/**
 * The element of earth card will change the targets offensive and defensive 
 * element to earth.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class TheElementOfEarth extends Elements {
	
	/**
	 * This method sets the element to earth.
	 */
	@Override
	protected void setElement() {
		element = EARTH_ELEMENT;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	@Override
	protected String[] createTextInfo() {
		return new String[]{
				"Earth can be one's greatest asset or one's greates liability. It",
				"can feed an entire population and yet kill thousands of people in a",
				"tremor. A shelter of earth can keep habitants safe but from Libra?"};
	}
		
	@Override
	protected String getSimpleName() {
		return "EarthElement";
	}
}
