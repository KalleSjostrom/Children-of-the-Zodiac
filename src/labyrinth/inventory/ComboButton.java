/*
 * Classname: Button.java
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
 * This class is the inventory button. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the button is pressed or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public abstract class ComboButton extends Button {

	private HinderDoor doorToOpen;
	private static final int NR_IMAGES = 2;
	
	protected int imageNr;
	protected int delayTime;
	protected String doneSound;
	
	public ComboButton(Node node, int dir, int nrOfTexs, String image, 
			int status, Inventory[] buttons, HinderDoor openDoor, int imageNr) {
		super(node, dir, nrOfTexs, image, status, buttons);
		doorToOpen = openDoor;
		this.imageNr = imageNr;
	}
	
	@Override
	public String getMapImage() {
		return getComboMapImage();
	}

	public void activate(Labyrinth labyrinth) {
		if (currentTex == 0) {
			new Thread() {
				public void run() {
					while (currentTex < NR_IMAGES-1) {
						currentTex++;
						Values.sleep(200);
					}
				}
			}.start();
			status = ON;
			SoundPlayer.playSound(sound);
			Database.addStatus(dataBaseName, status);
			checkButtons();
		}
	}

	private void reset(final boolean playSound) {
		if (status == ON) {
			new Thread() {
				public void run() {
					while (currentTex < NR_IMAGES-1) {
						Values.sleep(200);
					}
					Values.sleep(delayTime);
					while (currentTex > 0) {
						Values.sleep(200);
						currentTex--;
					}
					if (playSound) {
						SoundPlayer.playSound(SoundMap.ERROR);
					}
					status = 0;
					Database.addStatus(dataBaseName, status);
				}
			}.start();
		}
	}

	private void checkButtons() {
		boolean foundError = false;
		for (int i = 0; i < hinders.length && !foundError; i++) {
			ComboButton button = (ComboButton) hinders[i];
			foundError = button.status == OFF;
		}
		if (foundError) {
			for (int i = 0; i < hinders.length; i++) {
				ComboButton button = (ComboButton) hinders[i];
				button.reset(false);
			}
			reset(true);
		} else if (doorToOpen != null) {
			doorToOpen.open();
			new Thread() {

				public void run() {
					Values.sleep(delayTime);
					SoundPlayer.playSound(doneSound);
				}
			}.start();
		}
	}
	
	protected abstract String getComboMapImage();
}

