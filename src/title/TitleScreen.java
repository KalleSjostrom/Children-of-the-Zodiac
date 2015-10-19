/*
 * Classname: TitleScreen.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/05/2008
 */
package title;

import factories.Load;
import graphics.Graphics;
import graphics.ImageHandler;
import info.SoundMap;
import info.Values;
import java.util.HashMap;
import menu.Node;
import organizer.GameMode;
import sound.SoundPlayer;

/**
 * This class represents the title screen. The player can load games 
 * from here, but not create new save slots.
 * 
 * @author 		Kalle Sj�str�m.
 * @version 	0.7.0 - 27 Jan 2008
 */
public class TitleScreen extends GameMode {

	private String background;
	private String titleBackground;

	private int x = 78;
	private int y = 59;

	private Node activeNode;
	private float index = 0;
	
	/**
	 * Initiates the title screen.
	 * 
	 * @param info the information map containing the information
	 * for this game mode.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_INIT);
		pausable = false;
		loadImages();
		activeNode = new Node(null, "");
		fillRoot();
		fadeInSpeed = 1;
		logicLoading = false;
	}

	/**
	 * Fills the root menu used in the title screen.
	 */
	private void fillRoot() {
		Node n = activeNode;
		n.insertChild("Start");
		n.insertChild("Continue");
		n.setDistance(50);
		n.setPositions(Values.createNormalPoint(450, 600));
	}

	/**
	 * Fills the continue menu.
	 */
	private void fillContinue() {
		Node n = activeNode;
		if (!n.hasChildren()) {
			n.insertChild("Slot 1");
			n.insertChild("Slot 2");
			n.insertChild("Slot 3");
			n.setDistance(50);
			n.setPositions(Values.createNormalPoint(450, 600));
		}
	}

	/**
	 * Loads the images used in the title screen. These images are the 
	 * image of the dragon in the background and an image of the title
	 * "Children of the Zodiac".
	 */
	private void loadImages() {
		background = Values.TitleImages + "loggasten.png";
		titleBackground = Values.TitleImages + "loggatext.png";
		ImageHandler.addToCurrentLoadNow(background);
		ImageHandler.addToCurrentLoadNow(titleBackground);
	}

	/**
	 * The update method of title screen. It is used by the organizer.
	 * 
	 * @param elapsedTime the time between updates.
	 */
	public void update(float elapsedTime) {
		if (mode != Values.NO_MODE_IS_SELECTED) {
			fadeout = true;
		} else if (doneFading()) {
			checkGameInput();
		} else if (gameActions[CROSS].isPressed()) {
			fadein = fadeout = false;
			index = fadeValue = 1;
		}
		
		if (!fadein) {
			if (index < .9) {
				index += .005f;
			}
		}
		super.update(elapsedTime);
	}
	
	/**
	 * Checks the input from the player.
	 */
	public void checkGameInput() {
		if (gameActions[UP].isPressed()) {
			activeNode.previousChild(true);
		} else if (gameActions[DOWN].isPressed()) {
			activeNode.nextChild(true);
		} else if (gameActions[CIRCLE].isPressed()) {
			SoundPlayer.playSound(SoundMap.MENU_BACK);
			Node n = activeNode.getParent();
			if (n != null) {
				activeNode = n;
			}
		} else if (gameActions[CROSS].isPressed()) {
			SoundPlayer.playSound(SoundMap.MENU_ACCEPT);
			Node n = activeNode.getCurrentChild();
			if (n.getName().equals("Continue")) {
				activeNode = n;
				fillContinue();
			} else {
				Load.setSlot(n.getName());
				mode = Values.EXIT;
			}
		}
	}

	/**
	 * This method is called by the organizer when this game mode is about
	 * to be shut down. It loads the save slot that the player choose.
	 */
	public void finishOff() {
		Load.loadGame();
		nextPlace = Load.getStartLocation();
	}

	/**
	 * The draw method of title screen. It draws the background and the menu.
	 * 
	 * @param g the graphics on which to draw.
	 */
	public void draw(Graphics g) {
		/*g.setColor(1);
		g.setFontSize(24);*/
		g.drawImage(background, x, y);
		if (!fadein) {
			g.drawImage(titleBackground, x, y, 1, index);
			if (doneFading()) {
				activeNode.drawAllChildren(g);
			}
		}
		super.draw(g);
	}

	/**
	 * Checks if every fadeable item on the title screen has finished fading.
	 * The fadeable item on the title screen is the dragon image and the
	 * title text. This method return true if these images is opaque.
	 * 
	 * @return true if the title screen images is done fading.
	 */
	private boolean doneFading() {
		return index > .9f;
	}	
}