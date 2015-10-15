/*
 * Classname: MenuStarter.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/05/2008
 */
package organizer;

import input.GameAction.GameActions;

import java.awt.image.BufferedImage;

/**
 * This interface should be implemented if the game mode should be able
 * to enter the menu mode. The only method that is to be implemented is the
 * getThumbnailScreenShot() which enables the menu to get the
 * thumb nail screen shot to be used in the menu. 
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 19 May 2008
 */
public abstract class MenuStarter extends GameMode {
	
	private boolean enterMenu;
	private BufferedImage thumbNailScreenShot;

    /**
	 * Get the miniature screen shot of this village.
	 * This image is used in the menu.
	 * 
	 * @return the thumb nail screen shot.
	 */
	public BufferedImage getThumbnailScreenShot() {
		return thumbNailScreenShot;
	}
	
	protected void queueEnterMenu() {
		enterMenu = true;
	}
	
	public static boolean isMenuButtonPressed(GameActions[] gameActions) {
		boolean menuButtonPressed = gameActions[GameMode.TRIANGLE].isPressed();
		return menuButtonPressed;
	}
	
	protected void checkMenu() {
		if (enterMenu) {
			thumbNailScreenShot = enterMenu();
			enterMenu = false;
		}
	}
}
