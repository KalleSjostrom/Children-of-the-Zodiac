/*
 * Classname: Hideable.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/06/2008
 */
package battle;

import graphics.Graphics;
import graphics.Object2D;
import info.BattleValues;

import java.util.Stack;

/**
 * A hideable object2D is a two dimensional object that can be drawn in 3D
 * space in OpenGL. It can also be moved out of vision so that it is hidden.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 14 June 2008
 */
public abstract class Hideable extends Object2D {
	
	public static final int SHOW = 0;
	public static final int HIDE = 1;
	
	public static final int LIMITS_LOW = 0;
	public static final int LIMITS_HIGH = 1;
	
	public static final int X_AXIS = 0;
	public static final int Y_AXIS = 1;
	
	protected boolean shouldTranslate = true;
	protected boolean visible = true;
	protected float[] trans = new float[2];
	protected float[] transAmount = new float[2];

	private float[] limits = new float[2];
	private float[] pos = new float[2];
	private int[] visLimits = new int[2];
	private float currentTransAmount = 0;
	private int axis = X_AXIS;
	private float zDepth = BattleValues.STANDARD_Z_DEPTH;
	private Stack<Boolean> states = new Stack<Boolean>();
	
	/**
	 * Creates a new Hideable object2D with the given size. The size
	 * represents the number of textures that this object consists of.
	 * 
	 * @param size the maximum number of textures that this object 
	 * can consist of.
	 */
	public Hideable(int size) {
		super(size);
	}

	/**
	 * This method checks if the object is in between the limits and should
	 * therefore be translated (moved). Where it should be moved is not up
	 * to this method.
	 * 
	 * @return true if this object should be moved.
	 */
	private boolean shouldTranslate() {
		boolean higher = trans[axis] > limits[0];
		boolean lower = trans[axis] < limits[1]; 
		return higher && lower;
	}

	/**
	 * Translate the current matrix in the given GL. This will cause the 
	 * object to be moved if the show() or hide() method has recently be
	 * called.
	 * 
	 * @param gl the GL which matrix to translate.
	 */
	public void translate(Graphics g) {
		g.loadIdentity();
		g.translate(pos[X] + trans[X], pos[Y] + trans[Y], zDepth);
	}
	
	public void update(float dt) {
		if (shouldTranslate) {
			System.out.println("Updating " + shouldTranslate);
			trans[axis] += currentTransAmount;
			shouldTranslate = shouldTranslate();
			if (!shouldTranslate) {
				trans[axis] = limits[visible ? visLimits[SHOW] : visLimits[HIDE]];
			}
		}
//		if (shouldTranslate) {
//			trans[axis] += currentTransAmount;
//			shouldTranslate = shouldTranslate();
//			if (!shouldTranslate) {
//				trans[axis] = limits[visible ? LIMITS_LOW : LIMITS_HIGH];
//			}
//		}
	}

	protected void setZdepth(float z) {
		zDepth = z;
	}

	/**
	 * When this method is called the object will be moved to the set 
	 * positions as set by initPos() if it is not visible already. If
	 * this is the case nothing will happen.
	 */
	public void show() {
		System.out.println("Showing " + visible);
		if (!visible) {
			visible = true;
			shouldTranslate = true;
			currentTransAmount = transAmount[SHOW];
		}
	}

	/**
	 * When this method is called the object will be moved on the set axis 
	 * in the direction specified in setTransAmount(). If the second argument
	 * to setTransAmount() (hide value) is negative it will move left or down
	 * depending on which axis is set (setAxis()) and up down if 
	 * it is positive.
	 */
	public void hide() {
		System.out.println("Hiding " + visible);
		if (visible) {
			visible = false;
			shouldTranslate = true;
			currentTransAmount = transAmount[HIDE];
		}
	}
	
	public void pushState() {
		states.push(visible);
	}
	
	public void popState() {
		boolean v = states.pop();
		if (v) {
			show();
		} else {
			hide();
		}
	}
	
	public void toggle() {
		if (visible) {
			hide();
		} else {
			show();
		}
	}

	/**
	 * This method instantly hides the hand.
	 */
	public void instantHide() {
		if (visible) {
			visible = false;
			currentTransAmount = transAmount[HIDE];
			while (shouldTranslate) {
				trans[axis] += currentTransAmount;
				shouldTranslate = shouldTranslate();
			}
		}
	}

	/**
	 * Initiates the positions with the given values.
	 * These position is without any translations.
	 * 
	 * @param x the x position of the object.
	 * @param y the y position of the object.
	 */
	protected void setPos(float x, float y) {
		pos = new float[]{x, y};
	}

	/**
	 * Initiates the positions with the given values.
	 * These position is without any translations.
	 * 
	 * @param pos the position of the object.
	 */
	protected void setPos(float[] pos) {
		this.pos = pos;
	}

	/**
	 * Sets which axis that should be translated when the object is hidden or
	 * shown. This means which axis it should be moved on. This value is either
	 * Hideable.X or Hideable.Y. The default value is Hideable.X so if this 
	 * method is not called, the used axis is X (horizontal).
	 * 
	 * @param axis the axis the object should move on.
	 */
	protected void setAxis(int axis) {
		this.axis = axis;
	}

	/**
	 * Sets the limit positions of the object. These limits is the translation
	 * values to use when translation the current GL matrix. Zero means that
	 * there should be no translation. The given low and high values are the 
	 * limits where the low must be a smaller value than high. If the object should
	 * be moved left to be hidden, high should be zero and low maybe -1 depending 
	 * on how far to the left the object must go. To the right it could be that
	 * low is zero while the high value is set to around one.
	 * 
	 * @param low the lowest limit.
	 * @param high the highest limit.
	 */
	protected void setLimit(float low, float high, boolean lowHide) {
		limits[LIMITS_LOW] = low;
		limits[LIMITS_HIGH] = high;
		visLimits[HIDE] = lowHide ? LIMITS_LOW : LIMITS_HIGH;
		visLimits[SHOW] = lowHide ? LIMITS_HIGH : LIMITS_LOW;
	}

	/**
	 * This method just calls setLimit() with the values in the given array.
	 * 
	 * @param limits containing the low value on index zero and the high
	 * value on index one.
	 */
//	protected void setLimit(float[] limits) {
//		setLimit(limits[LIMITS_LOW], limits[LIMITS_HIGH]);
//	}

	/**
	 * Gets the appropriate limits for the hideable object.
	 * The given value represents the location of the object where
	 * true is the top or the right (positive values on x or y).
	 * False indicates the bottom or left (negative values on x or y).
	 * To set the specific axis see setAxis();
	 * 
	 * @see battle.Hideable#setAxis(int)
	 * @param topRight true if the limits for the top or the right positions
	 * should be set.
	 */
	protected void setLimit(boolean topRight) {
		setLimit(topRight ? 0 : -1, topRight ? 1 : 0, !topRight);
	}

	/**
	 * Sets the amount which should be incremented on the translation value,
	 * when this object is being shown or hidden. This can be seen as the 
	 * speed of the movement where the show value will be the speed when 
	 * the object is moving from its hidden location to its visible.
	 * One of these values must be negative because it should be opposite
	 * directions. If the show value is negative it will move left or down
	 * when made visible and the hide value should be positive which will
	 * cause the object to move right or up (opposite direction) when hidden.
	 * 
	 * @param show the speed to use when making the object visible.
	 * @param hide the speed to use when hiding the object.
	 */
	protected void setMovementSpeed(float show, float hide) {
		transAmount[SHOW] = show;
		transAmount[HIDE] = hide;
	}

	/**
	 * Sets the movement speed of this hideable.
	 * 
	 * @see battle.Hideable#setMovementSpeed(float, float)
	 * @param movementSpeed the speed to set.
	 */
	protected void setMovementSpeed(float[] movementSpeed) {
		transAmount = movementSpeed;
	}

	/**
	 * Gets the appropriate speed for the hideable object.
	 * The given value represents the location of the object where
	 * true is the top or the right (positive values on x or y).
	 * False indicates the bottom or left (negative values on x or y).
	 * To set the specific axis see setAxis();
	 * 
	 * @see battle.Hideable#setAxis(int)
	 * @param topRight true if the speed for the top or the right positions
	 * should be set.
	 */
	public void setMovementSpeed(boolean topRight) {
		float[] speed = new float[2];
		speed[0] = topRight ? -.1f : .1f;
		speed[1] = topRight ? .1f : -.1f;
		setMovementSpeed(speed);
	}

	/**
	 * Gets the value which this hideable is translating the matrix 
	 * on the Y-axis before drawing.
	 * 
	 * @return the amount of translation on the y axis.
	 */
	public float getYtrans() {
		return pos[Y] + trans[Y];
	}
	
	/**
	 * Gets the value which this hideable is translating the matrix 
	 * on the Y-axis before drawing.
	 * 
	 * @return the amount of translation on the y axis.
	 */
	public float getXtrans() {
		return pos[X] + trans[X];
	}

	/**
	 * Gets the position of this object on the given axis.
	 * If this value is Hideable.X it gets the x position and 
	 * if it is Hideable.Y the returned position is on the y axis.
	 * 
	 * @param axis the axis to get the position from.
	 * @return the position on the given axis.
	 */
	public float getPos(int axis) {
		return pos[axis];
	}
}
