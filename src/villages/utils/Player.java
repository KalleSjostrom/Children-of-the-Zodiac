/*
 * Classname: Player.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

import factories.Load;
import info.Values;

import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.HashMap;

import sprite.Instruction;
import sprite.Sprite;
import villages.Villager;
import character.Character;

/**
 * This class represents the players in the village. 
 * All the party members is managed from this class. The animation update 
 * and movement of all the party members is carried out here. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 13 May 2008
 */
public class Player {

	private static final int SIZE = 50;
	private static final int DISTANCE_BETWEEN_MEMBERS = 10;
	private static final float VELOCITY = .14f;
	
	private ArrayList<Position> posArray = 
		new ArrayList<Position>(SIZE);
	private ArrayList<PartyMember> partyMembers = 
		new ArrayList<PartyMember>();
	
	private int direction;
	private int currentPartyMember = 0;
	private float[] pos;
	private float distance;
	private boolean moving = false; 

	/**
	 * The constructor of player.
	 * 
	 * @param sPos the starting position.
	 * @param dir the starting direction.
	 */
	public Player(float[] sPos, int dir) {
		fillPartyMembers(sPos, dir);
		standStill();
		for (int i = 0; i < SIZE; i++) {
			posArray.add(new Position(sPos[Values.X], sPos[Values.Y], dir));
		}
		posArray.clear();
		for (int i = 0; i < SIZE + 2; i++) {
			posArray.add(new Position(sPos[Values.X], sPos[Values.Y], dir));
		}
	}

	/**
	 * Fills the list of party members.
	 * 
	 * @param sPos the starting position of the party members.
	 * @param dir the starting direction of the party members.
	 */
	private void fillPartyMembers(float[] sPos, int dir) {
		ArrayList<Character> characters = new ArrayList<Character>();
		ArrayList<Character> loadChars = Load.getCharacters();
		for (int i = 0; i < loadChars.size(); i++) {
			Character c = loadChars.get(i);
			if (c.isAlive()) {
				characters.add(c);
			}
		}
		int x = Values.X;
		int y = Values.Y;
		for (int i = 0; i < characters.size(); i++) {
			PartyMember pm = new PartyMember(characters.get(i).getName());
			pm.setCurrentPos(new Position(sPos[x], sPos[y], dir));
			partyMembers.add(pm);
		}
		pos = sPos;
	}

	/**
	 * Checks if the player has collided with the villager with the given
	 * position p. This method checks the distance between the player and
	 * the given position and if this distance is less than 30, it check
	 * for collision.
	 * 
	 * @param v the position of the villager to check
	 * @param direction the direction of the player.
	 * @return true if this player has collided with the given villager.
	 */
	public boolean checkCollision(Villager v, int direction) {
		int x = Values.X;
		int y = Values.Y;
		float[] villagerPos = v.getPos();
		float yy = villagerPos[y];
		float xx = villagerPos[x] - ((Sprite.STANDARD_WIDTH - v.getWidth()) / 2);
		if (pos[y] > villagerPos[y]) {
			yy = villagerPos[y] - (Sprite.STANDARD_HEIGHT - v.getHeight());
		}
		int dist = (int) Point2D.distance(xx, yy, pos[x], pos[y]);
		
		if (dist < 30) {
			int newDist;
			int check = Math.round(
					pos[direction % 2] + Values.DIRECTIONS[direction] * Values.LOGIC_INTERVAL);
			if (direction % 2 == x) {
				newDist = (int) Point2D.distance(
						check, pos[y], xx, yy);
			} else {
				newDist = (int) Point2D.distance(
						pos[x], check, xx, yy);
			}
			return newDist < dist;
		}
		return false;
	}

	/**
	 * Updates this players animation.
	 * 
	 * @param elapsedTime the amount of time that has elapsed.
	 */
	public void update(float elapsedTime) {
		for (int i = 0; i < partyMembers.size(); i++) {
			partyMembers.get(i).update(
					Instruction.modifyTime(elapsedTime, Instruction.FASTEST));
			partyMembers.get(i).updatePos(getNextPos(i));
		}
	}
	
	private Position getNextPos(int member) {
		return posArray.get(SIZE - (member * DISTANCE_BETWEEN_MEMBERS));
	}
	
	private static final double SIN45 = Math.sin(45);

	private static final float[] DIRECTIONS = 
		new float[]{-1, 1, 1, -1};
	static {
		for (int i = 0; i < DIRECTIONS.length; i++) {
			DIRECTIONS[i] *= Values.LOGIC_INTERVAL * VELOCITY;
		}
	}
	
	/**
	 * This method moves the player in the given direction.
	 * 
	 * @param dir the direction which the player should move.
	 * @param  
	 * @return true if the player has collided.
	 */
	public void go(int dir, boolean diagonal, ObstacleHandler oh) {
		//if (!moving || direction != dir) {
			move(dir);
		//}
		double dist = DIRECTIONS[dir] * (diagonal ? SIN45 : 1);
		float x = pos[Values.X];
		float y = pos[Values.Y];
		if (dir == Values.UP || dir == Values.DOWN) {
			y += dist * 1.5;
		} else {
			x += dist * 2.5;
		}
		if (!oh.hasCollided(x, y, dir)) {
			pos[dir % 2] += dist;
			distance += Math.abs(dist);
			if (distance >= 30) {
				Load.getPartyItems().takeStep();
				distance = 0;
			}
		}
	}

	/**
	 * Creates a Position object from the given values.
	 * 
	 * @param x the x coordinate of the position that will be created.
	 * @param y the y coordinate of the position that will be created.
	 * @param dir the direction coordinate of the position that will 
	 * be created.
	 * @return the newly created position object.
	 */
	private Position createPos(int x, int y, int dir) {
		return new Position(x, y, dir);
	}

	/**
	 * Adds all the party members position to the given hash map. It 
	 * fills the hash map with the position of all the party members 
	 * to be used in the village story mode when the mode should 
	 * generate the starting instructions.
	 * 
	 * @param pos the hash map to fill with positions.
	 */
	public void addPartyMembersPosition(
			HashMap<String, float[]> pos) {
		for (int i = 0; i < partyMembers.size(); i++) {
			PartyMember pm = partyMembers.get(i);
			pos.put(pm.getName(), pm.getPosAsFloatArray());
		}
	}

	/**
	 * Changes the images of the party to the move images.
	 * 
	 * @param dir the direction of the party.
	 */
	public void move(int dir) {
		moving = true;
		direction = dir;
		
		for (int i = 0; i < partyMembers.size(); i++) {
			PartyMember pm = partyMembers.get(i);
			pm.move();
		}
	}

	/**
	 * Changes the images of the party to the stand still images.
	 */
	public void standStill() {
		moving = false;
		for (int i = 0; i < partyMembers.size(); i++) {
			PartyMember pm = partyMembers.get(i);
			pm.standStill();
		}
	}

	/**
	 * Checks if this player is moving.
	 * 
	 * @return true if the player is moving.
	 */
	public boolean isMoving() {
		return moving;
	}

	/**
	 * Gets the height of the images used to draw the player.
	 * 
	 * @return the height of the player images.
	 */
	public int getHeight() {
		return partyMembers.get(0).getHeight();
	}

	/**
	 * Gets the width of the images used to draw the player.
	 * 
	 * @return the width of the player images.
	 */
	public int getWidth() {
		return partyMembers.get(0).getWidth();
	}

	/**
	 * Gets the direction of the current party member. 
	 * 
	 * @return the direction of the current party member.
	 */
	public int getDirection() {
		return direction;
	}

	/**
	 * Gets the position of the player.
	 * 
	 * @return the position of the player.
	 */
	public float[] getPos() {
		return pos;
	}

	/**
	 * Gets the position of the background.
	 * 
	 * @return the position of the background.
	 */

	/**
	 * Gets the players name.
	 * 
	 * @return the name of the player.
	 */
	protected String getName() {
		return partyMembers.get(currentPartyMember).getName();
	}

	/**
	 * This method sets every position in the posArray to the current position.
	 * This way, all the party members will be put in exactly the 
	 * same position. This is used mainly after the player exits a house and
	 * the members of the current party should stand outside the door 
	 * looking down.
	 *  
	 * @param dir the direction the party members should face.
	 */
	public void setDirectionForAll(int dir) {
		PartyMember pm = partyMembers.get(currentPartyMember);
		posArray.clear();
		for (int i = 0; i < SIZE + 1; i++) {
			Position p = pm.getPosition();
			posArray.add(new Position(p.getX(), p.getY(), dir));
		}
		move(dir);
	}

	/**
	 * Updates the list of party members. This is used if one or more members
	 * has been resurrected and the train of members must be updated.
	 */
	public void setPartyMembers() {
		ArrayList<Character> characters = new ArrayList<Character>();
		ArrayList<Character> loadChars = Load.getCharacters();
		for (int i = 0; i < loadChars.size(); i++) {
			Character c = loadChars.get(i);
			if (c.isAlive()) {
				characters.add(c);
			}
		}
		if (characters.size() != partyMembers.size()) {
			partyMembers.clear();
			for (int i = 0; i < characters.size(); i++) {
				PartyMember pm = new PartyMember(characters.get(i).getName());
				pm.setCurrentPos(posArray.get(SIZE - 1));
				partyMembers.add(pm);
			}
			standStill();
		}
	}
	
	public void setAllToPos() {
		for (int i = 0; i < partyMembers.size(); i++) {
			partyMembers.get(i).updatePos(getNextPos(i));
		}
	}

	/**
	 * Gets all the members of this players party.
	 * 
	 * @return the list of members of this players party.
	 */
	public ArrayList<PartyMember> getPartyMembers() {
		return partyMembers;
	}

	/**
	 * Adds the current direction and position of the player to the array
	 * of position so that they can be used later when moving the others
	 * behind the current party member.
	 */
	public void setPartyMembersPositions() {
		posArray.remove(0);
		posArray.add(SIZE, createPos(
				(int) pos[1], (int) pos[0], direction));
	}

	/**
	 * Sets the position of the party members. The array of positions
	 * will be cleared and filled with the given position.
	 * 
	 * @param p the new position.
	 */
	public void setPos(float[] p) {
		pos = p;
		posArray.clear();
		direction = (int) ((p.length > 2 && p[2] != -1) ? p[2] : 0);
		for (int i = 0; i < SIZE + 2; i++) {
			posArray.add(new Position(p[Values.X], p[Values.Y], direction));
		}
	}

	public float getVelocity() {
		return VELOCITY;
	}
}
