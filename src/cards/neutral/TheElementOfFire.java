/*
 * Classname: TheElementOfFire.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.neutral;


/**
 * The element of fire card will change the targets offensive and defensive 
 * element to fire.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class TheElementOfFire extends Elements {
	
	/**
	 * This method sets the element to fire.
	 */
	@Override
	protected void setElement() {
		element = FIRE_ELEMENT;
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
				"Fire is one of natures own elements that will either aid or hinder",
				"the one who uses it. Fire is not to be tampered with, but for those",
				"who know how to use it, the wind of battle can quickly change."};
	}
	
	@Override
	protected String getSimpleName() {
		return "FireElement";
	}
}
