package store;

import info.Values;
import menu.AbstractPage;
import menu.Node;
import equipment.AbstractEquipment;
import factories.Load;
import graphics.Graphics;
import static menu.MenuValues.DISTANCE;

public abstract class AbstractStore extends Building {
	
	protected Node confirmNode;
	private int confirm;
	public final static int POSITIVE = 0;
	public final static int NOT_AFFORD = 1;
	public final static int CANT_EQUIP = 2;
	public final static int CANT_MERGE = 3;
	public final static int POSITIVE_MERGE = 4;
	
	protected void initStore() {
		confirmNode = new Node(null, "");
	}
	
	protected abstract void fillPositiveConfirm(Node n);
	protected abstract void dirPressed(int dir);
	
	protected void checkBuy(Node node, AbstractEquipment ae) {
		if (ae != null && !Load.isCharacterActive(ae.getForWhom())) {
			negativeConfirm(CANT_EQUIP);
		} else {
			checkBuy(node.getPrice());
		}
	}
	
	protected void checkBuy(int price) {
		if (price > Load.getPartyItems().getGold()) {
			negativeConfirm(NOT_AFFORD);
		} else {
			positiveConfirm();
		}
	}

	/**
	 * This method is called when the user presses the up button.
	 * It moves the menu hand upwards in the current menu.
	 */
	protected void upPressed() {
		dirPressed(Values.UP);
	}

	/**
	 * This method is called when the user presses the down button.
	 * It moves the menu hand downwards in the current menu.
	 */
	protected void downPressed() {
		dirPressed(Values.DOWN);
	}
	
	/**
	 * This method is called when the user presses the right button.
	 * It moves the menu hand to the right when the player is editing
	 * the party's deck.
	 */
	protected void rightPressed() {
		dirPressed(Values.RIGHT);
	}
	
	/**
	 * This method is called when the user presses the left button.
	 * It moves the menu hand to the left when the player is editing
	 * the party's deck.
	 */
	protected void leftPressed() {
		dirPressed(Values.LEFT);
	}
	
	/**
	 * Fills the Confirm purchase menu.
	 */
	protected void positiveConfirm() {
		confirmNode.removeChildren(true);
		Node n = confirmNode;
		fillPositiveConfirm(n);
		n.insertChild("Cancel");
		n.setDistance(DISTANCE - 5);
		n.setPositions(440, 420);
		confirm = POSITIVE;
	}
	
	protected void positiveConfirm(String name, int type) {
		confirmNode.removeChildren(true);
		Node n = confirmNode;
		n.insertChild(name);
		n.insertChild("Cancel");
		n.setDistance(DISTANCE - 10);
		n.setPositions(450, 405);
		confirm = type;
	}
	
	/**
	 * Fills the confirm node with the response to a negative statement from
	 * the store keeper. This statement is that the player can not afford 
	 * the equipment and the only response to this is "OK".
	 */
	protected void negativeConfirm(int type) {
		confirmNode.removeChildren(true);
		confirmNode.insertChild("OK");
		confirmNode.setDistance(DISTANCE);
		confirmNode.setPositions(480, 415);
		confirm = type;
	}

	protected void drawConfirmDialog(Graphics g) {
		Node n = activeNode.getCurrentChild();
		drawConfirmDialog(g, n.getName(), n.getPrice());
	}
	
	/**
	 * Draws the confirm dialog on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void drawConfirmDialog(Graphics g, String name, int price) {
		switch (confirm) {
		case POSITIVE:
			g.fadeOldSchool(.5f);
			g.setColor(1);
			g.drawImage(AbstractPage.images[14], 400, 300);
			g.drawString(name, 430, 360);
			String s = price + " gp";
			int x = Graphics.calcAlignRight(s, 630);
			g.drawString(s, x, 390);
			break;
		case NOT_AFFORD:
			g.fadeOldSchool(.5f);
			g.setColor(1);
			g.drawImage(AbstractPage.images[3], 400, 315);
			g.drawString("You can't afford that!", 430, 360);
			break;
		case CANT_EQUIP:
			g.fadeOldSchool(.5f);
			g.setColor(1);
			g.drawImage(AbstractPage.images[3], 400, 315);
			g.drawString("No one can equip that.", 430, 360);
			break;
		case CANT_MERGE:
			g.fadeOldSchool(.5f);
			g.setColor(1);
			g.drawImage(AbstractPage.images[3], 400, 315);
			g.drawString("Can't merge that card.", 430, 360);
			break;
		case POSITIVE_MERGE :
			g.fadeOldSchool(.5f);
			g.setColor(1);
			g.drawImage(AbstractPage.images[3], 400, 315);
			g.drawString("Are you sure?", 430, 360);
			break;
		default:
			break;
		}
		confirmNode.drawAllChildren(g);
	}
}
