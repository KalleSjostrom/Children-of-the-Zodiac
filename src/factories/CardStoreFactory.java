/*
 * Classname: CardStoreFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 23/01/2008
 */
package factories;

import info.Database;

import java.util.HashMap;
import java.util.StringTokenizer;

import cards.Card;
import equipment.Deck;

/**
 * This represents a store factory with all the store in the game.
 * It is designed as a singleton which means there will only 
 * be one object of this class. It reads a file containing information 
 * concerning all the store in the game. One store contains array lists 
 * with weapons, armors and shields which can be gotten from the methods 
 * in this class.
 *
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 23 Jan 2008
 */
public class CardStoreFactory extends AbstractFactory {
	
	private static HashMap<String, Deck> bank = new HashMap<String, Deck>();
	static {new CardStoreFactory();}
	private String current;
	private int counter;
	private int storeStatus;

	/**
	 * The private constructor. This creates a new StoreFactory which 
	 * reads the stores.bank file and creates one instance of all the 
	 * stores in the game for future use.
	 */
	private CardStoreFactory() {
		parseFile("cardStores.bank");
	}

	/**
	 * Gets the normal cards in the store with the given name.
	 * 
	 * @param storeName the name of the store to get the cards from.
	 * @return the list of normal cards in the store with the given name.
	 */
	public static Deck getCardsFor(String storeName) {
		int status = Math.max(Database.getStatusFor(storeName), 0);
		Deck d = bank.get(storeName);
		Deck newDeck = new Deck(null);
		for (int i = d.getCurrentDeckSize() - 1; i >= 0; i--) {
			Card c = d.getCard(i);
			if (c.getStoreStatus() <= status) {
				int cardStatus = Database.getStatusFor(c.getDatabaseName());
				if (cardStatus == -1) {
					newDeck.addCard(c);
				}
			}
		}
		return newDeck;
	}
	
	/**
	 * This method implements the executeCommand from the 
	 * AbstractFactory class. It creates a store from the string values 
	 * in the string tokenizer.
	 * 
	 * @param command the command to execute.
	 * @param tokenizer the information concerning the store.
	 */
	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("store")) {
			String name = tokenizer.nextToken().replace("_", " ");
			bank.put(name, new Deck(null));
			current = name;
			counter = 0;
		} else if (command.equals("status")) {
			storeStatus = Integer.parseInt(tokenizer.nextToken());
		} else if (command.equals("card")) {
			String dbName = current + storeStatus + counter;
			int status = Database.getStatusFor(current + storeStatus + counter);
			counter++;
			if (status == -1) {
				String prefix = Card.getPrefix(tokenizer.nextToken());
				String name = prefix + tokenizer.nextToken();
				Card c = Card.createCard(name, tokenizer);
				c.setDatabaseName(dbName);
				c.setStoreStatus(storeStatus);
				bank.get(current).addCard(c);
			}
		}
	}
}