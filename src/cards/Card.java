/*
 * Classname: Card.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards;

import info.Values;

import java.util.StringTokenizer;

import java.util.logging.*;

import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import settings.Settings;
import sound.SoundPlayer;
import battle.Battle;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.offense.ChameleonStrike;
import character.Character;
import character.Creature;
import character.Enemy;

/**
 * This class extends the abstract card with the additional functions of
 * sorting and damage calculating when attacking.
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 11 Nov 2008
 */
public abstract class Card extends AbstractCard {
	
	public static final int IMMUNE = 0;
	public static final int HIT = 1;
	public static final int MISS = 2;
	
	private static Logger logger = Logger.getLogger("Card");
	
	private static final int PREFERENCE = 0;
	private static final int DEFENSE_BOOST = 1;
	private int storeStatus;
	private String sortingValue;
	private String databaseName;
	
	/**
	 * This method creates the value that this card should have.
	 * This value is then used when sorting the cards. The value of the
	 * card is calculated by the appending the following numbers:
	 * type, name (hash code), level, number, all (1 if true). 
	 */
	protected void createSortingValue() {
		int i = all ? 0 : 1;
		StringBuffer sb = new StringBuffer();
		sb.append(getType());
		sortingValue = getType() + getName() + level + i;
	}
	
	/**
	 * Implements the compareTo() method.
	 * 
	 * @param c the Card object to compare this to.
	 * @return -1 if this card is less than the given card, 0 if equal 
	 * and 1 if greater.
	 */
	public int compareTo(Card c) {
		return new String(sortingValue).compareTo(c.sortingValue);
	}
	
	public String getSortingValue() {
		return sortingValue;
	}
	
	/**
	 * This method creates a card from the given tokenizer.
	 * 
	 * @param tokenizer the tokenizer containing the information about 
	 * the card.
	 * @return the newly created card.
	 */
	public static Card createCard(StringTokenizer tokenizer) {
		String name = tokenizer.nextToken();
		return createCard(name, tokenizer);
	}
	
	public static Card createCard(String name, int level, boolean all) {
		return createCard(name, level, all, getType(name), 0);
	}
	
	/**
	 * This method creates a card from the given tokenizer and name.
	 * 
	 * @param name the name of the card.
	 * @param tokenizer the tokenizer containing the information about 
	 * the card.
	 * @return the newly created card.
	 */
	public static Card createCard(String name, StringTokenizer tokenizer) {
		int level = Integer.parseInt(tokenizer.nextToken());
		boolean all = false;
		int price = 0;
		if (tokenizer.hasMoreTokens()) {
			String val = tokenizer.nextToken();
			if (val.equals("true") || val.equals("false")) {
				all = Boolean.parseBoolean(val);
				if (tokenizer.hasMoreTokens()) {
					price = Integer.parseInt(tokenizer.nextToken());
				}
			} else {
				price = Integer.parseInt(val);
			} 
		}
		return createCard(name, level, all, getType(name), price);
	}
	
	public static int getType(String name) {
		int type = 0;
		if (name.contains("offense")) {
			type = AbstractCard.OFFENSE;
		} else if (name.contains("magic")) {
			type = AbstractCard.MAGIC;
		} else if (name.contains("support")) {
			type = AbstractCard.SUPPORT;
		} else if (name.contains("neutral")) {
			type = AbstractCard.NEUTRAL;
		}
		return type;
	}

	/**
	 * Creates a new card with the given information.
	 * 
	 * @see battle.Combo
	 * @param name the name of class to instantiate. For example:
	 * cards.offense.BattleCard.
	 * @param level the level of the card. One, two or three.s
	 * @param all true if the card should hit on all the enemies.
	 * @param type 
	 * @return the newly created card.
	 */
	@SuppressWarnings("unchecked")
	public static Card createCard(
			String name, int level, boolean all, int type, int price) {
		Card card = null;
		try {
			Class c = Class.forName(name);
			card = (Card) c.newInstance();
			card.init(level, all, type, price);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
		return card;
	}
	
	/**
	 * This method copies this card and returns the copy.
	 * 
	 * @return the copy of this card.
	 */
	public Card copyCard() {
		return createCard(
				getClass().getName(), level, all, type, getPrice());
	}

	/**
	 * This method only maps the short prefixes o, s and m into cards.offense,
	 * cards.support and cards.magic respectively. 
	 * 
	 * @param prefix the prefix o, s or m.
	 * @return the mapped name of the given prefix.
	 */
	public static String getPrefix(String prefix) {
		String ret = "";
		if (prefix.equals("o")) {
			ret = "cards.offense.";
		} else if (prefix.equals("s")) {
			ret = "cards.support.";
		} else if (prefix.equals("m")) {
			ret = "cards.magic.";
		} else if (prefix.equals("n")) {
			ret = "cards.neutral.";
		}
		return ret;
	}
	
	protected HitElement attack(Creature target, Character attacker) {
		return attack(target, attacker, false);
	}

	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param sureHit 
	 * @param b 
	 * @param b 
	 * @param string 
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement attack(
			Creature target, Character attacker, boolean ignoreCheck) {
		return attack(target, attacker, CRITICAL_PRECENT, ignoreCheck);
	}
	
	protected HitElement attack(
			Creature target, Character attacker, float critPrecent) {
		return attack(target, attacker, critPrecent, false);
	}

	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target. This method will use the given critPrecent as the chance to
	 * hit a critical blow.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param critPrecent the chance, in percent, to hit a critical blow.
	 * @param sureHit 
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement attack(
			Creature target, Character attacker, float critPrecent, 
			boolean ignoreCheck) {
		return attack(target, attacker, critPrecent, "", ignoreCheck);
	}

	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param effect a message to display to the player.
	 * @param sureHit 
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement attack(
			Creature target, Character attacker, String effect, 
			boolean ignoreCheck) {
		return attack(target, attacker, CRITICAL_PRECENT, effect, ignoreCheck);
	}

	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target. This method will use the given critPrecent as the chance to
	 * hit a critical blow.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param critPrecent the chance, in percent, to hit a critical blow.
	 * @param effect a message to display to the player.
	 * @param sureHit 
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement attack(
			Creature target, Character attacker, float critPrecent, 
			String effect, boolean ignoreCheck) {
		return attack(
				target, attacker, critPrecent, effect, 
				getType(), getType(), 0, ignoreCheck);
	}
	
	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target. This method will use the given critPrecent as the chance to
	 * hit a critical blow.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param critPrecent the chance, in percent, to hit a critical blow.
	 * @param effect a message to display to the player.
	 * @param type the of card to attack with
	 * @param extraAttack the extra attack to be added to the normal attack.
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement attack(
			Creature target, Character attacker, float critPrecent, 
			String effect, int attackType, int defenseType, 
			int extraAttack, boolean ignoreCheck) {
		HitElement he = null;
		if (!ignoreCheck) {
			he = checkPreferences(target, attacker, this, null);
		}
		if (he == null) {
			he = actuallAttack(
					target, attacker, critPrecent, effect, 
					attackType, defenseType, extraAttack);
		}
		return he;
	}
	
	public static HitElement checkPreferences(
			Creature target, Character attacker, Card attackingCard, String text) {
		return checkPreferences(target, attacker, attackingCard, text, false);
	}
		
	public static HitElement checkPreferences(
			Creature target, Character attacker, Card attackingCard, 
			String text, boolean sureHit) {
		HitElement he = null;
		Class<? extends Card> c = attackingCard.getClass();
		int ret = checkPreferences2(
				target, attacker, text, sureHit, 
				c.getName(), c.getSimpleName());
		switch (ret) {
		case IMMUNE:
			he = new HitElement(attackingCard, -1, HitElement.IMMUNE, "");
			break;
		case HIT:
			if (text != null) {
				he = new HitElement(attackingCard, -1, HitElement.NORMAL, text);
			}
			break;
		case MISS:
			he = new HitElement(attackingCard, -1, HitElement.MISS, "");
			break;
		}
		return he;
	}
	
	public static int checkPreferences2(
			Creature target, Character attacker,
			String text, boolean sureHit, String fullName, String simpleName) {
		float[] ret = getPreferences(target, attacker, text, sureHit, fullName, simpleName);
		float preference = ret[PREFERENCE];
		float defenseBoost = ret[DEFENSE_BOOST];
		int retVal;
		
		if (preference == 0) {
			retVal = IMMUNE;
		} else {
			if (sureHit || !Battle.calcMiss(target, attacker, defenseBoost)) {
				retVal = HIT;
			} else {
				retVal = MISS;
			}
		}
		return retVal;
	}
	
	public static int checkPreferences3(
			Creature target, Character attacker,
			String text, boolean sureHit, Card ac, String fullName, String simpleName) {
		float[] ret = getPreferences(target, attacker, text, sureHit, fullName, simpleName);
		float preference = ret[PREFERENCE];
		float defenseBoost = ret[DEFENSE_BOOST];
		int retVal;
		
		if (preference == 0) {
			retVal = IMMUNE;
		} else {
			if (sureHit || (Values.rand.nextFloat() <= (ac.getEffectChanceToHit() - defenseBoost))) {
				retVal = HIT;
			} else {
				retVal = MISS;
			}
		}
		return retVal;
	}
	
	public static float[] getPreferences(
			Creature target, Character attacker,
			String text, boolean sureHit, String fullName, String simpleName) {
		float defenseBoost = 0;
		float preference = -1;
		if (target instanceof Enemy) {
			Enemy e = (Enemy) target;
			if (fullName.contains("magic")) {
				preference = e.getCardPreference("magic");
			} else if (fullName.contains("neutral")) {
				preference = e.getCardPreference("neutral");
			} else if (fullName.contains("offense")) {
				preference = e.getCardPreference("offense");
			} else if (fullName.contains("support")) {
				preference = e.getCardPreference("support");
			}
			logger.log(Level.FINE, "Preference after all " + preference);
			float p = e.getCardPreference(simpleName);
			logger.log(Level.FINE, "Preference after name " + p);
			if (preference == -1) {
				preference = p;
			} else if (p != -1){
				preference = Math.min(preference, p);
			}
			logger.log(Level.FINE, "Total " + preference);
//			check preferences!!
			if (preference > 0) {
				defenseBoost = preference / 100f;
			}
		}
		return new float[]{preference, defenseBoost};
	}

	/**
	 * This method will carry out an attack made by the attacker on the given 
	 * target. This method will use the given critPrecent as the chance to
	 * hit a critical blow.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @param critPrecent the chance, in percent, to hit a critical blow.
	 * @param effect a message to display to the player.
	 * @param type the of card to attack with
	 * @param extraAttack the extra attack to be added to the normal attack.
	 * @return the HitElement containing the information about the attack.
	 */
	protected HitElement actuallAttack(
			Creature target, Character attacker, float critPrecent, 
			String effect, int attackType, int defenseType, int extraAttack) {
		
		////
		logger.log(Level.FINE, "------ New Attack ------");
		logger.log(Level.FINE, "Attacker: " + attacker.getName() + " - hp: " + attacker.getLife());
		logger.log(Level.FINE, "Target: " + target.getName() + " - hp: " + target.getLife());
		logger.log(Level.FINE, "Card used: " + getName());
		logger.log(Level.FINE, "Type: " + (attackType == 0 ? " Offensive card" : " Magic card"));
		logger.log(Level.FINE, "Effect: " + effect);
		
		int baseAttack = attacker.getBattleAttack(attackType) + extraAttack;
		int defense = target.getBattleDefense(defenseType);

		logger.log(Level.FINE, "Target's defense: " + defense);
		logger.log(Level.FINE, "Attacker's base attack: " + baseAttack);
		
		int elem = target.getElement();
		
		int heroElem = getElement() == NO_ELEMENT ? 
				attacker.getElement() : getElement();
		float percent = getAttackPercent();
		logger.log(Level.FINE, "Card percent " + percent);
		
		double attack = Math.round(baseAttack * percent);
		logger.log(Level.FINE, "Attack: " + attack);
		int hitType = HitElement.NORMAL;
		int damage = (int) Math.max(attack - defense, 0);
		logger.log(Level.FINE, "Damage before element check: " + damage);
		logger.log(Level.FINE, "Attacking element: " + heroElem);
		logger.log(Level.FINE, "Defensive element: " + elem);
		if (elem != Card.NO_ELEMENT && this instanceof ChameleonStrike) {
			damage *= ELEMENT_INCREASE;
		} else {
			damage = Math.round(addElementContribution(heroElem, elem, damage));
		}

		logger.log(Level.FINE, "Damage: " + damage);
//		if (!sureHit) {
//			if (Battle.calcMiss(target, attacker)) {
//				hitType = HitElement.MISS;
//				damage = 0;
//				logger.log(Level.FINE, "Miss!");
//			}
//		}
		if (damage > 0) {
			if (Values.rand.nextFloat() < critPrecent) {
				hitType = HitElement.CRIT;
				damage *= CRITICAL_INCREASE;
				logger.log(Level.FINE, "Crit!");
			}
		} else {
			damage = 0;
		}
		logger.log(Level.FINE, "Final damage: " + damage);
		logger.log(Level.FINE, "-----------------------");
		return new HitElement(this, damage, hitType, effect);
	}
	
	public static int addElementContribution(
			int attackerElement, int defenderElement, float damage) {
		if (defenderElement != NO_ELEMENT && attackerElement != NO_ELEMENT) {
			if (defenderElement == attackerElement) {
				damage /= 2;
			} else {
				switch (defenderElement % 2) {
				case 0 : 
					if (defenderElement - attackerElement == 1) {
						logger.log(Level.FINE, "Elemental damage!");
						damage *= ELEMENT_INCREASE;
					} 
					break;
				case 1 : 
					if (defenderElement - attackerElement == -1) {
						logger.log(Level.FINE, "Elemental damage!");
						damage *= ELEMENT_INCREASE;
					}
					break;
				}
			}
		}
		return Math.round(damage);
	}
	
	public void setDatabaseName(String dbName) {
		databaseName = dbName;
	}
	
	public void setStoreStatus(int storeStatus) {
		this.storeStatus = storeStatus;		
	}

	public String getDatabaseName() {
		return databaseName;
	}
	
	public int getStoreStatus() {
		return storeStatus;		
	}
	
	protected void setShortInfo(String si) {
//		shortInfo.add(si);
	}
	
	/**
	 * This method should be implemented with the specific rules of the
	 * card. This method will be called when it is used by the given attacker
	 * on the given target. It is up to the implementation of the subclass 
	 * to define what should happen.
	 *  
	 * @param target the target of the attack.
	 * @param attacker the attacker.
	 * @return the HitElement containing the information about the attack.
	 */
	public abstract HitElement use(Creature target, Character attacker);
	public abstract ParticleSystemPacket getAnimation(AnimationInfo info);

	public void playSound() {
		final int[] soundEffectDelay = getSoundEffectDelay();
		final String[] soundEffect = getSoundEffect();
		final int size = Math.min(soundEffect.length, getLevel());
		boolean found = false;
		for (int i = 0; i < size && !found; i++) {
			found = soundEffectDelay[0] > 0;
		}
		if (found) {
			new Thread() {
				public void run() {
					for (int i = 0; i < size; i++) {
						Values.sleep(soundEffectDelay[i]);
						SoundPlayer.playSound(soundEffect[i]);
					}
				}
			}.start();
		} else {
			for (int i = 0; i < size; i++) {
				SoundPlayer.playSound(soundEffect[i]);
			}
		}
	}
	
	protected String[] getSoundEffect() {
		return new String[]{""};
	}

	protected int[] getSoundEffectDelay() {
		return new int[]{0};
	}
	
	protected static void setSourceTargetVectorToLength(float lenght, Settings settings) {
		Vector3f t = settings.getVector(AnimSettings.TARGET);
		Vector3f s = settings.getVector(AnimSettings.SOURCE);
		Vector3f temp = t.subtract(s);
		temp.normalizeLocal().multLocal(lenght);
		t = s.add(temp);
		settings.setVector(AnimSettings.TARGET, t);
	}
	
	protected static void setTargetSourceVectorToLength(float lenght, Settings settings) {
		Vector3f t = settings.getVector(AnimSettings.TARGET);
		Vector3f s = settings.getVector(AnimSettings.SOURCE);
		Vector3f temp = s.subtract(t);
		temp.normalizeLocal().multLocal(lenght);
		s = t.add(temp);
		settings.setVector(AnimSettings.SOURCE, s);
	}

	public boolean canBeMerged() {
		return true;
	}
}
