/*
 * Classname: EquipPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package menu;

import info.SoundMap;
import info.Values;
import java.util.ArrayList;
import organizer.GameMode;
import sound.SoundPlayer;
import store.WeaponStore;
import character.Character;
import equipment.AbstractEquipment;
import factories.Load;
import graphics.Graphics;

/**
 * This class represents the page in the menu where the player can equip
 * weapons, armors and left handed items. These can be equipped in either the 
 * right hand, body or the left hand, respectively.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 13 May 2008
 */
public class EquipPage extends AbstractPage {

	public static final int RIGHT_HAND = 0;
	public static final int LEFT_HAND = 1;
	public static final int ARMORS = 2;
	
	private static int[] x = MenuValues.STATUS_X;
	private static int[] y = MenuValues.STATUS_Y;
	
	private Character c;
	private int mode;
	private int characterIndex;

	/**
	 * Creates a equip page from the given arguments. The character integer
	 * is the index in the Load.getCharacters() array of the characters in
	 * the game. This character is gotten and the page is create with weapons
	 * and information about this character. The menuIndex is where the hand
	 * should be when the page starts. If R2 or L2 is pressed, the equip page
	 * should remain but the characters should be exchanged, this index tells
	 * the page which position to place the menu hand. The inSubMenu indicates
	 * if the page should start in a sub menu.
	 * 
	 * @param character the index of the character to equip.
	 * @param menuIndex the index where the menu hand should start.
	 * @param inSubMenu true if the page should start in the sub menu.
	 */
	public EquipPage(int character, int menuIndex, boolean inSubMenu) {
		c = Load.getCharacters().get(character);
		characterIndex = character;
		activeNode = new Node(null, "Equip");
		fillRoot(true);
		activeNode.setMenuCursor(menuIndex);
		if (inSubMenu) {
			crossPressed();
		}
		setPage(EQUIP_PAGE);
	}

	/**
	 * Fills the root menu node.
	 * 
	 * @param resetCursor true if the hand should be moved to the top.
	 */
	private void fillRoot(boolean resetCursor) {
		Node n = activeNode;
		n.removeChildren(resetCursor);
		n.insertChild(
				WeaponStore.RIGHT_HAND + ":").setEquipment(c.getWeapon());
		n.insertChild(
				WeaponStore.LEFT_HAND + ":").setEquipment(c.getLeftHand());
		n.insertChild(
				WeaponStore.BODY + ":").setEquipment(c.getArmor());
		n.setDistance(55);
		n.setPositions(MenuValues.MENU_TEXT_X, 135);
		n.updateHandPos();
	}

	/**
	 * Fills the equip menu with different equipment depending on which 
	 * mode the player has selected. This mode could be either Armors
	 * right hand or left hand. The equipment is gotten from the load object.
	 */
	private void fillEquip() {
		Node n = activeNode;
		mode = n.getParent().getMenuCursor();
		n.removeChildren(true);
		ArrayList<AbstractEquipment> equipment = null;
		if (mode == ARMORS) {
			equipment = Load.getArmorFor(c.getEnum());
		} else if (mode == RIGHT_HAND) {
			equipment = Load.getWeaponFor(c.getEnum());
		} else {
			equipment = Load.getLeftHandFor(c.getEnum());
		}
		for (int i = 0; i < equipment.size(); i++) {
			AbstractEquipment ae = equipment.get(i);
			n.insertChild(ae.getName()).setEquipment(ae);
		}
		n.insertChild("Remove").setNoNumber();
		n.setStandardWeaponWithBB();
	}
	
	/**
	 * This method is called when the player presses the up button.
	 * It displays the info about that menu node. If the current menu
	 * has no children, this method does nothing.
	 */
	public void upPressed() {
		if (activeNode.hasChildren()) {
			activeNode.previousChild();
		}
	}

	/**
	 * This method is called when the player presses the down button.
	 * It displays the info about that menu node. If the current menu
	 * has no children, this method does nothing.
	 */
	public void downPressed() {
		if (activeNode.hasChildren()) {
			activeNode.nextChild();
		}
	}

	/**
	 * This method is called when the cross button is pressed.
	 */
	public void crossPressed() {
		boolean fromMain = activeNode.getParent() == null;
		if (fromMain) {
			SoundPlayer.playSound(SoundMap.MENU_ACCEPT);
			activeNode = activeNode.getCurrentChild();
			activeNode.setActive(true);
			fillEquip();
		} else {
			AbstractEquipment ae = activeNode.getCurrentChild().getEquipment();
			String name = activeNode.getCurrentChild().getName();
			if (name.equals("Remove")) {
				c.unequip(mode);
			} else {
				c.equip(ae, true);
			}
			circlePressed();
			fillRoot(false);
		}
	}

	/**
	 * This method is called when the circle button is pressed.
	 */
	public void circlePressed() {
		Node n = activeNode.getParent();
		if (n != null) {
			activeNode = Node.switchNode(activeNode, n);
		} else {
			MainMenu.getMainMenu().initStartPage(1);
		}
	}

	/**
	 * This method is called when the R2 button is pressed.
	 * This will flip the current equip page so that it displays the next
	 * character in the party.
	 */
	public void R1Pressed() {
		SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER);
		initEquipPage(++characterIndex);
	}

	/**
	 * This method is called when the L2 button is pressed.
	 * This will flip the current equip page so that it displays the next
	 * character in the party.
	 */
	public void L1Pressed() {
		SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER);
		initEquipPage(--characterIndex);
	}

	/**
	 * This method calls the main menus method initEquipPage() with the 
	 * given index. It does some calculations so that the menu cursor
	 * is moved to the right place, (or not at all).
	 * 
	 * @param charIndex the index of the character to display.
	 */
	private void initEquipPage(int charIndex) {
		boolean inSub = activeNode.getParent() != null;
		int menuIndex;
		if (inSub) {
			menuIndex = activeNode.getParent().getMenuCursor();
		} else {
			menuIndex = activeNode.getMenuCursor();
		}
		MainMenu.getMainMenu().initEquipPage(
				charIndex, menuIndex, inSub);
	}
	
	/**
	 * This method draws the equip page on the given graphics.
	 * 
	 * @param g the graphics to draw the page on.
	 */
	protected void draw3D(Graphics g) {
		super.drawStandard(g);
		AbstractEquipment ae = activeNode.getCurrentChild().getEquipment();
		Node n = activeNode.getParent();
		int index = n == null ? -1 : n.getMenuCursor();
		
		drawStatus(g, c, ae, index);
		drawEquip(g, ae);
		Node p = activeNode.getParent();
		if (p != null) {
			p.drawChildrenFreely(g, false, false, false, true, true);
			activeNode.drawChildrenFreely(g, false, false, true, false, false);
		} else {
			activeNode.drawChildrenFreely(g, false, false, false, true, true);
		}
		int x = MenuValues.MENU_TEXT_X;
		g.drawString(activeNode.getName().replace(":", ""), x, MenuValues.MENU_TITLE_Y);
		StartPage.drawInfo(g);
		drawHelp(g);
	}

	/**
	 * Draws the status for the given character on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character to draw status for.
	 * @param ae the abstract equipment that the character 
	 * should be compared with.
	 * @param mode indicates if the characters RIGHT_HAND, LEFT_HAND 
	 * or ARMORS should be compared with the values in the given equipment.
	 */
	public static void drawStatus(Graphics g, Character c, AbstractEquipment ae, int mode) {
		if (c != null) {
			AbstractEquipment equipped = null; 
			if (mode == RIGHT_HAND) {
				equipped = c.getWeapon();
			} else if (mode == LEFT_HAND){
				equipped = c.getLeftHand();
			} else if (mode == ARMORS) {
				equipped = c.getArmor();
			}
			int[] change = AbstractEquipment.getChange(c, ae, equipped);

			g.setColor(Graphics.BLACK);
			if (ae == equipped) {
				ae = null;
			}
			StatusPage.draw(g, c, ae);

			if (mode != -1) {
				for (int i = 0; i < 2; i++) {
					for (int j = 0; j < 4; j++) {
						int nr = i * 4 + j;
						int index = Values.ATTRIBUTE_MAP[nr];
						drawChange(c.get(index), x[j], y[i + 5], change[index], g);
					}
				}
			}
		}
	}

	/**
	 * Draws a normal line of text in the equip menu, but this method
	 * first draws the given line in a black color. Then it draws the line 
	 * in green if the change is higher than zero, in red if the change is 
	 * lower than zero or not at all if the change is equal to zero. 
	 * This will result in either a green or red text with black "shadow".
	 * 
	 * The change is the value that should be drawn to the right of the line
	 * like so "Attack 14 + 3" or "Attack 14 - 3" where +3 or -3 is the change
	 * and "Attack 14" is the line.
	 * 
	 * @param line the line to draw.
	 * @param x the x position of where to draw the line.
	 * @param y the y position of where to draw the line.
	 * @param change the change.
	 * @param g the graphics to draw the line on.
	 */
	private static void drawChange(
			String line, int x, int y, int change, Graphics g) {
		if (change == 0) {
			return;
		} else if (change < 0) {
			int c = change * -1;
			g.drawString(line+ " -" + c, x, y);
			g.setColor(Graphics.RED);
			g.drawString(line+ " -" + c, x-1, y-1);
		} else if (change > 0){
			g.drawString(line+ " +" + change, x, y);
			g.setColor(Graphics.GREEN);
			g.drawString(line+ " +" + change, x-1, y-1);
		}
		g.setColor(Graphics.BLACK);
	}
	
	/**
	 * Draws the given equipment using the method StatusPage.drawEquip() if
	 * the given equipment is not null. It draws the information about the
	 * given equipment in the menu.
	 * 
	 * @param g the graphics to draw on.
	 * @param ae the abstract equipment to draw.
	 * @see StatusPage#drawEquip(Graphics, AbstractEquipment, int)
	 */
	public static void drawEquip(Graphics g, AbstractEquipment ae) {
		if (ae != null) {
			StatusPage.drawEquip(g, ae, 324);
		}
	}

	/**
	 * This method draws the information about the given equipment.
	 * 
	 * @param g the graphics to draw on.
	 * @param ae the equipment to draw the information about.
	 * @param y the height or y-position of the information.
	 */
	public static void drawInformation(Graphics g, AbstractEquipment ae, int y) {
		/*for (int i = 0; i < 3; i++) {
			g.drawString(ae.getInfo(i), x[0], y + (i * 40));
		}*/
	}
	
	private void drawHelp(Graphics g) {
		int helpx = 90;
		int step = 125;
		int helpy = 720;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons);
		
		g.drawString("Exit", helpx, helpy);
		g.drawString("Select", helpx + step, helpy);
		g.drawString("Back", helpx + 2 * step, helpy);
		
		helpx += 3 * step + 100;
		helpxicons += 3 * step + 90;
		step += 70;
		
		g.drawString("Change character", helpx, helpy);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons, helpyicons);
	}
}
