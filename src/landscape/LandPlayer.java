/*
 * Classname: LandPlayer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/05/2008
 */
package landscape;

import graphics.Graphics;
import info.Values;
import sprite.Sprite;

/**
 * This class represents the player when it is walking around the landscape.
 * It has location and angle, but also all the images and animation.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 12 May 2008
 */
public class LandPlayer extends Sprite {
	
	public void init() {
		loadImages(Values.VillageImages + "Characters/", "Kin");
	}

	/**
	 * Draws the character.
	 * 
	 * @param g the graphics3D to draw on.
	 */
	public void draw(Graphics g) {
		draw(g, Math.round(pos[Values.X] - getWidth() / 2), 
				Math.round(pos[Values.Y] - 9 * getHeight() / 10));
	}
	
	/**
	 * Sets this players x and y position.
	 * 
	 * @param x the x position.
	 * @param y the y position.
	 */
	public void setXandY(int x, int y) {
		pos = Values.createNormalFloatPoint(x, y);
	}

	@Override
	public void draw(Graphics g, int x, int y) {
		super.drawAtPosition(g, x, y);
	}
}