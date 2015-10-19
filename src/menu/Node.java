/*
 * Classname: Node.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package menu;

import static menu.MenuValues.DISTANCE;
import static menu.MenuValues.MAIN_MENU_TEXT_Y_FOR_WEAPON;
import graphics.Graphics;
import info.SoundMap;
import info.Values;

import java.awt.Color;
import java.util.ArrayList;

import sound.SoundPlayer;

import equipment.AbstractEquipment;

/**
 * This class represents a node in the menu tree. 
 * A node is a choice in the menu, like equip.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 May 2008
 */
public class Node {

	private static final float[] enableColor = Graphics.BLACK;
	private static final float[] disableColor = Graphics.DARK_GRAY;

	private Node parent;
	private ArrayList<Node> children = new ArrayList<Node>();
	private MenuHand hand;
	private boolean active;
	private boolean enabled = true;
	private String name;
	private AbstractEquipment equipment;
	private int distance;
	private int Xpos;
	private int Ypos;
	private int price;
	private int number;
	private int menuCursor = 0;
	private final int Y_DISTANCE_OFFSET = 20;
	private ScrollBar scrollBar;
	
	private int bboffset;
	private int bbMaxY = -1;
	private int bbMinY = -1;

	/**
	 * Constructs a new node with parent p and name n.
	 * 
	 * @param p the parent node.
	 * @param n the name of the node.
	 */
	public Node (Node p, String n) {
		parent = p;
		name = n;
		hand = new MenuHand(Values.RIGHT);
	}

	/**
	 * Inserts a child with the given name and parent node.
	 * 
	 * @param name the newly created child with the given name and parent.
	 * @return the inserted child.
	 */
	public Node insertChild(String name) {
		Node child = new Node(this, name);
		children.add(child);
		return child;
	}

	/**
	 * Removes all the children to this node.
	 * 
	 * @param resetCursor true if this method should reset the menu cursor 
	 * and remove this nodes children.
	 */
	public void removeChildren(boolean resetCursor) {
		if (resetCursor) {
			menuCursor = 0;
			bboffset = 0;
		}
		children.clear();
	}

	/**
	 * Draws just the children of this node with default configuration,
	 * not this nodes grand children.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawChildren(Graphics g) {
		draw(g, false, false, false, false, false);
	}

	/**
	 * Draws all children (including grand children) of this node.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawAllChildren(Graphics g) {
		draw(g, false, true, false, false, false);
	}

	/**
	 * Draws the children of this node with the given configuration.
	 * 
	 * @param g the graphics to draw on.
	 * @param withPrice true if the children should be drawn with the set 
	 * price next to the text.
	 * @param allChildren true if all children should be drawn, including
	 * grand children or great grand children.
	 * @param withNumber true if the children should be drawn with the set 
	 * number next to the text.
	 * @param down true if the children should be drawn a bit further down.
	 * (25 pixels).
	 * @param withEquipment true if the children should be drawn with the set 
	 * number next to the text.
	 */
	public void drawChildrenFreely(Graphics g, boolean withPrice, 
			boolean allChildren, boolean withNumber, boolean down, 
			boolean withEquipment) {
		draw(g, withPrice, allChildren, withNumber, down, withEquipment);
	}

	/**
	 * Draws the children of this node with the given configuration.
	 * 
	 * @param g the graphics to draw on.
	 * @param withPrice true if the children should be drawn with the set 
	 * price next to the text.
	 * @param allChildren true if all children should be drawn, including
	 * grand children or great grand children.
	 * @param withNumber true if the children should be drawn with the set 
	 * number next to the text.
	 * @param down true if the extra information such as price, item should be 
	 * drawn a bit further down. (25 pixels).
	 * @param withEquipment true if the equipment or 
	 */
	private void draw(Graphics g, boolean withPrice, boolean allChildren, boolean withNumber, boolean down, boolean withEquipment) {
		if (menuCursor >= children.size()) {
			previousChild();
		}
		Node child = null;
		for (int i = 0; i < children.size(); i++) {
			child = children.get(i);
			if (allChildren && child.isActive()) {
				child.drawAllChildren(g);
			}
			g.setColor(child.enabled ? enableColor : disableColor);
			if (!child.getName().contains("character")) {
				int y = (Ypos + i * distance) + bboffset;
				if (bbMinY == -1 || 
						(y >= bbMinY && y <= bbMaxY)) {
					if (withPrice) {
						drawWithPrice(child, g, y, down);
					} 
					if (withNumber) {
						drawWithNumber(child, g, y, withNumber);
					} 
					if (!withPrice && !withNumber) {
						g.drawString(child.getName(), Xpos, y);
					}
					if (withEquipment) {
						drawWithEquipment(child, g, y, down);
					}
				}
			}
		}
		if (child != null) {
			hand.drawHand(g);
			if (bbMinY != -1) {
				int h = bbMaxY - bbMinY;
				if ((children.size() - 1) * distance > h) {
					scrollBar.draw(g, menuCursor, children.size());
				}
			}
		}
	}

	/**
	 * Draws the given child on the given graphics at the given y position.
	 * It could also move the text a bit further down if down is set to true. 
	 * This method draws the child with the set price stored in 
	 * the given child.
	 * 
	 * @param child the child to draw on the given graphics.
	 * @param g the graphics to draw on.
	 * @param y the y position to draw the text.
	 * @param down true if the text should be moved down a bit.
	 */
	private void drawWithPrice(
			Node child, Graphics g, int y, boolean down) {
		g.drawString(child.getName(), Xpos, y);
		if (child.getPrice() > 0) {
			g.setFontSize(20);
			String price = child.getPrice() + " gp";
			g.drawStringRightAligned(price, y + (down ? 25 : 0), 985);
			g.setFontSize(MenuValues.MENU_FONT_SIZE);
		}
	}

	/**
	 * This method draws the given child with the stored equipment
	 * a bit further down (if down is true), right aligned and 
	 * with a smaller font.
	 * Like:
	 * 		| Left Hand:		|
	 * 		|		Excalibur 	|
	 * 
	 * @param child the node to draw.
	 * @param g the graphics on which to draw the node.
	 * @param y the height of the node.
	 * @param down true if the name of the equipment should be drawn
	 * under the name of the node.
	 */
	private void drawWithEquipment(
			Node child, Graphics g, int y, boolean down) {
		AbstractEquipment ae = child.getEquipment();
		if (ae != null) {
			String name = ae.getName();
			g.setFontSize(20);
			g.drawStringRightAligned(name, y + (down ? 25 : 0), 985);
			g.setFontSize(MenuValues.MENU_FONT_SIZE);
		}
	}

	/**
	 * Draws the given child on the given graphics at the given y position.
	 * It uses the given font to render the text. It could also move the
	 * text a bit further down if down is set to true. This method draws the
	 * child with the set number stored in the given child.
	 * 
	 * @param child the child to draw on the given graphics.
	 * @param g the graphics to draw on.
	 * @param y the y position to draw the text.
	 * @param withNumber true if the price has already been drawn.
	 * If this is the case the name of the node should not be drawn. 
	 */
	private void drawWithNumber(Node child, Graphics g, int y, boolean withNumber) {
		g.drawString(child.getName(), Xpos, y);
		if (child.number > 0) {
			String number = "";
			if (child.number > 1) {
				number = "(" + String.valueOf(child.number) + ")";
			}
			g.setFontSize(20);
			int x = g.calcAlignRight(number, 980);
			g.drawString(number, x, y);
			g.setFontSize(MenuValues.MENU_FONT_SIZE);
		}
	}

	/**
	 * Switches the active node from the given node activeNode to
	 * the node n.
	 * 
	 * @param activeNode the active node to switch from.
	 * @param n the node to active
	 * @return the active node. This is the same object as the given node n.
	 */
	public static Node switchNode(Node activeNode, Node n) {
		activeNode.setActive(false);
		activeNode = n;
		activeNode.setActive(true);
		return activeNode;
	}

	///////////////////////
	// GETTERS & SETTERS //
	///////////////////////

	/**
	 * Checks if this node is active
	 * 
	 * @return true if the node is active
	 */
	public boolean isActive() {
		return active;
	}

	/**
	 * Gets the child with the given name.
	 * 
	 * @param name the name of the child.
	 * @return the child with the given name.
	 */
	public Node getChild(String name) {
		for (int i = 0; i < children.size(); i++) {
			if (children.get(i).name.equals(name)) {
				return children.get(i);
			}
		}
		return null;
	}

	/**
	 * Gets the child at index i.
	 * 
	 * @param i the index of the child to get.
	 * @return the child with index i.
	 */
	public Node getChild(int i) {
		return children.get(i);
	}

	/**
	 * Gets the child at the current index.
	 * 
	 * @return the node with the current index.
	 */
	public Node getCurrentChild() {
		return children.get(menuCursor);
	}

	/**
	 * Moves the cursor to the next child. If the index is higher than the 
	 * number of children the index is restored to zero. This means that if 
	 * the hand is at the bottom of a menu, and the user presses the down 
	 * button and calls this method the hand will be moved to the top 
	 * of the menu. 
	 */
	public void nextChild() {nextChild(true);}
	public void nextChild(boolean play) {
		if (play) SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		menuCursor++;
		if (menuCursor == children.size()) {
			menuCursor = 0;
			if (bbMinY != -1) {
				bboffset = 0;
			}
		}
		updateHandPos();
	}

	/**
	 * Moves the cursor to the previous child. If the current index is less 
	 * than the zero the index is set to the number of children. This means 
	 * that if the hand is at the top of a menu, and the user presses the up 
	 * button and calls this method the hand will be moved to the bottom 
	 * of the menu. 
	 */
	public void previousChild() {previousChild(true);}
	public void previousChild(boolean play) {
		if (play) SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		menuCursor--;
		if (menuCursor == -1) {
			menuCursor = children.size()-1;
			if (bbMinY != -1) {
				int h = bbMaxY - bbMinY;
				int nr = (int) Math.ceil(h / (float) distance);
				bboffset = (nr - menuCursor) * distance;
			}
		}
		updateHandPos();
	}

	/**
	 * Updates the hand position.
	 */
	public void updateHandPos() {
		int yPos = menuCursor * distance + Ypos + bboffset;
		if (bbMinY != -1) {
			if (yPos <= bbMinY) {
				bboffset += ((bbMinY - yPos) / distance) * distance;
			} else if (yPos >= bbMaxY) {
				bboffset -= ((yPos - bbMaxY) / distance) * distance;
			}
			yPos = menuCursor * distance + Ypos + bboffset;
		}
		hand.setYpos(yPos - Y_DISTANCE_OFFSET);
	}

	/**
	 * Checks if this nodes has any children.
	 * 
	 * @return true if this node has children.
	 */
	public boolean hasChildren() {
		return children.size() != 0;
	}

	/**
	 * Activates or deactivates this node.
	 * 
	 * @param active true if this node is to be active.
	 */
	public void setActive(boolean active) {
		this.active = active;
		hand.setVisible(active);
	}

	/**
	 * Sets the name of this node to the given name.
	 * 
	 * @param name the name of the node.
	 */
	public void setName(String name) {
		this.name = name;
	}

	/**
	 * Sets the price of this node. It is used in stores to store the price
	 * of the item this node represents.
	 * 
	 * @param p the price of the node.
	 */
	public void setPrice(int p) {
		price = p;
	}

	/**
	 * Gets the price stored in this node.
	 * 
	 * @return price the price stored in this node.
	 */
	public int getPrice() {
		return price;
	}

	/**
	 * Gets the parent to this node.
	 * 
	 * @return the parent node.
	 */
	public Node getParent() {
		return parent;
	}

	/**
	 * Gets the distance.
	 * 
	 * @return distance.
	 */
	public int getDistance() {
		return distance;
	}

	/**
	 * Gets this nodes name.
	 * 
	 * @return the name.
	 */
	public String getName() {
		return name;
	}

	/**
	 * Gets the y position of this node.
	 * 
	 * @return the ypos the y position of this node.
	 */
	public int getYpos() {
		return Ypos;
	}

	/**
	 * Gets the size of the menu.
	 * 
	 * @return the size of the menu.
	 */
	public int getSize() {
		return children.size();
	}

	/**
	 * Gets the current index of the menu cursor. The index
	 * of the node that the hand is pointing at.
	 * 
	 * @return the cursor index of the menu.
	 */
	public int getMenuCursor() {
		return menuCursor;
	}

	/**
	 * Gets the y position of the menu hand.
	 * 
	 * @return the y position of the menu hand.
	 */
	public int getMenuHandYpos() {
		return hand.getYpos();
	}

	/**
	 * Gets the position of the menu hand.
	 * 
	 * @return the position of the menu hand.
	 */
	public int[] getHandPos() {
		return hand.getPos();
	}

	/**
	 * Gets the equipment stored in this node or null if non is set.
	 * 
	 * @return the equipment stored in this node.
	 */
	public AbstractEquipment getEquipment() {
		return equipment;
	}

	/**
	 * Sets the position of the menu.
	 * 
	 * @param is the array containing the position to set.
	 */
	public void setPositions(int[] is) {
		setPositions(is[Values.X], is[Values.Y]);
	}

	/**
	 * Sets the position of the menu.
	 * 
	 * @param x the x position to set.
	 * @param y the y position to set.
	 */
	public void setPositions(int x, int y) {
		Xpos = x;
		Ypos = y;
		for (int i = 0; i < children.size(); i++) {
			children.get(i).setYpos(Ypos + (i * distance));
			children.get(i).setXpos(Xpos);
		}
		hand.setXpos(Xpos - 35);
		hand.setYpos(Ypos - Y_DISTANCE_OFFSET);
	}

	/**
	 * Sets the x position to set.
	 * 
	 * @param xpos the xpos to set
	 */
	private void setXpos(int xpos) {
		Xpos = xpos;
	}

	/**
	 * Sets the y position to set.
	 * 
	 * @param ypos the ypos to set
	 */
	public void setYpos(int ypos) {
		Ypos = ypos;
	}

	/**
	 * Sets the distance.
	 * 
	 * @param d the distance to be set.
	 */
	public void setDistance(int d) {
		distance = d;
	}

	/**
	 * Sets the current menu index to the given number.
	 * 
	 * @param currentChild the index to use as the current menu cursor.
	 */
	public void setMenuCursor(int currentChild) {
		menuCursor = currentChild;
		updateHandPos();
	}

	/**
	 * Store the given equipment in this node.
	 * 
	 * @param equip the equipment to store.
	 */
	public void setEquipment(AbstractEquipment equip) {
		equipment = equip;
		if (equip != null) {
			number = equip.getNumber();   
		}
	}
	
	public void setNoNumber() {
		number = -1;
	}

	/**
	 * Enables or disables this node. If a node is enabled it uses
	 * the color set by setEnableColor().
	 * 
	 * @param enabled true if this node should be enabled.
	 */
	public void setEnabled(boolean enabled) {
		this.enabled = enabled;
	}

	/**
	 * Adds the given number to the number that is stored in this node.
	 * 
	 * @param nr the number to add.
	 */
	public void addNumber(int nr) {
		number = Math.max(number + nr, 0);
	}

	/**
	 * Gets the number that is stored in this node.
	 * 
	 * @return the number that is stored.
	 */
	public int getNumber() {
		return number;
	}

	/**
	 * Gets the total price of all the children of this node.
	 * The total price is the number times the price for all this 
	 * nodes children.
	 * 
	 * @return the total price of all this nodes children.
	 */
	public int getTotalPrice() {
		int price = 0;
		for (int i = 0; i < children.size(); i++) {
			Node n = children.get(i);
			price += n.getPrice();
		}
		return price;
	}

	/**
	 * Checks if this node is enabled.
	 * 
	 * @return true if it is enabled.
	 */
	public boolean isEnabled() {
		return enabled;
	}
	
	public void setCurrentChild(String name) {
		for (int i = 0; i < children.size(); i++) {
			if (name.equalsIgnoreCase(children.get(i).name)) {
				setMenuCursor(i);
				return;
			}
		}
	}

	public void setBoundingBox(int minY, int maxY, int barX) {
		bbMinY = minY;
		bbMaxY = maxY;
		scrollBar = new ScrollBar(barX, minY, (maxY - minY));
	}

	public void setDimmedHand(boolean dimmed) {
		hand.setDimmed(dimmed);
	}

	public void setStandardWeaponWithBB() {
		setDistance(DISTANCE);
		int maxY = MAIN_MENU_TEXT_Y_FOR_WEAPON + 5 * DISTANCE;
		setBoundingBox(MAIN_MENU_TEXT_Y_FOR_WEAPON, maxY, 978);
		setPositions(MenuValues.MENU_TEXT_X, MAIN_MENU_TEXT_Y_FOR_WEAPON);
	}

	public void setStandardWithBB() {
		setDistance(MenuValues.DISTANCE);
		setPositions(
				MenuValues.MENU_TEXT_X, 
				MenuValues.MENU_TEXT_Y);
		int maxY = MenuValues.MENU_TEXT_Y + 6 * MenuValues.DISTANCE;
		setBoundingBox(MenuValues.MENU_TEXT_Y, maxY, 978);
	}
}