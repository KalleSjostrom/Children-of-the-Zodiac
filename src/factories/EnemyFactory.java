/*
 * Classname: EnemyFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package factories;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;
import java.util.StringTokenizer;

import java.util.logging.*;

import organizer.Organizer;

import character.Bestiary;
import character.Enemy;
import equipment.Items.Item;
import graphics.ImageHandler;

/**
 * This represents a bank with all the enemies in the game.
 * It is designed as a singelton which means there will only 
 * be one object of this class. It reads a file containing information 
 * concerning all the enemies in the game. 
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 21 Jan 2008
 */
public class EnemyFactory extends AbstractFactory {
	
	private static EnemyFactory enemyFactory = new EnemyFactory();

	private HashMap<String, EnemyGroup> bank = new HashMap<String, EnemyGroup>();
	private HashMap<String, Enemy> enemyBank = new HashMap<String, Enemy>();
	private String currentName;

	private float currentChance;

	/**
	 * The private constructor. This creates a new EnemyFactory which 
	 * reads the enemyBank.bank file and creates one instance of all the 
	 * enemies in the game for future use.
	 */
	private EnemyFactory() {
		parseFile("enemyBank.bank");
	}

	/**
	 * Gets the only EnemyFactory object.
	 * 
	 * @return the EnemyFactory object.
	 */
	public static EnemyFactory getEnemyFactory() {
		return enemyFactory;
	}
	
	/**
	 * Checks if the enemy group with the given name exists or not.
	 * 
	 * @param name the name of the enemy group to check on.
	 * @return true if the enemy group with the given name exists.
	 */
	public boolean doesEnemyGroupExist(String name) {
		return bank.containsKey(name);
	}

	/**
	 * Gets the enemy group with the specified name.
	 * 
	 * @param name the name of the enemy group.
	 * @return the enemy group with the given name.
	 */
	public EnemyGroup getEnemyGroup(String name) {
		return bank.get(name);
	}

	/**
	 * This method implements the executeCommand from the 
	 * AbstractFactory class. It creates enemies and puts them in different 
	 * groups according to the files instructions.
	 * 
	 * @param command the command to execute.
	 * @param tokenizer the information concerning the rest of the information.
	 */
	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("newGroup")) {
			currentName = Organizer.convertKeepCase(tokenizer.nextToken());
			currentChance = 0;
			bank.put(currentName, new EnemyGroup());
		} else if (command.equals("newEnemy")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			Enemy enemy = createEnemy(name);
			enemyBank.put(name, enemy);
		} else if (command.equals("enemy")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			Enemy e = enemyBank.get(name);
			float chance = Float.parseFloat(tokenizer.nextToken());
			currentChance += chance;
			float chanceForTwo = Float.parseFloat(tokenizer.nextToken());
			float chanceForThree = Float.parseFloat(tokenizer.nextToken());
			EnemyGroup group = bank.get(currentName);
			group.addFrequency(e, new float[]{chanceForTwo, chanceForThree});
			group.addChance(currentChance);
			group.addEnemy(e);
		} else if (command.equals("dropdata")) {
			String enemyName = Organizer.convertKeepCase(tokenizer.nextToken());
			Enemy e = enemyBank.get(enemyName);
			String itemName = Organizer.convertKeepCase(tokenizer.nextToken());
			Item item = new Item(itemName, Integer.parseInt(tokenizer.nextToken()));
			e.setDropData(item, Float.parseFloat(tokenizer.nextToken()));
		} else if (command.equals("stats")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			int[] stats = new int[16];
			for (int i = 1; i < stats.length; i++) {
				stats[i] = Integer.parseInt(tokenizer.nextToken());
			}
			Bestiary.getBestiary().addEnemy(enemyBank.get(name), stats);
		} else if (command.equals("cardPreference")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			HashMap<String, Integer> cardPreferences = new HashMap<String, Integer>();
			while (tokenizer.hasMoreTokens()) {
				String card = tokenizer.nextToken();
				int percent = Integer.parseInt(tokenizer.nextToken());
				cardPreferences.put(card, percent);
			}
			enemyBank.get(name).setCardPreferences(cardPreferences);
		}
	}

	/**
	 * Creates a new enemy from the information in the given tokenizer.
	 * 
	 * @param tokenizer the StringTokenizer containing the information about
	 * the enemy.
	 * @return the newly created enemy.
	 */
	private Enemy createEnemy(String name) {
		EnemyLoader enemyLoader = new EnemyLoader(name);
		return enemyLoader.getEnemy();
	}
	
	public Enemy getBoss(String string) {
		return enemyBank.get(string);
	}
	
	
	public static void main(String[] args) {
		Load.setupForTest();
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		EnemyFactory ef = EnemyFactory.getEnemyFactory();
		EnemyGroup eg = ef.getEnemyGroup("Central Pass--Central Part");
		for (int i = 0; i < 10; i++) {
			Enemy en = eg.getRandomEnemy();
			if (!map.containsKey(en.getName())) {
				map.put(en.getName(), 0);
			}
			Integer counter = map.get(en.getName());
			map.put(en.getName(), ++counter);
		}
	}

	/**
	 * This represents a list with all the enemies in a particular place.
	 * It has methods for getting a random enemy from the group.
	 * Each labyrinth has currently only one enemy group.
	 * 
	 * @author     Kalle Sjöström
	 * @version    0.7.0 - 21 Jan 2008
	 */
	public class EnemyGroup {

		private ArrayList<Enemy> enemies = new ArrayList<Enemy>();
		private ArrayList<Float> chances = new ArrayList<Float>();
		private HashMap<String, float[]> frequency = new HashMap<String, float[]>();
		private Random dice = new Random();
		private Logger logger = Logger.getLogger("EnemyGroup");
		private int lastEnemy = -1;

		/**
		 * Sets the boss for this enemy group.
		 * 
		 * @param boss the boss to set.
		 */
		public EnemyGroup() {}

		public void addChance(float chance) {
			chances.add(chance);
		}
		
		public void addFrequency(Enemy e, float[] freq) {
			frequency.put(e.getDbName(), freq);
		}

		/**
		 * Adds an enemy to this group.
		 * 
		 * @param enemy the enemy to add.
		 */
		private void addEnemy(Enemy enemy) {
			enemies.add(enemy);
		}
	
		/**
		 * Gets a random enemy from this group.
		 * 
		 * @return a random enemy from this group.
		 */
//		public Enemy getRandomEnemy() {
//			return getRandomEnemy(true);
//		}
//		
//		private Enemy getRandomEnemy(boolean checkLast) {
//			float rand = dice.nextFloat();
//			logger.log(Level.FINE, "Rand " + rand);
//			for (int i = 0; i < chances.size(); i++) {
//				logger.log(Level.FINE, "Chance " + i + " " + chances.get(i));
////				System.out.println("i " + i + " " + lastEnemy);
//				
//				if (chances.get(i) > rand) {
////					if (checkLast && i == lastEnemy) {
////						System.out.println("Notices same, getting new");
////						Enemy e = getRandomEnemy(false);
////						System.out.print("Same as last, therefore got new: ");
////						return e;
////					}
////					System.out.print("Updating " + lastEnemy + " to ");
//					lastEnemy = i;
////					System.out.println(lastEnemy);
//					return enemies.get(i).copy();
//				}
//			}
//			return enemies.get(enemies.size() - 1).copy();
//		}
		

		
		
		public Enemy getRandomEnemy() {
			float rand = dice.nextFloat();
			logger.log(Level.FINE, "Rand " + rand);
			for (int i = 0; i < chances.size(); i++) {
				logger.log(Level.FINE, "Chance " + i + " " + chances.get(i));
				if (chances.get(i) > rand) {
					return enemies.get(i).copy();
				}
			}
			return enemies.get(enemies.size() - 1).copy();
		}
		
		public float[] getFrequency(Enemy en) {
			return frequency.get(en.getDbName());
		}

		/**
		 * Gets the list of enemies contained in this group.
		 * 
		 * @return the enemies in this group.
		 */
		public ArrayList<Enemy> getEnemies() {
			return enemies;
		}

		/**
		 * Loads the textures of the enemies.
		 */
		public void loadTextures() {
			for (int i = 0; i < enemies.size(); i++) {
				String[] images = enemies.get(i).getImages();
				for (int j = 0; j < images.length; j++) {
					ImageHandler.addToCurrentLoadNow(images[j]);
				}
			}
		}
		
		/**
		 * Checks if this enemy group has any enemies.
		 * 
		 * @return true if this enemy group has any enemies.
		 */
		public boolean hasEnemies() {
			return enemies.size() > 0;
		}
	}
}
