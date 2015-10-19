/*
 * Classname: Enemy.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/01/2008
 */
package character;

import info.Values;

import java.util.HashMap;
import java.util.Random;

import java.util.logging.*;

import battle.bosses.BossDialog;
import battle.bosses.BossScript;
import battle.enemy.EnemyInfo;
import equipment.Slot;
import equipment.Items.Item;

/**
 * This class represents an enemy in the game. A enemy is a creature 
 * which the player battles.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Jan 2008
 */
public class Enemy extends Creature {

	public static final int NORMAL_IMAGE = 0;
	public static final int PRE_ATTACK_IMAGE = 1;
	public static final int ATTACK_IMAGE = 2;

	private String[] images;
	private EnemyArmor armor;
	private HashMap<String, Integer> cardPreferences;
	private float dropRate = 0;
	private Item dropItem;
	
	private float attackPercent;
	private float magicPercent;
	private EnemyInfo info;
	private BossDialog bossDialog;
	private BossScript script;
	private String dbName;
	private HashMap<String, Integer> triggers;
	private HashMap<String, Integer> items;
	private Logger logger = Logger.getLogger("Enemy");
	private String diesound;
	private int startFrame;
	private String nextPlace;

	/**
	 * Creates an enemy with the given values.
	 * 
	 * @param att the attribute array of the enemy.
	 * @param imageArray the array of images to use when displaying the enemy.
	 */
	public Enemy(String name, float[] att, String[] imageArray) {
		super(name, att);
		images = imageArray;
		progress = new Random(Math.abs(this.hashCode())).nextInt(70);
	}
	
	public String getDbName() {
		return dbName;
	}
	
	public void setDbName(String dbName) {
		this.dbName = dbName;
	}
	
	public void setDropData(Item item, float rate) {
		dropItem = item;
		dropRate = rate;
	}

	/**
	 * Copies this enemy. It just calls the constructor with the attributes as 
	 * parameters.
	 * 
	 * @return a copy of this enemy.
	 */
	public Enemy copy() {
		float[] attCopy = Values.copyArray(getAttribute());
		Enemy enemy = new Enemy(name, attCopy, images);
		enemy.setDbName(dbName);
		if (armor != null) {
			enemy.setArmor(armor.defense, armor.magicDefense);
		}
		enemy.setPreferences((int) (attackPercent * 100), (int) (magicPercent * 100));
		enemy.setCardPreferences(cardPreferences);
		enemy.setInfo(info);
		enemy.setDropData(dropItem, dropRate);
		enemy.setDieSound(diesound);
		enemy.setNextPlace(nextPlace);
		enemy.setStartFrame(startFrame);
		return enemy;
	}

	/**
	 * Loads the images for the enemy. The enemy has three images which is 
	 * combined to make a small animation when it attacks. This method loads
	 * the three images from the name, so the images must be named like so:
	 * name1.png, name2.png and name3.png.
	 * 
	 * Reuse indices are pairs of indices used when images should be reused. 
	 * The first index (in a pair) is the destination index in the image array
	 * and the second is the source. The source is then soft copied to the 
	 * destination.
	 * 
	 * @param name the name of the image to load.
	 * @param length the number of images to load.
	 * @param reuseindices an array containing the indices of the textures to reuse.
	 * @return the array containing the names of the images for this enemy. 
	 */
	public static String[] loadImages(String name, int length, int[] reuseindices) {
		String[] images = new String[length];
		for (int i = 0; i < images.length; i++) {
			images[i] = Values.EnemyImages + name + "/" + name + (i + 1) + ".png";
		}
		for (int i = 0; i < reuseindices.length; i += 2) {
			images[reuseindices[i]] = images[reuseindices[i + 1]];
		}
		return images;
	}

	/**
	 * Sets the card preference 
	 * 
	 * @param cardPre the card preference to set. 
	 */
	public void setCardPreferences(HashMap<String, Integer> cardPre) {
		cardPreferences = cardPre;
	}
	
	public void addCardPreferences(String name, int val) {
		if (cardPreferences == null) {		
			cardPreferences = new HashMap<String, Integer>();
		}
		cardPreferences.put(name, val);
		logger.log(Level.FINE, "Adding card to card pref " + cardPreferences);
	}

	/**
	 * Gets the image of this enemy with the specified number. This method
	 * should be called with the number Enemy.NORMAL_IMAGE, 
	 * .PRE_ATTACK_IMAGE or .ATTACK_IMAGE depending on which image is wanted.
	 * 
	 * @param number the number of the image to get.
	 * @return the image with the specified number.
	 */
	public String getImage(int number) {
		return images[number];
	}

	/**
	 * Gets the total defense of the creature.
	 * 
	 * @return the total defense of the creature.
	 */
	public int getTotalDefense() {
		int def = 0;
		if (armor != null && !tempCrushed) {
			def += armor.defense;
		}
		return getAttribute(DEFENSE) + def;
	}

	/**
	 * Gets the total magical defense of the creature.
	 * 
	 * @return the total magical defense of the creature.
	 */
	public int getTotalMagicDefense() {
		int def = 0;
		if (armor != null && !tempCrushed) {
			def += armor.magicDefense;
		}
		return getAttribute(MAGIC_DEFENSE) + def;
	}
	
	/**
	 * This method gets the total attack for this enemy. The given type
	 * represents which type of offense to return. The possible values for type
	 * is Slot.ATTACK and Slot.MAGIC. This method should only be used from the
	 * battle, because any boosts are added in this method.
	 * 
	 * @param type the kind of attack to return.
	 * @return the total offense value for the given type of attack.
	 */
	public int getBattleAttack(int type) {
		int att = 0;
		if (type == Slot.ATTACK) {
			logger.log(Level.FINE, "Attack boost " + attackBoost.getCurrentBoost());
			logger.log(Level.FINE, "Total attack " + getTotalAttack());
			att = Math.round(
					attackBoost.getCurrentBoost() * getTotalAttack());
		} else if (type == Slot.MAGIC) {
			att = Math.round(
					magicBoost.getCurrentBoost() * getTotalMagicAttack());
		} else if (type == Slot.SUPPORT) {
			att = getAttribute(SUPPORT_ATTACK);
		}
		return att;
	}
	
	/**
	 * This method gets the total defense for this enemy. The given type 
	 * represents which type of defense to return. The possible values
	 * for type is Slot.ATTACK or Slot.MAGIC. This method should
	 * only be used from the battle, because any boosts are added 
	 * in this method.
	 * 
	 * @param type the kind of defense to return.
	 * @return the total defense value for the given type.
	 */
	public int getBattleDefense(int type) {
		int def = 0;
		if (type == Slot.ATTACK) {
			def = Math.round(
					defenseBoost.getCurrentBoost() * 
					getTotalDefense());
		} else if (type == Slot.MAGIC) {
			def = Math.round(
					magicDefenseBoost.getCurrentBoost() * 
					getTotalMagicDefense());
		}
		return def;
	}
	
	/**
	 * Gets the total attack of the enemy.
	 * 
	 * @return the total attack of this enemy.
	 */
	public int getTotalAttack() {
		return getAttribute(ATTACK);
	}
	
	/**
	 * Gets the total magic attack of the enemy.
	 * 
	 * @return the total magic attack of this enemy.
	 */
	public int getTotalMagicAttack() {
		return getAttribute(MAGIC_ATTACK);
	}

	/**
	 * Gets the type of attack that this enemy would like to use.
	 * The returned value is either Slot.MAGIC, or Slot.ATTACK.
	 * 
	 * @return the type of attack that the enemy would like to attack with.
	 */
	public int getAttackType() {
		int type;
		double rand = Math.random();
		if (rand <= attackPercent) {
			type = Slot.ATTACK;
		} else if (rand <= magicPercent) {
			type = Slot.MAGIC;
		} else {
			type = Slot.SUPPORT;
		}
		return type;
	}
	
	public int getAttackTypeExcluedSupport() {
		int type = Slot.SUPPORT;
		while (type == Slot.SUPPORT) {
			type = getAttackType();
		}
		return type;
	}

	/**
	 * Gets the amount of experience to give to the player when this enemy
	 * is defeated.
	 * 
	 * @return the the amount of experience to give the player.
	 */
	public int getSpoilExp() {
		return getAttribute(EXPERIENCE_SPOILS);
	}

	/**
	 * Gets the amount of gold to give to the player when this enemy
	 * is defeated.
	 * 
	 * @return the the amount of gold to give the player.
	 */
	public int getSpoilGold() {
		return getAttribute(GOLD_SPOILS);
	}
	
	public Item getSpoilItem() {
		return dropItem;
	}
	
	public double getDropRate() {
		return dropRate;
	}

	/**
	 * Gets the list of all the images in this enemies animation.
	 * 
	 * @return the list of images for this enemy.
	 */
	public String[] getImages() {
		return images;
	}
	
	/**
	 * Gets the percentage of vulnerability for the card with the given name.
	 * If this percentage is 0, the enemy is immune against the card. If the
	 * percentage is 100, the enemy is fully susceptible to the card.
	 * 
	 * @param name the name of the card.
	 * @return the percentage of susceptibility.
	 */
	public int getCardPreference(String name) {
		logger.log(Level.FINE, "Getting card pref for " + name);
		int retVal = -1;
		if (cardPreferences != null) {
			Integer percent = cardPreferences.get(name);
			logger.log(Level.FINE, "Card pref " + cardPreferences);
			if (percent != null) {
				retVal = percent;
			}
		}
		return retVal;
	}
	
	/**
	 * Gets the next image in this enemies animation.
	 * 
	 * @param imageIndex the index of the current image.
	 * @return the index of the next image.
	 */
	public int nextImage(int imageIndex) {
		imageIndex++;
		if (imageIndex >= images.length) {
			imageIndex = 0;
		}
		return imageIndex;
	}

	public void setDieSound(String diesound) {
		this.diesound = diesound;
	}
	
	public String getDieSound() {
		return diesound;
	}

	/**
	 * Creates an armor with the given values and equips it.
	 * 
	 * @param armorDefense the amount of physical defense that 
	 * the armor should have.
	 * @param armorMagicDefense the amount of magic defense that 
	 * the armor should have.
	 */
	public void setArmor(int armorDefense, int armorMagicDefense) {
		armor = new EnemyArmor(armorDefense, armorMagicDefense);
	}

	/**
	 * This method temporarily removes the armor for this enemy.
	 * 
	 * @return true if the armor did exist and now is crushed.
	 */
	public int crushArmor() {
		int res = -1;
		if (armor == null) {
			res = Creature.HAS_NO_ARMOR;
		} else if (tempCrushed) {
			res = Creature.ARMOR_ALREADY_CRUSHED;
		} else {
			res = Creature.ARMOR_CRUSHED;
			tempCrushed = true;
		}
		return res;
	}

	/**
	 * Changes the element of this enemy to the given value.
	 * The elements to choose from is found in the class CardValues.
	 * 
	 * @param element the element to change to.
	 */
	public void changeElement(int element) {
		setAttribute(ELEMENT, element);
	}
	
	/**
	 * This method does nothing. It just implements the abstract method
	 * in Creature. The reason why this method does not do anything is
	 * that when the battle is over, the enemy is either dead or the
	 * game is over so the original element does not need to be changed
	 * back to.
	 */
	public void changeElementBack() {
		// Does nothing, it is created for the Character
	}
	
	/**
	 * This method gets the element of this enemy.
	 * 
	 * @return the element of this enemy.
	 */
	public int getElement() {
		return getAttribute(ELEMENT);
	}
	
	public void setStartFrame(int startFrame) {
		this.startFrame = startFrame;
	}
	
	public int getStartFrame() {
		return startFrame;
	}

	/**
	 * Converts the given percent to a floating point value ranging
	 * from 0 to 1 representing 0 % and 100 %.
	 * 
	 * @param attPre the percent to convert.
	 */
	public void setPreferences(int attPer, int magPer) {
		attackPercent = attPer / 100f;
		magicPercent = magPer / 100f;
	}
	
	public void setInfo(EnemyInfo info) {
		this.info = info;	
	}

	public EnemyInfo getInfo() {
		return info;	
	}
		
	public void setDialog(BossDialog bd) {
		bossDialog = bd;	
	}
	
	public BossDialog getDialog() {
		return bossDialog;
	}
	
	public void setScript(BossScript script) {
		this.script = script;
	}
	
	public BossScript getScript() {
		return script;
	}
	
	public void setTriggers(HashMap<String, Integer> triggers) {
		this.triggers = triggers;
	}

	public void setItems(HashMap<String, Integer> items) {
		this.items = items;
	}
	
	public HashMap<String, Integer> getTriggers() {
		return triggers;
	}
	
	public HashMap<String, Integer> getItems() {
		return items;
	}
	
	public void setNextPlace(String nextPlace) {
		this.nextPlace = nextPlace;
	}
	
	public String getNextPlace() {
		return nextPlace;
	}
	
	/**
	 * This class represents an enemy armor. It only has two
	 * values which is normal defense and magical defense.
	 * 
	 * @author 		Kalle Sjöström
	 * @version 	0.7.0 - 25 Jan 2008
	 */
	private class EnemyArmor {

		private int defense;
		private int magicDefense;

		/**
		 * Creates a new armor and sets the normal defense and the 
		 * magic defense.
		 * 
		 * @param armorDefense the normal defense to set.
		 * @param armorMagicDefense the magic defense to set.
		 */
		public EnemyArmor(int armorDefense, int armorMagicDefense) {
			defense = armorDefense;
			magicDefense = armorMagicDefense;
		}
	}
}