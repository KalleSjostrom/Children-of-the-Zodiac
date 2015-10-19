/*
 * Classname: GLCard.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/06/2008
 */
package battle.equipment;

import graphics.Graphics;
import graphics.Utils3D;
import info.BattleValues;
import info.Values;
import cards.Card;

/**
 * This class purpose is to manage the card drawn in 3D when battling. 
 * It draws the ordinary Card object that the player has in his deck in 3D.
 * It therefore has some methods for flipping and moving around the card
 * in a 3D space.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 12 June 2008
 */
public class GLCard extends FlatObj {

	private static final float MOVE_SPEED = BattleValues.CARD_MOVE_SPEED;

	private static final boolean USE_COLOR_BALLS_ON_GRAY_IMAGES = true;
	
	private float xTarget;
	private float yOffset;
	private float k;
	private float m;
	private boolean enabled = true;

	/**
	 * Creates a new GLCard and allocates memory for three textures.
	 * Front, back and in gray scale.
	 */
	public GLCard() {
		super(5);
		xTarget = xPos = BattleValues.DECK_POSITION;
		targetRotation = rotation = BACK;
	}

	/**
	 * This method initializes the graphic of the card, like textures and such.
	 * 
	 * @param gl the GL object to initialize the card on.
	 */
	public void initDraw(Graphics g) {
		loadTexture(card.getImage(0), 0); // Base image
		loadTexture(BattleValues.CARD_BACK, 1);
		loadTexture(card.getGrayImage(0), 2); // Base gray image
		loadTexture(card.getImage(1), 3); // Ball image
		if (USE_COLOR_BALLS_ON_GRAY_IMAGES) {
			loadTexture(card.getImage(1), 4); // Ball image
		} else {
			loadTexture(card.getGrayImage(1), 4); // Ball gray image
		}

		setSize(0, BattleValues.CARD_SCALE);
		createCoords(7);
		
		float w = texture[3].getWidth() * BattleValues.CARD_SCALE;
		float h = texture[3].getHeight() * BattleValues.CARD_SCALE;
		float x = -(w / 2) + 0.1f * w;
		float hx = w / 2 + 0.1f * w;
		
		createCoordFor(x, hx, 2, X);
		createCoordFor(height / 2 - 2.2f * h, height / 2 - 1.2f * h, 2, Y);
		createCoordFor(0.01f, .01f, 2, Z);
		
		float tx = 2.6f * x;
		createCoordFor(tx, tx + w, 3, X);
		copyCoords(3, 2, Y);
		copyCoords(3, 2, Z);
		
		tx = .5f * hx;
		createCoordFor(tx, tx + w, 4, X);
		copyCoords(4, 2, Y);
		copyCoords(4, 2, Z);
		
		tx = 4.2f * x;
		createCoordFor(tx, tx + w, 5, X);
		copyCoords(5, 2, Y);
		copyCoords(5, 2, Z);
		
		tx = 1.4f * hx;
		createCoordFor(tx, tx + w, 6, X);
		copyCoords(6, 2, Y);
		copyCoords(6, 2, Z);
	}
	
	private void makeCardDrawList(Graphics g, int base, int ball) {
		switch (card.getLevel()) {
		case 1 :
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[2]);
			break;
		case 2 :
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[3]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[4]);
			break;
		case 3 :
			Utils3D.draw3D(g, texture[base].getTexture(), coordList[0]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[2]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[5]);
			Utils3D.draw3D(g, texture[ball].getTexture(), coordList[6]);
			break;
		}
	}
	
	protected void draw(Graphics g, int texIndex, int coordIndex, boolean drawFront) {
		if (texture[texIndex] != null) {
			if (drawFront) {
				Utils3D.draw3D(g, texture[texIndex].getTexture(), coordList[coordIndex]);
			} else {
				Utils3D.draw3DBackside(g, texture[texIndex].getTexture(), coordList[coordIndex]);
			}
		}
	}

	/**
	 * Sets the target location for this card. This location is
	 * the x axis target.
	 * 
	 * @param value the value to use as target.
	 */
	public void setTarget(float value) {
		xTarget = value;
	}

	/**
	 * Moves the object towards the given target. This method compares the
	 * position before and after the move to see if the position after is 
	 * larger than the position before. If this has happen, there is no need
	 * to move any further and the value of the target is returned. This, to
	 * make sure that the object is not moved back and forth, trying to get
	 * to target but can't because the step (the speed) is to large.
	 * 
	 * @param pos the position of the object before the step.
	 * @param target the target x position.
	 * @param speed the speed of the move.
	 * @return the x position after the move has been made.
	 */
	protected float move(float pos, float target, float speed) {
		float dist = Math.abs(pos - target);
		pos += target > pos ? speed : -speed;
		return Math.abs(pos - target) >= dist ? target : pos;
	}

	/**
	 * Resets this cards x position to the position of the deck.
	 * This will cause the card to instantly move to the position of the deck.
	 * It also turns the card so that the back is showing.
	 */
	public void reset() {
		xPos = xTarget = BattleValues.DECK_POSITION;
		rotation = targetRotation = BACK;
		currentSide = BOTH_SIDES;
		enabled = true;
		yOffset = 0;
		card.reset();
	}

	/**
	 * Updates the card. This means that if the target rotation or
	 * target location is separate from the current position this method 
	 * will move the card towards the target.
	 */
	protected void update() {
		super.update();
		if (xPos != xTarget) {
			xPos = move(xPos, xTarget, MOVE_SPEED * Values.LOGIC_INTERVAL);
			if (xPos == xTarget) {
				flip(FRONT);
			}
		}
		if (yOffset != 0) {
			if (k == Float.POSITIVE_INFINITY) {
				yOffset = move(yOffset, 0, BattleValues.CARD_MOVE_SPEED_2 * Values.LOGIC_INTERVAL);
			} else {
				yOffset = (k * xPos) + m;
			}
		}
	}

	/**
	 * Sets this card in the weapon slot where x is the x position of the slot.
	 * 
	 * @param x the x coordinate of the slot.
	 */
	public void setInSlot(float x) {
		xTarget = x;
		yOffset = BattleValues.DECK_HEIGHT_CARDS;
		calc(xPos, yOffset, xTarget, 0);
	}

	/**
	 * Draws the card on the given GL at the given y location.
	 * The location is on the 2D plane where the battle graphic is drawn.
	 * This plane is defined as 0, 0, -2 after the identity matrix has been 
	 * loaded and can be reached by translating the matrix. (glTranslatef).
	 * 
	 * @param g the GL object to draw on.
	 * @param y the "height" of the card or y position.
	 */
	public void draw(Graphics g, float y) {
		g.loadIdentity();
		g.translate(xPos, y + yOffset, BattleValues.STANDARD_Z_DEPTH);
		g.rotate(rotation, 0, 1, 0);
		if (currentSide == BOTH_SIDES) {
			for (int i = 0; i < currentSide.length; i++) {
				switch (currentSide[i] + (enabled ? 0 : 1)) {
				case 0 :
					makeCardDrawList(g, 0, 3);
					break;
				case 1 :
					draw(g, 1, 1, false);
					break;
				case 2 :
					makeCardDrawList(g, 2, 4);
					break;
				}
			}
		} else {
			switch (enabled ? 0 : 2) {
			case 0 :
				makeCardDrawList(g, 0, 3);
				break;
			case 2 :
				makeCardDrawList(g, 2, 4);
				break;
			}
		}
	}

	/**
	 * Calculates k and m from the given points. K and m is the constants
	 * in the linear equation used to update yOffset when moving the card 
	 * on the x axis. This is the simple equation y = kx + m.
	 * 
	 * @param x1 the x coordinate of the first point.
	 * @param y1 the y coordinate of the first point.
	 * @param x2 the x coordinate of the second point.
	 * @param y2 the y coordinate of the second point.
	 */
	private void calc(float x1, float y1, float x2, float y2) {
		k = (y2 - y1) / (x2 - x1);
		m = y2 - (k * x2);
	}

	/**
	 * Sets if this card should be enabled for play or not.
	 * If the card is set not enabled, it will turn gray.
	 * 
	 * @param enabled true if the card should be able to play.
	 */
	public void setEnabled(boolean enabled) {
		this.enabled = enabled;
	}

	/**
	 * Gets the kind of type of card that this GLCard has wrapped.
	 * 
	 * @return the type of the underlying card.
	 */
	public int getType() {
		return card.getType();
	}

	/**
	 * Gets the Card object wrapped in this GLCard.
	 * 
	 * @return the Card object residing in this GLCard.
	 */
	public Card getCard() {
		return card;
	}

	/**
	 * Called when the rotation has finished. It sets the currentSide
	 * to UP_SIDE because after a rotation is done on a card it should
	 * always face up.
	 */
	public void rotateDone() {
		currentSide = FRONT_SIDE;
	}

	/**
	 * Checks if the card is enabled.
	 * 
	 * @return true if the card is enabled.
	 */
	public boolean isEnabled() {
		return enabled;
	}

	@Override
	public void draw(Graphics g) {
		// TODO Auto-generated method stub
		
	}
}
