/*
 * Classname: HinderDoor.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.Graphics;
import info.BattleValues;
import info.Database;
import info.Values;
import labyrinth.Labyrinth;
import labyrinth.Node;

import organizer.Organizer;

import villages.VillageLoader;

/**
 * This class is the inventory hinder. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the chest has been opened or not.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class HinderDoor extends AbstractDoor {
	
	private String nextPlace;
	private int villageStartPos;
	private boolean showingDialog;
	protected static final int LOCKED = 0;
	private static final int CLOSED = 1;
	// private static final int OPENED = 2;
	
	public HinderDoor(
			Node n, int dir, int nrOfTexs, String image,
			int status, String nextPlace, int vStartPos) {
		super(n, dir, nrOfTexs, image, status);
		index = Door.doorCount;
		Door.doorCount++;
		this.nextPlace = nextPlace;
		villageStartPos = vStartPos;
	}
	
	public int getDoorIndex() {
		return index;
	}
	
	// To be called when the player enters the labyrinth
	public void setHaveBeen(String lastNodesName) {
		if (lastNodesName == null || 
				Organizer.convert(nextPlace).equalsIgnoreCase(Organizer.convert(lastNodesName))) {
			setHaveBeen();
		}
	}
	
	public void draw(float dt, Graphics g) {
		int tex = checkIfOpen() ? 0 : 1;
		texture[tex].bind(g);
		g.beginQuads();
		node.drawOneWall(g, dir, false);
		g.end();
	}

	/**
	 * @inheritDoc
	 */
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
	}
	
	public boolean checkIfOpen() {
		status = Database.getStatusFor(dataBaseName);
		return status != LOCKED;
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
					lab.drawDialog("The door is locked!", "");
				}
				showingDialog = !showingDialog;
			}
		}
	}
	
	protected void enter(Labyrinth lab) {
		// status = OPENED;
		// Database.addStatus(dataBaseName, status);
		String next = lab.getMissionNext();
		if (next != null) {
			Organizer.getOrganizer().updateNextPlaceFor(next, nextPlace);
			lab.resetMissionNext();
		} else {
			next = nextPlace;
		}
		if (villageStartPos != -1) {
			VillageLoader.staticStartPos = villageStartPos;
		}
		info = getSettings();
		super.enter(lab, info);
		lab.exitLabyrinth(Values.EXIT);
		lab.setNextPlace(next);
		setHaveBeen();
	}
	
	public void open() {
		setStatus(CLOSED);
	}
}