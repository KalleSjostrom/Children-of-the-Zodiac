/*
 * Classname: HinderDoor.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.Database;
import info.Values;
import labyrinth.Labyrinth;
import labyrinth.Node;

/**
 * This class is the inventory hinder. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the chest has been opened or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public class HiddenHinderDoor extends HinderDoor {
	
	public HiddenHinderDoor(
			Node n, int dir, int nrOfTexs, String image,
			int status, String nextPlace, int vStartPos) {
		super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos);
	}
	
	public boolean checkIfOpen() {
		status = Database.getStatusFor(dataBaseName);
		return status >= 3;
	}
	
	protected String getMapImageWhenClosed() {
		return null;
	}

	/**
	 * Exits the given labyrinth, enters the door and sets the
	 * next place in the labyrinth by calling the setNextPlace()
	 * with nextPlace as argument.
	 * 
	 * @param lab the labyrinth where this door is. 
	 */
	public void activate(Labyrinth lab) {
		int playerDir = Values.angleToDirection(lab.getPlayerAngle());

		if (playerDir == dir) {
			status = Database.getStatusFor(dataBaseName);
			Database.addStatus(dataBaseName, status + 1);
			System.out.println("Activate hidden door, new status " + (status + 1));
			if (checkIfOpen()) {
				super.activate(lab);
			}
		}
	}
}