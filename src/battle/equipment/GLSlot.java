/*
 * Classname: GLSlot.java
 * 
 * Version information: 0.7.0
 *
 * Date: 28/06/2008
 */
package battle.equipment;

import info.BattleValues;
import cards.AbstractCard;
import equipment.Slot;
import graphics.Graphics;

/**
 * This class is GL wrapper for the objects of the Slot class. This is
 * done to be able to draw them in 3D space with openGL. It has two slots
 * one for each mode of the weapon.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 28 June 2008
 */
public class GLSlot extends FlatObj {

	private Slot[] slots;

	/**
	 * Creates a new slot2D containing the given slots.
	 * The given slots are for the offense side and defense side
	 * of the weapon.
	 * 
	 * @param slot1 the slot to use when the weapon is in offense mode.
	 * @param slot2 the slot to use when the weapon is in defense mode.
	 * @param x the x coordinate of the slot.
	 */
	public GLSlot(Slot slot1, Slot slot2, float x) {
		super(2);
		slots = new Slot[]{slot1, slot2};
		xPos = x;
		targetRotation = rotation = FRONT;
	}

	/**
	 * This method loads the textures, creates the position coordinates
	 * and makes the draw list and stores them in the given GL object. 
	 * 
	 * @param gl the GL object to use when initiating the slot.
	 */
	public void initDraw(Graphics g) {
		loadTextures();
		createCoordList(2);

		createCoordFor(-width / 2, width / 2, 0, X);
		createCoordFor(-height / 2, height / 2, 0, Y);
		createCoordFor(-.001f, -.001f, 0, Z);

		copyCoords(1, 0, X);
		copyCoords(1, 0, Y);
		createCoordFor(+.001f, +.001f, 1, Z);
		
		draw(g, 0, 0, true);
		draw(g, 1, 1, false);
	}

	/**
	 * This method loads the textures used. It uses the first slot given
	 * in the constructor as first texture and the second slot as 
	 * second texture. This is only true if the slots is non null.
	 * If this is the case no texture is drawn and it will be completely
	 * transparent.
	 */
	protected void loadTextures() {
		loadTexture(slots[0] == null ? null : slots[0].getImage(), 0);
		loadTexture(slots[1] == null ? null : slots[1].getImage(), 1);
		if (slots[0] != null) {
			setSize(0, BattleValues.SLOT_SCALE);
		} else if (slots[1] != null) {
			setSize(1, BattleValues.SLOT_SCALE);
		} else {
			height = .2f;
			width = .2f;
		}
	}

	/**
	 * Draws the slot on the given GL at the given y position.
	 * This method loads the identity matrix so call it with caution.
	 * 
	 * @param g the Graphics to draw on.
	 * @param y the height of the slot.
	 */
	public void draw(Graphics g, float y) {
		update();
		g.loadIdentity();
		g.translate(xPos, y, BattleValues.STANDARD_Z_DEPTH - .001f);
		g.rotate(rotation, 0, 1, 0);
		if (currentList == 0) {
			super.draw(g, 0, 0, true);
		} else {
			super.draw(g, 1, 1, false);
		}
	}

	/**
	 * Gets the type of slot, stored in this GLSlot. The given
	 * value represents which slot to get the type from. The slot
	 * stored in offense mode or defense mode. GLWeapon.OFFENSE_MODE
	 * or GLWeapon.DEFENSE_MODE.
	 * 
	 * @see GLWeapon#OFFENSE_MODE 
	 * @see GLWeapon#DEFENSE_MODE 
	 *  
	 * @param currentMode the side of the slot2D to check.
	 * @return the type of the slot stored in currentMode side.
	 */
	public int getKind(int currentMode) {
		return slots[currentMode].getType();
	}

	/**
	 * Checks if there is a card in this slot.
	 * 
	 * @return true if this slot has a card.
	 */
	public boolean hasCard() {
		return card != null;
	}

	/**
	 * This method turns the slot around. If the front of the slot
	 * is showing it is turned so that the backs is drawn and vice versa.
	 */
	public void toggleSide() {
		if (targetRotation != FRONT) {
			targetRotation = FRONT;
		} else {
			targetRotation = BACK;
		}
	}

	/**
	 * Called when the object has rotated half way. This method
	 * then switches the draw list so that the other side of the object 
	 * is drawn. This means that if the object front is showing
	 * (the texture with index 0) this method will change the draw list
	 * so that the back is showing when the object has rotated half way.
	 */
	public void rotatedHalfWay() {
		currentList = targetRotation == BACK ? 1 : 0;
	}

	/**
	 * This method throws away the card residing in this slot.
	 */
	public void clearSlot() {
		card = null;
	}

	/**
	 * Checks if the slot in the current mode is free to use, that
	 * it does not have any card in it. The current mode is either
	 * GLWeapon.OFFENSE_MODE or .DEFENSE_MODE.
	 * 
	 * @param currentMode the current battle mode.
	 * @return true if this slot is free to use.
	 */
	public boolean isFree(int currentMode) {
		return slots[currentMode] != null && !hasCard();
	}

	public boolean doesFit(GLCard card, int currentMode) {
		boolean cardFits = false;
		if (isFree(currentMode)) {
			int t = slots[currentMode].getType();
			if (card.getCard().getType() == AbstractCard.NEUTRAL) {
				cardFits = t == Slot.MAGIC || t == Slot.SUPPORT;
			} else {
				cardFits = t == card.getType();
			}
		}
		return cardFits;
	}

	@Override
	public void draw(Graphics g) {
		// TODO Auto-generated method stub
		
	}
}
