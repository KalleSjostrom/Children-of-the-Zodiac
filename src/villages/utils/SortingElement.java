/*
 * Classname: SortingElement.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/02/2008
 */
package villages.utils;

/**
 * The private class Element.
 * 
 * An element is just a comparable object for sorting the party members.
 * This way the actual order of the members does not change, just the
 * order of these comparable objects. After these objects is sorted
 * by their yPos values, the index is gotten and used to access the 
 * right party member.
 * 
 * @author 		Kalle Sjšstršm
 * @version     0.7.0 - 09 Feb 2008
 */
public class SortingElement implements Comparable<SortingElement> {

	private float yPos;
	private int index;

	/**
	 * Constructs a new element with the given values.
	 * 
	 * @param y the y value which represents the y position 
	 * of a party member.
	 * @param i the index of the party member with the given y position.
	 */
	public SortingElement(float y, int i) {
		yPos = y;
		index = i;
	}

	/**
	 * Implements the compareTo() method.
	 * 
	 * @param se the SortingElement to compare this to.
	 * @return -1 if this yPos is less than or equal to the given yPos. 
	 * 1 if not.
	 */
	public int compareTo(SortingElement se) {
		return yPos <= se.yPos ? -1 : 1;
	}

	/**
	 * Gets the y position stored in this element.
	 * 
	 * @return the y position stored in this element.
	 */
	public float getYpos() {
		return yPos;
	}

	/**
	 * Gets the index mapped with the y position.
	 * 
	 * @return the index.
	 */
	public int getIndex() {
		return index;
	}

	/**
	 * Sets the y position to the given y value.
	 * 
	 * @param y the y to set.
	 */
	public void setYpos(float y) {
		yPos = y;
	}

	/**
	 * Sets the index to the given value.
	 * 
	 * @param i the index to set.
	 */
	public void setIndex(int i) {
		index = i;
	}
}
