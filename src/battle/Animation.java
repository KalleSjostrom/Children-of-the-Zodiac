/*
 * Classname: Animation.java
 * 
 * Version information: 0.7.0
 *
 * Date: 15/06/2008
 */
package battle;

import equipment.Slot;
import graphics.Graphics;
import info.BattleValues;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.logging.Level;
import java.util.logging.Logger;

import particleSystem.ParticleSystemPacket;
import battle.character.CharacterRow;
import battle.enemy.BattleEnemy;
import battle.equipment.GLCard;
import cards.AbstractCard;
import cards.Card;
import cards.support.Resurrect;
import character.Character;
import character.Creature;
import character.Enemy;

/**
 * This class manages the animation when a player attacks an enemy.
 * These animations is based on particle systems and there are
 * four different kinds of systems. These four are when the player
 * attacks with a sword, magic, when a player heals or when the 
 * enemy hits. The last system is not used by this class however.
 * This class also does the actual damage on the targets even though
 * the damage is calculated by the BattleCalculator and stored in the
 * given list of HitElements.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 15 June 2008.
 */
public class Animation {
	
	private static Logger logger = Logger.getLogger("Animation");

	private ConcurrentLinkedQueue<AnimationSystem> currentSystem;
	private HashMap<Card, Integer> test = new HashMap<Card, Integer>();

	private AttackText attackText = AttackText.getAttackText();
	private ArrayList<GLCard> list;
	private ArrayList<HitElement> hitElements = new ArrayList<HitElement>();
	private ArrayList<Creature> targets;
	private BattleEnemy enemy;
	private Character attacker;
	private int target;
	private int initialTarget;
	private boolean done;
	private boolean update = false;
	private boolean animationDone = false;
	
	private int tempCurrent = -1;
	private CharacterRow characters;

	/**
	 * Creates a new animation based on the sorted list of HitElements.
	 * These elements contains the damage made on the enemies where
	 * the list is sorted so that every element contains a unique card.
	 * This is because there should only be one "fire ball" or "sword hit"
	 * per card.
	 * 
	 * @param cards the list of hit elements that the animations 
	 * should be based on.
	 * @param targetIndex the index of the target creature.
	 * @param creatureList the list of creatures that the attack is directed
	 * against. This could be the enemies or the party of characters.
	 * @param enemy the 3D graphic representation of the enemies.
	 * This is used to change the enemies color when hit on.
	 * @param attacker the character who is attacking.
	 * @param glCharacters 
	 */
	public void init(ArrayList<GLCard> cards, int targetIndex, 
			ArrayList<Creature> creatureList, BattleEnemy enemy, 
			Character attacker, CharacterRow glCharacters) {
		reset();
		this.list = cards;
		this.enemy = enemy;
		this.attacker = attacker;
		characters = glCharacters;

		targets = creatureList;
		target = initialTarget = targetIndex;
		nextSystem();
	}
	
	/**
	 * Creates a new Animation object which will display the given text next
	 * to the given character. 
	 * 
	 * @param text the text to display.
	 * @param attacker the character that the text will be shown next to.
	 */
	public void init(String text, int index) {
		reset();
		animationDone = true;
		float[] pos = BattleValues.getCharPosForText(index);
//		float off = text.length() * .05f;
		attackText.add(text, pos[0], pos[1], true);
	}
	
	/**
	 * Resets this animation. It clears all the lists and resets all the
	 * temporary values.
	 */
	private void reset() {
		done = false;
		animationDone = false;
		tempCurrent = -1;
		if (list != null) {
//			list.clear();
		}
		currentSystem = new ConcurrentLinkedQueue<AnimationSystem>();
		hitElements.clear();
		test.clear();
		// attackText.reset();
	}

	/**
	 * This method changes the current system to the next in the list.
	 * This is called when a particle system has exploded and the next
	 * should be fired.
	 */
	private void nextSystem() {
		new Thread() {
			public void run() {
				tempCurrent++;
				if (tempCurrent < list.size()) {
					Card c = list.get(tempCurrent).getCard();
					int sleepTime = c.getClass().getName().contains("offense") ? 400 : 0;
					Values.sleep(sleepTime);
					AnimationSystem s = new AnimationSystem(tempCurrent, getSystem(c, getElement(c)));
					currentSystem.add(s);
					c.playSound();
				} else {
					animationDone = true;
				}
			}
		}.start();
	}
	
	/**
	 * Gets the element of this specific card. The element of a card 
	 * (an attack) is the element of the card if the card actually has
	 * an element. If the card has no element, the element of the attack
	 * is equal to the attacking element of the attacker.
	 * 
	 * @param c the card (attack) to calculate the element for.
	 * @return the element of this attack.
	 */
	private int getElement(Card c) {
		int elem = c.getElement();
		if (elem == AbstractCard.NO_ELEMENT) {
			elem = attacker.getElement();
		}
		return elem;
	}

	/**
	 * Gets the list of HitElements in this Animation.
	 * 
	 * @return the list of HitElements.
	 */
	protected ArrayList<HitElement> getList() {
		return sortList(hitElements);
	}
	
	/**
	 * This method merges all the Hit Elements with the same card.
	 * This is because there should only be one animation per card.
	 *  
	 * @param he the hit element to sort.
	 * @return the sorted list of hit elements.
	 */
	private ArrayList<HitElement> sortList(ArrayList<HitElement> he) {
		Card c = null;
		ArrayList<HitElement> result = new ArrayList<HitElement>();
		for (int i = 0; i < he.size(); i++) {
			HitElement elem = he.get(i);
			Card card = elem.getCard();
			if (c == card) {
				result.get(result.size() - 1).merge(elem);
			} else {
				Integer t = test.get(card);
				if (t == null) {
					elem.setTest(initialTarget);
				} else {
					elem.setTest(t);
				}
				result.add(elem);
				c = card;
			}
		}
		return result;
	}

	/**
	 * Gets the system of the given type with the given color.
	 * These types can be either of Slot.ATTACK, .MAGIC or .SUPPORT.
	 * 
	 * @param c the type of system to get.
	 * @param color the color of the system.
	 * @return the particle system of the given type and color.
	 */
	private ParticleSystemPacket getSystem(Card c, int color) {
		boolean onEnemy = targets.get(0) instanceof Enemy;
		boolean onAll = list.get(tempCurrent).getCard().isAll();
		AnimationInfo info = new AnimationInfo();
		info.setTarget(target);
		info.setOnEnemy(onEnemy);
		info.setOnAll(onAll);
		info.setEnemy(enemy);
		info.setAttacker(attacker);
		info.setCharacters(characters);
		info.setLevel(c.getLevel());
		ParticleSystemPacket aps = c.getAnimation(info);
		
		return aps;
	}

	/**
	 * This method draws the current particle system on the given gl object.
	 * If the current system has not been initiated this method initiates the
	 * system by calling the initDraw(GL2 gl) method in the current system.
	 * 
	 * @param gl the GL to draw on.
	 */
	public void draw(Graphics g) {
		if (currentSystem != null) {
			for (AnimationSystem s : currentSystem) {
				ParticleSystemPacket psp = s.getSystem();
				psp.draw(g);
			}
		}
		attackText.draw(g);
	}
	
	/**
	 * Updates the current particle system and the texts shown in battle
	 * if there are any.
	 * 
	 * @return true if the animation has damages an enemy and is therefore
	 * in need of graphical update.
	 */
	public boolean update(float elapsedTime) {
		if (currentSystem.size() > 0) {
			for (AnimationSystem s : currentSystem) {
				ParticleSystemPacket psp = s.getSystem();
				psp.update(elapsedTime / 1000f);

				if (psp.isDestroyed() && !psp.isAdded()) {
					psp.add();
					final boolean isEnemy = targets.get(target) instanceof Enemy;
					
					attackTarget(isEnemy, s.index);
					if (isEnemy) {
						HitElement e = hitElements.get(hitElements.size() - 1);
						enemy.setHideTimer(200, e.isCrit());
					}
				}
				if (psp.isReady()) {
					nextSystem();
				}
			}
		} else if (animationDone) {
			done = attackText.isDone();
		}
		Iterator<AnimationSystem> it = currentSystem.iterator();
		while (it.hasNext()) {
			AnimationSystem s = it.next();
			if (s.getSystem().isDead()) {
				it.remove();
			}
		}
		return checkUpdate();
	}

	/**
	 * Damages the enemy with the attack values stores in the list of 
	 * HitElements set by the constructor. It uses the current index to
	 * get the values from the list.
	 * 
	 * @param onEnemy true if the attack is on the enemy team.
	 */
	private void attackTarget(boolean onEnemy, int index) {
		update = true;
		Card c = list.get(index).getCard();
		boolean onAll = c.isAll();
		int damage = 0;
		HitElement test = null;
		HitElement cureElement = null;
		if (onAll) {
			for (int i = 0; i < targets.size(); i++) {
				if (targets.get(i).isAlive() || c instanceof Resurrect) {
					HitElement newElement = c.use(targets.get(i), attacker);
					HitElement tempCure = newElement.getCureElement();
					if (tempCure != null) {
						if (cureElement == null) {
							cureElement = tempCure;
						} else {
							cureElement.cureMerge(tempCure);
						}
					}
					hitElements.add(newElement);
					damage += damageEnemy(i, onEnemy, newElement, index);
				}
			}
		} else {
			if (targets.get(target).isAlive() || c instanceof Resurrect) {
				test = c.use(targets.get(target), attacker);
				damage = damageEnemy(target, onEnemy, test, index);
				hitElements.add(test);
				cureElement = test.getCureElement();
			}
		}
		if (onEnemy && c.getType() != Slot.SUPPORT) {
			enemy.changeColor(currentSystem.peek().getSystem().getColor());
		}
		
		// Only for drain!
		if (cureElement != null) {
			attacker.cure(cureElement.getAttackDamage());
			createAttackTextForAttacker(cureElement);
			logger.log(Level.FINE, attacker.getName() + " drained " + cureElement.getAttackDamage());
		}
	}

	/**
	 * This method creates the damages the enemy, creates the appropriate 
	 * attack text and takes care of an possible cure element contained in
	 * the given hit element. 
	 * 
	 * @param enemyIndex the index of the enemy in the list of targets.
	 * @param enemy true if the damage is made on the enemy team or false
	 * if the character party should be damaged.
	 * @param he the hit element containing the information about the attack.
	 * @param pos the position of the enemy in the battle.
	 * @return the damage made on an enemy.
	 */
	private int damageEnemy(
			int enemyIndex, boolean enemy, HitElement he, int current) {
		Creature c = targets.get(enemyIndex);
		boolean alive = c.isAlive();
		int damage = c.addHP(he.getAttackDamage(), he.isSupport());
		if (enemyIndex == target && alive && !c.isAlive()) {
			// Main target is dead!
			clearList(current);
		}
		
		boolean elem = he.getCard() instanceof cards.neutral.Elements;
		if (enemy && enemyIndex == target) {
			createAttackText(he);
		} else {
			boolean support;
			if (elem) {
				support = !enemy;
			} else {
				support = he.isSupport();
			}
			createAttackText(enemyIndex, he, enemy, support, enemy && (enemyIndex == target));
		}
		if (elem && he.didHit()) {
			c.changeElement(he.getCard().getElement());
		}
		return damage;
	}

	/**
	 * Clears some of the animations in the list of animation instructions.
	 * This is done when the target has died and there is no need to hit it
	 * anymore. It does, however, keep the resurrect animation and any card
	 * hitting on all, given that there are more enemies to hit.
	 */
	private void clearList(int current) {
		if (Creature.isTeamDead(targets)) {
			list.clear();
		} else {
			// If the attack continues after the main target is dead
			target++;
			target %= targets.size();
			for (int i = current + 1; i < list.size(); i++) {
				Card c = list.get(i).getCard();
				test.put(c, target);
			}
			
			// If the attack should stop after the main target is dead, 
			// only keeping the all cards
//			for (int i = current + 1; i < list.size(); i++) {
//				Card c = list.get(i).getCard();
//				if (!c.isAll()) {
//					list.remove(i);
//					i--;
//				}
//			}
		}
	}

	/**
	 * This method creates the attack text for the enemy in the middle.
	 * It uses the information in the given hit element (index = 0).
	 * 
	 * @param he the hit element which contains the information 
	 * about the attack.
	 */
	private void createAttackText(HitElement he) {
		createAttackText(he, 0, 0, he.isSupport(), true);
	}

	/**
	 * This method creates the attack text for any creature.
	 * 
	 * @param i the index of the creature in the list of targets.
	 * @param pos the graphical position of the creature in the battle. 
	 * @param he the hit element containing the information.
	 * @param enemy true if the attack is on an enemy.
	 * @param support true if the attack is a support attack like cure.
	 * @param small 
	 */
	private void createAttackText(
			int i, HitElement he, boolean enemy, boolean support, boolean large) {
		float[] pos;
		if (enemy) {
			pos = BattleValues.getEnemyPosForText(i);
		} else {
			pos = BattleValues.getCharPosForText(i);
		}
		float x = pos[0];// + (enemy ? 0 : i * pos[2]);
		float y = pos[1];// + (enemy ? i * pos[2] : 0);
		createAttackText(he, x, y, support, large);
	}
	
	private void createAttackText(HitElement he, float x, float y, boolean support, boolean large) {
		String s = he.getEffectText(0);
		if (s != null && !s.equals("")) {
			attackText.addCenter(s, x, y, support, AttackText.getSize(large));
			if (he.getActuallAttackDamage() != -1) {
				y -= AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT;
				attackText.addCenter(
						he.getActuallAttackDamage(), x, y, support, AttackText.getSize(large));
			}
		} else {
			attackText.addCenter(he.getAttackDamage(), x, y, support, AttackText.getSize(large));
		}
	}

	/**
	 * Creates the attack text for when the attack on a target team
	 * influences the attacker. Examples on this is the drain, where
	 * not only the attack values should be drawn but also a text 
	 * displaying something like "Drained 53 hp".
	 * 
	 * @param pos the position of the attacker.
	 * @param he the hit element containing the attack on the attacker.
	 */
	private void createAttackTextForAttacker(HitElement he) {
		float[] pos = BattleValues.getCharPosForText(attacker.getIndex());
		float x = pos[0]; // + attacker.getIndex() * pos[2];
		float y = pos[1];
		String s = he.getEffectText(0);
		attackText.addCenter(s + " " + he.getAttackDamage(), x, y, true);
	}

	/**
	 * Checks if the animation has damages an enemy and is therefore
	 * in need of graphical update. This method resets the update value
	 * to false when called. Note this! This will mean that a subsequent
	 * call to this method will result in false, the second time it is
	 * called whatever the first call resulted in.
	 * 
	 * @return true if the graphical information display is in need 
	 * of an update.
	 */
	private boolean checkUpdate() {
		return update ? !(update = false) : false;
	}

	/**
	 * This method checks if the animation is done. This means that all
	 * the particle systems, in the list set by the constructor, has been 
	 * drawn and exploded.
	 *  
	 * @return true if the animation is done.
	 */
	public boolean isDone() {
		return done;
	}
	
	private class AnimationSystem {
		
		private ParticleSystemPacket psp;
		private int index;
		
		public AnimationSystem(int index, ParticleSystemPacket system) {
			this.index = index;
			psp = system;
		}

		public ParticleSystemPacket getSystem() {
			return psp;
		}
	}
	
	public static class AnimationInfo {
		
		private int nrTarget;
		private int target;
		private boolean onEnemy;
		private boolean onAll;
		private BattleEnemy enemy;
		private Character attacker;
		private CharacterRow characters;
		private int level;

		public AnimationInfo() {
		}

		public int getNrTarget() {
			return nrTarget;
		}

		public int getTarget() {
			return target;
		}

		public boolean isOnEnemy() {
			return onEnemy;
		}

		public boolean isOnAll() {
			return onAll;
		}

		public BattleEnemy getEnemy() {
			return enemy;
		}

		public Character getAttacker() {
			return attacker;
		}
		
		public CharacterRow getCharacters() {
			return characters;
		}
		
		public int getLevel() {
			return level;
		}

		public void setNrTarget(int nrTarget) {
			this.nrTarget = nrTarget;
		}

		public void setTarget(int target) {
			this.target = target;
		}

		public void setOnEnemy(boolean onEnemy) {
			this.onEnemy = onEnemy;
		}

		public void setOnAll(boolean onAll) {
			this.onAll = onAll;
		}

		public void setEnemy(BattleEnemy enemy) {
			this.enemy = enemy;
		}

		public void setAttacker(Character attacker) {
			this.attacker = attacker;
		}
		
		public void setCharacters(CharacterRow characters) {
			this.characters = characters;
		}

		public void setLevel(int level) {
			this.level = level;
		}
	}
}
