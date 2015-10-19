/*
 * Classname: StatusPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 18/02/2008
 */
package menu;

import static menu.MenuValues.DISTANCE;
import static menu.MenuValues.MENU_TEXT_X;
import static menu.MenuValues.MENU_TEXT_Y;
import static menu.MenuValues.MENU_TITLE_Y;
import equipment.AbstractEquipment;
import equipment.Armor;
import equipment.Shield;
import equipment.Slot;
import equipment.Weapon;
import factories.Load;
import graphics.Graphics;
import info.Values;

import java.util.ArrayList;

import organizer.GameMode;

import character.Character;
import character.Creature;

/**
 * This class represents the page in the menu where the player can see
 * the current characters status. It is possible to switch to another characters
 * status by pressing the R2 or L2 buttons.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 18 Feb 2008
 */
public class StatusPage extends AbstractPage {

	private static int[] x = MenuValues.STATUS_X;
	private static int[] y = Values.copyArray(MenuValues.STATUS_Y);
	
	private Character c;
	private int characterIndex;

	/**
	 * Creates a new StatusPage that displays the character with the given 
	 * index (in the load.character list).
	 *
	 * @param character the index of the character to display the status for.
	 * @param currentChild the index of the current child in the status menu.
	 */
	protected StatusPage(int character, int currentChild) {
		super();
		c = Load.getCharacters().get(character);
		characterIndex = character;
		fillRoot();
		activeNode.setMenuCursor(currentChild);
		setPage(STATUS_PAGE);
	}

	/**
	 * Creates the status menu node, fills it with children 
	 * and returns it.
	 */
	private void fillRoot() {
		activeNode = new Node(null, "Status");
		if (!activeNode.hasChildren()) {
			activeNode.insertChild("Back");
			activeNode.setDistance(DISTANCE);
			activeNode.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
		}
	}

	/**
	 * This method moves the menu hand one step upwards in the currently 
	 * active menu. To do this, it simply calls the previousChild() method
	 * in the Node class. This method is called when the player presses up.
	 */
	public void upPressed() {
		activeNode.previousChild();
	}

	/**
	 * This method moves the menu hand one step downwards in the currently
	 * active menu. To do this, it simply calls the nextChild() method
	 * in the Node class. This method is called when the player presses down.
	 */
	public void downPressed() {
		activeNode.nextChild();
	}

	/**
	 * This method activates the current node in the menu tree. It then 
	 * calls the MainMenu.initXXXPage(), where the X:es is the name
	 * of the page to initiate.
	 */
	public void crossPressed() {
		String mode = activeNode.getCurrentChild().getName();
		if (mode.equals("Back")) {
			circlePressed();
		}
	}

	/**
	 * This method is called if the player presses the circle button, and
	 * it will cause the start page to be initiated.
	 */
	public void circlePressed() {
		MainMenu.getMainMenu().initStartPage(3);
	}

	/**
	 * This method changes so that the next character in the party will
	 * have its status shown on the page. If there is no next character 
	 * in the party the first character (index 0) will be used instead.
	 */
	public void R1Pressed() {
		MainMenu.getMainMenu().initStatusPage(
				++characterIndex, activeNode.getMenuCursor());
	}

	/**
	 * This method changes so that the previous character in the party will
	 * have its status shown on the page. If there is no previous character 
	 * in the party the last character (index == load.character.size - 1) 
	 * will be used instead.
	 */
	public void L1Pressed() {
		MainMenu.getMainMenu().initStatusPage(
				--characterIndex, activeNode.getMenuCursor());
	}

	/**
	 * This method uses the static method draw() to draw the status page onto
	 * the canvas which is provided by the super class AbstractPage.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		drawStandard(g);
		activeNode.drawAllChildren(g);
		g.drawString(activeNode.getName(), MENU_TEXT_X, MENU_TITLE_Y);
		draw(g, c);
		StartPage.drawInfo(g);
		StartPage.drawScreenShot(g);
		drawHelp(g);
	}

	/**
	 * This method draws the status screen onto the given graphics. The given 
	 * image is used as a background where the given characters status is drawn
	 * on. The node is used to draw the menu and its children in the menu strip.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character which status will be drawn.
	 */
	protected static void draw(Graphics g, Character c) {	
		drawTop(g, c);
		drawAttributes(g, c);
	}
	
	/**
	 * Draws the information about given character on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character to draw the information about.
	 * @param compare the equipment to compare the given characters 
	 * equipment to, if compare is not null.
	 */
	protected static void draw(Graphics g, Character c, 
			AbstractEquipment compare) {
		drawTop(g, c, 0, compare);
		drawAttributes(g, c);
	}
	
	/**
	 * Draws the attributes of the given character on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character whose attributes to draw. 
	 */
	protected static void drawAttributes(Graphics g, Character c) {
		draw(g, c.get(Creature.ATTACK), 0, 5);
		draw(g, c.get(Creature.MAGIC_ATTACK), 1, 5);
		draw(g, c.get(Creature.SUPPORT_ATTACK), 2, 5);
		draw(g, c.get(Creature.AGILITY), 3, 5);

		draw(g, c.get(Creature.DEFENSE), 0, 6);
		draw(g, c.get(Creature.MAGIC_DEFENSE), 1, 6);
		draw(g, c.get(Creature.HIT), 2, 6);
		draw(g, c.get(Creature.EVADE), 3, 6);
		
		draw(g, c.get(Creature.EXPERIANCE), 0, 7);
		draw(g, c.get(Creature.EXP_LEFT_TO_NEXT_LEVEL), 1, 7);
		draw(g, c.get(Creature.LEVEL), 2, 7);
		draw(g, c.get(Creature.DECK_SIZE), 3, 7);
	}

	/**
	 * This method only draws the top three rows of the characters status.
	 * This includes the weapon and the image of the character. It is
	 * used in the start page to display only this information.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character whose status to draw.
	 * @param offset the y offset, the amount of pixels 
	 * to change the y value with.
	 */
	public static void drawTop(Graphics g, Character c, int offset) {
		drawTop(g, c, offset, null);
	}
	
	/**
	 * This method only draws the top three rows of the characters status. This
	 * includes the weapon and the image of the character. It is used in the 
	 * start page to display only this information. This method will also draw
	 * the difference between the equipment of the given character and the 
	 * given equipment compare. The difference is drawn in red if it is a 
	 * negative difference and in green if it is positive.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character whose status to draw.
	 * @param offset the y offset, the amount of pixels 
	 * to change the y value with.
	 * @param compare the equipment to compare the given characters equipment
	 * to.
	 */
	public static void drawTop(Graphics g, Character c, int offset, 
			AbstractEquipment compare) {
		int[] yCopy = null;
		if (offset != 0) {
			yCopy = Values.copyArray(y);
			for (int i = 0; i < y.length; i++) {
				y[i] += offset;
			}
		}
		g.drawImage(c.getImage(), x[0], y[0]);
		draw(g, c.getName(), 1, 1);
		draw(g, c, "Class: ", Creature.CLASS, 3, 1);
		draw(g, c, "Level: ", Creature.LEVEL, 4, 1);
		if (!c.isAlive()) {
			draw(g, "Dead", 2, 1);
		} else {
			draw(g, "Hp: " + c.getLife(), 2, 1);
		}
		draw(g, "Off. Slots: ", 1, 2);
		draw(g, "Def. Slots: ", 1, 3);
		drawSlots(g, c, compare);
		if (yCopy != null) {
			y = yCopy;
		}
	}
	
	/**
	 * Draws the slots of the character on the given graphics. It also draws
	 * the slots that the character would have if the given compare equipment
	 * would be equipped. If the character would gain additional slots when 
	 * equipping the compare item, the additional slots is drawn slightly 
	 * transparent and in green. If the character would loose slots, the lost
	 * slots are drawn slightly transparent and in red.   
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character whose slots to draw.
	 * @param compare the equipment to compare with.
	 */
	private static void drawSlots(Graphics g, Character c, 
			AbstractEquipment compare) {
		Weapon w = c.getWeapon();
		if (w != null) {
			ArrayList<Slot> slots = compare instanceof Weapon ? compare.getSlots() : null;
			drawSlots(g, w.getSlots(), slots, y[8]);
		}
		ArrayList<Slot> defSlots = Slot.merge(c.getArmor(), c.getLeftHand());
		ArrayList<Slot> slots = null;
		if (compare instanceof Armor) {
			slots = compare.getSlots();
			AbstractEquipment leftHand = c.getLeftHand();
			if (leftHand != null) {
				slots = Slot.merge(leftHand.getSlots(), slots);
			}
		} else if (compare instanceof Shield) {
			slots = compare.getSlots();
			AbstractEquipment armor = c.getArmor();
			if (armor != null) {
				slots = Slot.merge(armor.getSlots(), slots);
			}
		}
		drawSlots(g, defSlots, slots, y[9]);
	}

	/**
	 * This method draws the information about the given equipment on the 
	 * given graphics. The given offset is used to offset the 
	 * MenuValues.STATUS_Y array, e.g increase all values in 
	 * MenuValues.STATUS_Y by offset. This increment is done on a copy of 
	 * MenuValues.STATUS_Y.
	 *  
	 * @param g the graphics to draw on.
	 * @param ae the equipment to get the element from.
	 * @param offset the amount to offset the values in MenuValues.STATUS_Y.
	 */
	public static void drawEquip(Graphics g, AbstractEquipment ae, int offset) {
		int[] yCopy = null;
		if (offset != 0) {
			yCopy = Values.copyArray(y);
			for (int i = 0; i < y.length; i++) {
				y[i] += offset;
			}
		}
		g.drawImage(ae.getImage(), x[0] + 25, y[0]);
		draw(g, ae.getName(), 1, 1);
		int yPos = ae instanceof Weapon ? y[8] : y[9];
		draw(g, "Off. Slots:", 1, 2);
		draw(g, "Def. Slots:", 1, 3);
		drawSlots(g, ae.getSlots(), null, yPos);

		draw(g, "Attack: " + (int) (ae.getAttack() * 100) + " %", 0, 6);
		draw(g, "Magic Off: " + (int) (ae.getMagic() * 100) + " %", 1, 6);
		draw(g, "Support: " + (int) (ae.getSupport() * 100) + " %", 2, 6);
		draw(g, "Agility: " + (int) (ae.getAgility() * 100) + " %", 3, 6);

		draw(g, "Defence: " + (int) (ae.getDefense() * 100) + " %", 0, 7);
		draw(g, "Magic Def: " + (int) (ae.getMagicDefense() * 100) + " %", 1, 7);
		draw(g, "Hit: " + (int) (ae.getHit() * 100) + " %", 2, 7);
		draw(g, "Evade: " + (int) (ae.getEvade() * 100) + " %", 3, 7);

		EquipPage.drawInformation(g, ae, MenuValues.EQUIP_TEXT_Y + offset);
		if (yCopy != null) {
			y = yCopy;
		}
	}

	/**
	 * This method draws the status screen onto the given graphics. The given 
	 * image is used as a background where the given characters status is drawn
	 * on. The node is used to draw the menu and its children in the 
	 * menu strip.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character whose status to draw.
	 */
	protected static void drawTop(Graphics g, Character c) {
		drawTop(g, c, 0);
	}

	/**
	 * This method draws the given array of slots at the given height on
	 * the given graphics.
	 *  
	 * @param g the graphics to draw on.
	 * @param slots the slots to draw.
	 * @param compareW the slots to compare the given list of slots with. 
	 * @param y the height of the slots.
	 */
	private static void drawSlots(
			Graphics g, ArrayList<Slot> slots, 
			ArrayList<Slot> compareW, int y) {
		int[] type = new int[3];
		int[] t = new int[3];
		if (compareW != null) {
			for (int i = 0; i < compareW.size(); i++) {
				type[compareW.get(i).getType()]++;
			}
			for (int i = 0; i < slots.size(); i++) {
				t[slots.get(i).getType()]++;
			}
			int drawn = 0;
			for (int i = 0; i < t.length; i++) {
				int number = Math.max(t[i], type[i]);
				for (int j = 0; j < number; j++) {
					if (j < Math.min(t[i], type[i])) {
						g.setImageColor(1, 1, 1, 1);
						// Normal color
					} else if (j < t[i]) {
						// Red
						g.setImageColor(.75f, 0, 0, 1f);
					} else if (j < type[i]) {
						// Green
						g.setImageColor(0, .75f, 0, 1f);
					}
					String name = "small" + Values.MenuImages + i + "slot.png";
					g.drawImage(name, drawn * Slot.DISTANCE + 307, y);
					drawn++;
				}
			}
		} else {
			for (int i = 0; i < slots.size(); i++) {
				Slot s = slots.get(i);
				g.drawImage(s.getSmallImage(), i * Slot.DISTANCE + 307, y);
			}
		}
		g.setImageColor(1, 1, 1, 1);
	}

	/**
	 * This method draws the given attribute of the given character. It does
	 * so by first adding the given string before the attribute. It uses 
	 * the given values as indices in the MenuValues.x, .y to get the 
	 * coordinates. 
	 * 
	 * @param g the graphics to draw on.
	 * @param c the character to get the attributes from.
	 * @param s the string to draw before the attribute.
	 * @param attr the attribute to get.
	 * @param xi the index in MenuValues.x to get the x coordinate.
	 * @param yi the index in MenuValues.y to get the y coordinate.
	 */
	private static void draw(
			Graphics g, Character c, String s, int attr, int xi, int yi) {
		g.drawString(s + c.getAttribute(attr), x[xi], y[yi]);
	}

	/**
	 * This method draws the given string on the given graphics. It uses 
	 * the given values as indices in the MenuValues.x, .y to get the 
	 * coordinates. 
	 * 
	 * @param g the graphics to draw on.
	 * @param s the string to draw before the attribute.
	 * @param xi the index in MenuValues.x to get the x coordinate.
	 * @param yi the index in MenuValues.y to get the y coordinate.
	 */
	private static void draw(
			Graphics g, String s, int xi, int yi) {
		g.drawString(s, x[xi], y[yi]);
	}
		
	private void drawHelp(Graphics g) {
		int helpx = 90;
		int step = 125;
		int helpy = 720;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + step, helpyicons);
		
		g.drawString("Exit", helpx, helpy);
		g.drawString("Back", helpx + step, helpy);
		
		helpx += 3 * step + 100;
		helpxicons += 3 * step + 90;
		step += 70;
		
		g.drawString("Change character", helpx, helpy);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons, helpyicons);
	}
}
