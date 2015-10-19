/*
 * Classname: ScrollBar.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/07/2008
 */
package battle.bars;

import graphics.Graphics;
import graphics.Utils3D;
import info.Values;

/**
 * This class represents the scroll bar that is used in the deck menu.
 * It should indicate where the player is in his/her deck. 
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 22 July 2008
 */
public class ScrollBar extends ProgressBar {
	
	private boolean loaded = false;
	private float botHeight;

	public ScrollBar() {
		super(4, null);
//		size = Values.REAL_SIZE;
	}
	
	/**
	 * Initiates the drawings of the progress bar. It gets the images
	 * used and creates textures of them.
	 * 
	 * @param g the GL object to initiate the drawings on.
	 */
	public void initDraw(Graphics g) {
		loadTexture(Values.BattleBarImages, "emptyBarLong.png", 0);
		loadTexture(Values.BattleBarImages, "whiteLong.png", 1);
		loadTexture(Values.BattleBarImages, "top.png", 2);
		loadTexture(Values.BattleBarImages, "bottom.png", 3);
		createCoords();
	}
	
	/**
	 * Creates the coordinate list used by the scroll bar.
	 */
	protected void createCoords() {
		createCoordList(4);
		
		float x = -.12f;
		float y = -.76f;
		float z = -2f;
		
		setSize(0, size);

		createCoordFor(x, x + width, 0, X);
		createCoordFor(y, y + height, 0, Y);
		createCoordFor(z, z, 0, Z);
		
		x = -.081f;
		y = .193f;
		z = -2f;
		
		setSize(2, size);

		createCoordFor(x, x + width, 2, X);
		createCoordFor(y, y + height, 2, Y);
		createCoordFor(z, z, 2, Z);
		
		x = -.081f;
		y = -.73f;
		z = -2f;
		
		setSize(3, size);

		createCoordFor(x, x + width, 3, X);
		createCoordFor(y, y + height, 3, Y);
		createCoordFor(z, z, 3, Z);
		botHeight = height;
		
		x = -.12f;
		y = -.73f;
		z = -2f;
		
		setSize(1, size);

		createCoordFor(x, x + width, 1, X);
		createCoordFor(y, y + height, 1, Y);
		createCoordFor(z, z, 1, Z);
	}
	
	/**
	 * This 
	 * 
	 * @param progress the percentage of the deck shown. This will affect the
	 * size of the scroll bar. If there is lots of cards in the deck the 
	 * scroll bar is smaller. This is just like a normal Finder (on mac) or 
	 * any other application using a scroll bar. If there are lots of folders
	 *  and files the scroll bar is smaller. 
	 */
	public void update(double progress) {
		percent = (float) progress;
	}

	/**
	 * Draws the scroll bar on the given graphics. The offset argument is how
	 * much to offset the height of the scroll bar. It should represent where 
	 * the player is in the deck. 
	 * 
	 * It uses gl.glTranslatef(0, -offset * height, 0) to calculate the actual
	 * offset, where height is the height of the scroll bar.
	 * 
	 * @param g the graphics to draw on.
	 * @param offset the amount to offset the height with.
	 */
	public void draw(Graphics g, float offset) {
		if (!loaded) {
			initDraw(g);
			loaded = true;
		}
		draw(g, 0, 0);
		if (percent < 1) {
			g.translate(0, -offset * height, 0);
			Utils3D.draw3DPartY(g, texture[1].getTexture(), coordList[1], percent, height);

			coordList[3][1][0] = (-height * percent) + .194f;
			coordList[3][1][1] = (-(height * percent + botHeight)) + .194f;
			
			Utils3D.draw3D(g, texture[2].getTexture(), coordList[2]);
			Utils3D.draw3D(g, texture[2].getTexture(), coordList[3]);
		}
	}
}
