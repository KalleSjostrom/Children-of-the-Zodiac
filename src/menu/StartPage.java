/*
 * Classname: StartPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 15/05/2008
 */
package menu;

import equipment.Items.Item;
import factories.Load;
import factories.Save;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.SoundMap;
import info.Values;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.util.ArrayList;

import labyrinth.Labyrinth;
import labyrinth.inventory.Inventory;
import landscape.Landscape;
import landscape.airship.AirLandscape;

import organizer.GameMode;
import organizer.Organizer;

import sound.SoundPlayer;
import character.Character;

/**
 * This page is the first page that will show when the player enters the menu.
 * In this menu, the player can choose to check the status for the player,
 * check and use items, check the logbook and load another game. On this page
 * a screenshot over the screen before the menu was entered, 
 * is shown in thumbnail size. 
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 15 May 2008
 */
public class StartPage extends AbstractPage {

	private static String frame;
	private static BufferedImage miniScreenShot;
	private static final int EQUIP_PAGE = 0;
	private static final int DECK_PAGE = 1;
	
	private Node parentNode;
	private boolean displayParent = false;
	private boolean saving = false;
	private int selectedMode = -1;
	private String savingString;

	/**
	 * Creates the start page. The given image is the thumbnail sized screenshot
	 * over the screen before the menu was entered.
	 * 
	 * @param im the image to be displayed in the menu.
	 * @param menuIndex the index where the menu hand should start.
	 */
	protected StartPage(BufferedImage im, int menuIndex) {
		super();
		miniScreenShot = im;
		activeNode = new Node(null, "Main");
		activeNode.setDistance(MenuValues.DISTANCE);
		activeNode.setPositions(
				MenuValues.MENU_TEXT_X, 
				MenuValues.MENU_TEXT_Y);
		activeNode.setMenuCursor(menuIndex);
		loadImages();
		fillRoot();
		setPage(START_PAGE);
	}

	/**
	 * Loads the images used on this page.
	 */
	private void loadImages() {
		frame = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "frame.png");
	}

	/**
	 * This method moves the menu hand one step upwards in the currently 
	 * active menu. To do this, it simply calls the previousChild() method
	 * in the Node class. This method is called when the player presses up.
	 */
	public void upPressed() {
		if (!saving) {
			activeNode.previousChild();
		}
	}

	/**
	 * This method moves the menu hand one step downwards in the currently
	 * active menu. To do this, it simply calls the nextChild() method
	 * in the Node class. This method is called when the player presses down.
	 */
	public void downPressed() {
		if (!saving) {
			activeNode.nextChild();
		}
	}

	/**
	 * This method activates the current node in the menu tree. It then calls
	 * the executeNode() method with the newly activated nodes name, 
	 * to initiate the new node. This could be to fill the new node 
	 * with children.
	 */
	public void crossPressed() {
		if (!saving && activeNode.hasChildren()) {
			Node n = activeNode.getCurrentChild();
			if (n.isEnabled()) {
				activeNode = n;
				activeNode.setActive(true);
				parentNode = activeNode.getParent();
				parentNode.setActive(false);
				displayParent = false;
				String name = activeNode.getName();
				if (!name.contains("Slot")) {
					SoundPlayer.playSound(SoundMap.ACCEPT);
				}
				executeNode(name);
			} else {
				SoundPlayer.playSound(SoundMap.ERROR);
			}
		}
	}

	/**
	 * This method backs one step in the menu tree. It will make the
	 * active nodes parent, the new active node. If the circle button 
	 * (back button) is pressed when the active node is the root, the 
	 * menu is exited and the mode that the player was in when the menu
	 * was initiated is resumed.
	 */
	public void circlePressed() {
		circlePressed(false);
	}
	
	public void circlePressed(boolean pressAnyWay) {
		if (pressAnyWay || !saving) {
			Node n = activeNode.getParent(); 
			if (n != null) {
				activeNode = Node.switchNode(activeNode, n);
				parentNode = activeNode;
			} else {
				MainMenu.getMainMenu().exit();
			}
		}
	}

	/**
	 * Executes different methods depending on which node that
	 * should be executed. This method is called right after the player
	 * has chosen a node.
	 * 
	 * @param name the name of the node.
	 */
	private void executeNode(String name) {
		if (name.equals("Deck")) {
			fillCharacter();
			displayParent = true;
			selectedMode = DECK_PAGE;
		} else if (name.equals("Equip")) {
			fillCharacter();
			displayParent = true;
			selectedMode = EQUIP_PAGE;
		} else if (name.equals("Key Items")) {
			fillItems();
		} else if (name.equals("Tutorial")) {
			MainMenu.getMainMenu().initTutorialPage();
		} else if (name.equals("Options")) {
			MainMenu.getMainMenu().initHelpPage();
		} else if (name.equals("Load")) {
			fillLoad();
		} else if (name.contains("Save")){
			fillLoad();
		} else if (name.contains("Slot")) {
			boolean save = activeNode.getParent().getName().equals("Save");
			if (save) {
				GameMode prev = Organizer.getOrganizer().getPreviousMode();
				String mainName = prev.getName();
				if (prev instanceof Labyrinth) {
					mainName += "-save";
				} else if (prev instanceof Landscape) {
					mainName = "land" + mainName;
				} else if (prev instanceof AirLandscape) {
					mainName = "air" + mainName;
				}
				final String finalMainName = mainName;
				final String finalName = name;
				savingString = "Saving.  ";
				saving = true;
				final MainMenu t = MainMenu.getMainMenu();
				SoundPlayer.playSound(SoundMap.MENU_SAVE);
				new Thread() {
					public void run() {
						circlePressed(true);
						Values.sleep(500);
						savingString = "Saving.. ";
						Values.sleep(500);
						savingString = "Saving...";
						Values.sleep(500);
						Save.getSave().saveGame(finalName, finalMainName);
						saving = false;
						t.unLockInput();
					}
				}.start();
			} else {
				Load.loadGame(name);
				MainMenu.getMainMenu().exitTo(Load.getStartLocation());
			}
		} else if (name.equals("")) {
			if (selectedMode == DECK_PAGE) {
				MainMenu.getMainMenu().initDeckPage(
						activeNode.getParent().getMenuCursor(), -1, null);
			} else if (selectedMode == EQUIP_PAGE) {
				MainMenu.getMainMenu().initEquipPage(
						activeNode.getParent().getMenuCursor(), 0, false);
			} 
		} else if (name.contains("Map")){
			MainMenu.getMainMenu().initMapPage();
		}
	}

	/**
	 * Fills the root menu.
	 */
	protected void fillRoot() {
		activeNode.insertChild("Deck");
		activeNode.insertChild("Equip");
		activeNode.insertChild("Key Items");
		activeNode.insertChild("Tutorial");
		activeNode.insertChild("Options");
		activeNode.insertChild("Map").setEnabled(
				Database.getVisitedLabyrinths().size() > 0);
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		boolean isOnSave = false;
		if (gm instanceof Labyrinth) {
			Labyrinth lab = (Labyrinth) gm;
			Inventory inv = lab.getCurrentNode().getInventory();
			if (inv != null) {
				isOnSave = inv instanceof labyrinth.inventory.Save;
			}
		} else {
			isOnSave = true;
		}
		if (isOnSave) {
			activeNode.insertChild("Save");
		} else {
			activeNode.insertChild("Load");
		}
	}

	/**
	 * Fills the character menu
	 */
	private void fillCharacter() {
		ArrayList<String> list = new ArrayList<String>();
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			list.add("");
		}
		fillMenu(list, MenuValues.CHARACTER_DISTANCE, 50, 105);
	}
	
	private void fillItems() {
		Node n = activeNode;
		n.removeChildren(true);
		for (int i = 0; i < Load.getPartyItems().itemSize(); i++) {
			Item item = Load.getPartyItems().getItem(i);
			Node child = n.insertChild(item.getName());
			child.addNumber(item.getNr());
			child.setEnabled(false);
		}
		n.setStandardWithBB();
	}

	/**
	 * Fills the load menu.
	 */
	private void fillLoad() {
		ArrayList<String> list = new ArrayList<String>();
		list.add("Slot 1");
		list.add("Slot 2");
		list.add("Slot 3");
		fillMenu(list);
	}

	/**
	 * Inserts the elements in the list as children to the activeNode.
	 * It calls the fillMenu(ArrayList<String> list, int dist, int x, int y)
	 * with default values for the integers.
	 * 
	 * @param list the list of strings to be inserted as children.
	 */
	private void fillMenu(ArrayList<String> list) {
		fillMenu(list, MenuValues.DISTANCE, MenuValues.MENU_TEXT_X, MenuValues.MENU_TEXT_Y);
	}

	/**
	 * Inserts the elements in the list as children to the activeNode.
	 * It uses the given dist for the distance between the children in 
	 * the menu, and the x and y parameters as positions for the menu.  
	 * 
	 * @param list the list of strings to be inserted as children.
	 * @param dist the distance between the children in the menu.
	 * @param x the x position of the menu.
	 * @param y the y position of the menu.
	 */
	private void fillMenu(ArrayList<String> list, int dist, int x, int y) {
		Node n = activeNode;
		n.removeChildren(true);
		for (int i = 0; i < list.size(); i++) {
			n.insertChild(list.get(i));
		}
		n.setDistance(dist);
		n.setPositions(x, y);
	}
	
	/**
	 * Draws the start page on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		drawStandard(g);
		if (displayParent) {
			parentNode.drawAllChildren(g);
		} else {
			activeNode.drawChildrenFreely(g, false, 
					true, true, false, 
					false);
		}
		String title = activeNode.getName();
		int x = MenuValues.MENU_TEXT_X;
		g.drawString(title, x, MenuValues.MENU_TITLE_Y);
		
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			int d = MenuValues.CHARACTER_DISTANCE * i;
			Character c = Load.getCharacters().get(i);
			StatusPage.drawTop(g, c, d);
		}
		drawScreenShot(g);
		drawInfo(g);
		if (saving) {
			drawConfirmBuyDialog(g);
		}
	}

	private void drawConfirmBuyDialog(Graphics g) {
		g.drawCenteredImage(Values.MenuImages + "Pieces/1.png", 300);
		g.drawString(savingString, 470, 347);
	}

	/**
	 * Draws the screen shot miniature on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public static void drawScreenShot(Graphics g) {
		g.drawImage(miniScreenShot, MenuValues.MENU_TEXT_X, 428);
		g.drawImage(frame, MenuValues.MENU_TEXT_X, 428);
	}
	
	/**
	 * Draws some general information about the player, party and the game.
	 * This information consists of the amount of gold, the number of steps
	 * taken and the time that the player has played the game.
	 * 
	 * @param g the graphics to draw the information on.
	 */
	public static void drawInfo(Graphics g) {
		int x = MenuValues.MENU_TEXT_X;
		g.drawString("Gold: " + Load.getPartyItems().getGold()+" gp", x, 648);
		g.drawString("Steps: " + Load.getPartyItems().getSteps(), x, 689);
		g.drawString("Time: " + Load.getTime().getHours()+":" +  Load.getTime().getMin(), x, 730);
	}
}
