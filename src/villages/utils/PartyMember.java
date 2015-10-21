/*
 * Classname: PartyMember.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.utils;

import info.Values;
import sprite.Sprite;

/**
 * This class represents a party member. The party members is the players
 * walking in a straight line behind each other in the village. 
 * 
 * @author		Kalle Sjöström
 * @version     0.7.0 - 13 May 2008
 */
public class PartyMember extends Sprite {
	public PartyMember(String name) {
		this.name = name;
		loadPermImages(Values.VillageImages + "Characters/", name);
	}
	public void updatePos(Position p) {
		direction = p.getDirection();
		pos[Values.X] = p.getX();
		pos[Values.Y] = p.getY();
	}
	public float[] getPosAsFloatArray() {
		return new float[]{ pos[Values.X], pos[Values.Y], direction };
	}
}