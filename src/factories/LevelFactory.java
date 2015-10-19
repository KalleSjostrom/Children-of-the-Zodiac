/*
 * Classname: LevelFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package factories;

import info.Database;

import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import character.Creature;

import villages.villageStory.Parser;

/**
 * This represents a bank with all the levels in the game.
 * It is designed as a singelton which means there will only 
 * be one object of this class. It reads a file containing information 
 * concerning all the levels in the game. There are unique levels for
 * each character.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 21 Jan 2008
 */
public class LevelFactory extends AbstractFactory {

	public static final int NO_INCREASE = -Integer.MIN_VALUE;
	
	private static LevelFactory levelFactory = new LevelFactory();

	/**
	 * The private constructor. This creates a new LevelFactory which 
	 * reads the levels.bank file and creates one instance of all the 
	 * levels in the game for future use.
	 */
	private LevelFactory() {
		parseFile("levels.bank");
	}

	/**
	 * Gets the only LevelFactory object.
	 * 
	 * @return the LevelFactory object.
	 */
	public static LevelFactory getLevelFactory() {
		return levelFactory;
	}

	/**
	 * This method gets the level information for the level with number 
	 * "nextLevel" concerning the character with the specified name. 
	 * If one would like to get the fourth level information about 
	 * "Celis", a call to this method would be:
	 * 
	 * getLevelFor("Celis", 4);
	 * 
	 * This call returns a hash map with the wanted information from the 
	 * database. And to access it, use the StaticValues.LEVEL .EXPERIANCE
	 * .LIFE .ATTACK .DEFENSE .MAGIC_DEFENSE .AGILITY .EVADE .LUCK or
	 * .SPECIAL_SLOTS to get the desired information.
	 * 
	 * @param name the name of the character.
	 * @param nextLevel the number of the level that information is needed.
	 * @return an hash map with information about the searched level. 
	 */
	public static HashMap<Integer, Integer> getLevelFor(
			String name, int nextLevel, int currentClass) {
		return Database.getLevelFor(name, nextLevel, currentClass);
	}

	/**
	 * This method implements the executeCommand from the 
	 * AbstractFactory class. It creates inserts a level in the database 
	 * from the string values in the string tokenizer.
	 * 
	 * @param command the command to execute.
	 * @param t the tokenizer containing the information concerning the level.
	 */
	protected void executeCommand(String command, StringTokenizer t) {
		String currentName = command;
		HashMap<Integer, Integer> currentLevel = new HashMap<Integer, Integer>();
		HashMap<String, Integer> map = Creature.getAttributMap();
		Iterator<String> it = map.keySet().iterator();
		while (it.hasNext()) {
			int key = map.get(it.next());
			currentLevel.put(key, NO_INCREASE);
		}
		
		while (t.hasMoreTokens()) {
			String[] args = Parser.getArgument(t.nextToken());
			int key = map.get(args[0]);
			currentLevel.put(key, Integer.parseInt(args[1]));
		}
		Database.addLevelUpInfo(currentName, currentLevel);
	}

	public static String toString(String name, int classLevel, int level, HashMap<Integer, Integer> info) {
		return 
			name + "=" + classLevel + ":" + level + 
			" hp=" + info.get(Creature.MAX_HP) +
			" attack=" + info.get(Creature.ATTACK) +
			" magic=" + info.get(Creature.MAGIC_ATTACK) +
			" support=" + info.get(Creature.SUPPORT_ATTACK) +
			" defense=" + info.get(Creature.DEFENSE) +
			" magicDefense=" + info.get(Creature.MAGIC_DEFENSE) + 
			(info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL) == LevelFactory.NO_INCREASE ? "" :
				" expToNext=" + info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL)) +
			(info.get(Creature.DECK_SIZE) == LevelFactory.NO_INCREASE ? "" :
				" deckSize=" + info.get(Creature.DECK_SIZE));
	}
}
