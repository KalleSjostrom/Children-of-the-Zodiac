/*
 * Classname: Button.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.Graphics;
import info.Database;
import info.LabyrinthMap;
import info.SoundMap;
import labyrinth.Labyrinth;
import labyrinth.Node;
import sound.SoundPlayer;

/**
 * This class is the inventory button. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the button is pressed or not.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class FloorButton extends Inventory {

	protected Inventory[] hinders;

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
	 */
	public FloorButton(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] hinder) {
		super(node, dir, nrOfTexs, image, status);
		hinders = hinder;
		currentTex = status;
		image = null;
		if (status == -1) {
			this.status = 0;
		}
	}
	
	public void draw(Graphics g) {
		texture[status].bind(g);
		g.beginQuads();
		node.drawOneFloor(g);
		g.end();
	}
	
	@Override
	public void arrive(Labyrinth labyrinth) {
		if (status == 0) {
			SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET);
			status = 1;
			Database.addStatus(dataBaseName, 1);
			updateDoorStatus(hinders, 1);
		}
	}
	
	/**
	 * This method sets the settings for the button textures, such as scale
	 * y position and z offset.
	 */
	protected void setSettings() {
		
	}
	
	/**
	 * Activates the button. This method starts the animation for this
	 * button and updates the database. The given labyrinth is not used.
	 * 
	 * @param labyrinth the labyrinth where this button is. 
	 */
	public void activate(Labyrinth labyrinth) {
		
	}
	
	public static void updateDoorStatus(Inventory[] hinders, int status) {
		for (int i = 0; i < hinders.length; i++) {
			if (hinders[i] instanceof DummyDoor) {
				((DummyDoor) hinders[i]).addStatus(status);
			} else if (hinders[i] instanceof AdditiveHinderDoor) {
				((AdditiveHinderDoor) hinders[i]).addStatus(status);
			}
		}
	}

	@Override
	public String getMapImage() {
		return LabyrinthMap.lever[status];
	}

	@Override
	public boolean isPassable(int dir) {
		return true;
	}
	
	@Override
	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean isPassableOnThis(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return false;
	}
}