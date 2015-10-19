/*
 * Classname: Riddle.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.BattleValues;
import info.LabyrinthMap;
import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;

/**
 * This class is the inventory riddle. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, a riddle game mode is started
 * letting the player read and solve the riddle.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class Riddle extends Inventory {
	
	private String name;
	private String riddleClass;
	private Inventory[] hinders;

	/**
	 * Creates a new hinder from the given information.
	 * 
	 * @param node the node where the chest should be.
	 * @param dir the direction the texture should face. 
	 * (Values.UP, .RIGHT, .DOWN, .LEFT).
	 * @param name the name of the riddle file to execute.
	 * @param image the name of the first image in the series.
	 * @param status the status for this button according to the Database.
	 * @param riddleClass 
	 * @param hinders 
	 */
	public Riddle(
			Node node, int dir, String name, String image, 
			int status, String riddleClass, Inventory[] hinders) {
		super(node, dir, 1, image, status);
		this.hinders = hinders;
		this.name = name;
		this.riddleClass = riddleClass;
	}
	
	/**
	 * @inheritDoc
	 */
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		info = getSettings();
		if (info != null) {
			heightOffset = info.getHeightOffset();
			zOff = info.getZOffset();
			scale2 = info.getScale();
		} else {
			zOff = 1.99f;
			heightOffset = 1.65f;
			scale2 = 4;
		}
	}

	/**
	 * Activates the riddle by calling enterRiddle() in 
	 * the given labyrinth with the riddle file name.
	 * 
	 * @param lab the labyrinth where this riddle is. 
	 */
	public void activate(Labyrinth lab) {
		lab.enterRiddle(name, "miniGames." + riddleClass, hinders);
	}
	
	@Override
	public String getMapImage() {
		return LabyrinthMap.riddle[0];
	}

	public boolean isPassable(int dir) {
		return false;
	}
	
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return true;
	}
}
