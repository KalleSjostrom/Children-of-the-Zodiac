/*
 * Classname: EnemyLogic.java
 * 
 * Version information: 0.7.0
 *
 * Date: 26/12/2008
 */
package battle.enemy;

import info.BattleValues;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.Random;

import java.util.logging.*;

import sound.SoundPlayer;
import battle.AttackText;
import battle.Battle;
import battle.character.CharacterRow;
import cards.AbstractCard;
import cards.Card;
import cards.magic.Death;
import cards.neutral.Elements;
import character.Character;
import character.Creature;
import character.Enemy;
import character.Creature.Boost;
import equipment.Slot;

/**
 * This class implements the logic of the enemy. This is the class to change
 * if one would like to implement some AI. This version, however, does not
 * implement any artificial intelligence.
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 26 Dec 2008
 */
public class EnemyLogic {

	private static int target;
	private static boolean criticalHit = false;
	private static AttackInfo lastAttack;
	private static Battle battle;
	
	private static Logger logger = Logger.getLogger("EnemyLogic");

	/**
	 * Calculates the enemy target. Which of the party members to hit on.
	 * This method can not choose a dead character but it assumes that there
	 * are at least one alive party member.
	 * 
	 * @param characters the list of characters to chose the target from.
	 * @return the chosen target of the enemy.
	 */
	public static int calcTarget(ArrayList<Creature> characters) {
		logger.log(Level.FINE, "Calc target ");
		if (lastAttack.getType() == Slot.SUPPORT) {
			target = CharacterRow.NO_TARGET;
		} else if (lastAttack.isAll()) {
			target = CharacterRow.ON_ALL;
		} else {
			ArrayList<Integer> alive = new ArrayList<Integer>();
			for (int i = 0; i < characters.size(); i++) {
				if (characters.get(i).isAlive()) {
					alive.add(i);
				}
			}
			Random rand = new Random();
			target = alive.get(rand.nextInt(alive.size()));
		}
		logger.log(Level.FINE, "Resulting target " + target);
		return target;
	}

	/**
	 * Calculates the damage made by an enemy on a random target.
	 * It also adds the result to the list of attackTexts. 
	 * 
	 * @param enemy the enemy who should attack.
	 * @param characters the list of creatures that the enemy should attack.
	 * It should use the pre-calculated target as index in this list.
	 * @param characters2 
	 * @param attackText the list of animation text that can be filled with
	 * the events of this attack. Like "Miss!" or "56".
	 * @param battle 
	 * @return the index in the given list characters of the target.
	 */
	public static int calcEnemyDamage(Enemy enemy, 
			ArrayList<Creature> enemies, ArrayList<Creature> characters, 
			AttackText attackText, Battle battle) {
		EnemyLogic.battle = battle;
		logger.log(Level.FINE, "Last target " + lastAttack.getTarget());
		if (lastAttack.getTarget() == CharacterRow.NO_TARGET) {
			return CharacterRow.NO_TARGET;
		}
		int type = lastAttack.getType();
		ArrayList<EnemyAttackEffect> effects = lastAttack.getEffects();
		if (type == Slot.SUPPORT) {
			if (lastAttack.isAll()) {
				for (int i = 0; i < enemies.size(); i++) {
					calcSupport((Enemy) enemies.get(i), attackText, i, effects);
				}
			} else {
				calcSupport(enemy, attackText, target, effects);
			}
		} else {
			if (lastAttack.isAll()) {
				for (int i = 0; i < characters.size(); i++) {
					if (characters.get(i).isAlive()) {
						attackTarget(enemy, characters, attackText, i, effects);
					}
				}
			} else {
				attackTarget(enemy, characters, attackText, target, effects);
			}
			enemy.updateBoosts();
			return target;
		}

		return -1;
	}
	
	private static void calcSupport(
			Enemy enemy, AttackText attackText, int index, ArrayList<EnemyAttackEffect> effects) {
		int type = lastAttack.getType();
		float power = lastAttack.getPower();

		logger.log(Level.FINE, "------ Enemy Support -------");
		logger.log(Level.FINE, "Attack " + lastAttack);
		int damage = doit(enemy, null, attackText, effects, null, power);
		if (damage == -1) return;
		
		int amountToHeal = Math.round(enemy.getBattleAttack(type) * power);

		logger.log(Level.FINE, "Enemy name: " + enemy.getName());
		logger.log(Level.FINE, "Attack name: " + lastAttack.getName());
		logger.log(Level.FINE, "Enemy support: " + amountToHeal);

		float x;
		float y;
		if (index == target) {
			x = 0;
			y = -.6f;
		} else {
			float[] pos = BattleValues.getEnemyPosForText(index);
			x = pos[0];
			y = pos[1];// + pos[2] * index;
		}
		attackText.addCenter(String.valueOf(amountToHeal), x, y, true, AttackText.textSize.LARGE);
		enemy.addHP(amountToHeal, true);
		enemy.updateBoosts();
	}

	private static void attackTarget(
			Enemy enemy, ArrayList<Creature> characters, 
			AttackText attackText, int target, ArrayList<EnemyAttackEffect> effects) {
		int type = lastAttack.getType();
		float power = lastAttack.getPower();
		float[] pos = BattleValues.getCharPosForText(target);

		logger.log(Level.FINE, "------ Enemy attack -------");
		logger.log(Level.FINE, "Attack " + lastAttack);
		Character targetChar = null;
		if (target >= 0) {
			targetChar = (Character) characters.get(target);
		}
		int damage = doit(enemy, targetChar, attackText, effects, pos, power);
		if (damage == -1 || targetChar == null) return;

		int attack = Math.round(enemy.getBattleAttack(type) * power);
		int defense = targetChar.getBattleDefense(type);
		damage = Math.max(attack - defense, 0);

		logger.log(Level.FINE, "Type " + type);
		logger.log(Level.FINE, "Power " + power);
		logger.log(Level.FINE, "Enemy battle attack " + enemy.getBattleAttack(type));
		logger.log(Level.FINE, "Enemy name: " + enemy.getName());
		logger.log(Level.FINE, "Target name: " + targetChar.getName());
		logger.log(Level.FINE, "Enemy attack: " + attack);
		logger.log(Level.FINE, "Attack type: " + type);
		logger.log(Level.FINE, "Target defense: " + defense);
		logger.log(Level.FINE, "Damage before element check: " + damage);
		int attElem = lastAttack.getElement();
		if (attElem == Card.NO_ELEMENT) {
			attElem = enemy.getElement();
		}
		int defElem = targetChar.getElement();
		logger.log(Level.FINE, "Attacking element: " +  attElem);
		logger.log(Level.FINE, "Defensive element: " + defElem);
		damage = Card.addElementContribution(attElem, defElem, damage);

		logger.log(Level.FINE, "Damage: " + damage);

		//pos[0] += .3f;
//		if (enemy.hasOpenWound()) {
//			attackText.addCenter("", 0, 0, true);
//		}

		if (Battle.calcMiss(targetChar, enemy, 0)) {
			attackText.addCenter("Miss", pos[0], pos[1], false);
			logger.log(Level.FINE, "Miss!");
		} else {
			String addition = "";
			float crit = enemy.getAttribute(Creature.CRITICAL_HIT_PRECENT);
			float critPre = crit / 100f;
			if (criticalHit = Math.random() < critPre) {
				addition = "Crit";
				damage *= AbstractCard.CRITICAL_INCREASE;
				logger.log(Level.FINE, "Critical hit, new damage " + damage);
			}
			if (damage > 0) {
				targetChar.damage(damage);
				if (!targetChar.isAlive()) {
					if (targetChar.getName().equals("Kin") || targetChar.getName().equals("Borealis")) {
						SoundPlayer.playSound(SoundMap.BATTLE_KIN_BOREALIS_DYING);
					} else if (targetChar.getName().equals("Celis") || targetChar.getName().equals("Zalzi")) {
						SoundPlayer.playSound(SoundMap.BATTLE_CELIS_ZALZI_DYING);
					}
				}
				attackText.addCenter(addition + String.valueOf(damage), pos[0], pos[1], false);
				doit2(effects, enemy, attackText, damage);
			} else {
				logger.log(Level.FINE, "No damage!");
				attackText.addCenter("No Damage", pos[0], pos[1], false);
			}
		}
		logger.log(Level.FINE, targetChar.getName() + " has hp: " + targetChar.getLife());
		logger.log(Level.FINE, "--------------------------");
	}
	
	private static int doit(Enemy enemy, Character character, 
			AttackText attackText, ArrayList<EnemyAttackEffect> effects, 
			float[] pos, float power) {
		String hit = doit1(effects, enemy, attackText, character, pos);
		int damage = 0;
		if (hit != null) {
			if (hit.equals(Death.TEXT)) {
				damage = character.damage(character.getAttribute(Creature.HP));
				character.damage(damage);
				attackText.addCenter(hit, pos[0], pos[1], false);
			}
			doit2(effects, enemy, attackText, damage);
			return -1;
		}
		return power == 0 ? -1 : damage;
	}

	private static String doit1(
			ArrayList<EnemyAttackEffect> effects, Enemy enemy, AttackText text, 
			Character target, float[] pos) {
		float y = 0;
		for (EnemyAttackEffect eae : effects) {
			String name = eae.getName();
			if (name.equals("Element Change")) {
				enemy.changeElement(eae.getValuei());
				text.addCenter(Elements.TEXT, 0, y, true);
			} else if (name.equals("Heal")) {
				float percent = eae.getValuef();
				int ahp = enemy.curePercent(percent);
				text.addCenter("Healed " + ahp, 0, y, true);
			} else if (name.equals("Dispel")) {
				float chance = eae.getValuef();
				ArrayList<Boost> list = enemy.getBoostList();
				for (Boost b : list) {
					b.dispelNegativeEffectWithChance(chance);
				}
				text.addCenter("Dispel", 0, y, true);
			} else if (name.equals("DownTo")) {
				int hp = eae.getValuei();
				int damage = target.cure(hp - target.getAttribute(Creature.HP));
				text.addCenter("" + (-damage), pos[0], pos[1], false);
			} else if (name.equals("Renew")) {
				float percent = eae.getValuef();
				enemy.curePercent(percent);
				text.addCenter("Renewed!", 0, y, true);
			} else if (name.equals("Death")) {
				float percent = eae.getValuef();
				if (Values.rand.nextFloat() <= percent) {
					return Death.TEXT;
				}
			} else if (name.equals("cardPref")) {
				enemy.addCardPreferences(eae.getValues(), eae.getValuei());
			} else if (name.equals("dialog")) {
				battle.setDialog(eae.getDialog());
			} else if (name.equals("music")) {
				battle.changeMusic(eae.getValues());
			} else if (name.startsWith("Boost ")) {
				name = name.replace("Boost ", "");
				float boost = eae.getValuef();
				logger.log(Level.FINE, "Boost " + boost);
				Creature c = null;
				if (boost < 0) {
					c = target;
					text.addCenter(name, pos[0], pos[1], false);
					// TODO: Don't play multiple times if on all character.
					SoundPlayer.playSound(SoundMap.MAGICS_STATUS_DOWN);
				} else {
					c = enemy;
					text.addCenter(name, 0, y, true);
					SoundPlayer.playSound(SoundMap.MAGICS_STATUS_UP);
				}
				if (name.startsWith("Magic Attack")) {
					c.boostMagicAttack(eae.getValuei(), boost);
				} else if (name.startsWith("Attack")) {
					c.boostAttack(eae.getValuei(), boost);
				} else if (name.startsWith("Support")) {
					c.boostSupport(eae.getValuei(), boost);
				} else if (name.startsWith("Magic Defense")) {
					c.boostMagicDefense(eae.getValuei(), boost);
				} else if (name.startsWith("Defense")) {
					c.boostDefense(eae.getValuei(), boost);
				} else if (name.startsWith("Agility")) {
					c.boostSpeed(eae.getValuei(), boost);
				} else if (name.startsWith("Hp")) {
					c.boostLife(eae.getValuei(), boost);
				} else if (name.startsWith("All")) {
					c.boostDefense(eae.getValuei(), boost);
					c.boostMagicDefense(eae.getValuei(), boost);
					c.boostAttack(eae.getValuei(), boost);
					c.boostMagicAttack(eae.getValuei(), boost);
//					c.boostLife(eae.getValuei(), boost);
				}
			}
			y += AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT;
		}
		return null;
	}
	
	private static void doit2(ArrayList<EnemyAttackEffect> effects, Enemy enemy, AttackText text, float damage) {
		for (EnemyAttackEffect eae : effects) {
			String name = eae.getName();
			if (name.equals("Drain")) {
				float hp = eae.getValuef() * damage;
				int ahp = enemy.cure(hp);
				text.addCenter("Drained " + ahp, 0, 0, true);
			}
		}
	}

	public static boolean getCriticalHit() {
		return criticalHit;
	}

	public static AttackInfo makeMove(Enemy enemy, ArrayList<Creature> characters) {
		int type = enemy.getAttackType();
		lastAttack = enemy.getInfo().getRandomAttack(type);
		if (lastAttack.getType() == Slot.SUPPORT) {
			float hp = enemy.getAttribute(Creature.HP);
			float maxhp = enemy.getAttribute(Creature.MAX_HP);
			if (hp / maxhp > .5f) {
				lastAttack = 
					enemy.getInfo().getRandomAttack(
							enemy.getAttackTypeExcluedSupport());
			}
		}
		return lastAttack;
	}

	public static AttackInfo makeMove(AttackInfo attack) {
		return lastAttack = attack;
	}
}
