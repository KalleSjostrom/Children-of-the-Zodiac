/*
 * Classname: Building.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/03/2008
 */
package store;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;
import java.util.HashMap;
import menu.AbstractPage;
import menu.Node;
import organizer.GameMode;
import villages.utils.Dialog;

/**
 * This abstract class represents all the buildings in the game. Meaning the
 * inside of the building of course. These buildings are stores, inns,
 * churches, pubs, libraries and so on. If a new building should be made, it
 * has to extend this class in order to work. The buildings are entered through
 * the door class. So that class must, unfortunately, be modified if a new 
 * building should be made. These classes should be created just as they would
 * in 1024 * 768 resolution. The canvas created when drawing is rescaled anyway 
 * when drawn.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 01 Mar 2008
 */
public abstract class Building extends GameMode {
	
	public static final int MENU = 0;
	public static final int BUY = 1;
	public static final int SELL = 2;
	public static final int CONFIRM_BUY = 3;
	public static final int CONFIRM_SELL = 4;
	public static final int TUTORIAL = 5;
	public static final int BASE = 6;

	public static final int[] INN = new int[]{1, 14, 3};
	public static final int[] WEAPON_STORE = new int[]{1, 14, 3, 5, 6, 7};
	public static final int[] CHURCH = new int[]{1, 14};
	public static final int[] CARD_STORE = new int[]{1, 14, 3, 13, 0};
	
	protected Node activeNode;
	protected String background;
	protected String keeper;
	
	private String name;
	private String firstLine;
	private String secondLine;
	private String[] dialog = new String[2];
	private String[] lastDialog = new String[2];
	private boolean[] menusUsed;
	private boolean dialogIsShowing = true;
	private int[] store;

	/**
	 * Creates a new building, it initiates the GameMode with the detect init
	 * value which means that only the first press of a button is detected.
	 * This method should, but does not, initiate the music.
	 * 
	 * @param info the information map for this building.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_INIT);
		Dialog.getDialog().resetDialog();
	}
	
	protected void setStoreImages(int[] store) {
		this.store = store;
	}

	/**
	 * This method gets the usual information from the standard hash map
	 * and creates the background and the default dialog. This information 
	 * hash map is designed as following:
	 * 
	 * put("background", "image.jpg");
	 * put("keeper", "image.png");
	 * put("name", "Name");
	 * put("firstLine", "What can I do for you?");
	 * put("secondLine", "...");
	 * put("night", "false");
	 * 
	 * @param info the hash map containing the information for this building.
	 */
	protected void loadFromInfo(HashMap<String, String> info) {
		loadFromInfo(info, info.get("keeper"));
	}
	
	protected void loadFromInfo(HashMap<String, String> info, String altKeeper) {
		background = ImageHandler.addToCurrentLoadOnUse(
				Values.StoreImages + info.get("background"));
		keeper = ImageHandler.addToCurrentLoadOnUse(
				Values.StoreImages + altKeeper);
		name = info.get("name");
		firstLine = info.get("firstLine");
		secondLine = info.get("secondLine");
		makeDefaultDialog();
	}

	/**
	 * Overwrites the default dialog with a new dialog create from the 
	 * parameters. This dialog will have the store keepers name and
	 * will be in the background, just as the default one. 
	 * 
	 * @param fl the first line of text in the new dialog.
	 * @param sl the second line of text in the new dialog.
	 */
	protected void makeNewDialog(String fl, String sl) {
		dialog[0] = fl;
		dialog[1] = sl;
	}

	/**
	 * Overwrites the current dialog with the default. This is the dialog 
	 * created in the loadFromInfo() method. To use the dialog, just use
	 * the protected buffered image "dialog".
	 */
	protected void makeDefaultDialog() {
		makeNewDialog(firstLine, secondLine);
	}
	
	protected void copyDialog() {
		lastDialog[0] = dialog[0];
		lastDialog[1] = dialog[1];
	}

	protected void setDialogCopyAsACurrent() {
		dialog[0] = lastDialog[0];
		dialog[1] = lastDialog[1];
	}

	/**
	 * Sets which menu images to use when drawing.
	 * 
	 * @param used the integer mask containing the information about which 
	 * menus should be used.   
	 */
	protected void setMenuImagesUsed(int used) {
		menusUsed = new boolean[store.length];
		int mask = 0x0000000f;
		for (int i = 0; i < menusUsed.length; i++) {
			menusUsed[i] = (used & mask) == mask;
			mask <<= 4;
		}
	}

	/**
	 * Sets the visibility of the dialog.
	 * 
	 * @param dis true if the dialog should be visible, 
	 * false if the dialog should be hidden.
	 */
	protected void setDialogVisibility(boolean dis) {
		dialogIsShowing = dis;
	}

	/**
	 * Updates the building.
	 * 
	 * @param elapsedTime the amount of time since the 
	 * last call to this method.
	 */
	public void update(float elapsedTime) {
		checkGameInput();
		super.update(elapsedTime);
	}

	/**
	 * Checks if the player has pressed a button. 
	 * If any button has been pressed the drawToCanvas() is called to 
	 * update the changes.
	 */
	protected void checkGameInput() {
		if (gameActions[UP].isPressed()) {
			upPressed();
		} else if (gameActions[RIGHT].isPressed()) {
			rightPressed();
		} else if (gameActions[DOWN].isPressed()) {
			downPressed();
		} else if (gameActions[LEFT].isPressed()) {
			leftPressed();
		} else if (gameActions[TRIANGLE].isPressed()) {
			trianglePressed();
		} else if (gameActions[CIRCLE].isPressed()) {
			circlePressed();
		} else if (gameActions[CROSS].isPressed()) {
			crossPressed();
		} else if (gameActions[SQUARE].isPressed()) {
			squarePressed();
		}
	}

	/**
	 * Draws the menu background. This menu will only draw the menu strips
	 * which has been set to true via the setMenuImagesUsed() method.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void drawMenuBackground(Graphics g) {
		AbstractPage.drawMenuBackground(g, store, menusUsed);
	}	
	
	protected int keeperHeight() {
		return 205;
	}

	/**
	 * This method draws the building on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(float dt, Graphics g) {
		g.setColor(0, 0, 0, 1);

		g.drawImage(background, 0, 0);
		if (dialogIsShowing) {
			Dialog.getDialog().draw(
					g, true, name, dialog[0], dialog[1], false);
		}
		g.drawCenteredImage(keeper, keeperHeight());
		drawMenuBackground(g);

		draw3D(g);
		super.draw(dt, g);
	}
	
	/**
	 * This method sets the previous or next child as current child, in the 
	 * given node, depending on the value of dir. Is dir Values.UP it will 
	 * change the current child of the given node to the previous child and
	 * the next child if the Values.DOWN is given.
	 * 
	 * @param n the node to change.
	 * @param dir the direction telling if the previous or next child should
	 * become the current child.
	 */
	public static void dirMenuPressed(Node n, int dir) {
		switch (dir) {
		case Values.UP :
			n.previousChild();
			break;
		case Values.DOWN :
			n.nextChild();
			break;
		}
	}
	
	/**
	 * This method must be overridden to draw the subclasses of Building.
	 * The given graphics can be used to draw, but also the graphics
	 * object protected by this class.
	 * 
	 * @param g3D the graphics to draw on.
	 */
	protected abstract void draw3D(Graphics g3D);

	/**
	 * This method is called when the player presses the up button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void upPressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the right button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void rightPressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the down button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void downPressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the left button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void leftPressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the triangle button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void trianglePressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the circle button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void circlePressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the cross button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void crossPressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the square button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void squarePressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the R1 button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void R1Pressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the R2 button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void R2Pressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the L1 button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void L1Pressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the L2 button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void L2Pressed() {
		// Override to implement effect.
	}

	/**
	 * This method is called when the player presses the select button.
	 * Override this method to implement the consequences to this action.
	 * This method does nothing if it is not overridden.
	 */
	protected void selectPressed() {
		// Override to implement effect.
	}
}
