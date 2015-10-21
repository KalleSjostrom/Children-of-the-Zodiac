/*
 * Classname: ProgressBar.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/07/2008
 */
package battle.bars;

import graphics.Graphics;
import graphics.Object2D;
import graphics.Utils3D;
import info.BattleValues;
import info.Values;

/**
 * This class represents the bar displaying the progress of a creature.
 * It is used in battle to show which creature is about to hit.
 * The idling bar, is another name for it.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 22 July 2008
 */
public class ProgressBar extends Object2D {

	public static final float LEFT = .01f;
	public static final float RIGHT = -.415f;
	
	protected float percent = 1;
	protected float size = 1 / 800f;
	private float[] color;
	
	private static final float LOW = .3137f;
	private static final float HIGH = .9529f;
	
	private static final float[] BLUE = new float[]{LOW, LOW, HIGH};
	private static final float[] GREEN = new float[]{LOW, HIGH, LOW};
	private static final float[] RED = new float[]{HIGH, LOW, LOW};
	private float side;

	/**
	 * Creates a new progress bar on the given side.
	 * The sides to choose from are ProgressBar.RIGHT, ProgressBar.LEFT.
	 * 
	 * @param side the side to draw this progress bar on. 
	 * (ProgressBar.RIGHT or ProgressBar.LEFT.)
	 */
	public ProgressBar(float side) {
		super(3);
		this.side = side;
		color = BLUE;
	}
	
	/**
	 * Creates a bar with neither a specific side nor color. This is used
	 * as a scrolling bar in the deck menu.
	 * 
	 * @param size the size texture array to be used when drawing. 
	 * I.e the number of texture to use.
	 * @param o a dummy parameter to separate this constructor from the one above.
	 */
	public ProgressBar(int size, Object o) {
		super(size);
	}

	/**
	 * This method creates the coordinates for the progress bar.
	 * Where to draw it.
	 */
	protected void createCoords() {
		createCoordList(1);
		
		float x;
		x = side + .215f;
		float y = side == RIGHT ? -.05f : 0;
		float z = 0;

		createCoordFor(x, x + width, 0, X);
		createCoordFor(y, y + height - height / 4, 0, Y);
		createCoordFor(z, z, 0, Z);
	}

	/**
	 * Initiates the drawings of the progress bar. It gets the images
	 * used and creates textures of them.
	 * 
	 * @param gl the GL object to initiate the drawings on.
	 */
	public void initDraw(Graphics g) {
		loadTexture(Values.BattleBarImages, "emptyBar.png", 0);
		loadTexture(Values.BattleBarImages, "white.png", 1);
		loadTexture(Values.BattleBarImages, "overlay.png", 2);
		setSize(0, size);
		createCoords();
	}

	/**
	 * Draws the progress bar with the given alpha value as opacity.
	 * 
	 * @param g the Graphics to draw on.
	 * @param alpha the alpha value to use when drawing. 
	 * 1 = opaque, 0 = transparent.
	 * @param mode the mode of speed. Either BattleValues.HASTE, .SLOW or
	 * anything else for default.
	 */
	public void draw(Graphics g, float alpha, int mode) {
		draw(g, 0, 0);
		switch (mode) {
		case BattleValues.HASTE : 
			g.setColor(GREEN[0], GREEN[1], GREEN[2], alpha);
		break;
		case BattleValues.SLOW : 
			g.setColor(RED[0], RED[1], RED[2], alpha);
		break;
		default :
			g.setColor(color[0], color[1], color[2], alpha);
		}
		Utils3D.draw3DPart(g, texture[1].getTexture(), coordList[0], percent, width);
		g.setColor(1, 1, 1, alpha);
		Utils3D.draw3DPart(g, texture[2].getTexture(), coordList[0], percent, width);
	}
	
	@Override
	public void draw(float dt, Graphics g) {}

	/**
	 * Updates the progress bar with the given progress. The given number
	 * ranges from 0 to 100 and is to be seen as percent.
	 * 
	 * @param progress the progress to be shown with this progress bar.
	 */
	public void update(double progress) {
		percent = (float) progress / 100;
	}
}
