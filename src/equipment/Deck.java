/*
 * Classname: Deck.java
 * 
 * Version information: 0.7.0
 *
 * Date: 15/02/2008
 */
package equipment;

import graphics.Graphics;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

import menu.MenuHand;
import sound.SoundPlayer;
import store.CardStore;
import store.CardStore.CardInfo;
import bodies.Vector3f;
import cards.Card;
import character.Character;

/**
 * This class represents a deck. A deck consists of an array of cards
 * and a pointer hand. It also has methods to move around in the deck.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 15 Feb 2008
 */
public class Deck {

	public static final int X_DISTANCE = 75;
	public static final int Y_DISTANCE = 113;
	
	private static final int UP = 0;
	private static final int DOWN = 1;
	private static final int DEFAULT_DECK_SIZE = 500;
	
	public MenuHand hand;

	private ArrayList<Card> deck;
	private int[] pos = new int[2];
	private int[] relOffset = new int[2];
	private int lineLength;
	private int nrOfCardsShown;
	private int handLine = 1;
	private int currentLine = 1;
	private int shownLines = 1;
//	private int deckSize = 500;
	private Character owner;
	private int menuCursor = 0;
	private int xDistance = X_DISTANCE;
	private int yDistance = Y_DISTANCE;
	private boolean active = false;
	private boolean change = false;


	/**
	 * The constructor of Deck.
	 * Creates an empty deck, and loads the menu hand-image.
	 */
	public Deck(Character owner) {
		this.owner = owner;
		deck = new ArrayList<Card>();
		hand = new MenuHand(Values.DOWN);
	}
	
	/**
	 * Inserts a card in the deck.
	 * If the deck is full, nothing happens.
	 * 
	 * @param c the card to insert.
	 * @return true if the card was inserted.
	 */
	public boolean insert(Card c) {
		if (deck.size() < getDeckSize()) {
			deck.add(c);
			change = true;
			return true;
		}
		return false;
	}

	/**
	 * Inserts a card on the specified index in the deck.
	 * If the deck is full, nothing happens.
	 * 
	 * @param i the index where to insert the card.
	 * @param c the card to insert.
	 * @return true if the card was inserted. 
	 */
	public boolean insert(int i, Card c) {
		if (deck.size() < getDeckSize()) {
			deck.add(i, c);
			return change = true;
		}
		return false;
	}
	
	public void removeCard(Card c, int nrOfCards) {
		Iterator<Card> it = deck.iterator();
		
		while (it.hasNext()) {
			if (it.next().compareTo(c) == 0) {
				it.remove();
				nrOfCards--;
				if (nrOfCards <= 0) {
					return;
				}
			}
		}
	}

	/**
	 * Removes whatever the hand is pointing to in the deck.
	 * 
	 * @return the card that was removed.
	 */
	public Card removeCurrent() {
		Card c = deck.remove(menuCursor);
		change = true;
		if (menuCursor == deck.size()) {
			left();
		}
		return c;
	}

	/**
	 * This method activates or inactivates the deck according to the 
	 * parameter given. If a deck is active, the hand won't be shown and
	 * only the two first cards in the current rows will be shown.
	 * 
	 * @param active true if this method should activate this deck.
	 * false to inactivate.
	 */
	public void setActive(boolean active) {
		this.active = active;
	}

	/**
	 * Checks if this deck is empty.
	 * 
	 * @return true if this deck is empty.
	 */
	public boolean isEmpty() {
		return deck.size() == 0;
	}
	
	public void right() {
		right(true);
	}

	/**
	 * Moves the cursor one step to the right.
	 */
	public void right(boolean playSound) {
		if (!isEmpty()) {
			menuCursor++;
			if (menuCursor >= deck.size()) {
//				currentLine = 1;
//				menuCursor = 0;
//				updateHandpos(DOWN);
				menuCursor--;
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
				return;
			}
			if (playSound) {
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK);
			}
			if (menuCursor == currentLine * lineLength) {
				currentLine++;
				updateHandpos(DOWN);
			} else {
				updateHandpos(-1);
			}
		}
	}

	/**
	 * Moves the cursor one step to the left.
	 */
	public void left() {
		if (!isEmpty()) {
			menuCursor--;
			if (menuCursor < 0) {
				menuCursor++;
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
				return;
			}
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK);
			if (menuCursor < (currentLine - 1) * lineLength) {
				currentLine--;
				if (currentLine < 1) {
					currentLine = getTotalNrOfLines();
					menuCursor = deck.size() - 1;
					updateHandpos(DOWN);
				} else {
					updateHandpos(UP);
				}
			} else {
				updateHandpos(-1);
			}
		}
	}

	/**
	 * Moves the cursor down one line.
	 */
	public void down() {
		if (!isEmpty()) {
			if (currentLine == getTotalNrOfLines()) {
				menuCursor += lineLength;
				if (menuCursor >= deck.size()) {
					SoundPlayer.playSound(SoundMap.MENU_ERROR);
					menuCursor -= lineLength;
					return;
				} else {
					currentLine++;
				}
			} else {
				menuCursor += lineLength;
				if (menuCursor >= deck.size()) {
					currentLine++;
					menuCursor = deck.size() - 1;
				} else {
					currentLine++;
				}
			}
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK);
			updateHandpos(DOWN);
		}
	}

	/**
	 * Moves the cursor up one line
	 */
	public void up() {
		if (!isEmpty()) {
			menuCursor -= lineLength;
			if (menuCursor < 0) {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
				menuCursor += lineLength;
				return;
			} else {
				currentLine--;
			}
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE_IN_DECK);
			updateHandpos(UP);
		}
	}
	
	/**
	 * Updates the position of the hand.
	 * 
	 * @param dir the direction which has called the update
	 */
	public void updateHandpos(int dir) {
		if (dir == DOWN && handLine != shownLines) {
			handLine++;
		} else if (dir == UP) {
			if (handLine == 1) {
				if (currentLine == getTotalNrOfLines()) {
					handLine--;
				}
			} else {
				handLine--;
			}
			if (handLine <= 0) {
				handLine = Math.min(getTotalNrOfLines(), shownLines);
			}
		}
		
		setHandPos();
	}
	
	private void setHandPos() {
		int x = Values.X;
		int y = Values.Y;
		
		int newX =
			pos[x] + (menuCursor - (currentLine - 1) * lineLength) 
			* xDistance + 45 + relOffset[x];
		int newY = pos[y] + yDistance * (handLine - 1) + relOffset[y];
		hand.setXpos(newX);
		hand.setYpos(newY);
	}
	
	public Iterator<Card> iterator() {
		return deck.iterator();
	}

	/**
	 * Draws the cards in the deck up to the number of shown cards.
	 * 
	 * @param g the Graphics3D context on which to draw.
	 */
	public void drawDeck(Graphics g) {
		drawDeck(g, Integer.MAX_VALUE, false, null, null);
	}
	
	public void drawDeck(Graphics g, Card currentCard, HashMap<String, CardStore.CardInfo> map) {
		drawDeck(g, Integer.MAX_VALUE, true, currentCard, map);
	}
	
	public void drawDeck(Graphics g, Card currentCard) {
		drawDeck(g, Integer.MAX_VALUE, false, currentCard, null);
	}
	
	/**
	 * Draws the deck on the given graphics. It will draw the cards
	 * in black and white if the given amount of gold is not enough to
	 * purchase the card.
	 * 
	 * @param g the graphics to draw on.
	 * @param gold the amount of gold to use as limit for when this method
	 * should draw the cards in black and white.
	 */
	public void drawDeck(
			Graphics g, int gold, boolean large, 
			Card currentCard, HashMap<String, CardStore.CardInfo> map) {
		int offset = currentLine - handLine;
		if (offset < 0) {
			offset = 0;
		}
		int ci = 0;
		int cj = 0;
		int fs = g.getFontSize();
		g.setFontSize(26, true);
		for (int i = 0; i < shownLines; i++) {
			for (int j = 0; j < lineLength; j++) {
				int index = lineLength * (i + offset) + j;
				if (index < deck.size()) {
					int x = pos[Values.X] + j * xDistance;
					int y = pos[Values.Y] + i * yDistance;
					Card c = deck.get(index);
					if (currentCard != c) {
						boolean enabled = true;
						if (map != null) {
							CardInfo info = map.get(c.getSortingValue());
							enabled = info.isEnabled();
							drawCard(g, large, x, y, c, enabled);
							
							String string = "" + info.getIndex();
							int xright = g.calcAlignRight(string, x + 116);
							g.drawStringWithShadow(string, y + 169, xright);
						} else {
							enabled = c.getPrice() <= gold;
							drawCard(g, large, x, y, c, enabled);
						}
					} else {
						ci = i; cj = j;
					}
				}
			}
		}
		if (currentCard != null) {
			int x = pos[Values.X] + cj * xDistance;
			int y = pos[Values.Y] + ci * yDistance;
			boolean enabled = true;
			g.setFontSize(28, true);
			if (map != null) {
				CardInfo info = map.get(currentCard.getSortingValue());
				enabled = info.isEnabled();
				if (enabled) {
					currentCard.drawCard(g, x - 15, y - 20, large ? 1.2f : .9f);
				} else {
					currentCard.drawGrayCard(g, x - 15, y - 20, large ? 1.2f : .9f);
				}
				
				String string = "" + info.getIndex();
				int xright = g.calcAlignRight(string, x + 126);
				g.drawStringWithShadow(string, y + 184, xright);
			} else {
				if (currentCard.getPrice() <= gold) {
					currentCard.drawCard(g, x - 15, y - 20, large ? 1.2f : .9f);
				} else {
					currentCard.drawGrayCard(g, x - 15, y - 20, large ? 1.2f : .9f);
				}
			}
		}
		if (active) {
			hand.drawHand(g);
		}
		g.setFontSize(fs, false);
	}

	private void drawCard(Graphics g, boolean large, int x, int y, Card c, boolean enabled) {
		if (enabled) {
			c.drawCard(g, x, y, large ? 1 : .7f);
		} else {
			c.drawGrayCard(g, x, y, large ? 1 : .7f);
		}
	}
	
	public Card getSeenCard(int cardIndex) {
		int offset = currentLine - handLine;
		if (offset < 0) {
			offset = 0;
		}
		int ci = 0;
		for (int i = 0; i < shownLines; i++) {
			for (int j = 0; j < lineLength; j++) {
				int index = lineLength * (i + offset) + j;
				if (index < deck.size() && ci == cardIndex) {
					return deck.get(index);
				}
				ci++;
			}
		}
		return null;
	}

	public Vector3f getLastPos() {
		for (int i = 0; i < shownLines; i++) {
			for (int j = 0; j < lineLength; j++) {
				int index = lineLength * i + j;
				if (index == deck.size()) {
					int x = pos[Values.X] + j * xDistance;
					int y = pos[Values.Y] + i * yDistance;
					return new Vector3f(x, y, 0);
				}
			}
		}
		return null;
	}

	public Vector3f getPosFor(Card c) {
		int offset = currentLine - handLine;
		if (offset < 0) {
			offset = 0;
		}
		for (int i = 0; i < shownLines; i++) {
			for (int j = 0; j < lineLength; j++) {
				int index = lineLength * (i + offset) + j;
				if (index < deck.size()) {
					int x = pos[Values.X] + j * xDistance;
					int y = pos[Values.Y] + i * yDistance;
					if (deck.get(index) == c) {
						return new Vector3f(x, y, 0);
					}
				}
			}
		}
		return null;
	}

	/**
	 * Inserts the given card at the specified index. If the index is
	 * out of bound, it just appends the card to the deck.
	 * 
	 * @param c the card to be inserted.
	 * @param index the index of the card.
	 */
	public void replace(Card c, int index) {
		if (index < deck.size()) {
			deck.remove(index);
			if (c != null) {
				insert(index, c);
			}
		} else {
			insert(c);
		}
	}

	/**
	 * Empties this deck.
	 */
	public void clear() {
		change = true;
		deck.clear();
	}

	/**
	 * Swaps two cards with each other.
	 * 
	 * @param a the index of the first card.
	 * @param b the index of the second card.
	 */
	public void swap(int a, int b) {
		Card c = deck.set(a, deck.get(b));
		deck.set(b, c);
	}

	/**
	 * Copies the card with index i.
	 * 
	 * @param i the index of the card in this deck to copy.
	 * @return a copy of the card at index i.
	 */
	public Card copyCard(int i) {
		return deck.get(i).copyCard();
	}

	/**
	 * Checks if this deck is full.
	 * 
	 * @return true if this deck is full.
	 */
	public boolean isFull() {
		return deck.size() >= getDeckSize();
	}
	
	public boolean isFull(int size) {
		return (deck.size() + size) >= getDeckSize();
	}

	///////////////////////
	// GETTERS & SETTERS //
	///////////////////////

	/**
	 * Sets the decks coordinates.
	 * 
	 * @param x the x-coordinates of the deck. 
	 * @param y the y-coordinates of the deck. 
	 */
	public void setCoordinates(int x, int y) {
		pos[Values.X] = x - 10;
		pos[Values.Y] = y - 20;
		setHandPos();
	}

	/**
	 * Sets the number of cards which the player should 
	 * be able to move amongst.
	 * 
	 * @param nr the number of cards.
	 */
	public void setNrOfShownCards(int nr) {
		nrOfCardsShown = nr;
	}

	/**
	 * Sets the length of each line in the deck.
	 * 
	 * @param length the length of the line.
	 */
	public void setLineLength(int length) {
		lineLength = length;
	}

	/**
	 * Sets the number of lines that should be drawn.
	 * 
	 * @param nr the number of lines.
	 */
	public void setShownLines(int nr) {
		shownLines = nr;
	}

	/**
	 * Sets the offset position of the decks menu hand. The parameters 
	 * given to this method is used to, relative the hands old position,
	 * reposition the hand.
	 * 
	 * @param x the x position offset.
	 * @param y the y position offset.
	 */
	public void setHandPosRelative(int x, int y) {
		relOffset[Values.X] = x;
		relOffset[Values.Y] = y;
	}

	/**
	 * Gets whatever the hand is pointing to in the deck.
	 * 
	 * @return the current Card in the deck.
	 */
	public Card getCurrent() {
		if (menuCursor < deck.size()) {
			return deck.get(menuCursor);
		}
		return null;
	}

	/**
	 * Gets whatever the hand is pointing to in the deck.
	 * 
	 * @param i the index of the card to get.
	 * @return the current Card in the deck.
	 */
	public Card getCard(int i) {
		return deck.get(i);
	}

	/**
	 * Gets the size of the deck.
	 * 
	 * @return deckSize the size of the deck.
	 */
	public int getDeckSize() {
		return owner != null ? owner.getAttribute(Character.DECK_SIZE) : DEFAULT_DECK_SIZE;
	}

	/**
	 * Gets the current size of the deck.
	 * 
	 * @return the size of the deck.
	 */
	public int getCurrentDeckSize() {
		return deck.size();
	}
	
	public String getSizeInfo() {
		return "(" + deck.size() + "/" + getDeckSize() + ")";
	}


	/**
	 * Get the number of cards that ought to be shown.
	 * 
	 * @return nrOfCardsShown
	 */
	public int getNrOfCardsShown() {
		return nrOfCardsShown;
	}
	
	/**
	 * Gets the height of the scroll bar. This is used by the deck menu when
	 * drawing the scroll bar. The returned value is used as offset in 
	 * scrollBar.draw(g, offset);
	 * 
	 * @see battle.bars.ScrollBar#draw(Graphics, float)
	 * 
	 * @return the height of the scroll bar.
	 */
	public float getScrollBarHeight() {
		float t = Math.min(currentLine - handLine, getTotalNrOfLines() - 3);
		return t / getTotalNrOfLines();
	}

	/**
	 * Gets the x position of the deck.
	 * 
	 * @return the x position.
	 */
	public int getXpos() {
		return pos[Values.X];
	}

	/**
	 * Gets the y position of the deck.
	 * 
	 * @return the y position.
	 */
	public int getYpos() {
		return pos[Values.Y];
	}

	/**
	 * Gets the index of the cursor. This is the index in the deck
	 * which the hand points at. 
	 * 
	 * @return the menuCursor.
	 */
	public int getMenuCursor() {
		return menuCursor;
	}

	/**
	 * Gets the current line shown. This is the line in the menu 
	 * where the hand is currently pointing. currentLine * lineLength - 1 
	 * gives the index of the first card in the current line.
	 * This also means that menuCursor == currentLine * lineLength - 1 is true,
	 * if the hand is pointing at the first card in any given line.
	 *  
	 * @return the current line.
	 */
	public int getCurrentLine() {
		return currentLine;
	}

	/**
	 * Gets the total number of lines in this deck. This number is gotten from
	 * the number of cards in the deck divided by the length of the line. 
	 * 
	 * @return the total number of lines.
	 */
	public int getTotalNrOfLines() {
		return (int) Math.ceil((float) deck.size() / (float) lineLength);
	}

	/**
	 * Resets some of the decks values to default. 
	 */
	public void reset() {
		currentLine = 1;
		menuCursor = 0;
		handLine = 1;
		updateHandpos(-1);
		active = false;
	}

	/**
	 * Adds the given card to the deck.
	 * 
	 * @param c the card to add.
	 */
	public void addCard(Card c) {
		change = true;
		deck.add(c);
	}

	/**
	 * This method sorts the cards using the Arrays.sort() method.
	 */
	public void sort() {
		Card[] c = new Card[deck.size()];
		c = deck.toArray(c);
		Arrays.sort(c);
		deck.clear();
		for (int i = 0; i < c.length; i++) {
			deck.add(c[i]);
		}
	}

	/**
	 * This method counts the number of cards in this deck which is the same
	 * as the given card. The comparative method used is the compareTo() which
	 * can be used because the cards implements the comparable interface.
	 * 
	 * @param c the card to search and count.
	 * @return the number of cards in the deck that is equal to the given one.
	 */
	public int search(Card c) {
		if (c == null) {
			return 0;
		}
		int nr = 0;
		for (int i = 0; i < deck.size(); i++) {
			if (c.compareTo(deck.get(i)) == 0) {
				nr++;
			}
		}
		return nr;
	}
	
	/**
	 * Checks if this deck has changed in any way.
	 * 
	 * @return true if this deck has been changed.
	 */
	public boolean hasChanged() {
		return change;
	}

	/**
	 * Resets the change value so this deck does not appear as changed.
	 * This is done after the 3D battle deck has been synchronized with 
	 * this deck.
	 */
	public void resetChange() {
		change = false;
	}

	public void setXDistance(int d) {
		xDistance = d;
	}
	
	public void setYDistance(int d) {
		yDistance = d;
	}

	public int getShowLines() {
		return shownLines;
	}
}
