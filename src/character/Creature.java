/*
 * Classname: Creature.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package character;

import info.BattleValues;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Random;

import java.util.logging.*;

import cards.AbstractCard;

/**
 * This abstract class represents a creature in the game. A creature can 
 * either be a character or an enemy. 
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Jan 2008
 */
public abstract class Creature {

	/* Attributes for both characters and enemies. */
	public static final int HP = 0;
	
	public static final int DEFENSE = 1;
	public static final int MAGIC_DEFENSE = 2;
	public static final int AGILITY = 3;
	public static final int EVADE = 4;
	public static final int HIT = 5;
	public static final int ATTACK = 6;
	public static final int MAGIC_ATTACK = 7;
	public static final int SUPPORT_ATTACK = 8;
	public static final int MAX_HP = 9;
	
	/* Attributes for only characters. */
	public static final int EXP_LEFT_TO_NEXT_LEVEL = 10;
	public static final int DECK_SIZE = 11;
	public static final int CLASS = 12;
	public static final int EXPERIANCE = 13;
	public static final int LEVEL = 14;
	
	/* Attributes for only enemies. */
	public static final int ELEMENT = 10;
	public static final int GOLD_SPOILS = 11;
	public static final int EXPERIENCE_SPOILS = 12;
	public static final int CRITICAL_HIT_PRECENT = 13;
	
	public static final int HAS_NO_ARMOR = 0;
	public static final int ARMOR_ALREADY_CRUSHED = 1;
	public static final int ARMOR_CRUSHED = 2;

	private static HashMap<Integer, String> map = createMap();
	private static HashMap<String, Integer> attributeMap = createAttributeMap();
	
	private static Logger logger = Logger.getLogger("Creature");
	
	protected Boost defenseBoost = new Boost();
	protected Boost magicDefenseBoost = new Boost();
	protected Boost attackBoost = new Boost();
	protected Boost magicBoost = new Boost();
	protected Boost lifeBoost = new Boost();
	protected Boost speedBoost = new Boost();
	protected Boost supportBoost = new Boost();
	
	protected String name;
	protected int openWound = 0;
	protected double progress;
	protected boolean alive = true;
	protected boolean resurrected = false;
	protected boolean tempCrushed;
	protected boolean active = true;
	protected boolean inTurn = false;

	private float[] attributes;
	private float updateTime = 0;

	/**
	 * Creates a creature from the given name and attributes.
	 * 
	 * @param name the name of the creature.
	 * @param att the list of attributes.
	 */
	protected Creature(String name, float[] att) {
		this.name = name;
		attributes = att;
		progress = new Random().nextInt(100);
	}
	
	/**
	 * This method creates and returns a hash map that maps the attributes
	 * to a string telling which attribute it is. ATTACK becomes "Attack: "
	 * 
	 * @return a hash map mapping attributes to strings.
	 */
	private static HashMap<Integer, String> createMap() {
		HashMap<Integer, String> map = new HashMap<Integer, String>();
		map.put(ATTACK, "Attack: ");
		map.put(MAGIC_ATTACK, "Magic Off: ");
		map.put(SUPPORT_ATTACK, "Support: ");
		map.put(AGILITY, "Agility: ");
		map.put(DEFENSE, "Defence: ");
		map.put(MAGIC_DEFENSE, "Magic Def: ");
		map.put(HIT, "Hit: ");
		map.put(EVADE, "Evade: ");
		map.put(EXPERIANCE, "Exp: ");
		map.put(EXP_LEFT_TO_NEXT_LEVEL, "Next Lv: ");
		map.put(LEVEL, "Level: ");
		map.put(DECK_SIZE, "Decksize: ");
		return map;
	}
	
	private static HashMap<String, Integer> createAttributeMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("hp", MAX_HP);
		map.put("attack", ATTACK);
		map.put("support", SUPPORT_ATTACK);
		map.put("magic", MAGIC_ATTACK);
		map.put("defense", DEFENSE);
		map.put("magicDefense", MAGIC_DEFENSE);
		map.put("agility", AGILITY);
		map.put("evade", EVADE);
		map.put("hit", HIT);
		map.put("deckSize", DECK_SIZE);
		map.put("expToNext", EXP_LEFT_TO_NEXT_LEVEL);
		return map;
	}
	
	public static HashMap<Integer, String> getMap() {
		return map;
	}

	public static HashMap<String, Integer> getAttributMap() {
		return attributeMap;
	}
	
	/**
	 * Kills this creature.
	 */
	public void kill() {
		attributes[HP] = 0;
		alive = false;
	}

	/**
	 * Fully cures this creature, whether it's dead or not.
	 */
	public void fullLife() {
		alive = true;
		attributes[HP] = attributes[MAX_HP];
	}

	/**
	 * Resets the current speed. The current speed is incremented in battle 
	 * to keep track of whose turn it is.
	 */
	public void resetSpeed() {
		progress = 0;
	}

	/**
	 * Checks if the creature is alive.
	 * 
	 * @return true if the creature is alive.
	 */
	public boolean isAlive() {
		return alive = attributes[HP] > 0;
	}

	/**
	 * Fully cures this creature. But only if it is alive.
	 */
	public void fullCure() {
		if (isAlive()) {
			fullLife();
		}
	}

	/**
	 * Cures this creature with the given amount, if the creature is alive.
	 * Can not heal more than the creatures max life.
	 * 
	 * @param amount the amount to heal.
	 * @return the amount that has been healed. 
	 * If the creature is dead or if it has full life, this amount is zero.
	 */
	public int cure(float amount) {
		if (isAlive() || resurrected) {
			resurrected = false;
			int HpFromMax = Math.round(attributes[MAX_HP] - attributes[HP]);
			attributes[HP] += amount;
			if (attributes[HP] > attributes[MAX_HP]) {
				attributes[HP] = attributes[MAX_HP];
				return HpFromMax;
			}
			return Math.round(amount);
		}
		return 0;
	}

	public int curePercent(float f) {
		return cure(attributes[MAX_HP] * f);
	}
	
	/**
	 * Sets this creature as active. This will only matter if the creature
	 * is in battle. If a character is active, it is drawn in color while 
	 * an inactive creature is drawn in black and white.
	 * 
	 * @param active true if the creature should be activated.
	 */
	public void setActive(boolean active) {
		this.active = active;
	}

	/**
	 * This sets this creature turn in battle. If it has the turn
	 * this creature is the one hitting, playing cards. Set this
	 * true or false to mark this creatures turn.
	 * 
	 * @param turn true if this creature has the turn.
	 */
	public void setTurn(boolean turn) {
		inTurn = turn;
	}
	
	/**
	 * Adds the given value to the characters given attribute.
	 * Suppose that you would like to add 10 hp to the characters life.
	 * A call would then be made like this:
	 * </br>
	 * <code>int newLife = addAttribute(Creature.HP, 10);</code>
	 * 
	 * @param attribute is the kind of attribute to increase. This could be 
	 * Creature.HP, .MAX_HP and so on.
	 * @param value the value to add.
	 * @return the new value of the given attribute.
	 */
	public int addAttribute(int attribute, int value) {
		attributes[attribute] += value;
		return getAttribute(attribute);
	}
	
	public void setAttribute(int attribute, int values) {
		attributes[attribute] = values;
	}

	/**
	 * Checks if this creature is idling, waiting to hit. To in activate
	 * a creature so it is not idling, call setActive(). 
	 * 
	 * @return true if this creature is active.
	 */
	public boolean isActive() {
		return active;
	}

	/**
	 * Checks if this creature has the turn.
	 * 
	 * @return true if this creature has the turn.
	 */
	public boolean hasTurn() {
		return inTurn;
	}

	/**
	 * Increment the speed. This means increase the progress bar for this 
	 * creature. This is used in battle, when the battle is in idling mode, 
	 * i.e. when the creatures is waiting to make a move.
	 */
	public void incrementSpeed() {
		progress += updateTime * Math.max(
				speedBoost.getCurrentBoost(), .1f);
	}

	/**
	 * Checks if this creature is ready to fight.
	 * 
	 * @return true if the creature is ready.
	 */
	public boolean isReady() {
		return progress >= 100;
	}
	
	/**
	 * Checks if the all the creatures in the given list is dead.
	 * 
	 * @param list the list containing the creatures to check.
	 * @return true if all the creatures is dead.
	 */
	public static boolean isTeamDead(ArrayList<Creature> list) {
		boolean foundAliveChar = false;
		for (int i = 0; i < list.size() && !foundAliveChar; i++) {
			foundAliveChar = list.get(i).isAlive();
		}
		return !foundAliveChar;
	}
	
	/**
	 * Checks if one of the creatures in the given list is dead.
	 * 
	 * @param list the list containing the creatures to check.
	 * @return true if all the creatures is dead.
	 */
	public static boolean isOneInTeamDead(ArrayList<Creature> list) {
		boolean foundDeadChar = false;
		for (int i = 0; i < list.size() && !foundDeadChar; i++) {
			foundDeadChar = !list.get(i).isAlive();
		}
		return foundDeadChar;
	}

	/**
	 * Damages this creature with the given amount.
	 * If the life goes below zero the creature is killed (alive = false).
	 * This means that, if the creature is a character, the only way 
	 * to heal it is to first cast life (cureFromDead()) and then cure 
	 * the health points. 
	 * 
	 * @param damage the amount of damage to inflict.
	 * @return the amount actually damaged. If the given damage is more than
	 * the life of the target, the amount damaged is the life of the target.
	 */
	public int damage(int damage) {
		int ret = damage > getHP() ? getHP() : damage;
		attributes[HP] -= damage;
		if (attributes[HP] <= 0) {
			kill();
		}
		return ret;
	}

	private int getHP() {
		return Math.round(attributes[HP]);
	}

	/**
	 * Gets the attribute with the given number.
	 * 
	 * @param attribute the number of the attribute to get. This could be 
	 * any of the attributes in the Creature class. Make sure not to call this
	 * method with character specific attribute numbers when this creature is
	 * an enemy.
	 * @return the value of the attribute with the given number. 
	 */
	public int getAttribute(int attribute) {
		return Math.round(attributes[attribute]);
	}

	/**
	 * Gets the array of all the attributes for this creature.
	 * 
	 * @return the array of attributes.
	 */
	public float[] getAttribute() {
		return attributes;
	}

	/**
	 * Gets the life points (hp) formatted as a string.
	 * For example, if the creature has 50 hp and max 100 hp this string
	 * would be 50 / 100.
	 * 
	 * @return the life as a string, like so hp / maxHp.
	 */
	public String getLife() {
		return getAttribute(HP) + "/" + getAttribute(MAX_HP); 
	}

	/**
	 * Gets the progress of the creature. This is used
	 * when the progress bar is drawn in the BattleGUI class.
	 * When the progress is filled the creature is ready to fight.
	 * 
	 * @return the current progress of the character.
	 */
	public double getProgress() {
		return progress;
	}

	public float getLifePrecent() {
		return (float) attributes[HP] / (float) attributes[MAX_HP]; 
	}

	/**
	 * Gets the name of the creature.
	 * 
	 * @return the name of the creature.
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * This method resets some temporary values that only has effect
	 * until the current hand is played. This is called right after 
	 * the damage has been calculated.
	 */
	public void resetTempValues() {
		tempCrushed = false;
	}
	
	/**
	 * Gets the array of boosts. The returned array will contain the amount
	 * of percent to boost the attack, defense, magic attack and magic defense
	 * in that order.
	 * 
	 * @return the list containing the boosts.
	 */
	public int[] getBoosts() {
		int[] a = new int[5];
		a[0] = getBoostValue(attackBoost.getCurrentBoost());
		a[1] = getBoostValue(defenseBoost.getCurrentBoost());
		a[2] = getBoostValue(magicBoost.getCurrentBoost());
		a[3] = getBoostValue(magicDefenseBoost.getCurrentBoost());
		a[4] = getBoostValue(lifeBoost.getCurrentBoost());
		return a;
	}
	
	public ArrayList<Boost> getBoostList() {
		ArrayList<Boost> list = new ArrayList<Boost>();
		list.add(attackBoost);
		list.add(defenseBoost);
		list.add(magicBoost);
		list.add(magicDefenseBoost);
		list.add(lifeBoost);
		list.add(speedBoost);
		list.add(supportBoost);
		return list;
	}
	
	private int getBoostValue(float b) {
		return b==1 ? 0 : (b>1 ? 1 : -1);
	}
	
	public boolean hasOpenWound() {
		return lifeBoost.getCurrentBoost() < 1;
	}
	
	public int updateOpenWound() {
		int val = getLifeBoost();
		damage(val);
		lifeBoost.update();
		return val;
	}
	
	public int getLifeBoost() {
		return Math.round(
					lifeBoost.getCurrentBoost() * 
					attributes[Creature.MAX_HP]);
	}

	/**
	 * This method updates all the boost and wounds this
	 * creature has, if any.
	 */
	public void updateBoosts() {
		if (lifeBoost.getCurrentBoost() < 1) {
			if (this instanceof Character) {
				updateOpenWound();
			}
		} else if (lifeBoost.getCurrentBoost() > 1) {
			cure(getLifeBoost());
			lifeBoost.update();
		}
		speedBoost.update();
		attackBoost.update();
		magicBoost.update();
		defenseBoost.update();
		magicDefenseBoost.update();
	}
	
	/**
	 * Gets the mode of speed for this creature. This is either 
	 * BattleValues.HASTE, .SLOW or anything else for default.
	 * 
	 * @return the mode of speed for this creature.
	 */
	public int getSpeedMode() {
		int mode = -1;
		float boost = speedBoost.getCurrentBoost();
		if (boost < 1) {
			mode = BattleValues.SLOW;
		} else if (boost > 1) {
			mode = BattleValues.HASTE;
		}
		return mode;
	}
	
	/**
	 * This method cures or damages this creatures, with the 
	 * given amount of hp. 
	 * 
	 * @param hp the amount to cure or damage.
	 * @param cure true if this creature should be healed and false
	 * if it should be damaged.
	 * @return the amount of hp cured or damaged.
	 */
	public int addHP(int hp, boolean cure) {
		if (cure) {
			return cure(hp);
		}
		return damage(hp);
	}
	
	/**
	 * This method resets all the possible boosts that this creature can have.
	 */
	public void resetBoost() {
		defenseBoost.reset();
		magicDefenseBoost.reset();
		attackBoost.reset();
		magicBoost.reset();
		lifeBoost.reset();
		speedBoost.reset();
	}

	/**
	 * This method boost defense for the given amount of turns with the
	 * given amount of percent. This boost is carried out on the total 
	 * defense, but it does not boost any deck defense mode bonuses.
	 * 
	 * @param turns the amount of turns that this boost should last.
	 * @param percent the amount of percent to boost the defense with.
	 */
	public void boostDefense(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts defense with " + (percent * 100) 
				+ "% for " + turns + " turns");
		defenseBoost.add(turns, percent);
	}

	/**
	 * This method boost attack for the given amount of turns with the
	 * given amount of percent. This boost is carried out on the total 
	 * attack.
	 * 
	 * @param turns the amount of turns that this boost should last.
	 * @param percent the amount of percent to boost the attack with.
	 */
	public void boostAttack(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts attack with " + (percent * 100) 
				+ "% for " + turns + " turns");
		attackBoost.add(turns, percent);
	}
	
	public void boostSupport(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts support with " + (percent * 100) 
				+ "% for " + turns + " turns");
		supportBoost.add(turns, percent);
	}

	/**
	 * This method boost magic defense for the given amount of turns with the
	 * given amount of percent. This boost is carried out on the total magic
	 * defense, but it does not boost any deck defense mode bonuses.
	 * 
	 * @param turns the amount of turns that this boost should last.
	 * @param percent the amount of percent to boost the magic defense with.
	 */
	public void boostMagicDefense(int turns,float percent) {
		logger.log(Level.FINE,
				name + " boosts magic defense with " + (percent * 100) 
				+ "% for " + turns + " turns");
		magicDefenseBoost.add(turns, percent);
	}

	/**
	 * This method boost magic attack for the given amount of turns with the
	 * given amount of percent. This boost is carried out on the total magic
	 * attack.
	 * 
	 * @param turns the amount of turns that this boost should last.
	 * @param percent the amount of percent to boost the magic attack with.
	 */
	public void boostMagicAttack(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts magic attack with " + (percent * 100) 
				+ "% for " + turns + " turns");
		magicBoost.add(turns, percent);
	}
	
	/**
	 * This method boost the speed for the given amount of turns with the
	 * given amount of percent.
	 * 
	 * @param turns the amount of turns that this boost should last.
	 * @param percent the amount of percent to boost the speed with.
	 */
	public void boostSpeed(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts speed with " + (percent * 100) 
				+ "% for " + turns + " turns");
		speedBoost.add(turns, percent);
	}
	
	public void boostLife(int turns, float percent) {
		logger.log(Level.FINE,
				name + " boosts life with " + (percent * 100) 
				+ "% for " + turns + " turns");
		lifeBoost.add(turns, percent);
	}
	
	/**
	 * This methods wounds this creature and sets it to bleed
	 * for three rounds. 10 % of the creatures max hp is decreased
	 * each turn.
	 */
	public void openWound() {
		logger.log(Level.FINE, name + " got an open wound");
		lifeBoost.add(AbstractCard.TURNS_TO_BOOST_MANY, -.9f);
	}
	
	/**
	 * Sets the amount to increment the progress with in each update of the
	 * idling mode in battle. The speed of the creature.
	 * 
	 * @param u the time to set.
	 */
	public void setTime(float u) {
		updateTime = u;
	}
	
	/**
	 * Gets the total defense for this creature with all the 
	 * current battle bonuses and boosts. The given type tells
	 * which defense to get. Slot.ATTACK or SLOT.MAGIC.
	 * 
	 * @param type the type of defense to get.
	 * @return the total battle defense.
	 */
	public abstract int getBattleDefense(int type);
	
	/**
	 * Gets the total attack of the creature.
	 * 
	 * @return the total attack of the creature.
	 */
	public abstract int getTotalAttack();
	
	/**
	 * Gets the total magic attack of the creature.
	 * 
	 * @return the total magic attack of the creature.
	 */
	public abstract int getTotalMagicAttack();

	/**
	 * Gets the total defense of the creature.
	 * 
	 * @return the total defense of the creature.
	 */
	public abstract int getTotalDefense();

	/**
	 * Gets the total magical defense of the creature.
	 * 
	 * @return the total magical defense of the creature.
	 */
	public abstract int getTotalMagicDefense();

	/**
	 * This method should temporarily remove the armor for this creature.
	 * 
	 * @return true if the armor was crushed.
	 */
	public abstract int crushArmor();

	/**
	 * Gets this creatures attack element.
	 * 
	 * @return the attack element of this creature.
	 */
	public abstract int getElement();
	
	/**
	 * This method changes the element of this creature, temporarily, to 
	 * the given element.
	 * 
	 * @param element the element to change to.
	 */
	public abstract void changeElement(int element);
	
	/**
	 * This method changes the element of this creature back to the
	 * original one.
	 */
	public abstract void changeElementBack();

	/**
	 * This class represents a boost for one of the characters
	 * attributes, such as attack, defense and so on.
	 * 
	 * @author 		Kalle Sjöström
	 * @version 	0.7.0 - 15 Sep 2008
	 */
	public class Boost {

		private static final int TURNS = 0;
		private static final int PERCENT = 1;
		private ArrayList<float[]> boost = new ArrayList<float[]>();
		private float currentBoost = 1;

		/**
		 * This method adds a new boost to the list of current boosts.
		 * It creates a boost from the given value and it will last
		 * the given amount of turns and boost the value with the given
		 * amount of percent.
		 * 
		 * @param turns the turns that the boost should last.
		 * @param percent the amount of percent to boost the attribute with.
		 */
		private void add(int turns, float percent) {
			boolean found = false;
			for (int i = 0; i < boost.size() && !found; i++) {
				float[] b = boost.get(i);
				
				if ((percent < 0 && b[PERCENT] > 0) || 
						(percent > 0 && b[PERCENT] < 0)) {
					// Trying to add negative boosts to a list of positive ones, or vice versa.
					// Then the current list should be cleared and the new boost added.
					boost.clear();
				} else {
					// Trying to add same kind of boosts as already present.
					// Then the most effective one should be used first.
					if ((percent < 0 && percent < b[PERCENT]) || 
							(percent > 0 && percent > b[PERCENT])) {
						found = true;
						boost.add(i, new float[]{turns, percent});
					}
				}
			}
			if (!found) {
				boost.add(new float[]{turns, percent});
			}
			currentBoost = 1 + boost.get(0)[PERCENT];
		}

		/**
		 * This method clears all boosts in this list.
		 */
		public void reset() {
			boost.clear();
			currentBoost = 1;
		}

		/**
		 * This method updates the boost in this list.
		 */
		private void update() {
			if (boost.size() > 0) {
				logger.log(Level.FINE, "Boost size " + boost.size());
				for (int i = 0; i < boost.size(); i++) {
					logger.log(Level.FINE, "Turns " + boost.get(i)[TURNS]);
					if (boost.get(i)[TURNS] > 0) {
						boost.get(i)[TURNS]--;
					} else {
						boost.remove(i);
						i--;
					}
				}
				currentBoost = boost.size() > 0 ? 1 + boost.get(0)[PERCENT] : 1;
				logger.log(Level.FINE, "Current boost for " + getName() + " " + currentBoost);
			}
		}

		/**
		 * Gets the current boost percent. This should be a total of
		 * all the boosts in the list. 2 boost � 10 % would result in
		 * this method returning 1.2f.
		 * 
		 * @return the sum of all the boosts in this list.
		 */
		public float getCurrentBoost() {
			return currentBoost;
		}

		public void dispelNegativeEffectWithChance(float chance) {
			if (Values.rand.nextFloat() <= chance) {
				if (boost.size() > 0) {
					Iterator<float[]> it = boost.iterator();
					while (it.hasNext()) {
						float[] b = it.next();
						if (b[PERCENT] < 0) {
							it.remove();
						}
					}
					currentBoost = boost.size() > 0 ? 1 + boost.get(0)[PERCENT] : 1;
				}
			}
		}
	}
}