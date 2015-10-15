/*
 * Classname: PartyItems.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import java.util.HashMap;
import java.util.Iterator;

import organizer.Organizer;

import cards.Card;
import equipment.Items.Item;

/**
 * This class stores the shared assets for the party. So far
 * these assets are the gold and the main party deck.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Jan 2008
 */
public class PartyItems {

	private Deck mainDeck = new Deck(null);
	private Items items = new Items();
	private int gold;
	private int steps;
	private int battles;

	/**
	 * Constructs a new PartyItems (backpack) and initialize it with 
	 * the given amount of gold.
	 * 
	 * @param g the initial amount of gold.
	 */
	public PartyItems(int g) {
		gold = g;
	}

	/**
	 * Adds the given amount of gold to the party.
	 * 
	 * @param gold the gold to add.
	 */
	public void addGold(int gold) {
		this.gold += gold;
	}

	/**
	 * Gets the total amount of gold in possession by the party.
	 *  
	 * @return the amount of gold.
	 */
	public int getGold() {
		return gold;
	}

	/**
	 * Sets the main deck. This deck is the deck that every party member
	 * can access via the menu, and from there equip the desired cards.
	 * 
	 * @param d the deck to be used as the main deck.
	 */
	public void setMainDeck(Deck d) {
		mainDeck = d;
	}

	/**
	 * Gets the main deck. This deck is the deck that every party member
	 * can access via the menu, and from there equip the desired cards.
	 * 
	 * @return the main deck.
	 */
	public Deck getMainDeck() {
		return mainDeck;
	}
	
	/**
	 * Adds the given card to the main deck.
	 * 
	 * @param c the card to add.
	 */
	public void addCard(Card c) {
		mainDeck.addCard(c);
	}

	/**
	 * Gets the amount of steps that the player has walked.
	 * 
	 * @return the number of steps that the player has walked.
	 */
	public int getSteps() {
		return steps;
	}
	
	/**
	 * Sets the amount of steps that the player has walked.
	 * 
	 * @param step the number of steps that the player has walked.
	 */
	public void setSteps(int step) {
		steps = step;
	}
	
	/**
	 * Takes one step. The counter is incremented.
	 */
	public void takeStep() {
		steps++;
	}

	/**
	 * Gets the number of battles that the player has fought.
	 * 
	 * @param b the number of battles that the player has fought.
	 */
	public int getBattles() {
		return battles;
	}
	
	/**
	 * Sets the number of battles that the player has fought.
	 * 
	 * @param b the number of battles that the player has fought.
	 */
	public void setBattles(int b) {
		battles = b;
	}
	
	/**
	 * The battle counter is incremented.
	 */
	public void incrementBattle() {
		battles++;
	}
	
	/**
	 * Inserts an item in the list of items, with the given name and number.
	 * If an item with the given name already exists the given number is added
	 * to the already existing item. The number is the number of times that the
	 * item can be used.
	 * 
	 * @param name the name of the item.
	 * @param number the number of the item.
	 */
	public void addItem(String name, int number) {
		items.add(Organizer.convertKeepCase(name), number);
	}
	
	public void addItems(HashMap<String, Integer> items) {
		Iterator<String> it = items.keySet().iterator();
		while (it.hasNext()) {
			String key = it.next();
			int val = items.get(key);
			addItem(key, val);
		}
	}

	/**
	 * Inserts the given item in the list of items. If an item with the same
	 * name already exists, the number of this item is added to the existing
	 * item.
	 *  
	 * @param item the item to add.
	 */
	public void addItem(Item item) {
		items.add(item);
	}

	public void take(String name, int number) {
		items.take(name, number);
	}
	/**
	 * Gets the item with the given index from the list.
	 * 
	 * @param i the index of the item to get.
	 * @return the item with the given index.
	 */
	public Item getItem(int i) {
		return items.getItem(i);
	}

	/**
	 * Gets the number of items in the list.
	 * 
	 * @return the size of the item list.
	 */
	public int itemSize() {
		return items.getSize();
	}

	public boolean hasItem(String string) {
		for (int i = 0; i < items.getSize(); i++) {
			if (items.getItem(i).getName().equals(string)) {
				return true;
			}
		}
		return false;
	}
}
