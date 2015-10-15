package menu;

import graphics.Graphics;

import organizer.GameCore;
import organizer.GameMode;
import organizer.Organizer;

public class HelpPage extends AbstractPage {
	
	/**
	 * Creates the deck page from the given parameters.
	 * 
	 * @param character the character which deck to show.
	 * @param m the main deck to show.
	 * @param index 
	 * @param activeDeck 
	 */
	public HelpPage() {
		activeNode = new Node(null, "Options");
		fillRoot(true);
		activeNode.setMenuCursor(0);
		setPage(BESTIARY_PAGE);
	}
	
	/**
	 * Fills the root menu node.
	 * 
	 * @param resetCursor true if the hand should be moved to the top.
	 */
	private void fillRoot(boolean resetCursor) {
		Node n = activeNode;
		n.removeChildren(resetCursor);
		if (GameCore.inputManager.isGamePadManager()) {
			n.insertChild("Game Pad in use").setEnabled(false);
		} else {
			n.insertChild("Connect Game Pad");
		}
		n.insertChild("Set Music Vol");
		n.insertChild("Set SFX Vol");
		n.insertChild("Back");
		n.setDistance(MenuValues.DISTANCE);
		n.setPositions(
				MenuValues.MENU_TEXT_X, 
				MenuValues.MENU_TEXT_Y);
		n.updateHandPos();
	}

	/**
	 * This method is called by the menu when the player presses up.
	 * It just forwards the message to the currentDeck.
	 */
	public void upPressed() {
		activeNode.previousChild();
	}

	/**
	 * This method is called by the menu when the player presses down.
	 * It just forwards the message to the currentDeck.
	 */
	public void downPressed() {
		activeNode.nextChild();
	}

	/**
	 * Overrides the method from AbstractPage. It causes the deck page to
	 * initialize the status page. This means that the deck mode is exited 
	 * and the status mode takes over.
	 */
	public void circlePressed() {
		MainMenu.getMainMenu().initStartPage(4);
	}

	public void crossPressed() {
		String command = activeNode.getCurrentChild().getName();
		if (command.equals("Connect Game Pad")) {
		} else if (command.equals("Set Music Volume")) {
		} else if (command.equals("Set SFX Volume")) {
		} else if (command.equals("Back")) {
			circlePressed();
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
		StartPage.drawInfo(g);
		drawHelp(g);
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
	}
}
