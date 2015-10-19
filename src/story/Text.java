/*
 * Classname: Text.java
 * 
 * Version information: 0.7.0
 *
 * Date: 31/01/2008
 */
package story;

import graphics.Graphics;

import java.util.Arrays;

/**
 * This class has information about the text and 
 * the amount of time to display the text.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 31 Jan 2008
 */
public class Text extends Fadeable {

	private String firstLine;
	private String secondLine = "";
	public static final int SIZE = 40;
	private int size = SIZE;
	private int[] pos = new int[2];
	private boolean whisper;
	private int color;

	/**
	 * Constructs a text object from the given values.
	 * 
	 * @param fr the first row of text.
	 * @param sr the second row of text.
	 */
	public Text(String fr, String sr) {
		firstLine = fr;
		secondLine = sr;
	}
	
	/**
	 * Constructs a text object that contains the given first line
	 * and an empty string as the second.
	 * 
	 * @param fl the first line of text.
	 */
	public Text(String fl) {
		firstLine = fl;
	}
	
	public Text() {
		// Empty 
	}
	
	/**
	 * This method sets the given string as the second line.
	 * 
	 * @param s the string to use as second line.
	 */
	public void setSecondLine(String s) {
		secondLine = s;
	}
	
	public void setSize(int size) {
		this.size = size;
	}
	
	public void setColor(int color) {
		this.color = color;
	}

	/**
	 * This method draws the first and second line on the given graphics.
	 * The given alpha value is the transparency of the text.
	 * 
	 * @param g the graphics to draw the text on.
	 * @param alpha the alpha value of the text.
	 */
	public void draw(Graphics g, float alpha) {
		g.setColor(color);
		g.setAlpha(alpha);
		g.setFontSize(whisper ? size - 6 : size);
		g.drawStringCentered(firstLine, pos[1]);
		if (!secondLine.equals("")) {
			g.drawStringCentered(secondLine, pos[1] + 70);
		}
	}
	
	public String toString() {
		return firstLine + " ; " + secondLine + " ; " + Arrays.toString(pos);
	}
	
	/**
	 * Draws the text on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		draw(g, fadeValue);
	}

	/**
	 * Sets the position of the text.
	 * 
	 * @param pos the position to set to.
	 */
	public void setPos(int[] pos) {
		this.pos = pos;
	}

	public void setWhisper(boolean whisper) {
		this.whisper = whisper;
	}
}
