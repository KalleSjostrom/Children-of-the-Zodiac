/*
 * Classname: GLHand.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle;

import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Object2D;
import info.BattleValues;
import info.Values;

import java.util.ArrayList;
import java.util.Arrays;

import character.Creature;

/**
 * This class represents the hand in the battle. The hand is the cursor
 * pointer that tells which creature to attack.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 21 July 2008
 */
public class GLHand extends Object2D {

	/**
	 * The array of coordinates for the hand.
	 */
	public static float[][] pos;
	
	/**
	 * The index in <code>pos</code> is the position where to draw the hand.
	 */
	public int currentPos;

	private int size;
	private boolean[] alive;
	private boolean showing = true;
	private boolean done = false;
	private ArrayList<Creature> party;
	private ArrayList<Creature> enemies;

	/**
	 * Creates a new hand with the possibility to point to each creature in the
	 * given lists.
	 * 
	 * @param party the list if party members.
	 * @param enemies the list of enemies.
	 */
	public GLHand(ArrayList<Creature> party, ArrayList<Creature> enemies) {
		super(1);
		size = party.size() + enemies.size();
		this.party = party;
		this.enemies = enemies;
		currentPos = party.size();
		pos = new float[size][2];
		alive = new boolean[size];
		Arrays.fill(alive, true);
		calcCharPos(party.size());
		calcEnemyPos(party.size());
	}

	/**
	 * Creates a simple GLHand.
	 */
	public GLHand() {
		super(1);
	}

	/**
	 * This method updates the hands positions. This method should
	 * be used if an enemy dies and the list is changed.
	 */
	public void update() {
		size = party.size() + enemies.size();
		if (currentPos >= size) {
			currentPos = size - 1;
		}
		pos = new float[size][2];
		calcCharPos(party.size());
		calcEnemyPos(party.size());
	}

	/**
	 * This method calculates the positions of the characters in the battle.
	 * 
	 * @param partySize the size of the party.
	 */
	private void calcCharPos(int partySize) {
		float[] p = BattleValues.getCharPosForHand(0);
		
		pos[0][0] = p[0]; 
		pos[0][1] = p[1]; 
		
		for (int i = 1; i < partySize; i++) {
			pos[i] = Values.copyArray(pos[i - 1]);
			pos[i][0] += BattleValues.DISTANCE_BETWEEN_CHARACTERS_X;
		}
	}

	/**
	 * This method calculates the positions of the enemies in the battle.
	 * 
	 * @param partySize the size of the party. Note that this size must
	 * be the character party size and not the size of the enemy list.
	 */
	private void calcEnemyPos(int partySize) {
		if (partySize < pos.length) {
			pos[partySize] = Values.copyArray(BattleValues.ENEMY_ROW_POSITION);
			pos[partySize][0] -= .32f;
			pos[partySize][1] += .015f;
			for (int i = partySize + 1; i < size; i++) {
				pos[i] = Values.copyArray(pos[i - 1]);
				pos[i][1] += BattleValues.DISTANCE_BETWEEN_ENEMIES;
			}
		} else {
			done = true;
		}
	}

	/**
	 * This method creates the coordinates for hand texture in the
	 * openGl environment.
	 */
	protected void createCoords() {
		createCoordList(1);
		createCoordFor(0, 0 + width, 0, X);
		createCoordFor(0, 0 + height, 0, Y);
		createCoordFor(0, 0, 0, Z);
	}

	/**
	 * Initiates the drawings of the hand on the given GL object.
	 * This method loads the textures and sets the size.
	 * 
	 * @param gl the GL object to initiate the drawings on.
	 */
	public void initDraw(Graphics g) {
		texture[0] = ImageHandler.getTexture(
				Values.MenuImages + "hand1.png");

		setSize(0, BattleValues.HAND_SCALE);
		createCoords();
	}

	/**
	 * Draws the hand on the given GL object.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		if (showing && !done) {
			g.loadIdentity();
			g.translate(pos[currentPos][0], pos[currentPos][1], -2);
			if (!isEnemySelected()) {
				g.rotate(-90, 0, 0, 1);
			}
			super.draw(g, 0, 0);
		}
	}

	/**
	 * This method moves the hand to the right or down depending on 
	 * where the hand is. It moves the hand back to the top left corner 
	 * to target the leftmost character, if this method is called when
	 * the last enemy is targeted.
	 */
	public void next() {
		if (isEnemySelected()) {
			int s = enemies.size();
			int temp = ((++currentPos - party.size()) % s);
			currentPos = temp + party.size();
		} else {
			int s = party.size();
			currentPos = (++currentPos % s);
		}
		if (!alive[currentPos]) {
			next();
		}
	}

	/**
	 * This method moves the hand to the left or up depending on 
	 * where the hand is. It moves the hand back to the bottom right corner 
	 * to target the last enemy, if this method is called when
	 * the leftmost character is targeted.
	 */
	public void previous() {
		int s = party.size();
		s += isEnemySelected() ? enemies.size() : 0;
		int low = isEnemySelected() ? party.size() : 0;
		currentPos--;
		if (currentPos < low) {
			currentPos = s - 1;
		}
		if (!alive[currentPos]) {
			previous();
		}
	}

	/**
	 * Gets the index of the creature who is marked. The returned value is
	 * the index the marked creature has in the list which the creature
	 * originated from. This means that, if the marked creature is an
	 * enemy, the returned value represents the index in the list of
	 * enemies set by the constructor.
	 * 
	 * @return the index of the selected creature.
	 */
	public int getIndex() {
		return isEnemySelected() ? currentPos - party.size() : currentPos;
	}
	
	/**
	 * This method sets the current position of the hand to the first enemy.
	 */
	public void reset() {
		currentPos = party.size();
	}

	/**
	 * Checks if the enemy team is selected.
	 * 
	 * @return true if the enemy team is selected.
	 */
	private boolean isEnemySelected() {
		return currentPos >= party.size();
	}

	/**
	 * Gets the team which the marked creature belongs to.
	 * 
	 * @return the selected team.
	 */
	public ArrayList<Creature> getSelTeam() {
		return isEnemySelected() ? enemies : party;
	}

	/**
	 * This method hides the hand.
	 */
	public void hide() {
		showing = false;
	}

	/**
	 * This method shows the hand.
	 */
	public void show() {
		showing = true;
	}
	
	/**
	 * Sets the current position of the hand at the creature with 
	 * the given index.
	 * 
	 * @param playerParty true if the index is from the party, 
	 * false if the index is pointing to the enemies. 
	 * @param index the index in the party list or the enemy list.
	 */
	public void setPos(boolean playerParty, int index) {
		currentPos = playerParty ? index : party.size();
	}
}
