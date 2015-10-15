/*
 * Classname: TimeBar.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/07/2008
 */
package battle.bars;

import graphics.Graphics;

/**
 * This class represents the bar displaying the time the the player has
 * to make a move in battle.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 22 July 2008
 */
public class TimeBar extends ProgressBar {
	
	private float side;

	/**
	 * Creates a new time bar on the given side.
	 * The sides to choose from are ProgressBar.RIGHT, ProgressBar.LEFT.
	 * 
	 * @param side the side to draw this time bar on. 
	 * (ProgressBar.RIGHT or ProgressBar.LEFT.)
	 */
	public TimeBar(float side) {
		super(side);
		this.side = side;
		size = 1 / 400f;
	}
	
	/**
	 * This method creates the coordinates for the progress bar.
	 * Where to draw it.
	 */
	protected void createCoords() {
		createCoordList(1);
		
		float x;
		x = side + .2001f;
		float y = 0;
		float z = 0;

		createCoordFor(x, x + width, 0, X);
		createCoordFor(y, y + height - height / 4, 0, Y);
		createCoordFor(z, z, 0, Z);
	}
	
	/**
	 * Updates the life meter to display the given progress.
	 * The progress should range from 0 to 1 where 1 is 100 % (full bar)
	 * and 0 is 0 % (empty bar).
	 * 
	 * @param progress the progress of this bar.
	 */
	public void update(double progress) {
//		percent = (float) progress;
//		if (percent > .5f) {
//			color[0] = (float) (0.5f - ((percent - 0.5f) * 2) * 0.5);
//			color[1] = .5f;
//			color[2] = 0;
//		} else {
//			color[0] = .5f;
//			color[1] = (percent * 2) * .5f;
//			color[2] = 0;
//		}
	}

	/**
	 * This method draws the time on the screen.
	 * It also rotates the current matrix so that the horizontal time.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.rotate(90, 0, 0, 1);
		super.draw(g, 1, -1);
	}
}
