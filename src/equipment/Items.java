/*
 * Classname: Items.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package equipment;

import java.util.ArrayList;

/**
 * This class represents a list of items. Used by the main menu.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Items {

	private ArrayList<Item> items = new ArrayList<Item>();

	/**
	 * Inserts an item in the list of items, with the given name and number.
	 * If an item with the given name already exists the given number is added
	 * to the already existing item. The number is the number of times that the
	 * item can be used.
	 * 
	 * @param name the name of the item.
	 * @param number the number of the item.
	 */
	protected void add(String name, int number) {
		Item item = getItem(name);
		if (item == null) {
			items.add(new Item(name, number));
		} else {
			item.number += number;
		}
	}
	
	protected void take(String name, int number) {
		Item item;
		for (int i = 0; i < items.size(); i++) {
			item = items.get(i);
			if (name.equals(item.name)) {
				if (item.number >= 1) {
					item.number -= number;
				}
				if (item.number <= 0) {
					items.remove(i);
				}
			}
		}
	}
	/**
	 * Inserts the given item in the list of items. If an item with the same
	 * name already exists, the number of this item is added to the existing
	 * item.
	 *  
	 * @param item the item to add.
	 */
	protected void add(Item item) {
		Item oldItem = getItem(item.name);
		if (oldItem == null) {
			items.add(item);
		} else {
			oldItem.number += item.number;
		}
	}

	/**
	 * Subtracts one from the number of the item with the given name.
	 * If the number equals one it is removed.
	 * 
	 * @param name the name of the item.
	 * @return the new number.
	 */
	protected int reduceNumber(String name) {
		int number = 0;
		Item item = null;
		for (int i = 0; i < items.size(); i++) {
			item = items.get(i);
			if (name.equals(item.name)) {
				if (item.number > 1) {
					item.reduceNr();
					number = item.number;
				} else {
					items.remove(i);
					number = item.number;
				}
			}
		}
		return number;
	}

	/**
	 * Gets the item at index i.
	 * 
	 * @param i the index
	 * @return the item at index i.
	 */
	protected Item getItem(int i) {
		return items.get(i);
	}

	/**
	 * Gets the item with the given name.
	 * 
	 * @param name the name to search for.
	 * @return the item.
	 */
	private Item getItem(String name) {
		for (int i = 0; i < items.size(); i++) {
			if (name.equals(items.get(i).name)) {
				return items.get(i);
			}
		}
		return null;
	}

	/**
	 * Gets the size of this list.
	 * 
	 * @return the size of the items.
	 */
	protected int getSize() {
		return items.size();
	}

	/**
	 * This nested class stores information about a item.
	 * 
	 * @author 	   Kalle Sjšstršm 
	 * @version    0.7.0 - 25 Jan 2008
	 */
	public static class Item {

		private String name;
		private int number;

		/**
		 * Constructs a new item with the given name and number.
		 * 
		 * @param name the name of the item.
		 * @param Nr the number of this item own by the player.
		 */
		public Item(String name, int Nr) {
			this.name = name;
			this.number = Nr;
		}

		/**
		 * Gets the name of the item.
		 * 
		 * @return the name.
		 */
		public String getName() {
			return name;
		}

		/**
		 * Gets the number of items that can be used.
		 * This number will be presented to the left of the item in the menu.
		 * An example: 20 x potion.
		 *  
		 * @return the number of this item in the party's backpack.
		 */
		public int getNr() {
			return number;
		}

		/**
		 * This method uses an item and therefore
		 * subtracts one from the number.
		 */
		public void reduceNr() {
			number--;
		}
	}
}
