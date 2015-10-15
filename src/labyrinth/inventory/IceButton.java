/*
 * Classname: Button.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.LabyrinthMap;
import labyrinth.Node;

/**
 * This class is the inventory button. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the button is pressed or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public class IceButton extends Button {

	/**
	 * Creates a new button which will be found on the given node.
	 * 
	 * @param node the node where the button should be.
	 * @param dir the direction the texture should face. 
	 * (Values.UP, .RIGHT, .DOWN, .LEFT).
	 * @param nrOfTexs the number of textures to use.
	 * @param image the name of the first image in the series.
	 * @param status the status for this button according to the Database.
	 * @param hinder the array containing the hinder to lock / unlock when 
	 * pushing this button.
	 * @param sound 
	 */
	public IceButton(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] hinder, String sound) {
		super(node, dir, nrOfTexs, image, status, hinder);
		message = "Already activated.";
		this.sound = sound;
	}
	
	@Override
	public String getMapImage() {
		return LabyrinthMap.notes[status];
	}
	
//	@Override
//	public boolean isPassable(int dir) {
//		return false;
//	}
}
