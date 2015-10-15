/*
 * Classname: Sign.java
 * 
 * Version information: 0.7.0
 *
 * Date: 09/02/2008
 */
package villages.utils;

import info.Values;

import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.Arrays;

/**
 * The sign class represent the signs in the game. A sign is an obstacle 
 * with the possibility of storing text. When a user stands in front of it
 * and presses the cross button, this text will be received if the isInRange
 * method returns true.
 * 
 * @author 		Kalle Sjšstršm.
 * @version 	0.7.0 - 09 Feb 2008 
 *
 */
public class Sign {

	private static final int DEFAULT_WIDTH = 20;
	private String[] text = {"", ""};
	private int[] pos;
	private int c = 0;
	private int width;
	private Object content;
	private ArrayList<Integer> directions;

	/**
	 * Creates a sign at the given position and width.
	 * 
	 * @param x the x position.
	 * @param y the y position.
	 * @param w 
	 * @param y2 
	 */
	public Sign(int x, int y, int w, ArrayList<Integer> dirs) {
		pos = Values.createNormalPoint(x, y);
		directions = dirs;
		width = w == -1 ? DEFAULT_WIDTH : w;
	}
	
	/**
	 * Creates a sign with the given strings and the that will contain the
	 * given content.
	 * 
	 * @param one the first line of text in the message.
	 * @param two the second line of text in the message.
	 * @param content the content found in this sign.
	 */
	public Sign(String one, String two, Object content) {
		text[0] = one;
		text[1] = two == null ? "" : two;
		this.content = content;
	}
	
	/**
	 * Creates an empty sign.
	 */
	public Sign() {
		// Empty constructor.
	}

	/**
	 * Adds a text string to this sign.
	 * 
	 * @param t the text to add.
	 * @return true if the sign is full.
	 */
	public boolean addText(String t) {
		text[c++] = t;
		return c == 2;
	}

	/**
	 * Checks if the given position is in the range of this sign.
	 * The normal use of this method is to call it with the players position
	 * and when the player presses the action button.
	 * 
	 * @param p the position to check.
	 * @param i 
	 * @return true if the position is in the reading range of this sign.
	 */
	public boolean isInRange(float[] p, int dir) {
		boolean isInRange = false;
		if (canBeSeen(dir)) {
			int dist = 
				(int) Math.round(Point2D.distance(p[1], p[0], pos[1], pos[0]));
			isInRange = dist < width;
		}
		return isInRange;
	}

	private boolean canBeSeen(int dir) {
		boolean found = false;
		for (int i = 0; i < directions.size() && !found; i++) {
			found = directions.get(i) == dir;
		}
		return found;
	}

	/**
	 * Gets the array of string that represents the text in the sign.
	 * 
	 * @return the texts in the sing.
	 */
	public String[] getText() {
		return text;
	}
	
	/**
	 * Gets the content of this sign.
	 * 
	 * @return the content of this sign.
	 */
	public Object getContent() {
		return content;
	}
	
	public String toString() {
		return "Sign at pos " + Arrays.toString(pos) + " with text \n\t" + text[0] + "\n\t" + text[1];
	}
}
