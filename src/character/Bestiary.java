/*
 * Classname: Bestiary.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/09/2008
 */
package character;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

/**
 * This class represents a list of all the enemies in the game collected
 * in a bestiary. Here, the player can browse through the enemies that the
 * player has encountered. If the player has encountered the enemy enough 
 * times, some stats and images are shown from the bestiary page in the menu.
 * The information about which stats to show are stored in this class.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 22 Sept 2008
 */
public class Bestiary {

	private static Bestiary bestiary = new Bestiary();
	private HashMap<Integer, Stats> enemyList = 
		new HashMap<Integer, Stats>();
	
	/**
	 * The private constructor.
	 */
	private Bestiary() {
		// Empty private constructor.
	}

	/**
	 * Gets the only Bestiary object.
	 * 
	 * @return the Bestiary object.
	 */
	public static Bestiary getBestiary() {
		return bestiary;
	}
	
	/**
	 * Gets all the statistics in the bestiary. This is used by the save class
	 * when saving the game. The returned hash map will contain all the useful
	 * information.
	 *  
	 * @return the hash map containing the information in the bestiary.
	 */
	public HashMap<Integer, Stats> getStats() {
		return enemyList;
	}

	/**
	 * Gets the size of the bestiary.
	 * 
	 * @return the size of the bestiary.
	 */
	public int getSize() {
		return enemyList.size();
	}

	/**
	 * Adds the given enemy in the bestiary together with the given stats.
	 * 
	 * @param enemy the enemy to add.
	 * @param stats the stats of the enemy.
	 */
	public void addEnemy(Enemy enemy, int[] stats) {
		if (enemy == null) {
			new IllegalArgumentException("Null enemy!").printStackTrace();
			System.exit(0);
		}
		enemyList.put(getSize(), new Stats(enemy, stats));
	}

	/**
	 * Gets the stats object that corresponds with the index:th enemy added.
	 * If index is zero it means the first enemy added and so on.
	 * 
	 * @param index the index of the enemy to get.
	 * @return the i:th enemy added.
	 */
	public Stats getStats(int index) {
		return enemyList.get(index);
	}

	/**
	 * Gets the stats object that corresponds with the given enemy.
	 * 
	 * @param enemy the enemy to get the stats for.
	 * @return the stats for the given enemy.
	 */
	public Stats getStats(Enemy enemy) {
		return getStats(enemy.getDbName());
	}

	/**
	 * Gets the stats object that corresponds with the enemy 
	 * with the given name.
	 * 
	 * @param name the name of the enemy to get the stats for.
	 * @return the stats for the enemy with the given name.
	 */
	public Stats getStats(String name) {
		Iterator<Integer> it = enemyList.keySet().iterator();
		while (it.hasNext()) {
			int key = it.next();
			Stats stats = enemyList.get(key);
			if (name.equals(stats.enemy.getDbName())) {
				return stats;
			}
		}
		return null;
	}

	/**
	 * Updates the battle counter for the given enemy. This method is
	 * called after an enemy has been defeated.
	 * 
	 * @param enemy the enemy to update the battle counter for.
	 * @param enemySize the number of enemies encountered.
	 */
	public void updateStats(Enemy enemy, int enemySize) {
		getStats(enemy).battleCounter += enemySize;
	}

	/**
	 * This class represents the stats for an enemy. These stats is the 
	 * attributes of an enemy but with a limiting counter that must be
	 * higher than a set value to get the actual attribute of an enemy.
	 * If the counter is not higher than the set value, (this value is set
	 * by the enemy bank file) ??? is returned as the attribute. 
	 * 
	 * @author 		Kalle Sjšstršm
	 * @version 	0.7.0 - 22 Sept 2008
	 */
	public class Stats {
		
		public static final int NAME = 0;
		public static final int HP = 1;
		public static final int AGILITY = 2;
		public static final int ATTACK = 3;
		public static final int MAGIC = 4;
		public static final int SUPPORT = 5;
		public static final int DEFENSE = 6;
		public static final int MAGIC_DEFENSE = 7;
		public static final int EVADE = 8;
		public static final int HIT = 9;
		public static final int ELEMENT = 10;
		public static final int GOLD = 11;
		public static final int EXPERIANCE = 12;
		public static final int IMAGE = 13;
		public static final int CRITICAL_HIT = 14;
		public static final int BATTLE_COUNTER = 15;

		private Enemy enemy;
		private int[] stats;
		private int battleCounter;
		private int counterOffset;

		/**
		 * Creates a new stats with the given index and the list of limits
		 * for each attribute of the enemy.
		 * 
		 * @param enemy the enemy whose attributes can be gotten.
		 * @param stats the list of limits that the battle counter must surpass
		 * to get the attribute of the given enemy.
		 */
		public Stats(Enemy enemy, int[] stats) {
			this.enemy = enemy;
			this.stats = stats;
		}

		/**
		 * The enemy associated with these stats.
		 * 
		 * @return the enemy associated with these stats.
		 */
		public Enemy getEnemy() {
			return enemy;
		}

		/**
		 * Gets an array with the stats of the enemy in this Stats object.
		 * The returned array contains the attribute of the enemy, if the 
		 * player has encountered this enemy enough times to get the 
		 * attributes. The amount of times the player needs to have 
		 * encountered the enemy, is set by the stats array in the constructor.
		 * The stats array contains different limits for all the attributes
		 * of the enemy. If the player has not encountered the enemy set by 
		 * the constructor, enough times, ??? is the string for the attribute 
		 * that the player has not earned.
		 * 
		 * @return an array with strings representing the attributes of the 
		 * enemy, in this stats object. 
		 */
		public String[] getInfo() {
			String[] info = new String[BATTLE_COUNTER + 1];
			for (int i = 1; i <= IMAGE; i++) {
				info[i] = battleCounter + counterOffset + 1 >= stats[i] ? 
						String.valueOf(enemy.getAttribute(i)) : "???"; 
			}
			info[BATTLE_COUNTER] = String.valueOf(battleCounter);
			info[NAME] = battleCounter + counterOffset + 1 >= stats[13] ? enemy.getName() : "???";
			System.out.println("Stats " + Arrays.toString(stats));
			System.out.println("bc " + battleCounter + " " + counterOffset);
			return info;
		}
		
		/**
		 * This will cause the attributes up the given attribute of the enemy 
		 * to be shown in the bestiary. If the battle counter is 3, the offset
		 * is 0 and the limit when the image should be shown in the bestiary is
		 * 5 and this method is called, the battle counter would still be 3 the
		 * offset would be 2 so the image would be shown because the counter 
		 * + offset is >= than 5 (2 + 3 >= 5).
		 *  
		 * @param attribute the attribute to show.
		 */
		public void moveCounterTo(int attribute) {
			if (battleCounter + counterOffset < stats[attribute]) {
				counterOffset = stats[attribute] - battleCounter;
			}
		}
		
		/**
		 * This will cause all the attributes of the enemy to be shown in the
		 * bestiary.
		 */
		public void moveCounterToLast() {
			for (int i = 0; i < BATTLE_COUNTER; i++) {
				moveCounterTo(i);
			}
		}

		/**
		 * This enemy checks if the player has encountered this enemy enough
		 * times to show the image in the bestiary menu page.
		 * 
		 * @return true if the image of the enemy should be shown in the menu.
		 */
		public boolean shouldShowImage() {
			return battleCounter >= stats[IMAGE];
		}

		/**
		 * This method sets the battle counter to the given value.
		 * The battle counter is the amount of times that the player has
		 * encountered this enemy.
		 * 
		 * @param counter the value to set the battle counter to.
		 */
		public void setCounter(int counter) {
			battleCounter = counter;
		}
		
		/**
		 * This method sets the battle counter offset to the given value.
		 * The battle counter offset is the amount to offset the battle counter
		 * when calculating whether an attribute should be shown or not.
		 * 
		 * @param counter the value to set the battle counter to.
		 */
		public void setCounterOffset(int counter) {
			counterOffset = counter;
		}

		/**
		 * Gets the battle counter. The battle counter is the amount of times
		 * that the player has encountered this enemy.
		 * 
		 * @return the battle counter.
		 */
		public int getBattleCounter() {
			return battleCounter;
		}

		/**
		 * Gets the battle counter offset. The battle counter offset is the 
		 * amount to offset the battle counter when calculating whether an 
		 * attribute should be shown or not.
		 * 
		 * @return the battle counter offset.
		 */
		public int getCounterOffset() {
			return counterOffset;
		}
	}
}
