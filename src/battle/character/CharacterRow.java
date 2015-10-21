/*
 * Classname: CharacterRow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import info.BattleValues;
import info.Values;

import java.util.ArrayList;

import battle.bars.ProgressBar;
import bodies.Vector3f;
import character.Creature;
import factories.Load;
import graphics.Graphics;

/**
 * This class collects the characters in a row to make them easily 
 * manageable. The extend class CreatureRow is a hideable which makes
 * the character row possible to hide.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 19 June 2008
 */
public class CharacterRow extends CreatureRow {

	public static final int NO_TARGET = -1;
	public static final int ON_ALL = -2;
	public static final int RANDOM = -3;
	
	private int target = NO_TARGET;
	private ArrayList<Creature> characters = Load.getCharactersAsCreatures();
	private boolean supportMode;

	/**
	 * Creates a new row of characters which can be moved
	 * on the Y. (hidden on y).
	 */
	public CharacterRow() {
		super(1);
		setAxis(Y);
		setLimit(true);
		setMovementSpeed(true);
		instantHide();
	}

	/**
	 * Gets the list of creatures in this row.
	 * 
	 * @return the list of characters in this row.
	 */
	public ArrayList<Creature> getCreatureList() {
		return characters;
	}

	/**
	 * Gets the side on which this row is present.
	 * 
	 * @return the side.
	 */
	protected float getSide() {
		return ProgressBar.LEFT;
	}

	/**
	 * Gets the position of this row.
	 * 
	 * @return the position of the characters.
	 */
	protected float[] getPos() {
		return BattleValues.CHARACTER_POSITION;
	}

	/**
	 * Translates the images in this row.
	 * This method should be called between each drawing of the images in 
	 * this row.
	 * 
	 * @param gl the GL object to draw the row on.
	 */
	protected void translateCreature(Graphics g) {
		g.translate(BattleValues.DISTANCE_BETWEEN_CHARACTERS_X, 0, 0);
	}

	/**
	 * Sets the index of the target that the enemy is hitting at.
	 * This, to draw the character that the enemy is hitting on and not 
	 * the others.
	 * 
	 * @param newTarget the index of the character that the enemy is aiming on.
	 */
	public void setTarget(int newTarget, boolean supportMode) {
		target = newTarget;
		this.supportMode = supportMode;
	}

	/**
	 * This method draws all the character images in the character row.
	 * When an enemy is targeting one of the characters the others 
	 * is not drawn.
	 * 
	 * @param g the Graphics to draw on. 
	 */
	public void draw(float dt, Graphics g) {
		g.loadIdentity();
		g.translate(0, getYtrans(), -2);
		if (!boss) {
			drawBack(g);
		}
		g.setColor(1);
		translate(g);
		if (target == ON_ALL) {
			g.translate(0, -trans[Y], 0);
		}
		for (int i = 0; i < creatures3D.size(); i++) {
			if (i == target) {
				g.translate(0, -trans[Y], 0);
			}
			creatures3D.get(i).setSupport(supportMode && i == target);
			creatures3D.get(i).draw(dt, g);
			if (i == target) {
				g.translate(0, trans[Y], 0);
			}
			translateCreature(g);
			g.setColor(1, 1, 1);
		}
		if (target == ON_ALL) {
			g.translate(0, trans[Y], 0);
		}
	}

	public void testShowCharacters() {
		show();
		new Thread() {
			public void run() {
				while (shouldTranslate) {
					Values.sleep(100);
				}
				target = ON_ALL;
			}
		}.start();
	}
	
	public void testHideCharacters() {
		target = -1;
		hide();
	}
	
	protected void drawBack(Graphics g) {
		float x = 1.08f;
		g.drawGradient(
				Vector3f.ZERO, BACK_ALPHA_TOP, BACK_ALPHA_BOTTOM, 
				x, -x, -.07f, .3f, false, true);
	}

	/**
	 * Gets the Character3D with the given index from this row.
	 * 
	 * @param i the index of the character to get.
	 * @return the Character3D with the given index.
	 */
	public Character3D get(int i) {
		return (Character3D) creatures3D.get(i);
	}

}
