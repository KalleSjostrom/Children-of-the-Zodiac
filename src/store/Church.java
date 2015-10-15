/*
 * Classname: Church.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package store;

import static menu.MenuValues.DISTANCE;
import static menu.MenuValues.MENU_TEXT_X;
import static menu.MenuValues.MENU_TEXT_Y;
import static menu.MenuValues.MENU_TITLE_Y;
import factories.Load;
import factories.Save;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import menu.AbstractPage;
import menu.MenuHand;
import menu.MenuValues;
import menu.Node;
import menu.tutorial.HelpText;
import menu.tutorial.Tutorial;

import organizer.GameMode;

import sound.SoundPlayer;
import battle.bars.LevelUpBar;
import bodies.Vector3f;
import character.Character;

/**
 * This class represents the church. In this building, the player can save
 * the game or be resurrected if any of the party members has died.
 * The priest is animated when resurrecting.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 13 May 2008
 */
public class Church extends Building {

	private static final Vector3f GREEN = new Vector3f(0, .7f, 0);
	private static final Vector3f BLUE = new Vector3f(0, 0, .7f);
	
	private static final int BLESS_NAME_DISTANCE = 50;
	private static final int BLESS_NAME_X = 50;
	private static final int BLESS_NAME_Y = 400;

	private static final int BLESS_NOT_ACTIVE = -1;
	private static final int BLESS_LOW_HAND = 0;
	private static final int BLESS_HIGH_HAND = 1;
	private static final int BLESS_MODE_ANIMATE = 2;
	private static final int BLESS_DONE = 3;

	private static final int LOWEST_UPPER_BOUND = 250;
	private static final float BLESS_SCALE = 1000f;
	private static final int BLESS_MOVE_SPEED = 10;
	
	private static final int BLESS_COST_SPEED_LOW = 60; // 60 - Dellna
	private static final int BLESS_COST_SPEED_HIGH = 30; // 30

	// 30 - Berca
	// 15
	
	// 6 - Parasne
	// 3

	private static final int NORMAL = -1;
	private static final int LEVEL_TUTORIAL = 0;
	private static final int BLESS_TUTORIAL = 1;

	private String place;
	private String keeperName;
	private String[] images = new String[3];
	private boolean saving;
	private int blessMode = BLESS_NOT_ACTIVE;
	private int mode = NORMAL;
	private static HashMap<String, Integer> map = createMap();
	private static HashMap<String, String> testInfo;
	private MenuHand handLow = new MenuHand(Values.DOWN);
	private MenuHand handHigh = new MenuHand(Values.DOWN);
	private HashMap<String, PercentPair> percents;
	private PercentPair currentPair;
	private Tutorial levelTutorial;
	private Tutorial blessTutorial;
	private HelpText text;
	
	private MenuHand handAnim;

	private static final float MAX_SPEED = .1f;
	private float speed = MAX_SPEED;
	private float interval;
	private int counter = 0;
	private int totalCost;

	/**
	 * Initiates the church.
	 * 
	 * @param info the information map containing the 
	 * information for the church.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info);
		if (info == null) {
			info = testInfo;
		}
		place = info.get("villageName");

		keeperName = info.get("keeper").replace(".png", "");
		loadFromInfo(info, keeperName + "0.png");
		activeNode = new Node(null, "Church");
		fillRoot();
		setStoreImages(CHURCH);
		setMenuImagesUsed(0x000000ff);
		loadAnimImages();

		logicLoading = false;
	}

	private static HashMap<String, Integer> createMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("Alares", 2);
		map.put("Zazo", 3);
		map.put("Pensara - The School District", 4);
		map.put("Berca", 5);
		map.put("Dellna", 6);
		return map;
	}

	private int getClass(String place) {
		return map.get(place);
	}

	/**
	 * Loads all the images of the priest. Used when animating.
	 */
	private void loadAnimImages() {
		images[0] = keeper;
		images[1] = ImageHandler.addToCurrentLoadOnUse(
				Values.StoreImages + keeperName + "1.png");
		images[2] = ImageHandler.addToCurrentLoadOnUse(
				Values.StoreImages + keeperName + "2.png");
	}

	/**
	 * Updates the menu. Checks the game input.
	 * 
	 * @param elapsedTime the time between updates.
	 */
	public void update(long elapsedTime) {
		if (!isFading()) {
			checkGameInput();
		}
	}

	protected void rightPressed() {
		addToPair(blessMode, BLESS_MOVE_SPEED, BLESS_COST_SPEED_LOW, BLESS_COST_SPEED_HIGH);
	}
	protected void leftPressed() {
		addToPair(blessMode, -BLESS_MOVE_SPEED, -BLESS_COST_SPEED_LOW, -BLESS_COST_SPEED_HIGH);
	}

	private void addToPair(int type, int speed, int costSpeedLow, int costSpeedHigh) {
		if (blessMode == BLESS_LOW_HAND || blessMode == BLESS_HIGH_HAND) {
			PercentPair pair = getPair();
			if (pair != null) {
				if (blessMode == BLESS_LOW_HAND) {
					int tempLow = pair.low + speed;
					if (tempLow >= 0 && tempLow <= pair.high) {
						pair.low = tempLow;
						pair.cost += costSpeedLow;
					}
				} else if (blessMode == BLESS_HIGH_HAND) {
					int tempHigh = pair.high + speed;
					if (tempHigh >= Math.max(pair.low, LOWEST_UPPER_BOUND) && tempHigh <= BLESS_SCALE) {
						pair.high = tempHigh;
						pair.cost += costSpeedHigh;
					}
				}
			}
		}
	}

	private PercentPair getPair() {
		int i = activeNode.getMenuCursor();
		return getPair(i);
	}

	private PercentPair getPair(int i) {
		ArrayList<Character> l = Load.getCharacters();
		PercentPair pair = null;
		if (i < l.size()) {
			String name = l.get(i).getName();
			pair = percents.get(name);
		}
		return pair;
	}

	/**
	 * This method is called when the player presses the up button.
	 * It uses moves the hand to the previous child in the current menu.
	 */
	protected void upPressed() {
		if (!saving) {
			activeNode.previousChild();
		}
	}

	/**
	 * This method is called when the player presses the down button.
	 * It uses moves the hand to the next child in the current menu.
	 */
	protected void downPressed() {
		if (!saving) {
			activeNode.nextChild();
		}
	}

	/**
	 * This method is called if the circle button has been pressed.
	 * It backs one step in the menu, if the root has been reached
	 * the building is exited.
	 */
	protected void circlePressed() {
		if (!saving && blessMode != BLESS_MODE_ANIMATE) {
			blessMode = BLESS_NOT_ACTIVE;
			Node n = activeNode.getParent();
			if (n != null) {
				activeNode = n;
				makeDefaultDialog();
				keeper = images[0];
			} else {
				exit(Values.SWITCH_BACK);
			}
		}
	}

	/**
	 * This method is called when the cross button has been pressed.
	 * It takes the name of the node pressed, and executes different commands.
	 */
	protected void crossPressed() {
		switch (mode) {
		case NORMAL : 
			crossPressedInNormalMode();
			break;
		case LEVEL_TUTORIAL : 
			if (levelTutorial.crossedPressed()) {
				mode = NORMAL;
			}
			break;
		case BLESS_TUTORIAL : 
			if (blessTutorial != null && blessTutorial.crossedPressed()) {
				mode = NORMAL;
				activateBlessPage(activeNode.getCurrentChild());
			}
			break;
		}
	}

	private void crossPressedInNormalMode() {
		if (!saving) {
			Node n = activeNode.getCurrentChild();
			if (!n.isEnabled()) {
				return;
			}
			String choice = n.getName();
			if (choice.equals("Save")) {
				activeNode = n;
				initSaveMenu();
			} else if (choice.equals("Tutorial - Levels")) {
				levelTutorial = new Tutorial("churchlevels", true);
				if (levelTutorial.increment()) {
					mode = LEVEL_TUTORIAL; 
					levelTutorial.setActive(true);
				}
			} else if (choice.equals("Resurrect")) {
				activeNode = n;
				initResurrectMenu();
			} else if (choice.equals("Bless")) {
				blessTutorial = new Tutorial("churchbless", false);
				if (blessTutorial.increment()) {
					mode = BLESS_TUTORIAL;
					blessTutorial.setActive(true);
				} else {
					activateBlessPage(n);
				}
			} else if (choice.equals("Exit")) {
				exit(Values.SWITCH_BACK);
			} else if (choice.contains("Slot")) {
				makeNewDialog("Saving.", "");
				saving = true;
				final String c = choice;
				new Thread() {
					public void run() {
						Values.sleep(500);
						makeNewDialog("Saving..", "");
						Values.sleep(500);
						makeNewDialog("Saving...", "");
						Values.sleep(500);
						Save.getSave().saveGame(c, place);
						saving = false;
						circlePressed();
						makeNewDialog("Game saved!", "Anything else?");
					}
				}.start();
			} else if (choice.equals("Back")) {
				circlePressed();
			} else if (choice.equals("Done")) {
				if (Load.getPartyItems().getGold() >= totalCost) {
					Load.getPartyItems().addGold(-totalCost);
					handAnim = new MenuHand(Values.DOWN);
					setCurrentPair(0);
					blessMode = BLESS_MODE_ANIMATE;
					String s = place + "blessing";
					Database.addStatus(s, 1);
				} else {
					SoundPlayer.playSound(SoundMap.MENU_ERROR);
//					negativeConfirm(NOT_AFFORD);
				} /*else {
					positiveConfirm();
				}*/
			} else {
				if (blessMode == BLESS_HIGH_HAND || blessMode == BLESS_LOW_HAND) {
					int bm = Math.abs(blessMode - 1);
					switchBlessMode(bm);
				} else {
					SoundPlayer.playSound(SoundMap.MENU_ERROR);
				}
			}
		}
	}
	
	private void activateBlessPage(Node n) {
		activeNode = n;
		fillBless();
		blessMode = BLESS_HIGH_HAND;
		switchBlessMode(BLESS_LOW_HAND);
		text = new HelpText("bless", 50, 50);
		if (percents == null) {
			percents = new HashMap<String, PercentPair>();
			ArrayList<Character> l = Load.getCharacters();
			for (Character c : l) {
				percents.put(c.getName(), new PercentPair(0, LOWEST_UPPER_BOUND));
			}
		}
	}

	private void setCurrentPair(int index) {
		ArrayList<Character> l = Load.getCharacters();
		counter = 0;
		activeNode.setMenuCursor(index);
		if (index < l.size()) {
			currentPair = percents.get(l.get(index).getName());
			interval = currentPair.getRandomInterval();
			speed = Math.random() >= .5f ? MAX_SPEED : -MAX_SPEED;
		} else {
			blessMode = BLESS_DONE;
			activeNode.getCurrentChild().setEnabled(false);
			int newClass = getClass(place);
			ArrayList<Character> list = Load.getCharacters();
			for (int i = 0; i < list.size(); i++) {
				list.get(i).setClass(newClass);
			}
			for (int i = 0; i < list.size(); i++) {
				PercentPair p = getPair(i);
				Character c = list.get(i);
				c.setExpPercentOfNext(p.getLow());
				c.curePercent(1);
			}
			activeNode.setEnabled(false);
		}
	}

	public void update(float elapsedTime) {
		if (blessMode == BLESS_MODE_ANIMATE) {
			handAnim.setXpos(180-28 + currentPair.getHand(interval));
			interval += speed;
			speed *= .95f;
			if (Math.abs(speed) < .001f) {
				counter++;
				speed = 0;
				if (counter > 15) {
					currentPair.setHigh(interval);
					currentPair.setLow(interval);
					setCurrentPair(activeNode.getMenuCursor() + 1);
					super.update(elapsedTime);
					return;
				}
			}
			if (interval >= currentPair.getHigh()) {
				speed = -speed;
				interval = currentPair.getHigh();
			} else if (interval <= currentPair.getLow()) {
				speed = -speed;
				interval = currentPair.getLow();
			}
		}
		super.update(elapsedTime);
	}

	private void switchBlessMode(int newBlessMode) {
		switch (blessMode) {
		case BLESS_LOW_HAND:
			handLow.setDimmed(true);
			handHigh.setDimmed(false);
			break;
		case BLESS_HIGH_HAND:
			handLow.setDimmed(false);
			handHigh.setDimmed(true);
			break;
		}
		blessMode = newBlessMode;
	}

	protected int keeperHeight() {
		return 105;
	}

	/**
	 * Creates the save menu. It changes the default dialog.
	 */
	private void initSaveMenu() {
		fillSave();
		makeNewDialog("Which slot do you wish to use?", "");
	}

	/**
	 * Creates the resurrect menu. It changes the default dialog.
	 */
	private void initResurrectMenu() {
		if (fillResurrect()) {
			makeNewDialog(
					"Who do you wish do resurrect?", "");
		} else {
			makeNewDialog(
					"There are no partymembers in need of resurrection.", "");
		}
	}

	/**
	 * This method draws the church. It can draw the church on the 
	 * given graphics3D or choose to draw it on the protected graphics
	 * from the Building class. 
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		if (blessMode != BLESS_NOT_ACTIVE && mode != BLESS_TUTORIAL) {
			AbstractPage.drawMenuBackground(g, 6);
			AbstractPage.drawMenuBackground(g, 5);
			int barDist = -20;
			int barX = 180;
			int costX = 560;
			int active = activeNode.getMenuCursor();
			ArrayList<Character> cs = Load.getCharacters();
			g.drawStringSetSize("Cost", costX, BLESS_NAME_Y - 40, 30);
			totalCost = 0;
			for (int i = 0; i < cs.size(); i++) {
				Character c = cs.get(i);
				PercentPair pair = percents.get(c.getName());
				int y = BLESS_NAME_Y + i * BLESS_NAME_DISTANCE;
				g.drawStringSetSize(pair.getCost(), costX, y, 26);
				totalCost += pair.cost;
				LevelUpBar.draw(g, barX, y + barDist, pair.getLow(), pair.getHigh(), i == active ? 1.7f : 1.7f);
				if (i == active) {
					if (blessMode == BLESS_MODE_ANIMATE) {
						handAnim.setYpos(y + barDist - 30);
						handAnim.drawHand(g);
					} else {
						handLow.setXpos(barX-28 + pair.getLowHand());
						handLow.setYpos(y + barDist - 30);
						drawHand(g, handLow, BLUE);
						
						handHigh.setXpos(barX-28 + pair.getHighHand());
						handHigh.setYpos(y + barDist - 30);
						
						drawHand(g, handHigh, GREEN);
						g.setColor(1);
					}
				}
			}
			text.drawTopLayer(g);
			
			int y = BLESS_NAME_Y + (cs.size()+1) * BLESS_NAME_DISTANCE;
			g.drawString("Total cost: ", costX - 120, y);
			g.drawString(Math.round(totalCost) + " gp", costX, y);
			g.setFontSize(26);
			activeNode.drawAllChildren(g);
			g.setFontSize(MenuValues.MENU_FONT_SIZE);

			AbstractPage.drawMenuBackground(g, 3);
			int x = MenuValues.MENU_TEXT_X;
			g.drawString("Gold: " + Load.getPartyItems().getGold()+" gp", x, 648);
			g.drawString("Steps: " + Load.getPartyItems().getSteps(), x, 689);
			g.drawString("Time: " + Load.getTime().getHours()+":" +  Load.getTime().getMin(), x, 730);
			drawHelp(g);
		} else {
			activeNode.drawAllChildren(g);
		}
		Node n = activeNode.getParent();
		if (n != null && activeNode.getName().equals("Bless")) {
			n.drawChildren(g);
		}
		String title = activeNode.getName();
		g.drawString(title, MENU_TEXT_X, MENU_TITLE_Y);
		if (levelTutorial != null) {
			levelTutorial.drawTopLayer(g);
		}
		if (blessTutorial != null) {
			blessTutorial.drawTopLayer(g);
		}
	}

	private void drawHand(Graphics g, MenuHand hand, Vector3f v) {
		if (hand.isDimmed()) {
			hand.drawHand(g);
		} else {
			g.setColor(1);
			hand.drawHandWithColor(g);
			g.setColor(v, .3f);
			hand.drawHandWithColor(g);
		}
	}

	private void drawHelp(Graphics g) {
		int helpx = 90;
		int step = 195;
		int helpy = 720;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;

		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.UP_DOWN], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.LEFT_RIGHT], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + 2 * step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 3 * step, helpyicons);

		g.drawString("Select", helpx + 7, helpy);
		g.drawString("Move marker", helpx + step + 7, helpy);
		g.drawString("Switch marker", helpx + 2 * step - 7, helpy);
		g.drawString("Back", helpx + 3 * step - 7, helpy);
	}

	/**
	 * Fills the root menu.
	 */
	private void fillRoot() {
		Node n = activeNode;
		n.insertChild("Save");
		n.insertChild("Bless").setEnabled(canBeBlessed());
		n.insertChild("Tutorial - Levels");
		n.insertChild("Exit");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
	}

	private boolean canBeBlessed() {
		String s = place + "blessing";
		return Database.getStatusFor(s) == -1;
	}

	/**
	 * Fills the save menu.
	 */
	private void fillSave() {
		Node n = activeNode;
		n.removeChildren(true);
		if (!n.hasChildren()) {
			n.insertChild("Slot 1");
			n.insertChild("Slot 2");
			n.insertChild("Slot 3");
			n.insertChild("Back");
			n.setDistance(DISTANCE);
			n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
		}
	}

	/**
	 * Fills the resurrect menu.
	 * 
	 * @return true if there is any character in need of resurrection.
	 */
	private boolean fillResurrect() {
		Node n = activeNode;
		n.removeChildren(true);
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			Character c = Load.getCharacters().get(i);
			if (!c.isAlive()) {
				n.insertChild(c.getName()).setPrice(200);
			}
		}
		n.insertChild("Back");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
		return n.getSize() - 1 != 0;
	}

	private boolean fillBless() {
		Node n = activeNode;
		n.removeChildren(true);
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			Character c = Load.getCharacters().get(i);
			n.insertChild(c.getName());
		}
		n.insertChild("Done");
		n.insertChild("Back");
		n.setDistance(BLESS_NAME_DISTANCE);
		n.setPositions(BLESS_NAME_X, BLESS_NAME_Y);
		//		n.setActive(false);
		super.changeInput(new int[]{GameMode.LEFT, GameMode.RIGHT}, Values.DETECT_ALL);
		return n.getSize() - 1 != 0;
	}

	public static void setTestMap(HashMap<String, String> info) {
		testInfo = info;
	}

	private static class PercentPair {
		int low;
		int high;
		int cost;

		public PercentPair(int low, int high) {
			this.low = low;
			this.high = high;
		}

		public void setHigh(float h) {
			high = Math.round(h * BLESS_SCALE);
		}

		public void setLow(float l) {
			low = Math.round(l * BLESS_SCALE);
		}

		public float getRandomInterval() {
			return Math.round(low + (high - low) * Math.random()) / BLESS_SCALE;
		}

		public int getLowHand() {
			return Math.round(getLow() * 340);
		}

		public int getHand(float v) {
			return Math.round(v * 340);
		}

		public int getHighHand() {
			return Math.round(getHigh() * 340);
		}

		public float getLow() {
			return low / BLESS_SCALE;
		}

		public float getHigh() {
			return high / BLESS_SCALE;
		}

		public String getCost() {
			return cost + " gp";
		}
	}
}
