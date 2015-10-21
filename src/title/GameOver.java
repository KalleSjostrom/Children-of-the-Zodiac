/*
 * Classname: GameOver.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/05/2008
 */
package title;

import factories.Load;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import character.Character;

import organizer.GameMode;

/**
 * This class represents the game over screen. It will only show the game over
 * screen and switch to the title screen when the player presses the 
 * cross button.
 * 
 * @author 		Kalle Sjöström.
 * @version 	0.7.0 - 27 Jan 2008
 */
public class GameOver extends GameMode {

	private String background;
	private boolean done = false;
	
	/**
	 * Initiates the game over screen.
	 * 
	 * @param info the information map containing the information
	 * for this game mode.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_INIT);
		setFadeInSpeed(.01f);
		loadImages();
		
		logicLoading = false;
		new Thread() {
			public void run() {
				for (int i = 0; i < 22 && !done; i++) {
					Values.sleep(1000);
				}
				done = true;
			}
		}.start();
	}

	/**
	 * Loads the image used as the game over screen.
	 */
	private void loadImages() {
		ArrayList<Character> chars = Load.getCharacters();
		String name = "GameOver";
		for (Character c : chars) {
			name += c.getName();
		}
		name += ".jpg";
		background = 
			ImageHandler.addToCurrentLoadNow(Values.TitleImages + name);
	}

	/**
	 * The update method of title screen. It is used by the organizer.
	 * 
	 * @param elapsedTime the time between updates.
	 */
	public void update(float elapsedTime) {
		checkGameInput();
		super.update(elapsedTime);
	}
	
	/**
	 * Checks the input from the player.
	 */
	public void checkGameInput() {
		if (done || gameActions[CROSS].isPressed()) {
			if (!fadeout) {
				done = true;
				nextPlace = "Title Screen";
				exit(Values.EXIT);
			}
		}
	}
	
	/**
	 * The draw method of game over screen. It draws the background and
	 * the menu.
	 * 
	 * @param g3D the graphics on which to draw.
	 */
	public void draw(float dt, Graphics g3D) {
		g3D.setColor(1);
		g3D.setFontSize(24);
		g3D.drawImage(background, 0, 0);
		super.draw(dt, g3D);
	}
}