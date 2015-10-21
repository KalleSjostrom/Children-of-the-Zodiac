/*
 * Classname: Creature3D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Object2D;
import graphics.Utils3D;
import info.Values;

import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;

import battle.bars.ProgressBar;
import cards.AbstractCard;
import character.Creature;

import com.jogamp.opengl.util.texture.Texture;
import com.jogamp.opengl.util.texture.TextureData;
import com.jogamp.opengl.util.texture.awt.AWTTextureIO;

/**
 * This is an abstraction of the creatures presented in 3D. It draws
 * information about the creature, such as life, progress, and maybe
 * an image of the creature.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 19 June 2008
 */
public abstract class Creature3D extends Object2D {
	
	protected static final float SCALE = 1.1f;
	private static final float NOT_IN_TURN_ALPHA = .75f;
	
	private static final int WIDTH = 100 * 3;
	private static final int HEIGHT = 55 * 3;
	
	/**
	 * The creature to wrap into this Object2D compatible creature.  
	 */
	protected Creature creature;

	private ProgressBar progressBar;
	private Texture tex;
	private TextureData data;
	private BufferedImage textImage;
	
	private float textWidth;
	private float textHeight;
	private float side;
	private float alpha = .7f;
	private boolean mustUpdateText = true;
	protected boolean criticalHit;
	private boolean support;

	/**
	 * Creates a new creature on the given side with information from
	 * the given creature.
	 * 
	 * @param side the side on which to put the creature3D. (ProgressBar.LEFT, .RIGHT)
	 * @param c the character to wrap.
	 */
	public Creature3D(float side, Creature c) {
		super(1);
		this.side = side;
		progressBar = new ProgressBar(side);
		creature = c;
	}

	/**
	 * Creates the coordinates for the creature.
	 */
	protected void createCoords() {
		createCoordList(4);
		float x = 0;
		createCoordFor(0, width, 0, X);
		createCoordFor(0, height, 0, Y);
		createCoordFor(0, 0, 0, Z);
		
		x += (side == ProgressBar.LEFT ? .22f : -.75f);
		float y = (side == ProgressBar.LEFT ? .37f : .11f);
		createCoordFor(x, x + textWidth, 1, X);
		createCoordFor(y, y + textHeight, 1, Y);
		createCoordFor(0, 0, 1, Z);
		
		x = -.12f;
		y = -.09f;
		createCoordFor(x, x + .1f, 2, X);
		createCoordFor(y, y + .1f, 2, Y);
		createCoordFor(0, 0, 2, Z);
		
		x = side == ProgressBar.LEFT ? .52f : -0.14f; //-.17f;
		y = side == ProgressBar.LEFT ? .140f : .035f;
		createCoordFor(x, x + .1f, 3, X);
		createCoordFor(y, y + .1f, 3, Y);
		createCoordFor(0, 0, 3, Z);
	}

	/**
	 * Initiates the drawing in 3D space.
	 * 
	 * @param gl the GL object to initiate the drawings on.
	 */
	public void initDraw(Graphics g) {
		createTexture(g);
		createCoords();
		progressBar.initDraw(g);
		initCreature(g);
	}
	
	public void setSupport(boolean support) {
		this.support = support;
	}

	/**
	 * This method does to actual drawing of the creature. It calls
	 * the draw list in the super class and updates and draws the meters.
	 * 
	 * @param g the Graphics object to draw to.
	 * @param supportMode 
	 */
	public void draw(float dt, Graphics g) {
		
		if (creature.isActive() && creature.isAlive()) {
			alpha = .7f;
		} else {
			if (!support) {
				g.setColor(NOT_IN_TURN_ALPHA);
				alpha = .2f;
			} else {
				alpha = .7f;
			}
		}
		drawImage(g);
		progressBar.update(creature.getProgress());
		progressBar.draw(g, alpha, creature.getSpeedMode());
		
		if (mustUpdateText) {
			updateTexture(g);
			mustUpdateText = false;
		}
		g.push();
		g.translate(.13f, -.15f, 0);
		g.scale(.45f);
		Utils3D.draw3D(g, tex, coordList[1]);
		g.pop();
		drawElements(g);
		drawBoosts(g);
	}
	
	/**
	 * Sets the time that this character will be hidden (not drawn).
	 * 
	 * @param hideTime the amount of time to hide the character.
	 * @param criticalHit true if the enemy has hit a critical hit and the 
	 * red screen should be drawn when the character is hidden.
	 */
	public void setHideTimer(final int hideTime, boolean criticalHit) {
		hide(hideTime);
		this.criticalHit = criticalHit;
	}

	/**
	 * Draws the elements of the creature if it has one. This will draw
	 * both the defensive and offensive element.
	 * 
	 * @param g the GL object to use when rendering.
	 */
	private void drawElements(Graphics g) {
		int element = creature.getElement();
		if (element != AbstractCard.NO_ELEMENT) {
			Texture t = ImageHandler.getTexture(
					Values.MenuImages + "Elements/" + element + ".png")
					.getTexture();
			t.bind(Graphics.gl);
			g.push();
			g.scale(.65f);
			g.beginQuads();
			Utils3D.draw3D(g, tex.getImageTexCoords(), coordList[3]);
			g.end();
			g.pop();
		}
	}

	/**
	 * Draws the boost icons under the creature, 
	 * if the creature has any boosts. 
	 * 
	 * @param gl the GL object to use when rendering.
	 */
	private static final float DISTANCE_BETWEEN_ICONS = .1f;
	private void drawBoosts(Graphics g) {
		g.push();
		if (creature instanceof character.Enemy) {
			g.scale(.9f);
			g.translate(-.22f, -.05f, 0);
		}
		int[] boosts = creature.getBoosts();
		for (int i = 0; i < boosts.length; i++) {
			if (boosts[i] != 0) {
				int nr = (i + 1) * (boosts[i] == 1 ? 1 : 11);
				Texture t = ImageHandler.getTexture(
						Values.Cards + nr + ".png")
						.getTexture();
				g.translate(DISTANCE_BETWEEN_ICONS, 0, 0);
				Utils3D.draw3D(g, t, coordList[2]);
			}
		}
		g.pop();
	}

	/**
	 * Gets the name of the creature.
	 * 
	 * @return the name of the creature.
	 */
	public String getName() {
		return creature.getName();
	}
	
	public Creature getCreature() {
		return creature;
	}

	/**
	 * Creates the texture where the information can be drawn using java2D.
	 */
	private void createTexture(Graphics g) {
		textImage = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_4BYTE_ABGR);
		textWidth = textImage.getWidth() / 300f;
		textHeight = textImage.getHeight() / 300f;

		data = GameTexture.newTextureData(textImage);
		tex = AWTTextureIO.newTexture(Graphics.gl, data);
		tex.updateImage(Graphics.gl, data);
	}

	/**
	 * This method updates the information texture and calls the drawInfo
	 * to draw the actual information.
	 */
	protected void updateTexture(Graphics g) {
		textImage.getAlphaRaster().setPixels(
				0, 0, WIDTH, HEIGHT, new int[WIDTH * HEIGHT]);
		
		Graphics2D g2d = textImage.createGraphics();
		g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, 
				RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
		
		drawInfo(g2d);
		g2d.dispose();
		tex.updateImage(Graphics.gl, data);
	}

	/**
	 * Gets which alpha value to use when drawing the creature.
	 * When a character has the turn, all the other characters
	 * is faded a bit and this method calculates which alpha value
	 * the creature has.
	 * 
	 * @return the alpha value to use when drawing the creature.
	 */
	public float getAlpha() {
		return creature.isActive() ? 1 : NOT_IN_TURN_ALPHA;
	}
	
	/**
	 * Checks if the wrapped creature is alive or not.
	 * 
	 * @return true if the creature is alive.
	 */
	public boolean isAlive() {
		return creature.isAlive();
	}

	/**
	 * This method is called in the initiating process to give subclasses a
	 * chance to initiate any creature specific graphics.
	 * 
	 * @param g the GL object to initiate the graphics on.
	 */
	protected abstract void initCreature(Graphics g);

	/**
	 * Draws the information about the creature.
	 *  
	 * @param g2D the graphics2D object to draw on.
	 */
	protected abstract void drawInfo(Graphics2D g2D);
	
	/**
	 * This method is called when the creature is drawn. It can be used to draw
	 * anything. It is currently only used by Character3D to draw the character
	 * images.
	 * 
	 * @param gl the GL object to use when rendering.
	 */
	protected abstract void drawImage(Graphics g);
}
