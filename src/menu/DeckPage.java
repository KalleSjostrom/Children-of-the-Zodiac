/*
 * Classname: DeckPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/02/2008
 */
package menu;

import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.Iterator;

import organizer.GameMode;

import sound.SoundPlayer;
import bodies.Vector3f;
import cards.Card;
import character.Character;
import equipment.Deck;
import factories.Load;
import graphics.Graphics;

/**
 * This class represents the page in the menu where the player can organize 
 * the decks in the game. A deck is a deck of cards that is used when battling.
 * On this deck page, the user can exchange cards between their own deck and
 * the main party deck, but also arrange the decks.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 11 Feb 2008
 */
public class DeckPage extends AbstractPage {
	
	private static final int NO_DECK = -1;
	private static final int CHARACTER_DECK = 0;
	private static final int MAIN_DECK = 1;

	private static String cardHelp = Values.MenuImages + "Pieces/10.png";

	private Card selectedCard;
	private Deck charDeck;
	private Deck mainDeck;
	private Deck currentDeck;
	private Character c;
	private ScrollBar charScrollBar;
	private ScrollBar mainScrollBar;
	
	private int characterIndex;
	private int showLines = 4;
	private int lineLength = 5;
	private boolean edit;
	private boolean displayCardHelp;

	private String charName;
	private int activeDeck = NO_DECK;
	private ArrayList<Animator> animators = new ArrayList<Animator>();

	/**
	 * Creates the deck page from the given parameters.
	 * 
	 * @param character the character which deck to show.
	 * @param m the main deck to show.
	 * @param index 
	 * @param activeDeck 
	 */
	public DeckPage(int character, Deck m, int activeDeck, int index) {
		c = Load.getCharacters().get(character);
		characterIndex = character;
		charDeck = c.getDeck();
		charName = c.getName();
		charDeck.setCoordinates(MenuValues.CHAR_DECK_X, MenuValues.DECK_Y);
		charScrollBar = new ScrollBar(450, 282, 418);
		
		mainDeck = m;
		mainDeck.setCoordinates(MenuValues.MAIN_DECK_X, MenuValues.DECK_Y);
		mainScrollBar = new ScrollBar(940, 282, 418);
		
		initDecks();
		activeNode = new Node(null, "Deck");
		fillRoot(true);
		activeNode.setMenuCursor(0);
		displayCardHelp = true;
		setPage(DECK_PAGE);
		
		this.activeDeck = activeDeck;
		if (activeDeck != NO_DECK) {
			startEditing(activeDeck);
			for (int i = 0; i < index && i < currentDeck.getCurrentDeckSize(); i++) {
				currentDeck.right(false);
			}
		}
	}
	
	/**
	 * Fills the root menu node.
	 * 
	 * @param resetCursor true if the hand should be moved to the top.
	 */
	private void fillRoot(boolean resetCursor) {
		Node n = activeNode;
		n.removeChildren(resetCursor);
		n.insertChild("Edit");
		n.insertChild("Back");
		n.setDistance(35);
		n.setPositions(
				MenuValues.MENU_TEXT_X, 
				MenuValues.MAIN_MENU_TEXT_Y_FOR_DECK);
		n.updateHandPos();
	}

	/**
	 * Initiates the decks.
	 *  
	 * It resets the decks so that the hand is pointing to the top left card
	 * in each deck. It also sets how much of the deck is to be shown and
	 * changes the decks hand so it points down and is displayed 
	 * above the deck.
	 */
	private void initDecks() {
		Deck[] decks = new Deck[2];
		decks[0] = charDeck;
		decks[1] = mainDeck;

		for (int i = 0; i < decks.length; i++) {
			Deck d = decks[i];
			d.setNrOfShownCards(d.getDeckSize());
			d.setShownLines(showLines);
			d.setLineLength(lineLength);
			d.setHandPosRelative(-21, -20);
			d.reset();
		}
	}
	
	@Override
	public void update(float elapsedTime) {
		Iterator<Animator> it = animators.iterator();
		while (it.hasNext()) {
			Animator a = it.next();
			a.update(elapsedTime);
			if (a.isDone()) {
				a.addCardToDeck();
				it.remove();
			}
		}
	}

	/**
	 * This method is called by the menu when the player presses right.
	 * It just forwards the message to the currentDeck.
	 */
	public void rightPressed() {
		if (edit) {
			currentDeck.right();
		}
	}

	/**
	 * This method is called by the menu when the player presses left.
	 * It just forwards the message to the currentDeck.
	 */
	public void leftPressed() {
		if (edit) {
			currentDeck.left();	
		}
	}

	/**
	 * This method is called by the menu when the player presses up.
	 * It just forwards the message to the currentDeck.
	 */
	public void upPressed() {
		if (edit) {
			currentDeck.up();
		} else {
			activeNode.nextChild();
		}
	}

	/**
	 * This method is called by the menu when the player presses down.
	 * It just forwards the message to the currentDeck.
	 */
	public void downPressed() {
		if (edit) {
			currentDeck.down();
		} else {
			activeNode.nextChild();
		}
	}

	/**
	 * Overrides the method from AbstractPage. It causes the deck page to 
	 * switch the deck that the player is browsing in.
	 */
	public void R2Pressed() {
		if (edit) {
			currentDeck.setActive(false);
			SoundPlayer.playSound(SoundMap.MENU_SWITCH_DECK);
			switchDeck();
		}
	}
	
	public void L2Pressed() {
		R2Pressed();
	}
	
	/**
	 * This method changes so that the next character in the party will
	 * have its deck shown on the page. If the player is browsing in Kin's 
	 * deck and decides to switch to Celis', this method is called by 
	 * pressing the R2 button. If there is no next character in the party
	 * the first character (index 0) will be used instead.
	 */
	public void R1Pressed() {
		SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER);
		MainMenu.getMainMenu().initDeckPage(++characterIndex, activeDeck, currentDeck);
	}

	/**
	 * This method changes so that the previous character in the party will
	 * have its deck shown on the page. If the player is browsing in Kin's 
	 * deck and decides to switch to Celis', this method is called by 
	 * pressing the L2 button. If there is no previous character in the party
	 * the last character (index == load.character.size - 1) 
	 * will be used instead.
	 */
	public void L1Pressed() {
		SoundPlayer.playSound(SoundMap.MENU_SWITCH_CHARACTER);
		MainMenu.getMainMenu().initDeckPage(--characterIndex, activeDeck, currentDeck);
	}
	
	/**
	 * Overrides the method from AbstractPage. It causes the deck page to
	 * initialize the status page. This means that the deck mode is exited 
	 * and the status mode takes over.
	 */
	public void circlePressed() {
		if (edit) {
			edit = false;
			activeNode.setDimmedHand(false);
			currentDeck.setActive(false);
			currentDeck = null;
			activeDeck = NO_DECK;
		} else {
			MainMenu.getMainMenu().initStartPage(0);
		}
	}

	/**
	 * This method is called by the menu when the player presses
	 * the action button. If no card has been selected, it selects
	 * the card the menu hand is over, the card that the hand is pointing at.
	 * If a card has been selected, it exchanges the selected card with the 
	 * card that the hand is pointing at.
	 */
	public void crossPressed() {
		if (edit) {
			selectCard();
		} else {
			String command = activeNode.getCurrentChild().getName();
			if (command.equals("Edit")) {
				SoundPlayer.playSound(SoundMap.MENU_ACCEPT);
				startEditing(CHARACTER_DECK);
			} else if (command.equals("Back")) {
				if (currentDeck != null) { 
					currentDeck.setActive(false);
					currentDeck = null;
				}
				SoundPlayer.playSound(SoundMap.MENU_BACK);
				circlePressed();
			}
		}
	}
	
	private void startEditing(int ad) {
		edit = true;
		activeNode.setDimmedHand(true);
		activeDeck = ad;
		currentDeck = ad == CHARACTER_DECK ? charDeck : mainDeck;
		currentDeck.setActive(true);
	}
	
	/**
	 * This method is called by the menu when the player presses the select
	 * button. It will display / hide the card information text.
	 */
	public void selectPressed() {
		if (edit) {
			displayCardHelp  = !displayCardHelp;
		} else {
			SoundPlayer.playSound(SoundMap.MENU_ERROR);
		}
	}
	
	/**
	 * This method is called by the menu when the player presses the triangle
	 * button. It will sort the current deck.
	 */
	public void squarePressed() {
		if (edit) {
			Deck d = isInMainDeck() ? mainDeck : c.getDeck();
			d.sort();
		} else {
			SoundPlayer.playSound(SoundMap.MENU_ERROR);
		}
	}

	/**
	 * This method selects one card, it saves that card in "firstCard"
	 * so it can be exchanged later. 
	 * To exchange, call the exchangeCard() method.
	 */
	private void selectCard() {
		Deck from = isInMainDeck() ? mainDeck : c.getDeck();
		Deck to = isInMainDeck() ? c.getDeck() : mainDeck;
		
		selectedCard = from.getCurrent();
		if (selectedCard == null) {
			return;
		}
		if (!to.isFull(animators.size())) {
			SoundPlayer.playSound(SoundMap.MENU_CHOOSE_CARD);
			Vector3f p = from.getPosFor(selectedCard);
			from.removeCurrent();
			animators.add(new Animator(selectedCard, p, isInMainDeck(), to, to.getLastPos()));
		} else {
			selectedCard = null;
			SoundPlayer.playSound(SoundMap.MENU_ERROR);
		}
		if (from.isEmpty()) {
			circlePressed();
		}
	}

	/**
	 * Switches the focus from the characters deck to the main deck 
	 * or vice versa.
	 */
	private void switchDeck() {
		if (!isInMainDeck()) {
			activeDeck = MAIN_DECK;
			setCurrentDeck(mainDeck, charDeck);
		} else {
			activeDeck = CHARACTER_DECK;
			setCurrentDeck(charDeck, mainDeck);
		}
		currentDeck.updateHandpos(-1);
	}
	
	private boolean isInMainDeck() {
		return activeDeck == MAIN_DECK;
	}

	/**
	 * Activates the given deck and deactivates the other. This is used to
	 * switch between the decks.
	 * 
	 * @param activeDeck the deck to activate.
	 * @param passiveDeck the deck to deactivate.
	 */
	private void setCurrentDeck(Deck activeDeck, Deck passiveDeck) {
		currentDeck = activeDeck;
		currentDeck.setActive(true);
		passiveDeck.setActive(false);
	}
	
	/**
	 * This method draws the deck onto the canvas, which will then be drawn.
	 * It should be called every time the screen needs to update.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		drawStandard(g);
		g.drawString(charName + "'s Deck - " + charDeck.getSizeInfo(),
				MenuValues.CHAR_DECK_X - 10, 
				MenuValues.DECK_Y - 20);
		g.drawString("Party Deck - " + mainDeck.getSizeInfo(),
				MenuValues.MAIN_DECK_X - 10,
				MenuValues.DECK_Y - 20);
		switch (activeDeck) {
		case NO_DECK :
			g.setImageColor(1, 1, 1, 1);
			charDeck.drawDeck(g);
			mainDeck.drawDeck(g);
			break;
		case CHARACTER_DECK :
			charDeck.drawDeck(g, currentDeck.getCurrent());
			g.setImageColor(1, 1, 1, .5f);
			mainDeck.drawDeck(g);
			break;
		case MAIN_DECK :
			mainDeck.drawDeck(g, currentDeck.getCurrent());
			g.setImageColor(1, 1, 1, .5f);
			charDeck.drawDeck(g);
			break;
		}
		int x = MenuValues.MENU_TEXT_X;
		g.drawString(activeNode.getName(), x, 54);
		activeNode.drawChildren(g);
		Card c = null;
		if (displayCardHelp) {
			if (currentDeck != null) {
				 c = currentDeck.getCurrent();
			}
			drawCardInfo(g, c, -29);
			if (c == null) {
				StatusPage.drawTop(g, this.c);
			}
		} else {
		}
		charScrollBar.draw(g, charDeck.getCurrentLine() - 1, charDeck.getTotalNrOfLines());
		mainScrollBar.draw(g, mainDeck.getCurrentLine() - 1, mainDeck.getTotalNrOfLines());
		
		for (Animator a : animators) {
			a.draw(g);
		}
		switch (activeDeck) {
		case NO_DECK :
			drawTopHelp(g);
			break;
		default :
			drawDeckHelp(g);
		}
	}
	
	private void drawTopHelp(Graphics g) {
		int helpx = 90;
		int step = 125;
		int helpy = 740;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons);
		
		String n = activeNode.getCurrentChild().getName();
		g.drawString("Exit", helpx, helpy);
		g.drawString(n , helpx + step, helpy);
		g.drawString("Back", helpx + 2 * step, helpy);
	}
	
	private void drawDeckHelp(Graphics g) {
		int helpx = 90;
		int step = 125;
		int helpy = 740;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], helpxicons + 2 * step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 3 * step, helpyicons);
		
		g.drawString("Exit", helpx, helpy);
		g.drawString("Select", helpx + step, helpy);
		g.drawString("Sort", helpx + 2 * step, helpy);
		g.drawString("Back", helpx + 3 * step, helpy);
		
		helpx += 4 * step + 50;
		helpxicons += 4 * step + 40;
		step += 70;
		
		g.drawString("Change deck", helpx, helpy);
		g.drawString("Change character", helpx + step, helpy);
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L2R2], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons + step, helpyicons);
	}

	/**
	 * Draws the information of the card on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 * @param c the card which information to draw.
	 * @param y the height of the information.
	 */
	public static void drawCardInfo(Graphics g, Card c, int y) {
		g.drawImage(cardHelp, 4, y + 35);
		if (c != null) {
			int x = 150;
			c.drawCard(g, 10, y + 25, 1);
			String[] info = c.getInfo();
			String name = info[0];
			y += 75;
			g.setFontSize(26);
			g.drawString("Name: " + name, x, (y));
			
			g.setFontSize(MenuValues.MENU_FONT_SIZE);
			y += 32;
			g.drawString(info[1], x + 20, y);
			y += 27;
			g.drawString(info[2], x + 20, y);
			y += 27;
			g.drawString(info[3], x + 20, y);
			y += 32;
			
			info = c.getVeryShortInfo();
			g.setFontSize(20);
			g.drawString("Effect: " + info[0] + info[1], x, y);
		}
	}
	
	private static class Animator {
		
		private final static float VECLOCITY = 2f;
		private static final Vector3f DEFAULT_PARTY_DECK_END = new Vector3f(200, 600, 0);
		private static final Vector3f DEFAULT_MAIN_DECK_END = new Vector3f(700, 600, 0);
		private Card card;
		private Vector3f start;
		private Vector3f end;
		private float currentTime;
		private float endTime;
		private float percent;
		
		private Vector3f startToEnd;
		private Vector3f currentPos;
		private Deck to;
		
		private Animator(Card card, Vector3f p, boolean inMainDeck, Deck to, Vector3f target) {
			this.card = card;
			this.to = to;
			start = p;
			if (target != null) {
				end = target;
			} else {
				end = inMainDeck ? DEFAULT_PARTY_DECK_END : DEFAULT_MAIN_DECK_END;
			}
			startToEnd = end.subtract(start);
			
			endTime = startToEnd.length() / VECLOCITY;
			currentPos = start.add(startToEnd.mult(0));
		}
		
		public boolean isDone() {
			return percent >= 1;
		}
		
		public void addCardToDeck() {
			to.addCard(card);
		}

		private void update(float dt) {
			currentTime += dt;
			
			percent = currentTime / endTime;
			currentPos = start.add(startToEnd.mult(percent));
		}
		
		private void draw(Graphics g) {
			g.setColor(1, 1, 1, 1 - percent);
			card.drawCard(g, (int) currentPos.x, (int) currentPos.y);
			g.setColor(1);
		}
	}
}
