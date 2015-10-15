/*
 * Classname: CreatureRow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import graphics.Graphics;

import java.util.ArrayList;

import battle.Hideable;
import character.Character;
import character.Creature;
import character.Enemy;

/**
 * This is an abstraction of a row of creatures presented in 3D.
 * It draws some number of creature3D. It also extends hideable
 * which makes the rows able to hide.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 19 June 2008
 */
public abstract class CreatureRow extends Hideable {

	public static final float BACK_ALPHA_TOP = 0.8f;
	public static final float BACK_ALPHA_BOTTOM = 0.3f;
	
	/**
	 * The list of creature3D that this row consists of.
	 */
	protected ArrayList<Creature3D> creatures3D;
	protected boolean boss;

	/**
	 * Creates a new row of creatures with the given amount of separate
	 * draw lists. This number is the maximum number of textures to use.
	 * If any sub class would like to draw anything else besides the creatures,
	 * like backgrounds and such, this number must be set to the maximum number
	 * of separate textures that should be loaded and drawn.
	 * 
	 * @param nrOfTextures the number of textures to use.
	 */
	public CreatureRow(int nrOfTextures) {
		super(nrOfTextures);
		creatures3D = new ArrayList<Creature3D>();
	}
	
	/**
	 * Initiates the creature list. It creates 3D wrappers for all creatures
	 * that getCreatureList() returns.
	 * @param boss 
	 */
	public void init(boolean boss) {
		this.boss = boss;
		ArrayList<Creature> characters = getCreatureList();
		setPos(getPos());
		for (int i = 0; i < characters.size(); i++) {
			Creature c = characters.get(i);
			Creature3D creature = null;
			if (c instanceof Character) {
				creature = new Character3D(getSide(), (Character) c);
			} else {
				creature = new Enemy3D(getSide(), (Enemy) c);
			}
			creatures3D.add(creature);
		}
	}

	/**
	 * This method initiates the creatures returned from getCreatureList().
	 * It calls the addBackground() method first which could be overridden to 
	 * add anything to the scene. It wraps the creatures into a Creature3D
	 * and calls its initDraw().
	 * 
	 * @param gl the GL object to initiate.
	 */
	public void initDraw(Graphics g) {
		for (int i = 0; i < creatures3D.size(); i++) {
			creatures3D.get(i).initDraw(g);
		}
	}

	/**
	 * This method draws the creature row. 
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		translate(g);
		drawBack(g);
		for (int i = 0; i < creatures3D.size(); i++) {
			creatures3D.get(i).draw(g);
			translateCreature(g);
			g.setColor(1);
		}
	}

	/**
	 * This method updates the texture in each creature in this row.
	 */
	public void updateTexture(Graphics g) {
		for (int i = 0; i < creatures3D.size(); i++) {
			creatures3D.get(i).updateTexture(g);
		}
	}

	/**
	 * Checks all 3D creatures in this row and removes anyone that
	 * is not alive.
	 */
	public void check3DCreatures() {
		for (int i = 0; i < creatures3D.size(); i++) {
			if (!creatures3D.get(i).isAlive()) {
				creatures3D.remove(i);
				i--;
			}
		}
	}
	
	/**
	 * Gets the Character3D with the given index from this row.
	 * 
	 * @param i the index of the character to get.
	 * @return the Character3D with the given index.
	 */
	public Creature3D get(int i) {
		return creatures3D.get(i);
	}

	/**
	 * Gets the amount of creatures3D in this row.
	 * 
	 * @return the amount of creatures in this row.
	 */
	public int size() {
		return creatures3D.size();
	}

	protected abstract void drawBack(Graphics g);

	/**
	 * This method gets the list of creatures to display.
	 * 
	 * @return the list of creatures.
	 */
	protected abstract ArrayList<Creature> getCreatureList();

	/**
	 * Gets the side which the creatures should be on. This side is a 
	 * right or left alignment for such elements as the progress
	 * and the life bar. (Either ProgressBar.RIGHT or ProgressBar.LEFT.)
	 * 
	 * @return the side which the creatures are.
	 */
	protected abstract float getSide();

	/**
	 * Gets the position of the creatures.
	 * 
	 * @return the position of the creature row.
	 */
	protected abstract float[] getPos();

	/**
	 * Translates the images in the row. This method is called between 
	 * each creature is drawn and its purpose is to translate the current 
	 * matrix so that the next drawn creature is drawn at a different location.
	 * 
	 * @param g the GL object to translate.
	 */
	protected abstract void translateCreature(Graphics g);
}
