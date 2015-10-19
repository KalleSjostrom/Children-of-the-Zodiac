/*
 * Classname: GLDeck.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/06/2008
 */
package battle.equipment;

import info.BattleValues;
import info.SoundMap;

import java.util.ArrayList;
import java.util.Random;

import java.util.logging.*;

import sound.SoundPlayer;
import battle.character.CreatureRow;
import bodies.Vector3f;
import cards.AbstractCard;
import cards.Card;
import equipment.Deck;
import equipment.Slot;
import graphics.Graphics;

/**
 * This class represents the deck that the player can draw cards from 
 * in the battle. It consists of a pile of cards and a couple of slots
 * which some of these cards are shown. From these slots the player can
 * choose which cards to play. It also has a save slot which the player
 * can use to save one card.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 28 June 2008
 */
public class GLDeck extends AbstractDeck {

	private static final int SAVED_CARD = -1;
	
	private static Logger logger = Logger.getLogger("GLDeck");
	
	private ArrayList<GLCard> shownCards;
	private ArrayList<GLCard> deckCards;
	private ArrayList<GLCard> allCards;
	private Deck deck;
	private GLCard savedCard;
	private GLWeapon weaponDeck;
	
	private int xsOffset = 0;
	private float saveDeckPos;
	private boolean change = false;
	private boolean needUpdate = true;

	/**
	 * Creates a new deck.
	 */
	public GLDeck() {
		super(3);
		shownCards = new ArrayList<GLCard>();
		deckCards = new ArrayList<GLCard>();
		allCards = new ArrayList<GLCard>();
		selectedCard = 0;
		setAxis(Y);
		setLimit(false);
		setMovementSpeed(false);
		instantHide();
	}

	/**
	 * Extends the initDraw method of AbstractDeck by calling the fillSlots() 
	 * method also.
	 * 
	 * @param gl the GL object to use when initializing the graphics.
	 */
	public void initDraw(Graphics g) {
		super.initDraw(g);
		weaponDeck.initDraw(g);
		initCards(g);
	}
	
	public void update() {
		super.update();
		weaponDeck.update();
	}

	/**
	 * Wraps the set deck into this extended 3D deck.
	 * 
	 * @param d the deck to wrap.
	 * @param handSize the size of the hand.
	 */
	public void setDeck(Deck d, int handSize) {
		deck = d;
		nrOfSlots = handSize;
		saveDeckPos = AbstractDeck.xs[nrOfSlots - 1] + 0.25f;//0.315f;
		
		if (!change) {
			for (int i = 0; i < deck.getCurrentDeckSize(); i++) {
				GLCard card = new GLCard();
				card.setCard(deck.getCard(i));
				deckCards.add(card);
				allCards.add(card);
			}
		}
	}

	/**
	 * Sets the deck (slots) that the player is putting the chosen cards.
	 * These slots is the slots that resides in the players weapon.
	 * 
	 * @param deck the deck representing the players weapon.
	 */
	public void setWeaponDeck(GLWeapon deck) {
		weaponDeck = deck;
	}

	/**
	 * This method overrides the draw method in AbstractDeck by drawing
	 * the cards in this deck on top of the empty slots in AbstractDeck.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		weaponDeck.draw(g);
		super.draw(g);
		drawDeck(g, shownCards, BattleValues.CARD_SELECTED_OFFSET);
		drawSavedCard(g);
		drawTopCard(g, deckCards);
		Card c = null;
		if (shownCards.size() > 0) {
			if (selectedCard != -1) {
				c = shownCards.get(selectedCard).getCard();
			} else if (savedCard != null) {
				c = savedCard.getCard();
			}
			
			float xRight = 1.080f;
			float xLeft = .51f;
			float yBottom = -.145f + getYtrans();
			float yTop = .146f + getYtrans();
			
			g.drawGradient(
					Vector3f.ZERO, CreatureRow.BACK_ALPHA_TOP, CreatureRow.BACK_ALPHA_BOTTOM, 
					xRight, xLeft, yBottom, yTop, true, true);
			
			if (c != null) {
				int x = 760;
				g.setFontSize(34);
				int y = Math.round(660 + 200 *  (-getYtrans() - .65f));
				int y2 = y + 40;
				g.drawString(c.getName(), x + 2, y + 2);
				g.setColor(1);
				g.drawString(c.getName(), x, y);
				
				g.setFontSize(50);
				int size = deckCards.size();
				int textx = 70;
				if (size > 0) {
					if (size >= 10 && size <= 19) {
						textx -= 5;
					}
					g.drawStringCentered(String.valueOf(deckCards.size()), y + 62, textx + 2);
					g.setColor(1);
					g.drawStringCentered(String.valueOf(deckCards.size()), y + 60, textx);
				}
				textx = 47;
				int texty = y + 10;
				
				g.setFontSize(24);
				String[] info = c.getVeryShortInfo();
				g.drawString(info[0], x + 2, y2 + 2);
				g.drawString(info[1], x + 2, y2 + 27);
				g.drawString("Deck", textx + 2, texty + 2);
				g.setColor(1);
				g.drawString(info[0], x, y2);
				g.drawString(info[1], x, y2 + 25);
				g.drawString("Deck", textx, texty);
			}
		}
	}

	/**
	 * Initiates the drawings on all the cards in the list allCards.
	 * 
	 * @param g the GL object to initiate the rendering on.
	 */
	private void initCards(Graphics g) {
		for (int i = 0; i < allCards.size(); i++) {
			allCards.get(i).initDraw(g);
		}
	}

	/**
	 * Draws the saved card on the given GL.
	 * 
	 * @param gl the GL to draw on.
	 */
	private void drawSavedCard(Graphics g) {
		if (savedCard != null) {
			if (selectedCard == -1) {
				savedCard.draw(g, getYtrans() + BattleValues.CARD_SELECTED_OFFSET);
				drawHand(g, nrOfSlots, .05f);
			} else {
				savedCard.draw(g, getYtrans());
			}
		}
	}
	
	public ArrayList<GLCard> getShowCards() {
		return shownCards;
	}

	/**
	 * Implements the getY() method in AbstractDeck. It is used as
	 * y position when initializing the deck graphics.
	 * 
	 * @return the height (y-value) of the deck slots.
	 */
	public float getY() {
		return BattleValues.DECK_HEIGHT_SLOTS;
	}

	/**
	 * Empties the visible slots and puts all the cards in the deck.
	 */
	public void empty() {
		for (int i = 0; i < shownCards.size(); i++) {
			shownCards.get(i).reset();
		}
		deckCards.addAll(shownCards);
		shownCards.clear();
		weaponDeck.empty();
	}

	/**
	 * This method fills the slots with the nrOfSlots first cards in the deck.
	 */
	private void fill() {
		for (int i = 0; i < nrOfSlots && deckCards.size() > 0; i++) {
			shownCards.add(deckCards.remove(0));
			shownCards.get(i).setTarget(xs[i]);
		}
	}

	/**
	 * Puts the selected card in the weapon and draws a new card from the deck.
	 * This new card drawn from the deck is put directly to the right
	 * of the deck and the cards is shifted to the right to fill the
	 * void that the selected card left.
	 * 
	 * @return true if the round is done.
	 */
	public boolean chooseSelectedCard() {
		if (!weaponDeck.isFull() && selIsInRange()) {
			GLCard c = getSelectedCard();
			if (c != null) {
				SoundPlayer.playSound(SoundMap.BATTLE_CHOOSE_CARD);
				updateCards(weaponDeck.receive(c));
			} else {
				SoundPlayer.playSound(SoundMap.ERROR);
			}
			if (selectedCard == -1) {
				selectedCard = 0;
			}
			return false;
		} else if (selectedCard == -1 && savedCard != null) {
			allCards.add(savedCard);
			GLCard c = savedCard;
			savedCard = null;
			updateCards(weaponDeck.receive(c));
			selectLeft();
			return false;
		}
		return weaponDeck.isFull();
	}

	/**
	 * Checks if the cards stored in shownCards should be disabled or
	 * enabled according to the given array.
	 * 
	 * @param enabled the array containing which slots are free.
	 */
	private void updateCards(int[] enabled) {
		for (int i = 0; i < shownCards.size(); i++) {
			updateCard(shownCards.get(i), enabled);
		}
		if (savedCard != null) {
			updateCard(savedCard, enabled);
		}
	}

	/**
	 * Checks if the given card should be disabled or
	 * enabled according to the given array.
	 * 
	 * @param card the card to check.
	 * @param enabled the array containing which slots are free.
	 */
	private void updateCard(GLCard card, int[] enabled) {
		if (enabled != null) {
			Card c = card.getCard();
			boolean enable = false;
			if (c.getType() == AbstractCard.NEUTRAL) {
				enable = 
					(enabled[Slot.MAGIC] + enabled[Slot.SUPPORT]) > 0;
			} else {
				enable = enabled[card.getType()] != 0;
			}
			card.setEnabled(enable);
		}
	}

	/**
	 * Gets the selected card and moves the card to the left one step
	 * to the right. It also draws a new card from the deck if the deck
	 * is not empty.
	 * 
	 * @return the card with index selectedCard, null if the card is
	 * not enabled.
	 */
	public GLCard getSelectedCard() {
		if (selIsInRange()) {
			GLCard c = shownCards.get(selectedCard);
			if (c.isEnabled()) {
				shownCards.remove(selectedCard);
				for (int i = 0; i < selectedCard; i++) {
					shownCards.get(i).setTarget(xs[i + 1 + xsOffset]);
				}
				drawNewCard();
				return c;
			}
		}
		return null;
	}

	/**
	 * Gets the selected card. This method removes returned card from the
	 * deck, so if the returned card is not taken care of, it is discarded.
	 * 
	 * @return the discarded card.
	 */
	public GLCard discardCard() {
		logger.log(Level.FINE, "Discard card " + selectedCard + " " + savedCard);
		if (selIsInRange()) {
			logger.log(Level.FINE, "Sel in range");
			GLCard c = shownCards.remove(selectedCard);
			for (int i = 0; i < selectedCard; i++) {
				shownCards.get(i).setTarget(xs[i + 1 + xsOffset]);
			}
			drawNewCard();
			logger.log(Level.FINE, "Sel in range returns " + c);
			logger.log(Level.FINE, "After Discard card1 " + selectedCard);
			if (selectedCard == -1) {
				selectedCard = 0;
			}
			return c;
		} else if (selectedCard == -1 && savedCard != null) {
			allCards.add(savedCard);
			logger.log(Level.FINE, "Adding saved to all " + savedCard);
			GLCard c = savedCard;
			savedCard = null;
			selectLeft();
			logger.log(Level.FINE, "After Discard card2 " + selectedCard);
			return c;
		}
		logger.log(Level.FINE, "After Discard card3 " + selectedCard);
		logger.log(Level.WARNING, "WARNING discard null");
		return null;
	}
	
	/**
	 * Puts the current card in the save slot for later use.
	 * It will throw away any previously saved cards if any exists. 
	 */
	public void saveCard() {
		if (selectedCard != -1) {
			if (savedCard != null) {
				allCards.add(savedCard);
			}
			savedCard = discardCard();
			if (savedCard != null) {
				if (shownCards.size() == 0) {
					selectedCard = SAVED_CARD;
				}
				boolean found = false;
				for (int i = 0; i < allCards.size() && !found; i++) {
					if (allCards.get(i) == savedCard) {
						allCards.remove(i);
						found = true;
					}
				}
				savedCard.setTarget(saveDeckPos);
			}
		}
	}

	/**
	 * Checks if the selected card index is in range. This to make
	 * sure there are not any index out of bounds exceptions. 
	 * The selected card index is the index representing the selected card. 
	 * 
	 * @return true if the index is in range.
	 */
	private boolean selIsInRange() {
		return selectedCard < shownCards.size() && selectedCard >= 0;
	}

	/**
	 * Draws a new card from the deck and puts it directly to the right
	 * of the deck, and the rest of the cards is shifted to the right to 
	 * fill the void that the selected card left.
	 */
	private void drawNewCard() {
		GLCard card = drawTopCard();
		if (card != null) {
			updateCard(card, weaponDeck.getFreeSlots());
			shownCards.add(0, card);
			shownCards.get(0).setTarget(xs[0]);
			return;
		} else if (selectedCard >= 0) {
			selectedCard--;
		}
		xsOffset++;
	}

	/**
	 * This method removes any card in the slots, shuffles all the cards
	 * and fills the slots with new cards.
	 */
	public void shuffleAndDeal() {
		shownCards.clear();
		deckCards.clear();
		deckCards.addAll(shuffleCards(allCards));
		xsOffset = 0;
		fill();
	}

	/**
	 * This method gets the top card from the deck if there are any.
	 * 
	 * @return the top card of the deck, null if no cards is in the deck.
	 */
	private GLCard drawTopCard() {
		if (deckCards.size() == 0) {
			return null;
		}
		return deckCards.remove(0);
	}

	/**
	 * Moves the "select cursor" one step to the right. If the cursor is at
	 * the rightmost end of the cards it is moved to the leftmost card.
	 */
	public void selectRight() {
		if (selectedCard == SAVED_CARD) {
			SoundPlayer.playSound(SoundMap.BATTLE_ERROR);
			return;
		} else {
			selectedCard++;
			if (selectedCard == shownCards.size()) {
				if (savedCard == null) {
					selectedCard--;
					SoundPlayer.playSound(SoundMap.BATTLE_ERROR);
					return;
				} else {
					selectedCard = SAVED_CARD;
				}
			}
		}
		SoundPlayer.playSound(SoundMap.BATTLE_NAVIAGATE);
	}

	/**
	 * Moves the "select cursor" one step to the left. If the cursor is at
	 * the leftmost end of the cards it is moved to the rightmost card.
	 */
	public void selectLeft() {
		if (selectedCard == SAVED_CARD) {
			selectedCard = shownCards.size() - 1;
		} else {
			selectedCard--;
			if (selectedCard < 0) {
				SoundPlayer.playSound(SoundMap.BATTLE_ERROR);
				selectedCard++;
				return;
			}
		}
		SoundPlayer.playSound(SoundMap.BATTLE_NAVIAGATE);
	}

	/**
	 * Overrides the hide method in Hideable to also hide the weapon.
	 */
	public void hide() {
		super.hide();
		weaponDeck.hide();
	}

	/**
	 * Overrides the show method in Hideable to also show the weapon.
	 */
	public void show() {
		super.show();
		weaponDeck.show();
	}

	/**
	 * This method shows the deck if not visible, it hides the deck otherwise.
	 */
	public void toggle() {
		if (visible) {
			hide();
		} else {
			show();
		}
	}

	/**
	 * Flips the weapon mode. If the mode is defense mode it is switched to
	 * attack mode and vice versa. This method just calls the swichSide() 
	 * method in the weapon deck, and this method wont do anything if
	 * the player has played any cards.
	 * 
	 * @return the new mode, or -1 if this operation is currently unavailable.
	 */
	public int flipMode() {
		int pointToParty = weaponDeck.switchSide();
		updateCards(weaponDeck.getFreeSlots());
		return pointToParty;
	}
	
	public int getMode() {
		return weaponDeck.getMode();
	}

	/**
	 * This method finishes the round and gets the list of cards from the 
	 * weapon. It also hides the deck.
	 * 
	 * @return the list of cards from the weapon.
	 */
	public ArrayList<GLCard> finish() {
		weaponDeck.setToAttackMode();
		hide();
		return weaponDeck.getCards();
	}

	/**
	 * Initiates a new round of battle. It clears the weapon deck, sets
	 * the deck to attack mode and shuffles the deck if necessary.
	 */
	public void initNewRound() {
		weaponDeck.empty();
		weaponDeck.setToAttackMode();
		show();
		updateCards(weaponDeck.getFreeSlots());
	}

	/**
	 * This method shuffles the cards in the given list. Note that 
	 * this method does not create a copy, it uses the given list.
	 * This means that the returned list is the same as the given one,
	 * except that the cards in it is (probably) in a different order.
	 * 
	 * @param deck the list of cards to shuffle.
	 * @return a shuffled list of cards.
	 * This is the same list as the given one.
	 */
	private ArrayList<GLCard> shuffleCards(ArrayList<GLCard> deck) {
		for (int i = 0; i < deck.size(); i++) {
			deck.get(i).reset();
		}
		Random random = new Random();
		int length = deck.size();
		if (length >= 2) {
			for (int i = 0; i < 300; i++) {
				int a = random.nextInt(length);
				int b = random.nextInt(length);
				GLCard c = deck.set(a, deck.get(b));
				deck.set(b, c);
			}
		}
		return deck;
	}

	/**
	 * Checks if the weapon deck is in defense mode.
	 * 
	 * @return true if the weapon deck is in defense mode.
	 */
	public boolean isDefenseMode() {
		return weaponDeck.getMode() == GLWeapon.DEFENSE_MODE;
	}

	/**
	 * Checks if the weapon deck is in attack mode.
	 * 
	 * @return true if the weapon deck is in attack mode.
	 */
	public boolean isAttackMode() {
		return weaponDeck.getMode() == GLWeapon.OFFENSE_MODE;
	}

	/**
	 * Checks if the slots in the weapon deck is full. That all the
	 * cards that fit the weapon deck has been played.
	 * 
	 * @return true if the weapon deck is full.
	 */
	public boolean isFull() {
		return weaponDeck.isFull();
	}

	/**
	 * Checks if this deck is in need of a shuffle. This is needed when 
	 * the deckCards is empty.
	 * 
	 * @return true if this deck needs to shuffle.
	 */
	public boolean needsToShuffle() {
		return deckCards.size() == 0;
	}

	/**
	 * Updates the given characters GLDeck to match the normal deck exactly.
	 * 
	 * @param c the character whose deck to update.
	 */
	public void update(character.Character c) {
		// Deck 
		logger.log(Level.FINE, "-----------------------------------");
		logger.log(Level.FINE, "Updtating GLDeck for " + c.getName());
		logger.log(Level.FINE, "Deck cards " + deckCards.size()); 
		logger.log(Level.FINE, "All cards " + allCards.size()); 
		logger.log(Level.FINE, "Saved card " + savedCard); 
		logger.log(Level.FINE, "Normal deck " + deck.getCurrentDeckSize()); 
		if (savedCard != null) {
			logger.log(Level.FINE, "Saved Card is not null"); 
			allCards.add(savedCard);
			logger.log(Level.FINE, "All cards " + allCards.size()); 
		}
		nrOfSlots = character.Character.HAND_SIZE;
		int size = deckCards.size() + shownCards.size();
		deckCards.addAll(shownCards);
		shownCards.clear();
		if (size != deckCards.size()) {
			logger.log(Level.SEVERE, "Size is not the same for deck cards, exiting12");
			System.exit(0);
		}
		logger.log(Level.FINE, "Deck cards += showCards " + deckCards.size()); 
		if (savedCard != null) {
			deckCards.add(savedCard);
			logger.log(Level.FINE, "Deck cards += savedCard " + deckCards.size()); 
		}
		
		//ArrayList<GLCard> thrownCards = getThrownCards(); // De som tidigare kastats.
		ArrayList<GLCard> availableCards = deckCards; // De kort som man kunde spela med. (med save card).
		ArrayList<GLCard> newCards = getNewCards(); // De kort som inte fanns innan.
		logger.log(Level.FINE, "New cards " + newCards.size()); 
		size = deckCards.size();
		removeFromAllCards(); // Remove from all cards
		logger.log(Level.FINE, "All cards " + allCards.size()); 
		if (size != deckCards.size()) {
			logger.log(Level.WARNING, "Size is not the same for deck cards, exiting1");
			System.exit(0);
		}
		allCards.addAll(newCards);
		logger.log(Level.FINE, "All cards += newCards " + allCards.size()); 
		
		// Hur m�nga av available cards �r kvar i decken? i procent
		int nrAvailable = availableCards.size();
		logger.log(Level.FINE, "Nr of available " + nrAvailable);
		ArrayList<GLCard> cardsLeftInDeck = getCardsLeftInDeck(availableCards);
		int nrAvailableLeft = cardsLeftInDeck.size();
		logger.log(Level.FINE, "Nr of available left " + nrAvailableLeft);
		
		// Hur m�nga av thrown cards �r kvar i decken? i procent
		// float thrownCardsLeftInDeck = getCardsLeftInDeck(thrownCards);
		// F�rdela de nya korten p� trownCards och available cards.
		if (newCards.size() > 0) {
			logger.log(Level.FINE, "Shuffle new cards");
			shuffleCards(newCards);
			for (int i = 0; i < nrAvailable - nrAvailableLeft; i++) {
				cardsLeftInDeck.add(newCards.get(i));
			}
		}
		deckCards = cardsLeftInDeck;
		// Blanda om available cards.
		logger.log(Level.FINE, "Shuffle deck cards");
		
		if (savedCard != null) {
			logger.log(Level.FINE, "Adding saved card again");
			logger.log(Level.FINE, "Deck cards " + deckCards.size());
			logger.log(Level.FINE, "All cards " + allCards.size());
			boolean savedCardStillInDeck = false;
			for (int j = 0; j < deckCards.size() && !savedCardStillInDeck; j++) {
				if (savedCard == deckCards.get(j)) {
					savedCardStillInDeck = true;
					deckCards.remove(j);
					boolean found = false;
					for (int i = 0; i < allCards.size() && !found; i++) {
						if (allCards.get(i) == savedCard) {
							allCards.remove(i);
							found = true;
						}
					}
					// savedCard.setTarget(saveDeckPos);
				}
			}
			if (!savedCardStillInDeck) {
				/*
				 * Saved card var inte kvar i decken;
				 * Det m�ste betyda att man bytt ut savedCard, s�tt till null.
				 */
				savedCard = null;
			}
			logger.log(Level.FINE, "Deck cards " + deckCards.size());
			logger.log(Level.FINE, "All cards " + allCards.size());
		}
		shuffleCards(deckCards);
		for (int i = 0; i < allCards.size(); i++) {
			allCards.get(i).reset();
		}
		xsOffset = 0;
		fill();
		change = true;
	}

	private ArrayList<GLCard> getCardsLeftInDeck(ArrayList<GLCard> cards) {
		ArrayList<GLCard> cardsLeft = new ArrayList<GLCard>();
		for (int i = 0; i < cards.size(); i++) {
			boolean found = false;
			GLCard glCard = cards.get(i);
			Card card = glCard.getCard();
			for (int j = 0; j < deck.getCurrentDeckSize() && !found; j++) {
				found = deck.getCard(j) == card;
				if (found) {
					cardsLeft.add(glCard);
				}
			}
		}
		return cardsLeft;
	}

	private ArrayList<GLCard> getNewCards() {
		ArrayList<GLCard> newCards = new ArrayList<GLCard>();
		for (int i = 0; i < deck.getCurrentDeckSize(); i++) {
			boolean found = false;
			Card card = deck.getCard(i);
			for (int j = 0; j < allCards.size() && !found; j++) {
				GLCard glCard = allCards.get(j);
				found = glCard.getCard() == card;
			}
			if (!found) {
				GLCard newCard = new GLCard();
				newCard.setCard(card);
				newCards.add(newCard);
			}
		}
		return newCards;
	}
	
	private void removeFromAllCards() {
		logger.log(Level.FINE, "Remove from all cards " + allCards.size());
		ArrayList<Integer> removeIndex = new ArrayList<Integer>();
		for (int i = 0; i < allCards.size(); i++) {
			boolean found = false;
			GLCard glCard = allCards.get(i);
			Card card = glCard.getCard();
			for (int j = 0; j < deck.getCurrentDeckSize() && !found; j++) {
				found = deck.getCard(j) == card;
			}
			if (!found) {
				removeIndex.add(i);
			}
		}
		for (int i = 0; i < removeIndex.size(); i++) {
			allCards.remove((int) removeIndex.get(i) - i);
		}
		logger.log(Level.FINE, "Removed " + removeIndex.size());
		logger.log(Level.FINE, "All cards " + allCards.size());
	}

	/**
	 * This method turns the need for update flag on or off depending on 
	 * the given value. If the parameter needsUpdate is true the this deck
	 * will turn on its need for update flag. This will cause this deck
	 * to be updated when necessary. 
	 * 
	 * @param needsUpdate true if this method should request an update.
	 */
	public void setNeedUpdate(boolean needsUpdate) {
		needUpdate = needsUpdate;
	}
	
	/**
	 * Checks if the need for update flag is set. If it is set it should
	 * be updated when necessary.
	 * 
	 * An update will make sure that this 3D deck contains exactly the same
	 * cards that the player has in the 2D deck. 
	 * 
	 * @return true if the need for update flag is set.
	 */
	public boolean getNeedUpdate() {
		return needUpdate;
	}

	/**
	 * Updates the position of the cards in the hand deck and the weapon deck.
	 * The hand deck are the cards that is currently showing in battle and the
	 * weapon deck is the cards that the player has chosen to attack with.
	 */
	public void updatePos() {
		for (int i = 0; i < shownCards.size(); i++) {
			shownCards.get(i).update();
		}
		weaponDeck.updatePos();
		if (savedCard != null) {
			savedCard.update();
		}
	}

	public void setSelected(int i) {
		selectedCard = i;
	}

	public boolean hasRoomFor(int t) {
		int nr;
		int[] s = weaponDeck.getFreeSlots();
		if (t == Card.NEUTRAL) {
			nr = s[Card.MAGIC] + s[Card.SUPPORT];
		} else {
			nr = s[t];
		}
		return nr > 0;
	}
	
	public boolean hasRoomFor(int t, boolean undecided) {
		if (undecided) {
			if (t == Card.SUPPORT) {
				weaponDeck.switchSide();
				boolean a = hasRoomFor(t);
				weaponDeck.switchSide();
				return a;
			}
		}
		return hasRoomFor(t);
	}

	public GLCard getSaveCard() {
		return savedCard;
	}
}
