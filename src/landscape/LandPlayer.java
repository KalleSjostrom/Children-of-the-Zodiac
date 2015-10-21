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
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 12 May 2008
 */
public class LandPlayer extends Sprite {	
	public void init() {
		loadImage(Values.VillageImages + "Characters/", "Kin");
	}
	public void setXandY(int x, int y) {
		pos = Values.createNormalFloatPoint(x, y);
	}
	public void draw(float dt, Graphics g) {
		draw(dt, g, Math.round(pos[Values.X] - width / 2), Math.round(pos[Values.Y] - 9 * height / 10));
	}
}