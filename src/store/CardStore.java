/*
 * Classname: CardStore.java
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
import info.Database;
import info.Values;

import java.util.HashMap;
import java.util.Iterator;

import menu.AbstractPage;
import menu.DeckPage;
import menu.MenuValues;
import menu.Node;
import menu.ScrollBar;
import menu.tutorial.Tutorial;
import cards.AbstractCard;
import cards.Card;
import equipment.Deck;
import equipment.PartyItems;
import factories.CardStoreFactory;
import factories.Load;
import graphics.Graphics;

/**
 * This class represents an item store in a village.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 13 May 2008
 */
public class CardStore extends AbstractStore {
	
	private static HashMap<String, String> testInfo;
	private String storeName;
	private Deck currentDeck;
	private int menuMode = 0;
	private int stocked = 0;
	private ScrollBar scrollBar;
	private Tutorial tutorial;
	private ScrollBar mergeScrollBar;
	
	private static final int MERGE = BASE;
	private static final int CONFIRM_MERGE = BASE + 1;

	/**
	 * Initiates the card store with the information in the given hash map.
	 * 
	 * @param info the information to use when creating the card store.
	 */
	public void init(HashMap<String, String> info) {
		if (info == null) {
			info = testInfo;
		}
		super.init(info);
		initStore();
		storeName = info.get("storeName");
		loadFromInfo(info);
		activeNode = new Node(null, "Card Shop");
		menuMode = MENU;
		
		fillRoot();
		setStoreImages(CARD_STORE);
		setMenuImagesUsed(0x000000ff);
		
		logicLoading = false;
	}
    
	/**
	 * This method is called when the user presses the circle button.
	 * It moves to the previous place in the store. If the player is editing
	 * and presses the circle, the menu is seen.
	 */
	protected void circlePressed() {
		if (menuMode == MENU) {
			exit(Values.SWITCH_BACK);
		} else {
			switch (menuMode) {
			case CONFIRM_BUY:
				menuMode = BUY;
				break;
			case CONFIRM_MERGE:
				menuMode = MERGE;
				break;
			default:
				menuMode = MENU;
			setMenuImagesUsed(0x000000ff);
			break;
			}
		}
		setDialogVisibility(false);
	}
	
	/**
	 * This method can be called when a directional button has been pressed.
	 * The specific direction of the press is given as dir and this method will
	 * take the appropriate action depending on the state of the store.
	 * 
	 * @param dir the direction of the button press.
	 */
	protected void dirPressed(int dir) {
		switch(menuMode) {
		case MENU : 
			dirMenuPressed(activeNode, dir);
			break;
		case BUY :
			dirBuyPressed(dir);
			break;
		case CONFIRM_BUY :
			dirMenuPressed(confirmNode, dir);
			break;
		case CONFIRM_MERGE :
			dirMenuPressed(confirmNode, dir);
			break;
		case MERGE :
			dirMergePressed(confirmNode, dir);
			break;
		}
	}

	/**
	 * This method translates the given direction into a command that is 
	 * given to the current deck. If the given value dir is Values.UP the
	 * currentDeck's up() method is called. Similar results will take place
	 * if the given value is any of the other direction values in Values.
	 *
	 * @see equipment.Deck#up()
	 * @see equipment.Deck#right()
	 * @see equipment.Deck#down()
	 * @see equipment.Deck#left()
	 * @see info.Values#UP
	 * @see info.Values#RIGHT
	 * @see info.Values#DOWN
	 * @see info.Values#LEFT
	 * 
	 * @param dir the direction telling which direction method of the 
	 * currentDeck that should be called.
	 */
	private void dirBuyPressed(int dir) {
		switch (dir) {
		case Values.UP :
			currentDeck.up();
			break;
		case Values.RIGHT :
			currentDeck.right();
			break;
		case Values.DOWN :
			currentDeck.down();
			break;
		case Values.LEFT :
			currentDeck.left();
			break;
		}
		updateNumbers();
	}
	
	private void dirMergePressed(Node confirmNode, int dir) {
		switch (dir) {
		case Values.UP :
			currentDeck.up();
			break;
		case Values.RIGHT :
			currentDeck.right();
			break;
		case Values.DOWN :
			currentDeck.down();
			break;
		case Values.LEFT :
			currentDeck.left();
			break;
		}
	}
	
	/**
	 * Updates the number shown in the bottom right corner. There it will say
	 * how many of the currently selected card the player owns. 
	 */
	private void updateNumbers() {
		int inCharDeck = 0;
		if (currentDeck != null) {
			Card c = currentDeck.getCurrent();
			for (int i = 0; i < Load.getCharacters().size(); i++) {
				Deck d = Load.getCharacters().get(i).getDeck();
				inCharDeck += d.search(c);
			}
			Deck d = Load.getPartyItems().getMainDeck();
			stocked = d.search(c) + inCharDeck;
		}
	}

	/**
	 * This method is called when the player presses the cross button.
	 */
	protected void crossPressed() {
		Node n;
		String choice;
		switch (menuMode) {
		case MENU :
			n = activeNode.getCurrentChild();
			choice = n.getName();
			if (choice.equals("Tutorial - Cards")) {
				tutorial = new Tutorial("cardstore", true);
				if (tutorial.increment()) {
					menuMode = TUTORIAL;
					tutorial.setActive(true);
				}
			} else if (choice.equals("Buy cards")) {
				fillCards();
			} else if (choice.equals("Merge cards")) {
				fillMerge();
			} else if (choice.equals("Exit")) {
				exit(Values.SWITCH_BACK);
				return;
			}
			updateNumbers();
			break;
		case MERGE :
			Card currentCard = currentDeck.getCurrent();
			if (currentCard != null) {
				String sortValues = currentCard.getSortingValue();
				CardInfo info = map.get(sortValues);
				menuMode = CONFIRM_MERGE;
				if (info.enabled) {
					positiveConfirm("Merge cards", POSITIVE_MERGE);
				} else {
					negativeConfirm(CANT_MERGE);
				}
			}
			break;
		case TUTORIAL :
			if (tutorial.crossedPressed()) {
				menuMode = MENU;
			}
			break;
		case BUY :
			currentCard = currentDeck.getCurrent();
			if (currentCard != null) {
				checkBuy(currentCard.getPrice());
				menuMode = CONFIRM_BUY;
			}
			break;
		case CONFIRM_BUY :
			n = confirmNode.getCurrentChild();
			choice = n.getName();
			if (choice.equals("Buy card")) {
				Card c = currentDeck.getCurrent().copyCard();
				int price = c.getPrice();
				PartyItems p = Load.getPartyItems(); 
				p.addGold(-price);
				p.getMainDeck().addCard(c);
				Card removedCard = currentDeck.removeCurrent();
				Database.addStatus(removedCard.getDatabaseName(), 0);
				if (currentDeck.getCurrentDeckSize() == 0) {
					circlePressed();
					updateNumbers();
					return;
				}
				updateNumbers();
			}
			menuMode = BUY;
			break;
		case CONFIRM_MERGE :
			n = confirmNode.getCurrentChild();
			choice = n.getName();
			if (choice.equals("Merge cards")) {
				Card c = currentDeck.getCurrent();
				/*CardInfo cinfo = map.get(c.getSortingValue());
				cinfo.quantity -= 5;
				if (cinfo.quantity <= 0) {
					currentDeck.removeCurrent();
					map.remove(c.getSortingValue());
				}*/
				
				PartyItems p = Load.getPartyItems(); 
				p.getMainDeck().removeCard(c, 5);
				c = Card.createCard(c.getClass().getName(), c.getLevel() + 1, c.isAll());
				p.getMainDeck().addCard(c);
				setMergeDeck(p.getMainDeck(), currentDeck.getMenuCursor());
			}
			menuMode = MERGE;
			break;
		}
	}

	private void fillMerge() {
		Deck d = Load.getPartyItems().getMainDeck();
		setMergeDeck(d, 0);
		makeNewDialog("The following cards can be merged.", "");
		setDialogVisibility(true);
	}

	/**
	 * Fills the store with the normal cards. Use this method if the player
	 * chooses to buy normal cards.
	 */
	private void fillCards() {
		Deck d = CardStoreFactory.getCardsFor(storeName);
		setDeck(d);
		if (d.getTotalNrOfLines() > 2) {
			scrollBar = new ScrollBar(710, 430, 300);
		}
	}
	
	/**
	 * Sets the given deck as the current deck.
	 * 
	 * @param d the deck to set.
	 */
	private void setDeck(Deck d) {
		currentDeck = d;
		currentDeck.reset();
		currentDeck.setActive(true);
		currentDeck.setShownLines(2);
		currentDeck.setLineLength(7);
		currentDeck.setNrOfShownCards(currentDeck.getCurrentDeckSize());
		currentDeck.setHandPosRelative(0, -19);
		currentDeck.setCoordinates(8, 430);
		currentDeck.setXDistance(98);
		currentDeck.setYDistance(150);
		setMenuImagesUsed(0x0000ffff);
		menuMode = BUY;
	}
	
	HashMap<String, CardInfo> map = new HashMap<String, CardInfo>();
	private void setMergeDeck(Deck d, int cursor) {
		map.clear();
		Iterator<Card> it = d.iterator();
		while (it.hasNext()) {
			Card c = it.next();
			String s = c.getSortingValue();
			CardInfo ci = map.get(s);
			if (ci == null) {
				map.put(s, new CardInfo(c, 1, c.canBeMerged() && c.getLevel() < 3));
			} else {
				ci.quantity++;
				map.put(s, ci);
			}
		}
		Deck deck = new Deck(null);
		
		Iterator<CardInfo> mit = map.values().iterator();
		while (mit.hasNext()) {
			CardInfo ci = mit.next();
			if (ci.isEnabled()) {
				deck.addCard(ci.c);
			}
		}
		
		deck.sort();
		deck.setActive(true);
//		deck.setShownLines(2);
//		deck.setLineLength(6);
//		deck.setNrOfShownCards(deck.getCurrentDeckSize());
//		deck.setHandPosRelative(-21, -20);
//		deck.setCoordinates(16, 260);
//		deck.setXDistance(Deck.X_DISTANCE + 10);
//		deck.setYDistance(Deck.Y_DISTANCE + 5);
		deck.setShownLines(2);
		deck.setLineLength(7);
		deck.setNrOfShownCards(deck.getCurrentDeckSize());
		deck.setHandPosRelative(0, -19);
		deck.setCoordinates(8, 230);
		deck.setXDistance(98);
		deck.setYDistance(150);
//		setMenuImagesUsed(0x0000ffff);
		currentDeck = deck;
		// setMenuImagesUsed(0x00ff0fff);
		setMenuImagesUsed(0x00000fff);
		menuMode = MERGE;
		mergeScrollBar = new ScrollBar(700, 350, 330);
		for (int i = 0; i < cursor; i++) {
			currentDeck.right(false);
		}
	}

	/**
	 * Fills the root menu with options. These options are Buy cards, Buy
	 * special cards or Exit.
	 */
	private void fillRoot() {
		Node n = activeNode;
		n.insertChild("Buy cards");
		n.insertChild("Merge cards");
		n.insertChild("Tutorial - Cards");
		n.insertChild("Exit");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
	}
	
	@Override
	protected void fillPositiveConfirm(Node n) {
		n.insertChild("Buy card");
	}

	/**
	 * This method draws the item store on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
		activeNode.drawAllChildren(g);
		String title = menuMode == MENU ? activeNode.getName() : activeNode.getCurrentChild().getName(); 
		g.drawString(title, 
				MENU_TEXT_X, 
				MENU_TITLE_Y);
		switch (menuMode) {
		case MENU: break;
		case MERGE:
			drawMerge(g);
			break;
		case CONFIRM_MERGE:
			drawMerge(g);
			Card c = currentDeck.getCurrent();
			drawConfirmDialog(g, c.getName(), 0);
			break;
		/*case SHOW_MERGED_CARD:
			drawMerge(g);
			Card c = currentDeck.getCurrent();
			drawConfirmDialog(g, c.getName(), 0);
			break;*/
		case CONFIRM_BUY:
			c = currentDeck.getCurrent();
			drawBuy(g, c);
			drawConfirmDialog(g, c.getName(), c.getPrice());
			break;
		case BUY:
			c = currentDeck.getCurrent();
			drawBuy(g, c);
			break;
		case TUTORIAL :
			tutorial.drawTopLayer(g);
			break;
		}
	}
	
	private void drawMerge(Graphics g) {
		g.drawImage(AbstractPage.images[13], 4, 195);
		g.drawImage(AbstractPage.images[12], 4, 565);
		currentDeck.drawDeck(g, currentDeck.getCurrent(), map);
		if (currentDeck.getTotalNrOfLines() > currentDeck.getShowLines()) {
			mergeScrollBar.draw(g, 
					currentDeck.getCurrentLine() - 1, 
					currentDeck.getTotalNrOfLines());
		}
		Card c = currentDeck.getCurrent();
		if (c != null && c.getLevel() < 3) { 
			int fs = g.getFontSize();
			g.setFontSize(40);
			c.drawCard(g, 10, 554, 1);
			g.drawString("x 5 merges to", 200, 654);
			c.drawCard(g, 400, 554, 1, AbstractCard.NORMAL, c.getLevel() + 1);
			g.setFontSize(fs);
		}
		
		drawInfo(g);
	}
	
	private void drawMergedCard(Graphics g) {
		Card c = currentDeck.getCurrent();
		DeckPage.drawCardInfo(g, c, 530);
	}

	private void drawBuy(Graphics g, Card c) {
		c = currentDeck.getCurrent();
		if (c != null) {
			int gold = Load.getPartyItems().getGold();
			currentDeck.drawDeck(g, gold, true, currentDeck.getCurrent(), null);
			DeckPage.drawCardInfo(g, currentDeck.getCurrent(), -23);
			drawInfo(g);
			if (currentDeck.getTotalNrOfLines() > 2) {
				scrollBar.draw(g, 
						currentDeck.getCurrentLine() - 1, 
						currentDeck.getTotalNrOfLines());
			}
		}
	}

	/**
	 * Draws relevant information. This information consists of the amount
	 * of stocked cards that are equal to the currently selected card. The
	 * price of the currently selected card and the amount of gold that the
	 * player has.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawInfo(Graphics g) {
		int x = MenuValues.MENU_TEXT_X;
		
		g.drawString("Stocked: " + stocked, x, 648);
		Card c = currentDeck.getCurrent();
		int price = c == null ? 0 : c.getPrice();
		g.drawString("Price: " + price, x, 689);
		g.drawString("Gold: " + Load.getPartyItems().getGold(), x, 730);
	}

	public static void setTestMap(HashMap<String, String> info) {
		testInfo = info;
	}
	
	public static class CardInfo {
		
		private Card c;
		private int quantity;
		private boolean enabled;
		
		public CardInfo(Card card, int quantity, boolean enabled) {
			c = card;
			this.quantity = quantity;
			this.enabled = enabled;
		}

		public int getIndex() {
			return quantity;
		}

		public boolean isEnabled() {
			return enabled && quantity >= 5;
		}
	}
}
