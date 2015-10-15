/*
 * Classname: Database.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/05/2008
 */
package info;

import factories.Load;

import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

import java.util.logging.*;

import organizer.Organizer;

import landscape.Landscape;

/**
 * This singleton class manages the information in the database.
 * This information could be level information, character status, road status
 * and so on.
 * 
 * @author		Kalle Sj�str�m
 * @version 	0.7.0  - 19 May 2008
 */
public class Database {

	private static HashMap<String, Integer> status;
	private static HashMap<String, HashMap<Integer, Integer>> levelInformation;
	private static HashMap<String, String> storedTriggers;
	private static HashMap<String, LabyrinthInfo> visitedLabyrinth;
	private static ArrayList<String> visitedLabyrinthList;
	private static String[] lastVisitedLabyrinth;
	private static Logger logger = Logger.getLogger("Database");

	public static synchronized void reset() {
		status = new HashMap<String, Integer>();
		storedTriggers = new HashMap<String, String>();
		levelInformation = new HashMap<String, HashMap<Integer, Integer>>();
		visitedLabyrinth = new HashMap<String, LabyrinthInfo>();
		visitedLabyrinthList = new ArrayList<String>();
	}

	/**
	 * Adds the given hash map of status triggers to the database.
	 * 
	 * @param triggers the triggers to add.
	 */
	public static synchronized void addStatus(HashMap<String, Integer> triggers) {
		if (triggers != null) {
			Iterator<String> it = triggers.keySet().iterator();
			while (it.hasNext()) {
				String name = it.next();
				int value = triggers.get(name);
				addStatus(name, value);
			}
		}
	}
	
	public static void incrementStatus(HashMap<String, Integer> triggers) {
		Iterator<String> it = triggers.keySet().iterator();
		while (it.hasNext()) {
			String name = it.next();
			int value = triggers.get(name);
			value += getStatusFor(name);
			addStatus(name, value);
		}	
	}

	/**
	 * Adds the given information to the database.
	 * 
	 * @param name the name of the status to add.
	 * @param value the value of the status.
	 */
	public static synchronized void addStatus(String name, int value) {
		name = name.toLowerCase();
		logger.info("Adding status " + name + " " + value);
		Integer i = status.put(name, value);
		if (i != null) {
			logger.info("Status with name: " + name 
					+ " and status " + i + " was overwritten with " + value);
		}
	}

	/**
	 * Updates the status information contained in the given hash map.
	 *  
	 * @param triggers the status triggers to add.
	 */
	public static synchronized void updateStatus(HashMap<String, Integer> triggers) {
		addStatus(triggers);
	}

	/**
	 * Adds the given level up information about the character with the 
	 * given name. 
	 * 
	 * @param name the name of the character who the level information is for.
	 * @param info the level up information to add.
	 */
	public static synchronized void addLevelUpInfo(
			String name, HashMap<Integer, Integer> info) {
		String temp = name; 
		levelInformation.put(name, info);

	}

	/**
	 * Gets the level up information about the character with the given name.
	 * The information is about the given level.
	 * 
	 * @param name the name of the character who the information is for.
	 * @param nextLevel the number of the level to get.
	 * @return the level information as a hash map.
	 */
	public static synchronized HashMap<Integer, Integer> getLevelFor(
			String name, int nextLevel, int currentClass) {
		name += "=" + currentClass + ":" + nextLevel;
		HashMap<Integer, Integer> result = levelInformation.get(name);
		return result;
	}

	/**
	 * Gets the current status for the entity with the given name.
	 * An entity could be a villager, road or something like that.
	 * 
	 * @param name the name of the entity to check the status for.
	 * @return the status of the entity with the given name, or -1
	 * if the given name does not have a status.
	 */
	public static synchronized int getStatusFor(String name) {
		Integer s = status.get(name);
		int retStatus = s == null ? -1 : s;
		if (retStatus == -1) {
			logger.log(Level.FINE, "Could not find the status for " + name + " in the database.");
			name = Organizer.convert(name);
			s = status.get(name);
			logger.log(Level.FINE, "Checking " + name + " instead: " + s);
			retStatus = s == null ? -1 : s;
		}
		return retStatus;
	}

	/**
	 * Gets the status for all the open roads in the game. 
	 * 
	 * @return a list of addresses for all the open roads in the game.
	 */
	public static synchronized HashMap<Integer, Integer> getOpenedRoads(String zone) {
		HashMap<Integer, Integer> oRoads = new HashMap<Integer, Integer>();
		Iterator<String> it = status.keySet().iterator();
		int land = Landscape.convert(zone);
		while (it.hasNext()) {
			String key = it.next();
			if (key.startsWith("road" + land)) {
				int val = status.get(key);
				int addr = Integer.parseInt(key.split("-")[1]); 
				oRoads.put(addr, val);
			}
		}
		return oRoads;
	}

	/**
	 * Gets the status for the normal cards from the store with the given name.
	 * These statuses are the combo icon for each of the cards.
	 * 
	 * @param storeName the name of the store.
	 * @param size the size of the decks in the store.
	 * @return the status for the cards in the card shop with the given name.
	 */
	public static synchronized int[] getStatusForDeckStore(String storeName, int size) {
		int[] ret = new int[size];
		Arrays.fill(ret, -1);
		Iterator<String> it = status.keySet().iterator();
		int i = 0;
		while (it.hasNext()) {
			String key = it.next();
			if (key.startsWith(storeName)) {
				ret[i++] = status.get(key);
			}
		}
		return ret;
	}

	/**
	 * Store the given trigger of the given type in the map of stored
	 * triggers. These are different from the normal triggers in the way that
	 * one could save a string as value. It is used to store trigger events
	 * which could be executed by doing things like going to an inn and sleep.
	 * If one called this method with "inn" as name and "pathToStoreSequence"
	 * as trigger, the sequence "pathToStoreSequence" will be played when the
	 * character sleeps in an inn.
	 *   
	 * @param name the name of the trigger to store.
	 * @param trigger the actual trigger to store.
	 */
	public static void storeTriggers(String name, String trigger) {
		storedTriggers.put(name.toLowerCase(), trigger);
	}

	/**
	 * Gets the stored trigger with the given name.
	 * 
	 * @param name the name to get the stored trigger for.
	 * @return the stored trigger for the given name.
	 */
	public static String getStoredTriggers(String name) {
		return storedTriggers.get(name.toLowerCase());
	}

	/**
	 * Removes the stored trigger stored with the given name, if any exists.
	 * 
	 * @param name the name whose trigger to remove.
	 */
	public static void clearStoredTriggers(String name) {
		storedTriggers.remove(name.toLowerCase());
	}

	/**
	 * This method prints all the information in the database
	 * into the given writer.
	 * 
	 * @param writer the writer to print into.
	 */
	public static synchronized void saveData(PrintWriter writer) {
		Iterator<String> it = status.keySet().iterator();
		while (it.hasNext()) {
			String key = it.next();
			int val = status.get(key);
			writer.println("status " + key.replace(" ", "_") + " " + val);
		}
		Iterator<String> its = storedTriggers.keySet().iterator();
		while (its.hasNext()) {
			String key = its.next();
			String val = storedTriggers.get(key);
			writer.println("storedTrigger " + 
					key.replace(" ", "_") + " " + val.replace(" ", "_"));
		}
	}

	/**
	 * This method opens all roads in the database. 
	 */
	public static synchronized void openAllRoads() {
		Iterator<String> it = status.keySet().iterator();
		while (it.hasNext()) {
			String key = it.next();
			if (key.startsWith("road")) {
				status.put(key, 1);
			}
		}
	}

	/**
	 * Adds the given labyrinth map in the list containing all the visited 
	 * labyrinths in the game. The given name is used as key for the given map,
	 * and to retrieve it, call getMap(name) with the given name.
	 * 
	 * @param name the name of the map to store.
	 * @param map the map to store.
	 */
	public static void visitLabyrinth(String name, LabyrinthMap map) {
		boolean found = false;
		LabyrinthInfo info = null;
		Iterator<String> it = visitedLabyrinth.keySet().iterator();
		while (it.hasNext() && !found) {
			String s = it.next();
			info = visitedLabyrinth.get(s);
			found = name.startsWith(info.getLabyrinthName());
		}
		lastVisitedLabyrinth = LabyrinthMap.convert(name);
		if (!found) {
			info = new LabyrinthInfo(lastVisitedLabyrinth[0]);
			visitedLabyrinth.put(info.getLabyrinthName(), info);
			visitedLabyrinthList.add(info.getLabyrinthName());
		}
		info.addFloor(lastVisitedLabyrinth[1], map);
	}

	/**
	 * Gets the name of the last visited labyrinth.
	 * 
	 * @return the name of the last visited labyrinth.
	 */
	public static String[] getLastVisitedLabyrinth() {
		return lastVisitedLabyrinth;
	}

	/**
	 * Gets the list of all visited labyrinths.
	 * 
	 * @return the list of all visited labyrinths.
	 */
	public static HashMap<String, LabyrinthInfo> getVisitedLabyrinths() {
		return visitedLabyrinth;
	}
	
	public static ArrayList<String> getVisitedLabyrinthsList() {
		return visitedLabyrinthList;
	}

	/**
	 * Gets the labyrinth map with the given name.
	 * 
	 * @param name the name of the labyrinth map to get.
	 * @return the labyrinth map with the given name.
	 */
	public static LabyrinthInfo getMap(String name) {
		return visitedLabyrinth.get(Load.prepare(name.split("--")[0]));
	}

	public static void setLastVisitedLabyrinth(String[] lab) {
		lastVisitedLabyrinth = lab;
	}

	public static String[] getStoredKeys() {
		String[] keys = new String[0];
		keys = status.keySet().toArray(keys);
		Arrays.sort(keys);
		return keys;
	}
}
