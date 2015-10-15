/*
 * Classname: AnimatedObjects.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

import graphics.Graphics;
import info.Values;
import sprite.Sprite;

/**
 * This class animates the objects in the game. These objects are, 
 * for example, the fountain in the grass village. 
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 13 May 2008
 */
public class AnimatedObjects extends Sprite {

	/**
	 * Creates a animated object with the given name and position.
	 * The name of the object is the prefix name of the image series
	 * that should be animated. For example, the name well would load
	 * grasstown/well1.png, well2.png ... well4.png.
	 * 
	 * @param path the path to the images that should be animated.
	 * @param name the name of the object.
	 * @param pos the position of the object.
	 */
	public AnimatedObjects(String path, String name, int[] pos, int size) {
		this.pos = Values.convertToFloatArray(pos);
		loadImages(Values.VillageImages + path + "/animobj/", name, size);
		move();
	}

	/**
	 * Draws the animated object on the given graphics. It takes the 
	 * position of the background so it can calculate where on the screen 
	 * to draw the object.
	 * 
	 * @param g the graphics to draw on.
	 * @param x the x position of the background.
	 * @param y the y position of the background.
	 */
	public void draw(Graphics g, int x, int y) {
		super.drawAtPosition(g, (int) pos[Values.X] + x, (int) pos[Values.Y] + y);
	}
}