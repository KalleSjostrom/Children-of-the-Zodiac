/*
 * Classname: MainMenu.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package menu;

import info.SoundMap;
import info.Values;

import java.awt.image.BufferedImage;
import java.util.HashMap;

import organizer.GameEventListener;
import organizer.GameMode;
import organizer.MenuStarter;
import organizer.Organizer;

import sound.SoundPlayer;
import sound.SoundValues;
import character.Bestiary;
import equipment.Deck;
import factories.Load;
import graphics.Graphics;

/**
 * This is the main menu of the game. The player can access this menu 
 * from almost every mode in the game. Here, changes can be made to the 
 * equipment such as armor, weapon and deck. It consist of a number of pages
 * which all are subclasses of the abstract class AbstractPage. 
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 May 2008
 */
public class MainMenu extends GameMode {

	protected static MainMenu menu;

	protected AbstractPage currentPage;
	protected BufferedImage thumbNailScreen;
	protected String statusImage;
	protected String[] deckImages = new String[4];
	protected boolean loaded = false;

	private boolean inputLocked = false;

	/**
	 * Initiates the main menu, this method initiates this game mode.
	 * It creates its own information so it does not matter if the
	 * given info is null.
	 * 
	 * @param info could be anything.
	 */
	public void init(HashMap<String, String> info) {
		super.init(new HashMap<String, String>(), Values.DETECT_AS_KEY);
		GameEventListener.set2D();
		// TODO: 
		Organizer.getOrganizer().getPreviousMode().setMusicMode(
				SoundValues.FADE_OUT, SoundValues.SLOW, SoundValues.HALF);
		SoundPlayer.playSound(SoundMap.MENU_ENTER_MENU);
		fadein = fadeout = false;
		fadeValue = 1;
		menu = this;

		thumbNailScreen = getScreenShot();
		initStartPage(0);

		logicLoading = false;
	}

	/**
	 * Gets the MainMenu object currently in use. This is used by the 
	 * page objects to communicate with the menu and to initiate other 
	 * pages.
	 * 
	 * @return the MainMenu object in use.
	 */
	protected static MainMenu getMainMenu() {
		return menu;
	}

	/**
	 * Gets the thumb nail screen shot from the previous mode. If
	 * this mode does not implement the MenuStarter this method will 
	 * return null.
	 * 
	 * @return the thumb nail screen shot to display in the menu..
	 */
	protected BufferedImage getScreenShot() {
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		if (gm != null && gm instanceof MenuStarter) {
			MenuStarter starter = (MenuStarter) gm;
			return starter.getThumbnailScreenShot();
		}
		return null;
	}

	public void locksInput() {
		inputLocked = true;
	}

	public void unLockInput() {
		inputLocked = false;
	}

	/**
	 * Implements the update method from the GameMode class. 
	 * This method is called as long as the menu is active and with the 
	 * interval from the StaticValues class.
	 * Normally between 30 and 50 milliseconds.
	 * 
	 * @param elapsedTime the time that has elapsed since the game was 
	 * last updated.
	 */
	public void update(float elapsedTime) {
		if (!inputLocked) {
			boolean buttonPressed = true;
			if (gameActions[UP].isPressed()) {
				currentPage.upPressed();
			} else if (gameActions[RIGHT].isPressed()) {
				currentPage.rightPressed();
			} else if (gameActions[DOWN].isPressed()) {
				currentPage.downPressed();
			} else if (gameActions[LEFT].isPressed()) {
				currentPage.leftPressed();
			} else if (MenuStarter.isMenuButtonPressed(gameActions)) {
				currentPage.trianglePressed();
			} else if (gameActions[CIRCLE].isPressed()) {
				SoundPlayer.playSound(SoundMap.MENU_BACK);
				currentPage.circlePressed();
			} else if (gameActions[CROSS].isPressed()) {
				currentPage.crossPressed();
			} else if (gameActions[SQUARE].isPressed()) {
				currentPage.squarePressed();
			} else if (gameActions[R1].isPressed()) {
				currentPage.R1Pressed();
			} else if (gameActions[R2].isPressed()) {
				currentPage.R2Pressed();
			} else if (gameActions[L1].isPressed()) {
				currentPage.L1Pressed();
			} else if (gameActions[L2].isPressed()) {
				currentPage.L2Pressed();
			} else if (gameActions[SELECT].isPressed()) {
				currentPage.selectPressed();
			} else {
				buttonPressed = false;
			}
			if (buttonPressed) {
				currentPage.buttonPressed();
			}
		}
		currentPage.update(elapsedTime);
		super.update(elapsedTime);
	}

	/**
	 * Initiates the start page.
	 * 
	 * @param menuIndex the index where the menu hand should start.
	 */
	protected void initStartPage(int menuIndex) {
		currentPage = new StartPage(thumbNailScreen, menuIndex);
	}

	/**
	 * Initiates the equip page with the given character index.
	 * 
	 * @param character the index of the character to equip.
	 * @param menuIndex the index where the menu hand should start.
	 * @param inSub true if the page should start in the sub menu.
	 */
	protected void initEquipPage(int character, int menuIndex, boolean inSub) {
		character = checkCharacterInRange(character);
		currentPage = new EquipPage(character, menuIndex, inSub);
	}

	/**
	 * Initializes the deck mode, loads images and sets values.
	 * 
	 * @param character the character which deck to show.
	 * @param i 
	 * @param activeDeck 
	 */
	protected void initDeckPage(int character, int activeDeck, Deck currentDeck) {
		character = checkCharacterInRange(character);
		int index = 0;
		if (currentDeck != null) {
			index = currentDeck.getMenuCursor();
		}
		currentPage = new DeckPage(
					character, Load.getPartyItems().getMainDeck(), 
					activeDeck, index);
	}

	/**
	 * Checks the that the given character index is in the range of the 
	 * list of character from the load class. If the character index 
	 * is less than zero it returns the last index in the character list and
	 * vice versa.
	 * 
	 * @param character the index to check.
	 * @return the character index to use to get a character from the list
	 * of character. 
	 */
	private int checkCharacterInRange(int character) {
		int size = Load.getCharacters().size();
		if (character < 0) {
			character = size - 1;
		} else if (character >= size) {
			character = 0;
		}
		return character;
	}

	/**
	 * Initiates the status page.
	 * 
	 * @param character the index of the character to display the status for.
	 * @param current the index of the current child in the status menu.
	 */
	protected void initStatusPage(int character, int current) {
		character = checkCharacterInRange(character);
		currentPage = new StatusPage(character, current);
	}

	/**
	 * Initiates the bestiary page.
	 * 
	 * @param enemy the index of the enemy to display information about.
	 * @param current the index of the current child in the bestiary menu.
	 */
	protected void initBestiaryPage(int enemy, int current) {
		enemy = checkEnemyInRange(enemy);
		currentPage = new BestiaryPage(enemy, current);
	}

	public void initTutorialPage() {
		currentPage = new TutorialPage();
	}

	public void initHelpPage() {
		currentPage = new HelpPage();
	}
	
	public void initMapPage() {
		currentPage = new MapPage();
	}

	/**
	 * Checks that the given enemy index is in the range of the list of enemies
	 * from the bestiary class. If the enemy index is less than zero it returns
	 * the last index in the list of enemies and vice versa.
	 * 
	 * @param enemyIndex the index to check.
	 * @return the enemyIndex index to use to get an enemy from the list
	 * of enemies.
	 */
	protected int checkEnemyInRange(int enemyIndex) {
		int size = Bestiary.getBestiary().getSize();
		if (enemyIndex < 0) {
			enemyIndex = size - 1;
		} else if (enemyIndex >= size) {
			enemyIndex = 0;
		}
		return enemyIndex;
	}

	/**
	 * Gets the background image for the status page.
	 * 
	 * @return the background used in the status page.
	 */
	protected String getStatusImage() {
		return statusImage;
	}

	/**
	 * Exits the main menu. It calls exitWithoutFading(Values.SWITCH_BACK)
	 * to switch back to the previous mode. 
	 */
	protected void exit() {
		exitWithoutFading(Values.SWITCH_BACK);
	}

	/**
	 * This method sets up the drawing of the menu pages.
	 * It calls the draw3D() method in the currentPage.
	 * 
	 * @param g the graphics to draw the menu on.
	 */
	public void draw(Graphics g) {
		g.setColor(1);
		g.setAlphaFunc(.02f);
		g.setFontSize(MenuValues.MENU_FONT_SIZE);
		currentPage.draw3D(g);
		super.draw(g);
	}

	public void exitTo(String startLocation) {
		nextPlace = startLocation;
		exit(Values.EXIT);
	}
	
	public void setGameAction() {
		super.setGameAction();
		initInput(Values.DETECT_AS_KEY);
	}
}