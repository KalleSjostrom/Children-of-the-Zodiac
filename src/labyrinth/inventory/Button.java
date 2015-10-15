/*
 * Classname: Button.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import info.BattleValues;
import info.Database;
import info.LabyrinthMap;
import info.SoundMap;
import info.Values;
import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;
import sound.SoundPlayer;

/**
 * This class is the inventory button. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the button is pressed or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public class Button extends Inventory {

	private boolean showingDialog = false;
	protected Inventory[] hinders;
	public static final int OFF = 0;
	public static final int ON = 1;
	public static final int DEFAULT_SLEEP_TIME = 250;
	
	protected String message;
	protected int nrOfTextures;
	protected String sound = SoundMap.LABYRINTH_LEVER_PRESSED;

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
	public Button(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] hinder) {
		super(node, dir, nrOfTexs, image, status);
		hinders = hinder;
		nrOfTextures = (nrOfTexs - 1);
		currentTex = status == 1 ? (nrOfTexs - 1) : 0;
		if (status == -1) {
			this.status = 0;
		}
		message = "The lever is already on!";
	}
	
	/**
	 * This method sets the settings for the button textures, such as scale
	 * y position and z offset.
	 */
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		info = getSettings();
		heightOffset = info.getHeightOffset();
		zOff = info.getZOffset();
		scale2 = info.getScale();
	}
	
	/**
	 * Activates the button. This method starts the animation for this
	 * button and updates the database. The given labyrinth is not used.
	 * 
	 * @param labyrinth the labyrinth where this button is. 
	 */
	public void activate(Labyrinth labyrinth) {
		if (currentTex == 0) {
			SoundPlayer.playSound(sound);
			countTo(true, nrOfTextures, DEFAULT_SLEEP_TIME);
		} else if (currentTex == nrOfTextures) {
			if (!showingDialog) {
				labyrinth.drawDialog(message, "");
			} else {
				labyrinth.exitDialog();
			}
			showingDialog = !showingDialog;
		}
	}
	
	protected void countTo(final boolean up, final int limit, final int sleepTime) {
		new Thread() {
			public void run() {
				if (up) {
					new Thread() {
						public void run() {
							while (currentTex < limit) {
								Values.sleep(sleepTime);
								currentTex++;
							}
						}
					}.start();
				} else {
					while (currentTex > 0) {
						currentTex--;
						Values.sleep(sleepTime);
					}
				}
			}
		}.start();
		status = Math.abs(status - 1);
		Database.addStatus(dataBaseName, status);
		updateDoorStatus(hinders, status);
	}
	
	public static void updateDoorStatus(Inventory[] hinders, int status) {
		for (int i = 0; i < hinders.length; i++) {
			if (hinders[i] instanceof Door) {
				((Door) hinders[i]).setStatus(status);
			} else if (hinders[i] instanceof DummyDoor) {
				((DummyDoor) hinders[i]).setStatus(status);
			} else if (hinders[i] instanceof HinderDoor) {
				((HinderDoor) hinders[i]).setStatus(status);
			}
		}
	}

	@Override
	public String getMapImage() {
		return LabyrinthMap.lever[status];
	}

	@Override
	public boolean isPassable(int dir) {
		return false;
	}
	
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	@Override
	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return true;
	}
}

