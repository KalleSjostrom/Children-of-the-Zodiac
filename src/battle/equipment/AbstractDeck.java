/*
 * Classname: AbstractDeck.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/06/2008
 */
package battle.equipment;

import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Utils3D;
import info.BattleValues;
import info.Values;

import java.util.ArrayList;

import battle.Hideable;

/**
 * This class is an abstraction of a deck drawn in 3D. It extends hideable
 * which makes the decks possible to hide.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 14 June 2008
 */
public abstract class AbstractDeck extends Hideable {

	/**
	 * The x positions of the eight slots in battle.
	 */
	public static float[] xs = new float[]{-.7f, -.5f, -.3f, -.1f, .1f, .3f, .5f, .7f};
	protected int nrOfSlots;
	protected int selectedCard = -1;

	public static String[] images = new String[3];
	static{
		images[0] = ImageHandler.addPermanentlyLoadNow(
				Values.BattleImages + "transball.png");
		images[1] = ImageHandler.addPermanentlyLoadNow(
				Values.BattleImages + "save.png");
		images[2] = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "hand2.png");
	}

	/**
	 * Creates a new deck object with the given size. The size
	 * represents the number of textures that this object consists of.
	 * 
	 * @param size the maximum number of textures that this object 
	 * can consist of.
	 * @param deckImage the name of the image to use as background 
	 * where the deck should be.
	 * @param slotImage the name of the image to use as slots where
	 * the player can put the card.
	 */
	public AbstractDeck(int size) {
		super(size);
	}
	
	float largeDist = .034f;

	/**
	 * Creates the coordinates for the deck. It uses getY to get the height
	 * of the deck, the x value is gotten from the first xs value.
	 * The object is centered around the position.
	 */
	protected void createCoords(float saveW, float saveH, float handW, float handH) {
		createCoordList(3);
		setPos(BattleValues.DECK_POSITION - .04f, getY());

		setCoords(width, height, 0);
		setCoords(saveW, saveH, 1);
		
		float x = (saveW / 2);
		float y = (saveH / 2);
		float z = -saveW;
		float nx = -x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist;
		float nx2 = x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist;
		nx += .04f;
		nx2 += .04f;
		float ny = -y - .04f;
		float ny2 = y - .04f;

		createCoordFor(nx, nx2, 1, X);
		createCoordFor(ny, ny2, 1, Y);
		createCoordFor(z, z, 1, Z);
		
		x = -.085f;
		y = -.49f;
		z = 0;
		
		createCoordFor(x, x + handW, 2, X);
		createCoordFor(y, y + handH, 2, Y);
		createCoordFor(z, z, 2, Z);
	}
	
	private void setCoords(float w, float h, int i) {
		float x = w / 2;
		float y = h / 2;
		float z = -w;
		float nx = -x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist;
		float nx2 = x + BattleValues.CARD_DISTANCE_BETWEEN + largeDist;

		createCoordFor(nx, nx2, i, X);
		createCoordFor(-y, y, i, Y);
		createCoordFor(z, z, i, Z);
	}

	/**
	 * Initiates the drawing on the given GL object. This method
	 * loads the texture used, and creates the draw list. This
	 * makes it possible to draw the slots by calling the super.draw()
	 * method. This will however only draw the slots, not the cards.
	 * 
	 * @param gl the GL object to initiated the drawings on.
	 */
	public void initDraw(Graphics g) {
		loadTexture(images[0], 0);
		loadTexture(images[1], 1);
		loadTexture(images[2], 2);
		setSize(2, BattleValues.HAND_SCALE);
		float handH = height;
		float handW = width;
		
		setSize(1, BattleValues.CARD_SCALE);
		float saveH = height;
		float saveW = width;
		
		setSize(0, BattleValues.CARD_SCALE);
		
		createCoords(saveW, saveH, handW, handH);
		g.setAlphaFunc(0);

		coordList[1][X][0] = coordList[1][X][0] + nrOfSlots * BattleValues.CARD_DISTANCE_BETWEEN + largeDist;
		coordList[1][X][1] = coordList[1][X][1] + nrOfSlots * BattleValues.CARD_DISTANCE_BETWEEN + largeDist;
	}

	/**
	 * This method draws the slots on the current location.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		translate(g);

		float[][] cl = new float[3][2];
		cl[X][0] = coordList[0][X][0];
		cl[X][1] = coordList[0][X][1];
		cl[Y][0] = coordList[0][Y][0];
		cl[Y][1] = coordList[0][Y][1];
		cl[Z][0] = coordList[0][Z][0];
		cl[Z][1] = coordList[0][Z][1];
		for (int i = 0; i < nrOfSlots; i++) {
			Utils3D.draw3D(g, texture[0].getTexture(), cl);
			cl[X][0] += BattleValues.CARD_DISTANCE_BETWEEN;
			cl[X][1] += BattleValues.CARD_DISTANCE_BETWEEN;
		}
		Utils3D.draw3D(g, texture[1].getTexture(), coordList[1]);
	}

	/**
	 * This method will draw all the cards in the given deck at the given height.
	 * If one of these cards is selected it will be drawn a length units above
	 * the rest.
	 * 
	 * @param gl the GL object to draw the deck on.
	 * @param deck the deck to draw.
	 * @param a the value to add to y if the card is selected.
	 */
	public void drawDeck(Graphics g, ArrayList<GLCard> deck, float a) {
		for (int i = 0; i < deck.size(); i++) {
			if (i == selectedCard) {
				deck.get(i).draw(g, getYtrans() + a);
				int off = Math.max(nrOfSlots - deck.size(), 0);
				drawHand(g, i + off, 0);
			} else {
				deck.get(i).draw(g, getYtrans());
			}
		}
	}

	/**
	 * Draws the pointer hand with the given GL object.
	 * 
	 * @param gl the GL to use when drawing.
	 * @param index the index of the position list that contains 
	 * the position of the hand.
	 * @param offset the offset of the hand in x position.
	 */
	protected void drawHand(Graphics g, int index, float offset) {
		if (visible) {
			g.loadIdentity();
			g.translate(xs[index] + offset + .01f, 0, BattleValues.STANDARD_Z_DEPTH);
			Utils3D.draw3D(g, texture[2].getTexture(), coordList[2]);
		}
	}
	
	/**
	 * Draws only the first card of the given deck.
	 * 
	 * @param gl the GL to draw on.
	 * @param deck the deck whose first card will be drawn.
	 */
	public void drawTopCard(Graphics g, ArrayList<GLCard> deck) {
		if (deck != null && deck.size() > 0) {
			deck.get(0).draw(g, getYtrans());
		}
	}

	/**
	 * Sets the number of slots to the given number.
	 * 
	 * @param nr the number of slots shown for this deck.
	 */
	public void setNrOfSlots(int nr) {
		nrOfSlots = nr - 1;
	}

	/**
	 * This method gets the height of the deck if it is not translated.
	 * 
	 * @return the y value of the deck.
	 */
	protected abstract float getY();
}
