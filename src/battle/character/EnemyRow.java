/*
 * Classname: EnemyRow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import graphics.Graphics;
import info.BattleValues;
import info.Values;

import java.util.ArrayList;

import sound.SoundPlayer;

import battle.bars.ProgressBar;
import bodies.Vector3f;
import character.Creature;
import character.Enemy;

/**
 * This class collects the enemies in a row to make them easily 
 * manageable. The extend class CreatureRow is a hideable which makes
 * the row of enemies possible to hide.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 19 June 2008
 */
public class EnemyRow extends CreatureRow {

	private ArrayList<Creature> enemies;

	/**
	 * Creates a new enemy row based on the information in the given list.
	 * 
	 * @param enemies the enemies to display information about in the row.
	 */
	public EnemyRow(ArrayList<Creature> enemies) {
		super(1);
		this.enemies = enemies;
		setLimit(true);
		setMovementSpeed(true);
		instantHide();
	}

	/**
	 * Gets the list of creatures that this enemy row is based on.
	 * 
	 * @return the list of enemies as creatures.
	 */
	protected ArrayList<Creature> getCreatureList() {
		return enemies;
	}

	/**
	 * Gets the side which the enemies should be on. This side is a 
	 * right or left alignment for such elements as the progress
	 * and the life bar. Either ProgressBar.RIGHT or ProgressBar.LEFT.
	 * 
	 * @return the side which the enemies are.
	 */
	protected float getSide() {
		return ProgressBar.RIGHT;
	}

	/**
	 * Gets the position of the enemies.
	 * 
	 * @return the position of the enemy row.
	 */
	protected float[] getPos() {
		return BattleValues.ENEMY_ROW_POSITION;
	}

	/**
	 * Translates the images in the row. This method is called between 
	 * each enemy is drawn and its purpose is to translate the current 
	 * matrix so that the next drawn enemy is drawn at a different location.
	 * In this case, it will translate the matrix down on the y axis because
	 * the next enemy should be drawn under the previous one.
	 * 
	 * @param gl the GL object to translate.
	 */
	protected void translateCreature(Graphics g) {
		g.translate(0, BattleValues.DISTANCE_BETWEEN_ENEMIES, 0);
	}

	/**
	 * Checks all the creatures in this row and removes any who are dead.
	 */
	public void check() {
		for (int i = 0; i < enemies.size(); i++) {
			if (!enemies.get(i).isAlive()) {
				enemies.remove(i);
				i--;
			}
		}
		check3DCreatures();
	}
	
	public void checkDead() {
		for (int i = 0; i < enemies.size(); i++) {
			if (!enemies.get(i).isAlive()) {
				String sound = ((Enemy) enemies.get(i)).getDieSound();
				SoundPlayer.playSound(Values.BattleSoundEffects + "Monster/" + sound + ".wav");
			}
		}
	}

	@Override
	protected void drawBack(Graphics g) {
		float yBottom = -.89f;
		float yTop = .16f;
		float xRight = .18f;
		float xLeft = -.22f;
		float dist = Math.abs(yTop - yBottom) / 4f;
		float d = creatures3D.size() * dist;
		yBottom = yTop - d;
		
		g.drawGradient(
				Vector3f.ZERO, BACK_ALPHA_TOP, BACK_ALPHA_BOTTOM, xRight, 
				xLeft, yBottom, yTop, false, true);
		
		g.setColor(1);
	}
}
