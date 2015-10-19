/*
 * Classname: HinderDoor.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.Database;
import labyrinth.Node;

/**
 * This class is the inventory hinder. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the chest has been opened or not.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class AdditiveHinderDoor extends HinderDoor {
	
	private int openStatus;

	public AdditiveHinderDoor(
			Node n, int dir, int nrOfTexs, String image,
			int status, String nextPlace, int vStartPos) {
		super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos);
	}
	
	public boolean checkIfOpen() {
		status = Database.getStatusFor(dataBaseName);
		return status == openStatus;
	}
	
	protected void setOpenStatus(int status) {
		openStatus = status;
	}

	public void addStatus(int i) {
		status = Database.getStatusFor(dataBaseName);
		status += i;
		Database.addStatus(dataBaseName, status);
	}
}