/*
 * Classname: LevelUpBar.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package battle.bars;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

/**
 * This class represents the bar displaying the the current experience relative
 * the limit to the next level. It is used after battle to show the player 
 * how much experiance is missing for a new level up.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 27 Dec 2008
 */
public class LevelUpBar {
	
	private static final String[] bar = new String[]{
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "emptyBar.png"),
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "blueBar.png"),
			ImageHandler.addPermanentlyLoadOnUse(Values.BattleBarImages + "overlay.png")
	};
	private float percent;
	
	/**
	 * Initiates the drawings of the level up bar. It gets the images
	 * used and creates textures of them.
	 * 
	 * @param g the Graphics to draw on.
	 * @param canLevelUp 
	 */
	public void draw(Graphics g, int x, int y, boolean canLevelUp) {
		float p = percent;
		if (!canLevelUp) {
			g.setImageColor(1, 0, 0, 1);
			p = 1;
		}
		g.drawImage(bar[0], x, y, 200, 20, 1, 1);
		g.drawImage(bar[1], x, y, 200, 20, 1, p);
		g.drawImage(bar[2], x, y, 200, 20, 1, p);
		
		g.setColor(1);
	}
	
	public static void draw(Graphics g, int x, int y, float p1, float p2, float scale) {
		g.drawImage(bar[0], x, y, 200, 20, scale, 1);
		g.setColor(1);
		g.drawImage(bar[1], x, y, 200, 20, scale, 0, p1);
		g.setColor(0, 1, 0, 1);
		g.drawImage(bar[1], x, y, 200, 20, scale, p1, p2);
		g.setColor(1);
		g.drawImage(bar[2], x, y, 200, 20, scale, 0, p2);
		
		g.setColor(1);
	}
	
	/**
	 * Updates the level up bar with the given progress. The given number
	 * ranges from 0 to 1 and is to be seen as percent.
	 * 
	 * @param progress the progress to be shown with this level up bar.
	 */
	public void update(float progress) {
		percent = progress;
	}
}
