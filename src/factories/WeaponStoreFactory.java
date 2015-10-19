/*
 * Classname: StoreFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 23/01/2008
 */
package factories;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import organizer.Organizer;

import equipment.AbstractEquipment;

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
public class WeaponStoreFactory extends AbstractFactory {
	
	private static WeaponStoreFactory storeFactory = new WeaponStoreFactory();

	private HashMap<String, Store> bank = new HashMap<String, Store>();
	private String current;

	/**
	 * The private constructor. This creates a new StoreFactory which 
	 * reads the stores.bank file and creates one instance of all the 
	 * stores in the game for future use.
	 */
	private WeaponStoreFactory() {
		parseFile("stores.bank");
	}

	/**
	 * Gets the only StoreFactory object.
	 * 
	 * @return the StoreFactory object.
	 */
	public static WeaponStoreFactory getStoreFactory() {
		return storeFactory;
	}

	/**
	 * Gets the abstract equipment with the given name from the given list.
	 * If the list does not contain any equipment with the given name
	 * this method will return null. If the list contains more than one with 
	 * the same name, this method will return the first equipment with that 
	 * name. I.e. the equipment with the lowest index.
	 * 
	 * @param list the list of equipments.
	 * @param name the name of the equipment to get.
	 * @return the equipment with the given name
	 */
	public AbstractEquipment getEquipmentByName(
			ArrayList<AbstractEquipment> list, String name) {
		for (int i = 0; i < list.size(); i++) {
			if (list.get(i).getName().equals(name)) {
				return list.get(i);
			}
		}
		return null;
	}

	/**
	 * Gets the list of right handed equipments from 
	 * the store with the specified name.
	 * 
	 * @param storeName the name of the store.
	 * @return the list of right handed equipments that this store has.
	 */
	public ArrayList<AbstractEquipment> getRightHandFor(String storeName) {
		return bank.get(storeName).rightHand;
	}

	/**
	 * Gets the list of armors from the store with the specified name.
	 * 
	 * @param storeName the name of the store.
	 * @return the list of armors that this store has.
	 */
	public ArrayList<AbstractEquipment> getArmorsFor(String storeName) {
		return bank.get(storeName).armors;
	}

	/**
	 * Gets the list of left handed equipments from 
	 * the store with the specified name.
	 * 
	 * @param storeName the name of the store.
	 * @return the list of left handed equipments that this store has.
	 */
	public ArrayList<AbstractEquipment> getLeftHandFor(String storeName) {
		return bank.get(storeName).leftHand;
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
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			bank.put(name, new Store());
			current = name;
		} else if (command.equals("rightHand")) {
			bank.get(current).rightHand.add(get(tokenizer));
		} else if (command.equals("leftHand")) {
			bank.get(current).leftHand.add(get(tokenizer));
		} else if (command.equals("body")) {
			bank.get(current).armors.add(get(tokenizer));
		}
	}

	private AbstractEquipment get(StringTokenizer tokenizer) {
		String name = Organizer.convertKeepCase(tokenizer.nextToken());
		AbstractEquipment ae = 
			EquipmentFactory.getEquipment(name);
		return ae;
	}

	/**
	 * The Store class represents a store which has three separate list 
	 * containing weapons, armors and shields. This is just a storage
	 * class without getters and setters. This is because the only class
	 * who needs the information is the store factory.
	 *
	 * @author     Kalle Sjöström
	 * @version    0.7.0 - 21 Jan 2008
	 */
	private class Store {
		private ArrayList<AbstractEquipment> rightHand = 
			new ArrayList<AbstractEquipment>();	
		private ArrayList<AbstractEquipment> leftHand = 
			new ArrayList<AbstractEquipment>();
		private ArrayList<AbstractEquipment> armors = 
			new ArrayList<AbstractEquipment>();
	}
}