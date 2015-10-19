/*
 * Classname: DeckPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/02/2008
 */
package menu;

import info.Database;

import java.util.ArrayList;
import java.util.HashMap;

import menu.tutorial.Tutorial;

import character.Character;


import factories.Load;
import graphics.Graphics;

import organizer.GameMode;

/**
 * This class represents the page in the menu where the player can organize 
 * the decks in the game. A deck is a deck of cards that is used when battling.
 * On this deck page, the user can exchange cards between their own deck and
 * the main party deck, but also arrange the decks.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 11 Feb 2008
 */
public class TutorialPage extends AbstractPage {
	
	private static final ArrayList<String> list = createList(); 
	private static final HashMap<String, String> map = createMap();
	private static final int NORMAL = 0; 
	private static final int TUTORIAL = 1; 
	private int mode = NORMAL; 

	private Tutorial tutorial;
	
	private static ArrayList<String> createList() {
		ArrayList<String> l = new ArrayList<String>();
		l.add("Battle - Basic");
		l.add("Battle - Cards & Slots");
		l.add("Battle - Battle Modes");
		l.add("Battle - Elements");
		l.add("Levels");
		l.add("Bless");
		l.add("Equipment & Slots");
		l.add("Cards");
		l.add("Decks");
		return l;
	};
	
	private static HashMap<String, String> createMap() {
		HashMap<String, String> map = new HashMap<String, String>();
		map.put("Battle - Basic", "forest of reil--forest path");
		map.put("Battle - Cards & Slots", "forest of reil--deep forest");
		map.put("Battle - Battle Modes", "grivera--first floor");
		map.put("Battle - Elements", "elements");
		map.put("Levels", "churchlevels");
		map.put("Bless", "churchbless");
		map.put("Equipment & Slots", "weaponstore");
		map.put("Cards", "cardstore");
		map.put("Decks", "deck");
		return map;
	}

	/**
	 * Creates the deck page from the given parameters.
	 * 
	 * @param character the character which deck to show.
	 * @param m the main deck to show.
	 * @param index 
	 * @param activeDeck 
	 */
	public TutorialPage() {
		activeNode = new Node(null, "Tutorial");
		fillRoot(true);
		activeNode.setMenuCursor(0);
		setPage(START_PAGE);
	}
	
	/**
	 * Fills the root menu node.
	 * 
	 * @param resetCursor true if the hand should be moved to the top.
	 */
	private void fillRoot(boolean resetCursor) {
		Node n = activeNode;
		n.removeChildren(resetCursor);
		
		for (String s : list) {
			if (Database.getStatusFor(map.get(s)+".tut") == 2) {
				n.insertChild(s);
			}
		}
		
		n.insertChild("Back");
		n.setStandardWithBB();
		n.updateHandPos();
	}

	/**
	 * This method is called by the menu when the player presses up.
	 * It just forwards the message to the currentDeck.
	 */
	public void upPressed() {
		if (mode == NORMAL) {
			activeNode.previousChild();
		}
	}

	/**
	 * This method is called by the menu when the player presses down.
	 * It just forwards the message to the currentDeck.
	 */
	public void downPressed() {
		if (mode == NORMAL) {
			activeNode.nextChild();
		}
	}

	/**
	 * Overrides the method from AbstractPage. It causes the deck page to
	 * initialize the status page. This means that the deck mode is exited 
	 * and the status mode takes over.
	 */
	public void circlePressed() {
		if (mode == NORMAL) {
			MainMenu.getMainMenu().initStartPage(3);
		}
	}

	public void crossPressed() {
		switch (mode) {
		case NORMAL:
			String command = activeNode.getCurrentChild().getName();
			if (command.equals("Back")) {
				circlePressed();
			} else {
				String s = map.get(command);
				tutorial = new Tutorial(s, true);
				if (tutorial.increment()) {
					mode = TUTORIAL;
					tutorial.setActive(true);
				}
			}
			break;
		case TUTORIAL:
			if (tutorial.crossedPressed()) {
				mode = NORMAL;
			}
			break;
		}
	}
	
	/**
	 * This method is called by the menu when the player presses the select
	 * button. It will display / hide the card information text.
	 */
	public void selectPressed() {
		// HELP
	}
	
	/**
	 * This method draws the deck onto the canvas, which will then be drawn.
	 * It should be called every time the screen needs to update.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		drawStandard(g);
		int x = MenuValues.MENU_TEXT_X;
		g.drawString(activeNode.getName(), x, 54);
		activeNode.drawChildren(g);
		
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			int d = MenuValues.CHARACTER_DISTANCE * i;
			Character c = Load.getCharacters().get(i);
			StatusPage.drawTop(g, c, d);
		}
		StartPage.drawScreenShot(g);
		StartPage.drawInfo(g);
		
//		drawHelp(g);
		if (mode == TUTORIAL) {
			tutorial.drawTopLayer(g);
		}
	}

	private void drawHelp(Graphics g) {
		int helpx = 90;
		int step = 125;
		int helpy = 720;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2*step, helpyicons);
		
		g.drawString("Exit", helpx, helpy);
		g.drawString("Choose", helpx + step, helpy);
		g.drawString("Back", helpx + 2*step, helpy);
	}
}