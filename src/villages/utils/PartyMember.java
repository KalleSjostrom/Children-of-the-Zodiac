/*
 * Classname: PartyMember.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

import graphics.Graphics;
import info.Values;
import sprite.Sprite;

/**
 * This class represents a party member. The party members is the players
 * walking in a straight line behind each other in the village. 
 * 
 * @author		Kalle Sjšstršm
 * @version     0.7.0 - 13 May 2008
 */
public class PartyMember extends Sprite {

	private Position currentPos = new Position(0, 0, 0);

	/**
	 * Creates a new party member with the given name.
	 * 
	 * @param name the name of the party member.
	 */
	public PartyMember(String name) {
		this.name = name;
		loadPermImages(Values.VillageImages + "Characters/", name);
	}

	/**
	 * Updates the current position to the given one. If the direction
	 * has changed since the last update, the animation images is changed.
	 * 
	 * @param p the new position.
	 */
	public void updatePos(Position p) {
		if (p.getDirection() != currentPos.getDirection()) {
			setImages(p.getDirection());
		}
		currentPos = p;
	}

	/**
	 * @inheritDoc
	 */
	public void standStill() {
		standStill(currentPos.getDirection());
	}

	/**
	 * @inheritDoc
	 */
	public void move() {
		move(currentPos.getDirection());
	}

	/**
	 * Gets the position of the party member.
	 * 
	 * @return the position of the party member.
	 */
	public Position getPosition() {
		return currentPos;
	}

	/**
	 * Sets the current position to the given one.
	 * 
	 * @param position the position to set as the current.
	 */
	public void setCurrentPos(Position position) {
		currentPos = position;
	}

	/**
	 * Gets the y position stored in the current position.
	 * 
	 * @return the y position of the party member.
	 */
	public float getY() {
		return currentPos.getY();
	}

	/**
	 * Gets the x position stored in the current position.
	 * 
	 * @return the x position of the party member.
	 */
	public float getX() {
		return currentPos.getX();
	}

	/**
	 * Draws the party member on the given graphics at the given position.
	 * 
	 * @param g the graphics to draw on.
	 * @param x the x position to draw the member.
	 * @param y the y position to draw the member.
	 */
	public void draw(Graphics g, int x, int y) {
		super.drawAtPosition(g, x, y);
	}

	/**
	 * Gets the position of this party member as a float array.
	 * 
	 * @return the position as a float[].
	 */
	public float[] getPosAsFloatArray() {
		return currentPos.getPosAsFloatArray();
	}
	
	public float[] getMemberPos() {
		pos[Values.X] = currentPos.getX();
		pos[Values.Y] = currentPos.getY();
		return pos;
	}
}