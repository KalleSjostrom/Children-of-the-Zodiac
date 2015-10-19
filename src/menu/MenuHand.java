/*
 * Classname: MenuHand.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package menu;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

/**
 * The MenuHand class represents the hand that is used to display choices
 * in the game. It is normally found in the menus, but also in the battle
 * and dialog questions. The hand can be used to point at anything and 
 * the direction of which the hand is pointing can be set. 
 * It is also possible to hide the hand.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 May 2008
 */
public class MenuHand {
	
	public static final String handRight = 
		ImageHandler.addPermanentlyLoadOnUse(
				Values.MenuImages + "hand1.png");
	public static final String handDown =  
		ImageHandler.addPermanentlyLoadOnUse(
				Values.MenuImages + "hand2.png");
	
	private static final int X = 0;
	private static final int Y = 1;
	
	private String hand = null;
	private int[] pos = new int[2];
	private boolean show = true;
	private boolean dimmed;

	/**
	 * The constructor of MenuHand.
	 * 
	 * @param dir the direction of which the hand should point.
	 */
	public MenuHand(int dir) {
		hand = dir == Values.DOWN ? handDown : handRight;
	}

	/**
	 * Draws the hand on the given graphics if it is not hidden.
	 * 
	 * @param g the graphics 3D in which to draw.
	 */
	public void drawHand(Graphics g) {
		if (show) {
			if (dimmed) {
				g.dim(.3f);
			}
			g.drawImage(hand, pos[X], pos[Y]);
			if (dimmed) {
				g.dim(1);
			}
		}
	}
	
	public void drawHandWithColor(Graphics g) {
		if (show) {
			g.drawImage(hand, pos[X], pos[Y]);
		}
	}

	/**
	 * Sets the visibility of the menu hand.
	 * 
	 * @param show true if the hand should be visible.
	 */
	public void setVisible(boolean show) {
		this.show = show;
	}

	/**
	 * Sets the x position of the menu hand.
	 * 
	 * @param xpos the xpos to set
	 */
	public void setXpos(int xpos) {
		pos[X] = xpos;
	}

	/**
	 * Sets the y position of the menu hand.
	 * 
	 * @param ypos the ypos to set
	 */
	public void setYpos(int ypos) {
		pos[Y] = ypos;
	}

	/**
	 * Gets the y position of the menu hand.
	 * 
	 * @return the y position of the menu hand.
	 */
	public int getYpos() {
		return pos[Y];
	}
	
	public int getXpos() {
		return pos[X];
	}

	/**
	 * Gets the position of the menu hand.
	 * 
	 * @return the position of the menu hand.
	 */
	public int[] getPos() {
		return pos;
	}

	public int getXOffset() {
		return 40;
	}

	public int getYOffset() {
		return 25;
	}

	public void setDimmed(boolean dimmed) {
		this.dimmed = dimmed;
	}
	
	public boolean isDimmed() {
		return dimmed;
	}
}
