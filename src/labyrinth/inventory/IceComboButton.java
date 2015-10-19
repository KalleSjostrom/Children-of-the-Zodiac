/*
 * Classname: Button.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.LabyrinthMap;
import info.SoundMap;
import labyrinth.Node;

/**
 * This class is the inventory button. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the button is pressed or not.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class IceComboButton extends ComboButton {

	public IceComboButton(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] buttons, HinderDoor openDoor, int imageNr, String sound) {
		super(node, dir, nrOfTexs, image, status, buttons, openDoor, imageNr);
		delayTime = 1500;
		this.sound = sound;
		doneSound = SoundMap.LABYRINTH_NOTES_DONE;
	}
	
	@Override
	protected String getComboMapImage() {
		return LabyrinthMap.notes[status];
	}
//	
//	@Override
//	public boolean isPassable(int dir) {
//		return true;
//	}
}

