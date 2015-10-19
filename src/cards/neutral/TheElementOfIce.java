/*
 * Classname: TheElementOfIce.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.neutral;


/**
 * The element of ice card will change the targets offensive and defensive 
 * element to ice.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class TheElementOfIce extends Elements {
	
	/**
	 * This method sets the element to ice.
	 */
	@Override
	protected void setElement() {
		element = ICE_ELEMENT;
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
				"Chilly essence of ice can aid the wielder greatly by wrapping its",
				"frozen energy around the weapon and armor. But beware for warm",
				"entities that could devastate this frosty defense."};
	}

	@Override
	protected String getSimpleName() {
		return "IceElement";
	}
}
