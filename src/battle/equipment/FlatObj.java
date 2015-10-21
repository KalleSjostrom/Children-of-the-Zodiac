/*
 * Classname: FlatObj.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/06/2008
 */
package battle.equipment;

import graphics.Object2D;
import info.BattleValues;
import cards.Card;

/**
 * This class implements the similar behavior from both the GLCard and GLSlot
 * classes. Both of these extends this class. Similar abilities includes
 * double texture (front and back), able to rotate and to choose which side to
 * draw if not drawing both.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 28 June 2008
 */
public abstract class FlatObj extends Object2D {

	/**
	 * The rotation in degrees when showing the front of this flat object.
	 */
	public static final int FRONT = 0;
	
	/**
	 * The rotation in degrees when showing the back of this flat object.
	 */
	public static final int BACK = 180;
	
	protected static final int[] FRONT_SIDE = new int[]{0};
	protected static final int[] BACK_SIDE = new int[]{1};
	protected static final int[] BOTH_SIDES = 
		new int[]{FRONT_SIDE[0], BACK_SIDE[0]};

	protected Card card;
	protected int[] currentSide = BOTH_SIDES;
	protected float rotation;
	protected float targetRotation;
	protected float xPos;
	protected float speed = BattleValues.CARD_FLIP_SPEED;
	
	private float startRotation;

	/**
	 * Constructs a new FlatObj.
	 * 
	 * @param size the number of textures to use.
	 */
	public FlatObj(int size) {
		super(size);
	}

	/**
	 * This method updates the rotation. If the object has rotated half
	 * way the method rotatedHalfWay() is called and when the rotation is 
	 * done, the rotateDone() method is called. These methods does not
	 * do anything and is free to override.
	 */
	protected void update(float dt) {
		if (targetRotation != rotation) {
			rotation += (targetRotation == BACK ? speed : -speed) * dt;
			hasRotatedHalfWay();
			if (targetRotation == rotation) {
				rotateDone();
			}
		}
	}

	/**
	 * This method checks if the object has rotated half the
	 * way to its target.
	 * 
	 * @return true if the object has rotated half the way.
	 */
	protected boolean hasRotatedHalfWay() {
		boolean b = Math.abs(rotation - targetRotation) < 
		Math.abs(rotation - startRotation);
		if (b) {
			startRotation = targetRotation;
			rotatedHalfWay();
		}
		return b;
	}

	/**
	 * This method rotates the object to the given side.
	 * 
	 * @param side the side to flip this object to.
	 */
	public void flip(int side) {
		startRotation = rotation;
		targetRotation = side;
	}

	/**
	 * Sets the card that should be stored in this object.
	 * 
	 * @param card the card to set.
	 */
	public void setCard(Card card) {
		this.card = card;
	}

	/**
	 * This method is called when the rotation is done.
	 * It does nothing so it should be overridden to 
	 * implement an effect.
	 */
	protected void rotateDone() {
		// Empty method
	}

	/**
	 * This method is called when the object has rotated half way.
	 * It does nothing so it should be overridden to 
	 * implement an effect.
	 */

	protected void rotatedHalfWay() {
		// Empty method
	}
}
