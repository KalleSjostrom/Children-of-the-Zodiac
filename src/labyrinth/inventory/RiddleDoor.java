/*
 * Classname: HinderDoor.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.Database;
import info.SoundMap;
import info.Values;
import labyrinth.Labyrinth;
import labyrinth.Node;
import sound.SoundPlayer;

/**
 * This class is the inventory hinder. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the chest has been opened or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public class RiddleDoor extends HinderDoor {
	
	private boolean showingDialog;
	
	public RiddleDoor(
			Node n, int dir, int nrOfTexs, String image,
			int status, String nextPlace, int vStartPos) {
		super(n, dir, nrOfTexs, image, status, nextPlace, vStartPos);
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
			if (checkIfOpen()) {
				enter(lab);
			} else {
				if (!showingDialog) {
					lab.drawDialog("The door is shut tight, but music echoes", "down the silent great hall when the door is touched.");
					SoundPlayer.playSound(SoundMap.LABYRINTH_NOTES);
				}
				showingDialog = !showingDialog;
			}
		}
	}
}