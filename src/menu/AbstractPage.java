/*
 * Classname: AbstractPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 17/02/2008
 */
package menu;

import graphics.Graphics;
import graphics.ImageHandler;
import info.SoundMap;
import info.Values;

import java.awt.Color;
import java.awt.Font;
import java.util.HashMap;
import java.util.Iterator;

import organizer.GameCore;
import organizer.GameMode;
import organizer.SubGameMode;

import sound.SoundPlayer;

/**
 * This class is an abstraction of a page in the menu. It has methods to 
 * implement, such as the draw method, and some that should be overridden.
 * These methods are the navigation methods and these will be called when the
 * player presses a button. For example, when the player presses the up button
 * the upPressed() method will be called. If the subclass wants anything
 * to happen when this happens, the upPressed() method must be overridden.
 * 
 * This class also has a canvas image that any subclass should use to draw on.
 * Therefore, the drawToCanvas method should be implemented.
 * When the menu calls the page to draw, this canvas is drawn.
 * 
 * The graphics is all ready double buffered on a higher level 
 * so subclasses does not need to consider this. 
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 17 Feb 2008
 */
public abstract class AbstractPage extends SubGameMode {
	
	protected static final int[] EQUIP_PAGE = new int[]{1, 7, 3, 5, 6};
	protected static final int[] START_PAGE = new int[]{0, 1, 2, 3, 10, 11, 12};
	protected static final int[] STATUS_PAGE = new int[]{1, 2, 3, 5, 6};
	protected static final int[] DECK_PAGE = new int[]{1, 8, 9};
	protected static final int[] BESTIARY_PAGE = new int[]{1, 2, 3, 4};
	
	protected static String background = ImageHandler.addPermanentlyLoadNow(
			Values.MenuImages + "back.jpg");
	
	public static String[] images = new String[16];
	static{
		for (int i = 0; i < 16; i++) {
			images[i] = ImageHandler.addPermanentlyLoadNow(
					Values.MenuImages + "Pieces/" + String.valueOf(i) + ".png");
		}
	}
	
	public static String[] BUTTON_ICONS = new String[GameMode.UP + 3];
	public static int xoffset;
	static{
		HashMap<Integer, String> map = null;
		String folder = null;
		if (GameCore.inputManager.isGamePadManager()) {
			map = createPSMap();
			folder = "PS";
			xoffset = 4;
		} else if (GameCore.inputManager.isKeyBoardManager()) {
			map = createKeyBoardMap();
			folder = "KeyBoard";
			xoffset = 0;
		}
		Iterator<Integer> it = map.keySet().iterator();
		while (it.hasNext()) {
			int i = it.next();
			BUTTON_ICONS[i] = ImageHandler.addPermanentlyLoadNow(
					Values.MenuImages + folder + "/" + map.get(i) + ".png");
		}
	}

	protected Node activeNode;
	protected Font font = Values.getFont(24);
	// protected Graphics g = Values.getGraphics();
	
	private static final int[][] pos = new int[15][2];
	static {
		int left = 762;
		int leftleft = 4;
		// 0 = character start info kin
		pos[0] = Values.createNormalPoint(leftleft, 5);
		// 1 = title piece
		pos[1] = Values.createNormalPoint(left, 2);
		// 2 = main menu right
		pos[2] = Values.createNormalPoint(left, 90);
		// 3 = gold / time / steps piece
		pos[3] = Values.createNormalPoint(left, 610);
		// 4 = huge back for the beastary
		pos[4] = Values.createNormalPoint(leftleft, 5);
		// 5 = detailed character info
		pos[5] = Values.createNormalPoint(leftleft, 5);
		// 6 = detailed equip info
		pos[6] = Values.createNormalPoint(leftleft, 325);
		// 7 = split middle right
		pos[7] = Values.createNormalPoint(left, 90);
		// 8 = mini menu under title in deck page
		pos[8] = Values.createNormalPoint(left, 90);
		// 9 = Huge deck underlay
		pos[9] = Values.createNormalPoint(leftleft, 205);
		// 10 = character start info celis
		pos[10] = Values.createNormalPoint(leftleft, 195);
		// 11 = character start info borealis
		pos[11] = Values.createNormalPoint(leftleft, 385);
		// 12 = character start info zalzi
		pos[12] = Values.createNormalPoint(leftleft, 575);
		
		// 13 = card store deck background
		pos[13] = Values.createNormalPoint(leftleft, 408);
		// 14 = main menu right small top
		pos[14] = Values.createNormalPoint(left, 92);
	}
	
	private int[] page;
	
	/**
	 * Sets the page layout to use. The predefined ones are any of the
	 * XXX_PAGE integer arrays in this class.
	 * 
	 * @param page the page layout to set.
	 */
	protected void setPage(int[] page) {
		this.page = page;
	}
	
	private static HashMap<Integer, String> createWiiMap() {
		HashMap<Integer, String> map = new HashMap<Integer, String>();
		map.put(GameMode.TRIANGLE, "wii+");
		map.put(GameMode.CROSS, "wii2");
		map.put(GameMode.CIRCLE, "wii1");
		map.put(GameMode.SQUARE, "wii-");
		map.put(GameMode.L1, "wiiB");
		map.put(GameMode.L2, "wiiA");
		map.put(GameMode.R1, "wiiB");
		map.put(GameMode.R2, "wiiA");
		map.put(GameMode.L1R1, "wiiB");
		map.put(GameMode.L2R2, "wiiA");
		map.put(GameMode.SELECT, "wiiShake");
		map.put(GameMode.START, "wiiHome");
		map.put(GameMode.UP_DOWN, "wiiUpDown");
		map.put(GameMode.LEFT_RIGHT, "wiiLeftRight");
		return map;
	}

	private static HashMap<Integer, String> createKeyBoardMap() {
		HashMap<Integer, String> map = new HashMap<Integer, String>();
		map.put(GameMode.TRIANGLE, "w");
		map.put(GameMode.CROSS, "s");
		map.put(GameMode.CIRCLE, "d");
		map.put(GameMode.L1, "q");
		map.put(GameMode.L2, "1");
		map.put(GameMode.R1, "e");
		map.put(GameMode.R2, "3");
		map.put(GameMode.L1R1, "keyboardQE");
		map.put(GameMode.L2R2, "keyboard13");
		map.put(GameMode.SELECT, "space");
		map.put(GameMode.SQUARE, "a");
		map.put(GameMode.START, "enter");
		map.put(GameMode.UP_DOWN, "keyboardUpDown");
		map.put(GameMode.LEFT_RIGHT, "keyboardLeftRight");
		return map;
	}

	private static HashMap<Integer, String> createPSMap() {
		HashMap<Integer, String> map = new HashMap<Integer, String>();
		map.put(GameMode.TRIANGLE, "playstationTriangle");
		map.put(GameMode.CROSS, "playstationCross");
		map.put(GameMode.CIRCLE, "playstationCircle");
		map.put(GameMode.L1, "playstationLeft1");
		map.put(GameMode.L2, "playstationLeft2");
		map.put(GameMode.R1, "playstationRight1");
		map.put(GameMode.R2, "playstationRight2");
		map.put(GameMode.L1R1, "playstationRL1");
		map.put(GameMode.L2R2, "playstationRL2");
		map.put(GameMode.SELECT, "playstationSelect");
		map.put(GameMode.SQUARE, "playstationSquare");
		map.put(GameMode.START, "playstationStart");
		map.put(GameMode.UP_DOWN, "playstationUpDown");
		map.put(GameMode.LEFT_RIGHT, "playstationLeftRight");
		return map;
	}

	/**
	 * Draw the menu background on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	private void drawMenuBackground(Graphics g) {
		drawMenuBackground(g, page);
	}

	public static void drawMenuBackground(Graphics g, int index) {
		g.drawImage(
				images[index], pos[index][Values.X], pos[index][Values.Y]);
	}
	
	public static void drawMenuBackground(Graphics g, int[] page) {
		for (int i = 0; i < page.length; i++) {
			int index = page[i];
			g.drawImage(
					images[index], pos[index][Values.X], pos[index][Values.Y]);
		}
	}
	
	public static void drawMenuBackground(Graphics g, int[] page, boolean[] used) {
		for (int i = 0; i < page.length; i++) {
			if (used[i]) {
				int index = page[i];
				g.drawImage(
						images[index], pos[index][Values.X], pos[index][Values.Y]);
			}
		}
	}
	
	/**
	 * This method gets the position of the hand used in the menu.
	 * 
	 * @return the position of the menu hand.
	 */
	public int[] getHandPos() {
		return activeNode.getHandPos();
	}
	
	/**
	 * Gets the images used in the menus. These are also used
	 * by the stores to make sure that the same look in the stores
	 * are exactly the same as in the menus.
	 * 
	 * @return the images used in the menus.
	 */
	public static String[] getImages() {
		return images;
	}

	/**
	 * Draws the standard graphics that all the pages should draw. The things
	 * that all the pages should draw includes the background, the page layout
	 * and the dragon overlay.
	 * 
	 * @param g3D the graphics to draw on.
	 */
	protected void drawStandard(Graphics g3D) {
		g3D.setFontSize(MenuValues.MENU_FONT_SIZE);
		Graphics.setTextColor(Color.BLACK);
		g3D.drawImage(background, 0, 0);
		drawMenuBackground(g3D);
	}
	
	public void trianglePressed() {
		SoundPlayer.playSound(SoundMap.MENU_EXIT);
		MainMenu.getMainMenu().exit();
	}
	
	/**
	 * This method draws the page on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected abstract void draw3D(Graphics g);

	public void update(float elapsedTime) {}

	public static String getExecuteButtonIcon() {
		return BUTTON_ICONS[GameMode.TRIANGLE];
	}
}
