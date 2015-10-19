/*
 * Classname: WeaponStore.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package store;

import static menu.MenuValues.DISTANCE;
import static menu.MenuValues.DISTANCE_ROOM_FOR_PRICE;
import static menu.MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON;
import static menu.MenuValues.MENU_TEXT_X;
import static menu.MenuValues.MENU_TEXT_Y;
import static menu.MenuValues.MENU_TITLE_Y;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Stack;


import menu.AbstractPage;
import menu.EquipPage;
import menu.MenuValues;
import menu.Node;
import menu.tutorial.Tutorial;
import character.Character;
import equipment.AbstractEquipment;
import factories.Load;
import factories.WeaponStoreFactory;
import graphics.Graphics;

/**
 * This class represents a weapon shop in a village. In a weapon shop the 
 * player can buy or sell weapons, shield or armors. It uses the static method
 * from the equip page, in the menu, to draw parts of the store.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 May 2008
 */
public class WeaponStore extends AbstractStore {

	private static final int NO_MODE = -1;
	private static HashMap<String, String> testInfo;
	
	private Character currentCharacter;
	private String storeName;
	private Stack<Integer> stack = new Stack<Integer>();
	private ArrayList<AbstractEquipment> equipment;
	private AbstractEquipment current;
	private int mode = NO_MODE;
	private int menuMode = MENU;
	private int equipped = 0;
	private int total = 0;
	private Tutorial tutorial;
	
	public static final String RIGHT_HAND = "Weapons";
	public static final String LEFT_HAND = "Accessories";
	public static final String BODY = "Armors";

	/**
	 * Initiates the weapon store.
	 * 
	 * @param info the information about the weapon store.
	 */
	public void init(HashMap<String, String> info) {
		if (info == null) {
			info = testInfo;
		}
		super.init(info);
		initStore();
		storeName = info.get("storeName");
		loadFromInfo(info);
		activeNode = new Node(null, "Weapon Store");
		fillRoot();
		setStoreImages(WEAPON_STORE);
		setMenuImagesUsed(0x000000ff);
		stack.push(MENU);
		
		logicLoading = false;
	}

	/**
	 * This method is called when the player presses the a button. This will
	 * result in different actions depending on which state the store is in,
	 * (buy, sell, confirm and so on). It will, however, almost always lead to
	 * a movement of the menu hand.
	 * 
	 * @param dir the direction of the button pressed.
	 */
	protected void dirPressed(int dir) {
		if (menuMode == BUY || menuMode == SELL) {
			dirMenuPressed(activeNode, dir);
			updateCurrent();
		} else if (menuMode == MENU) {
			dirMenuPressed(activeNode, dir);
		} else if (menuMode == CONFIRM_BUY || menuMode == CONFIRM_SELL) {
			dirMenuPressed(confirmNode, dir);
		}
	}
	
	/**
	 * This method is called when the player presses the cross button.
	 */
	protected void crossPressed() {
		Node n = activeNode.getCurrentChild();
		String choice = n.getName();
		int newMode = menuMode;
		boolean back = false; 
		
		if (choice.equals("Back")) {
			circlePressed();
		} else if (choice.equals("Tutorial - Equipment")) {
			switch (menuMode) {
			case TUTORIAL:
				if (tutorial.crossedPressed()) {
					menuMode = stack.pop();
				}
				break;
			default:
				tutorial = new Tutorial("weaponstore", true);
				if (tutorial.increment()) {
					changeMenuMode(TUTORIAL);
					tutorial.setActive(true);
				}
				break;
			}
		} else if (choice.equals("Exit")) {
			exit(Values.SWITCH_BACK);
		} else {
			switch (menuMode) {
			case MENU :
				if (choice.equals("Buy")) {
					activeNode = Node.switchNode(activeNode, n);
					fillBuy();
					newMode = BUY;
				} else if (choice.equals("Sell")) {
					activeNode = Node.switchNode(activeNode, n);
					fillSell();
					newMode = SELL;
				} else if (choice.equals("Exit")) {
					exit(Values.SWITCH_BACK);
				}
				break;
			case BUY :
				if (choice.equals(RIGHT_HAND)) {
					initiateEquipMenu(n, EquipPage.RIGHT_HAND);
				} else if (choice.equals(LEFT_HAND)) {
					initiateEquipMenu(n, EquipPage.LEFT_HAND);
				} else if (choice.equals(BODY)) {
					initiateEquipMenu(n, EquipPage.ARMORS);
				} else {
					checkBuy(activeNode.getCurrentChild(), current);
					newMode = CONFIRM_BUY;
				}
				break;
			case SELL :
				if (choice.equals(RIGHT_HAND)) {
					initiateEquipMenu(n, EquipPage.RIGHT_HAND);
				} else if (choice.equals(LEFT_HAND)) {
					initiateEquipMenu(n, EquipPage.LEFT_HAND);
				} else if (choice.equals(BODY)) {
					initiateEquipMenu(n, EquipPage.ARMORS);
				} else {
					confirmSell();
					newMode = CONFIRM_SELL;
				}
				break;
			case CONFIRM_BUY :
				int price = activeNode.getCurrentChild().getPrice();
				choice = confirmNode.getCurrentChild().getName();
				if (choice.startsWith("Equip")) {
					Load.getPartyItems().addGold(-price);
					currentCharacter.equip(current, true);
					Load.addEquipment(current);
					updateCurrent();
				} else if (choice.startsWith("Put")) {
					Load.getPartyItems().addGold(-price);
					Load.addEquipment(current);
					updateCurrent();
				}
				back = true;
				confirmNode.setMenuCursor(0);
				menuMode = stack.pop();
				break;
			case CONFIRM_SELL : 
				price = activeNode.getCurrentChild().getPrice();
				choice = confirmNode.getCurrentChild().getName();
				if (choice.equals("Sell")) {
					Load.getPartyItems().addGold(price);
					Load.removeEquipment(activeNode.getCurrentChild().getName());
				}
				confirmNode.setMenuCursor(0);
				back = true;
				menuMode = stack.pop();
				circlePressed();
				crossPressed();
				break;
			}
			if (!back) {
				changeMenuMode(newMode);
			}
		}
	}
	
	/**
	 * This method changes the menu mode to the given mode. It also
	 * uses a stack to push the current menu mode on the stack so that
	 * it can be retrieved when the player presses the circle button.
	 * 
	 * @param newMode the mode to set.
	 */
	private void changeMenuMode(int newMode) {
		stack.push(menuMode);
		menuMode = newMode;
	}

	/**
	 * This method is called when the player presses the circle button.
	 * It backs one step in the current menu. If the root is found, this
	 * method exits the store.
	 */
	protected void circlePressed() {
		Node n = activeNode.getParent();
		if (n != null) {
			if (menuMode == CONFIRM_SELL || menuMode == CONFIRM_BUY) {
				n = activeNode.getCurrentChild();
				confirmNode.setMenuCursor(0);
				menuMode = stack.pop();
				circlePressed();
				crossPressed();
			} else {
				activeNode = Node.switchNode(activeNode, n);
				mode = NO_MODE;
				if (stack.size() == 0) {
					stack.push(0);
				}
				setMenuImagesUsed(0x000000ff);
				menuMode = stack.pop();
			}
		} else {
			exit(Values.SWITCH_BACK);
		}
	}

	/**
	 * Updates the information about a certain equipment.
	 * It will display the information about the current equipment, 
	 * the equipment that the hand is pointing at. This method
	 * should be called when the hand is moved.
	 */
	private void updateCurrent() {
		if (mode != NO_MODE) {
			Node n = activeNode.getCurrentChild();
			current = WeaponStoreFactory.getStoreFactory().getEquipmentByName(
					equipment, n.getName());
			currentCharacter = Load.getCharacterWithForWhom(current.getForWhom());
			updateNumbers();
		}
	}

	/**
	 * Initiate the equip menu. This menu is the one where the player can 
	 * select equipment from the right side, and see the information about it.
	 * 
	 * @param n the node to set as the active node.
	 * @param mode the equip mode. This could be either of EquipPage.RIGHT_HAND
	 * .LEFT_HAND or .ARMOR.
	 */
	private void initiateEquipMenu(Node n, int mode) {
		this.mode = mode; 
		activeNode = n;
		activeNode.setActive(true);
		fillEquipment(mode);
		if (activeNode.hasChildren()) {
			setMenuImagesUsed(0x00ffff0f);
			setDialogVisibility(false);
			updateCurrent();
		} else {
			activeNode.setEnabled(false);
			circlePressed();
		}
	}

	/**
	 * This method draws the weapon store on the given graphics.
	 * 
	 * @param g the graphics to draw the store on.
	 */
	protected void draw3D(Graphics g) {
		if (mode != NO_MODE) {
			activeNode.drawChildrenFreely(g, true, false, false, true, false);
		} else {
			activeNode.drawAllChildren(g);
		}
		
		Node n = activeNode.getParent();
		if (n != null && n.isActive()) {
			activeNode.getParent().drawChildren(g);
		}
		
		String title = activeNode.getName();
		g.drawString(title, 
				MENU_TEXT_X, 
				MENU_TITLE_Y);
		
		if (mode != NO_MODE) {
			EquipPage.drawStatus(g, currentCharacter, current, mode);
			EquipPage.drawEquip(g, current);
			drawInfo(g);
		} 
		switch (menuMode) {
		case CONFIRM_BUY : 
			drawConfirmDialog(g);
			break;
		case CONFIRM_SELL :
			drawConfirmSellDialog(g);
			break;
		case TUTORIAL :
			tutorial.drawTopLayer(g);
			break;
		}
	}

	/**
	 * Draws the confirm sell dialog asking if the player would like to sell 
	 * the current equipment.
	 *  
	 * @param g the graphics to draw on.
	 */
	private void drawConfirmSellDialog(Graphics g) {		
		g.fadeOldSchool(.5f);
		g.setColor(1);
		Node n = activeNode.getCurrentChild();
		g.drawImage(AbstractPage.images[14], 400, 300);
		g.drawString(n.getName() + ": " + n.getPrice() + " gp", 430, 360);
		confirmNode.drawAllChildren(g);
	}
	
	/**
	 * Updates the numbers seen in the bottom right corner in the game. These 
	 * numbers are the total amount of owned equipments of the current kind
	 * and the amount of equipped equipments of the current kind.
	 */
	private void updateNumbers() {
		equipped = 0;
		AbstractEquipment ae = Load.getEquipments().get(
				activeNode.getCurrentChild().getName());
		if (ae != null) {
			total = ae.getNumber();
			equipped = ae.isEquiped() ? 1 : 0;
		} else {
			total = 0;
		}
	}
	
	/**
	 * Draws the information concerning the purchase in the bottom right corner
	 * of the screen. This information consists in the amount of equipped 
	 * equipment of the same kind as the currently selected one, the total 
	 * amount of owned equipment of the same kind and how much gold the 
	 * character has.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawInfo(Graphics g) {
		int x = MenuValues.MENU_TEXT_X;
		
		g.drawString("Equipped: " + equipped, x, 648);
		g.drawString("Total: " + total, x, 689);
		g.drawString("Gold: " + Load.getPartyItems().getGold(), x, 730);
	}

	/**
	 * Fills the root menu.
	 */
	private void fillRoot() {
		Node n = activeNode;
		n.insertChild("Buy");
		n.insertChild("Sell");
		n.insertChild("Tutorial - Equipment");
		n.insertChild("Exit");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
	}
	
	@Override
	protected void fillPositiveConfirm(Node n) {
		n.insertChild("Equip");
		n.insertChild("Put in inventory");
	}

	/**
	 * Fills the confirm node with the response to a positive statement from
	 * the store keeper. This statement is a question asking if the player
	 * would like to sell the currently selected item. The responses to this 
	 * are yes or no.
	 */
	private void confirmSell() {
		confirmNode.removeChildren(true);
		confirmNode.insertChild("Keep");
		confirmNode.insertChild("Sell");
		confirmNode.setDistance(DISTANCE);
		confirmNode.setPositions(480, 430);
	}

	/**
	 * Fills the buy menu.
	 */
	private void fillBuy() {
		Node n = activeNode;
		n.removeChildren(true);
		if (!n.hasChildren()) {
			n.insertChild(RIGHT_HAND).setEnabled(!
					checkBuyEquipmentIsEmpty(EquipPage.RIGHT_HAND));
			n.insertChild(LEFT_HAND).setEnabled(!
					checkBuyEquipmentIsEmpty(EquipPage.LEFT_HAND));
			n.insertChild(BODY).setEnabled(!
					checkBuyEquipmentIsEmpty(EquipPage.ARMORS));
			n.insertChild("Back");
			n.setDistance(DISTANCE);
			n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
		}
	}

	/**
	 * Fills the sell menu.
	 */
	private void fillSell() {
		Node n = activeNode;
		n.removeChildren(true);
		Node rh = n.insertChild(RIGHT_HAND);
		rh.setEnabled(!
				checkSellEquipmentIsEmpty(EquipPage.RIGHT_HAND));
		int maxY = MAIN_MENU_TEXT_Y_FOR_WEAPON + 3 * DISTANCE_ROOM_FOR_PRICE;
		rh.setBoundingBox(MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978);
		
		Node lf = n.insertChild(LEFT_HAND);
		lf.setEnabled(!
				checkSellEquipmentIsEmpty(EquipPage.LEFT_HAND));
		lf.setBoundingBox(MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978);
		
		Node b = n.insertChild(BODY);
		b.setEnabled(!
				checkSellEquipmentIsEmpty(EquipPage.ARMORS));
		b.setBoundingBox(MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978);
		n.insertChild("Back");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
	}
	
	/**
	 * Checks if the equipment list for the given mode is empty or not.
	 * 
	 * @param mode the equipment mode.
	 * @return true if the list is empty.
	 */
	private boolean checkBuyEquipmentIsEmpty(int mode) {
		if (mode == EquipPage.RIGHT_HAND) {
			equipment = WeaponStoreFactory.getStoreFactory().getRightHandFor(storeName);
			return equipment.size() == 0;
		} else if (mode == EquipPage.ARMORS) {
			equipment = WeaponStoreFactory.getStoreFactory().getArmorsFor(storeName);
			return equipment.size() == 0;
		} else if (mode == EquipPage.LEFT_HAND) {
			equipment = WeaponStoreFactory.getStoreFactory().getLeftHandFor(storeName);
			return equipment.size() == 0;
		}
		return false;
	}
	
	/**
	 * Checks if the equipment list for the given mode is empty or not.
	 * 
	 * @param mode the equipment mode.
	 * @return true if the list is empty.
	 */
	private boolean checkSellEquipmentIsEmpty(int mode) {
		if (mode == EquipPage.RIGHT_HAND) {
			equipment = Load.convertWeaponListToAbstractRemoveEquipped();
			return equipment.size() == 0;
		} else if (mode == EquipPage.ARMORS) {
			equipment = Load.convertArmorListToAbstractRemoveEquipped();
			return equipment.size() == 0;
		} else if (mode == EquipPage.LEFT_HAND) {
			equipment = Load.convertShieldListToAbstractRemoveEquipped();
			return equipment.size() == 0;
		}
		return false;
	}

	/**
	 * Fills the equipment menu, with equipment of the given mode.
	 * This mode could be either of EquipPage.RIGHT_HAND .LEFT_HAND or 
	 * .ARMOR. And the list will be filled with the correct type
	 * of equipment.
	 * 
	 * @param mode the equipment mode.
	 */
	private void fillEquipment(int mode) {
		Node n = activeNode;
		n.removeChildren(false);
		int div = 1;
		switch (menuMode) {
		case BUY :
			if (mode == EquipPage.RIGHT_HAND) {
				equipment = WeaponStoreFactory.getStoreFactory().getRightHandFor(storeName);
			} else if (mode == EquipPage.ARMORS) {
				equipment = WeaponStoreFactory.getStoreFactory().getArmorsFor(storeName);
			} else if (mode == EquipPage.LEFT_HAND) {
				equipment = WeaponStoreFactory.getStoreFactory().getLeftHandFor(storeName);
			}
			break;
		case SELL :
			if (mode == EquipPage.RIGHT_HAND) {
				equipment = Load.convertWeaponListToAbstractRemoveEquipped();
			} else if (mode == EquipPage.ARMORS) {
				equipment = Load.convertArmorListToAbstractRemoveEquipped();
			} else if (mode == EquipPage.LEFT_HAND) {
				equipment = Load.convertShieldListToAbstractRemoveEquipped();
			}
			div = 2;
			break;
		}
		for (int i = 0; i < equipment.size(); i++) {
			AbstractEquipment ae = equipment.get(i);
			Node child = n.insertChild(ae.getName());
			child.setPrice(ae.getPrice() / div);
			if (div == 1) {
				int gold = Load.getPartyItems().getGold();
				child.setEnabled(ae.getPrice() <= gold);
				if (!Load.isCharacterActive(ae.getForWhom())) {
					child.setEnabled(false);
				}
			}
		}
		n.setDistance(DISTANCE_ROOM_FOR_PRICE);
		n.setPositions(MENU_TEXT_X, MAIN_MENU_TEXT_Y_FOR_WEAPON);
		n.updateHandPos();
	}

	public static void setTestMap(HashMap<String, String> info) {
		testInfo = info;
	}
}