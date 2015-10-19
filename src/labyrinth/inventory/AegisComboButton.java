/*
 * Classname: Button.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.BattleValues;
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
public class AegisComboButton extends ComboButton {

	public AegisComboButton(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] buttons, HinderDoor openDoor, int imageNr) {
		super(node, dir, nrOfTexs, image, status, buttons, openDoor, imageNr);
		delayTime = 2500;
		sound = SoundMap.LABYRINTH_ACTIVATE_SYMBOL;
		doneSound = SoundMap.LABYRINTH_SECRET;
	}
	
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		heightOffset = 0;
		zOff = 1.99f;
		scale2 = 3;
	}
	
	@Override
	protected String getComboMapImage() {
		if (status == ON) {
			return LabyrinthMap.aegisOn[imageNr];
		}
		return LabyrinthMap.aegisOff[imageNr];
	}
}

