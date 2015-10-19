/*
 * Classname: Screen.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package battle.resultScreen;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;


/**
 * This class represents a basic screen which results or spoils 
 * can be drawn upon. 
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 27 Dec 2008
 */
public class Screen {

	/**
	 * The background used in the result screens.
	 */
	private static String back = 
		ImageHandler.addPermanentlyLoadNow(
				Values.BattleImages + "resultBack.png");
	private String background;
	private float scale;
	private int bx;
	private int by;
	private float alpha;
	
	public Screen() {
		this(back, 170, 190, 1.1f, .5f);
	}
	
	public Screen(String back, int x, int y, float scale, float alpha) {
		background = back;
		bx = x;
		by = y;
		this.scale = scale;
		this.alpha = alpha;
	}

	public Screen(float alpha) {
		this(back, 170, 190, 1.1f, alpha);
	}

	/**
	 * Draws the background on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawBackground(Graphics g) {
		g.fadeOldSchool(alpha);
		g.setColor(1);
		g.drawImage(background, bx, by, scale);
	}
}
