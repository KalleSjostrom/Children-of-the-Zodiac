/*
 * Classname: Battle.java
 * 
 * Version information: 0.7.0
 *
 * Date: 18/06/2008
 */
package battle;

import info.BattleValues;
import info.Database;
import info.SoundMap;
import info.Values;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.Semaphore;
import java.util.logging.*;

import menu.tutorial.Tutorial;

import organizer.Organizer;
import organizer.SubGameMode;

import sound.SoundPlayer;
import villages.utils.DialogSequence;
import battle.AttackText.textSize;
import battle.bosses.Boss;
import battle.bosses.BossDialog;
import battle.character.CharacterRow;
import battle.character.Creature3D;
import battle.character.EnemyRow;
import battle.enemy.AttackInfo;
import battle.enemy.BattleEnemy;
import battle.enemy.EnemyLogic;
import battle.equipment.GLCard;
import battle.equipment.GLDeck;
import battle.equipment.GLWeapon;
import battle.resultScreen.ResultScreen;
import battle.resultScreen.SpoilsScreen;
import character.Character;
import character.Creature;
import character.Enemy;
import factories.Load;
import graphics.Graphics;

/**
 * This class is the sub game mode Battle. When a player is in a labyrinth
 * and a monster appears, the BattleManager is initiated by the Labyrinth.
 * The BattleManager then initiates a object of this class to run the battle.
 * 
 * The Battle is sub game mode because the BattleManager which is a 
 * game mode runs it. The battle consists of different modes, which are
 * Idling, Battling, Enemy turn, Game over, Animate, Result, Spoils and Exit.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 18 June 2008.
 */
public class Battle extends SubGameMode {
	
	private static Logger logger = Logger.getLogger("Battle");
	
	/**
	 * The list containing all the idling creatures in the battle.
	 */
	protected ArrayList<Creature> idling = new ArrayList<Creature>();
	
	/**
	 * The list containing all the enemies in the battle.
	 */
	protected ArrayList<Creature> enemies = new ArrayList<Creature>();
	
	/**
	 * The queue which creatures, who are ready to battle, is put in.
	 */
	protected BattleQueue queue = new BattleQueue();
	
	private Animation animate = new Animation();
	private AttackText attackText;
	private ArrayList<Creature> characters;
	private BattleEnemy monster;
	private BattleManager manager;
	private Character attacker;
	private CharacterRow glCharacters;
	private Clock clock;
	private Legend legend;
	private Tutorial tutorial;
	private EnemyRow glEnemies;
	private Enemy enemy;
	private GLDeck currentDeck;
	private GLHand hand;
	private ResultScreen resultScreen = new ResultScreen();
	private SpoilsScreen spoilsScreen;
	private Semaphore finishRound = new Semaphore(1);
	
	private boolean update = false;
	private boolean firstTimeFlee = true;
	private DialogSequence dialog;
	private int mode;

	private int enemySize;

	/**
	 * Constructs a new Battle and saves the given row of characters.
	 * This row is used just to update and move the row of characters
	 * at the top of the battle. This class does not draw any of the
	 * enemies, enemy rows or characters.
	 * 
	 * @param boss true if this battle is against a boss.
	 * @param en the enemy to battle.
	 * @param freq 
	 * @param manager 
	 */
	public Battle(boolean boss, Enemy en, float[] freq, BattleManager manager) {
		this.manager = manager;
		characters = Load.getCharactersAsCreatures();
		attacker = (Character) characters.get(0);
		BattleValues.setCharacterPosition(characters.size());
		enemy = en;
		fillIdling(boss, freq);
		attackText = AttackText.getAttackText();
		attackText.reset();
		
		hand = new GLHand(characters, enemies);
		Enemy e = (Enemy) enemies.get(0);
		monster = boss ? getBoss(e): new BattleEnemy(e);
		monster.setBattle(this);
		clock = new Clock();
		legend = new Legend();
		tutorial = new Tutorial(manager.getName(), false);
		
		glCharacters = new CharacterRow();
		glCharacters.init(boss);
		glEnemies = new EnemyRow(enemies);
		glEnemies.init(boss);
		currentDeck = attacker.get2DDeck();
	}
	
	public void init() {
		if (monster instanceof Boss) {
			Boss b = (Boss) monster;
			if (b.wantsToTalk(BossDialog.BEGINNING)) {
				mode = BattleManager.TALKING;
				dialog = b.next(BossDialog.BEGINNING);
				glCharacters.hide();
				glEnemies.hide();
			}
		}
		if (mode != BattleManager.TALKING) {
			mode = BattleManager.IDLING;
			glCharacters.show();
			glEnemies.show();
		}
	}

	/**
	 * Fills the Idling list with all of the battles participants.
	 * It also chooses how many enemies to battle. 
	 * 
	 * 70 % of the time it is against one enemy,
	 * 20 % against two enemies and
	 * 10 % against one enemy. 
	 * 
	 * @param boss true if this battle is against a boss.
	 * @param freq 
	 */
	private void fillIdling(boolean boss, float[] freq) {
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			Character c = Load.getCharacters().get(i);
			idling.add(c);
		}
		idling.add(enemy);
		enemies.add(enemy);
		int rand = 0;
		if (!boss) {
			float pre = (float) Math.random();
			if (pre <= freq[BattleManager.THREE_ENEMIES]) {
				rand = 2;
			} else if (pre <= freq[BattleManager.TWO_ENEMIES] + freq[BattleManager.THREE_ENEMIES]) {
				rand = 1;
			}
		}
		for (int i = 0; i < rand; i++) {
			Enemy newEnemy = enemy.copy();
			idling.add(newEnemy);
			enemies.add(newEnemy);
		}
		enemySize = enemies.size();
		logger.log(Level.FINE, "Encountered creature: " + (rand + 1) + " " + enemy.getName());
		setUpdateTime(idling);
	}

	/**
	 * Updates the battle. Depending on which mode the battle
	 * currently is in, different parts of the battle is updated.
	 */
	public void update(float dt) {
		currentDeck.update(dt);
		glCharacters.update(dt);
		glEnemies.update(dt);
		legend.update(dt);
		monster.update(dt);
		attackText.update(dt);
		if (mode == BattleManager.ANIMATE && animate != null) {
			update = animate.update(dt);
			
			if (update) {
				glEnemies.checkDead();
			}
			
			if (animate.isDone()) {
				ArrayList<HitElement> list = animate.getList();
				if (list != null && !list.isEmpty()) {
					resultScreen.setHitElements(list);
					glEnemies.check();
					hand.update();
					mode = BattleManager.RESULT;
					if (Creature.isTeamDead(enemies)) {
						killMonster();
					}
					show();
				} else {
					finishRoundForCharacters(false, true);
				}
			}
		}
		if (mode == BattleManager.SPOILS) {
			spoilsScreen.update(dt);
		} else if (mode == BattleManager.IDLING) {
			updateIdlingMode();
		} else if (mode == BattleManager.BATTLING) {
			if (clock.timesUp()) {
				finishRound();
			}
		}
		if (mode == BattleManager.ENEMY_TURN) {
			if (monster.shouldHit()) {
				calcEnemyDamage();
				monster.resetHit();
			}
			if (!monster.isHitting()) {
				if (mode == BattleManager.ENEMY_TURN) {
					switchMode(BattleManager.IDLING);
				}
			}
		}
		currentDeck.updatePos(dt);
	}

	private void killMonster() {
		monster.kill();
//		if (((Boss) monster).continueBattleMusic()) {
//			manager.overwriteStarterMusic();
//		}
		if (!(monster instanceof Boss && ((Boss) monster).continueBattleMusic())) {
			manager.switchMusic("Level Up");
		}
	}

	/**
	 * This method is called when the battle is in the "Idling" mode. In this
	 * mode, none of the creatures are battling each other, they are just 
	 * waiting for their turn. When a creature is ready, it is the removed from
	 * the idling list and the game switches modes. To which mode, depends on what 
	 * kind of creature it was.
	 */
	private void updateIdlingMode() {
		for (int i = 0; i < idling.size(); i++) {
			Creature c = idling.get(i);
			if (c.isAlive()) {
				c.incrementSpeed();
				if (c.isReady()) {
					queue.enqueue(c);
					idling.remove(i);
				}
			}
		}
		if (!queue.isEmpty()) {
			Creature newChar = queue.dequeue();
			if (newChar instanceof Enemy) {
				newChar.resetSpeed();
				enemy = (Enemy) newChar;
				idling.add(enemy);
				switchMode(BattleManager.ENEMY_TURN);
			} else {
				initNewRound((Character) newChar);
			}
		}
	}

	/**
	 * This method sets the given character as the attacker of the next round
	 * and initiates the round. It initiates the deck, sets the clock 
	 * and so on.
	 * 
	 * @param character the character to set as the attacker.
	 */
	private void initNewRound(Character character) {
		logger.log(Level.FINE, "Init new round");
		attacker = character;
		
		if (character.get2DDeck().needsToShuffle()) {
			character.get2DDeck().shuffleAndDeal();
			int i = Math.min(character.getIndex(), BattleValues.CHAR_POS_FOR_TEXT.length - 1);
			animate.init("Shuffle", i);
			mode = BattleManager.ANIMATE;
		} else {
			currentDeck = attacker.get2DDeck();
			currentDeck.initNewRound();
			clock.show();
			legend.show();
			clock.reset();
			hand.show();
			hand.reset();
			switchMode(BattleManager.BATTLING);
		}
		attacker.setActive(true);
		attacker.setTurn(true);
		setActiveForAll(false);
		if (tutorial.increment()) {
			mode = BattleManager.TUTORIAL;
			tutorial.setActive(true);
		}
	}

	/**
	 * This method initiates the drawing of the hand shown in battle.
	 * 
	 * @param g the GL object to use when initializing.
	 */
	public void initDraw(Graphics g) {
		clock.initDraw(g);
		legend.initDraw(g);
		hand.initDraw(g);
		hand.hide();
	}
	
	public void drawTopLayer(Graphics g) {
		if (mode == BattleManager.RESULT) {
			resultScreen.drawResult(g);
		} else if (mode == BattleManager.SPOILS) {
			spoilsScreen.drawSpoils(g);
		}
		legend.drawTopLayer(g);
		tutorial.drawTopLayer(g);
	}

	/**
	 * This method draws some of the battle. The things it draws are
	 * the current deck (if any) the hand that points at creatures.
	 * The animation and attack text and the result screen.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawBattle(float dt, Graphics g) {
		if (mode == BattleManager.TALKING) {
			manager.setDialog(dialog);
		} else {
			currentDeck.draw(dt, g);
			if (update) {
				glEnemies.updateTexture(g);
				glCharacters.updateTexture(g);
				update = false;
			}
			hand.draw(dt, g);
			legend.setSupport(isSupportMode());
			legend.draw(dt, g);
			if (mode == BattleManager.ANIMATE) {
				animate.draw(dt, g);
			}
			attackText.draw(dt, g);
		}
	}

	/**
	 * This method is called when the cards has been played in the weapon
	 * and the attack should be made. The current decks card is gotten and
	 * an animation list is constructed. The mode is switched from Battling
	 * to Idling.
	 */
	private void finishRound() {
		try {
			finishRound.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		logger.log(Level.FINE, "\n" + attacker.getName() + " is about to attack.");
		ArrayList<GLCard> cards = currentDeck.finish();
		logger.log(Level.FINE, "Attacking with " + cards.size() + " number of cards.");
		calcDamage(cards);
		logger.log(Level.FINE, "Time it took to complete the turn: " + clock.getTime() + " seconds.\n");
		clock.hide();
		legend.hide();
		clock.finish();
		hand.hide();
		glCharacters.setTarget(-1, false);
		
		if (cards.size() == 0) {
			logger.log(Level.FINE, "Setting idling");
			finishRoundForCharacters(false, true);
		} else {
			animate.init(
					cards, hand.getIndex(), hand.getSelTeam(), 
					monster, attacker, glCharacters);
			mode = BattleManager.ANIMATE;
		}
		finishRound.release();
	}
	
	private void finishRoundForCharacters(boolean didAction, boolean setIdling) {
		setActiveForAll(true);
		attacker.finishRound(didAction);
		idling.add(attacker);
		if (setIdling) {
			mode = BattleManager.IDLING;
		}
	}

	/**
	 * Calculates how much the player has damaged the enemy.
	 * Adds the cards in the weapon to the attack.
	 * Does not return anything but the class variables are changed
	 * so the draw method prints the correct values.
	 * Works like the calculateEnemyDamage() method but way more
	 * advanced because the player has more choices to make and can get 
	 * combinations and such.
	 * 
	 * @param cards the list of cards to damage with.
	 */
	protected void calcDamage(ArrayList<GLCard> cards) {
		ArrayList<Creature> targetTeam = hand.getSelTeam();
		resultScreen.init(targetTeam);
		update = true;
	}
	
	/**
	 * The method calculates the damage made on a character by the enemy. 
	 * This is done by calling the calcEnemyDamage() method in the
	 * EnemyLogic class.
	 * 
	 * @see EnemyLogic#calcEnemyDamage(Enemy, ArrayList, AttackText)
	 */
	protected void calcEnemyDamage() {
		int target = 
			EnemyLogic.calcEnemyDamage(enemy, enemies, characters, attackText, this);
		for (int i = 0; i < glCharacters.size(); i++) {
			Creature c = glCharacters.get(i).getCreature();
			if (!c.isAlive()) {
				c.resetBoost();
			}
		}
		if (!checkIfEnemiesAreDead(false)) {
			if (target != CharacterRow.NO_TARGET) {
				if (target == CharacterRow.ON_ALL) {
					for (int i = 0; i < glCharacters.size(); i++) {
						glCharacters.get(i).setHideTimer(150, EnemyLogic.getCriticalHit());
					}
					glCharacters.show();
				} else {
					glCharacters.get(target).setHideTimer(150, EnemyLogic.getCriticalHit());
				}
				checkIfPartyIsDead();
			}
			update = true;
		}
		if (mode == BattleManager.ENEMY_TURN) {
			checkOpenWound();
		}
	}

	private void checkOpenWound() {
		if (enemy.hasOpenWound()) {
			show();
			mode = BattleManager.WAITING;
			new Thread() {
				public void run() {
					Values.sleep(1000);
					boolean found = false;
					for (int i = 0; i < glEnemies.size() && !found; i++) {
						Creature3D e = glEnemies.get(i);
						found = e.getCreature() == enemy;
						if (found) {
							e.setHideTimer(150, false);
							float[] pos = BattleValues.getEnemyPosForText(i);
							int val = enemy.updateOpenWound();
							attackText.addCenter(
									"Open wound!", 
									pos[0], pos[1], false, textSize.SMALLEST);
							attackText.addCenter(
									String.valueOf(val), 
									pos[0], pos[1] - AttackText.HEIGHT_DISTANCE_BETWEEN_TEXT, 
									false, textSize.SMALLEST);
							update = true;
						}
					}
					Values.sleep(1000);
					
					glEnemies.check();
					boolean enemyDead = Creature.isTeamDead(enemies);
					if (enemyDead) {
						hide();
						attackText.reset();
						killMonster();
						checkIfEnemiesAreDead(true);
					} else {
						switchMode(BattleManager.IDLING);
					}
					show();
				}
			}.start();
		}
	}

	/**
	 * This method checks if all of the characters are dead.
	 * It is called when someone dies, to check if the rest is also dead.
	 * If the party is dead, the mode is switched to game over.
	 * 
	 * @return true if the party is dead and false if some character in
	 * the team is alive.
	 */
	private void checkIfPartyIsDead() {
		logger.log(Level.FINE, "Check if party dead");
		if (Creature.isTeamDead(characters)) {
			logger.log(Level.FINE, "Party is dead!");
			monster.setDialog(BossDialog.PARTY_DEAD);
			if (monster.wouldLikeToTalk()) {
				mode = Integer.MAX_VALUE;
				new Thread() {
					public void run() {
						Values.sleep(2500);
						mode = BattleManager.TALKING;
						dialog = ((Boss) monster).next(BossDialog.PARTY_DEAD);
					}
				}.start();
			} else {
				gameOver(2500);
			}
		}
	}

	/**
	 * Checks if all the enemies is dead. If so the spoils mode is 
	 * entered and a result screen is made.
	 * 
	 * @return 
	 */
	private boolean checkIfEnemiesAreDead(boolean endForCharacters) {
		boolean enemiesDead;
		if (enemiesDead = Creature.isTeamDead(enemies)) {
			monster.setDialog(BossDialog.ENEMY_DEAD);
			String nextPlace = monster.getNextPlace();
			if (monster.wouldLikeToTalk()) {
				mode = Integer.MAX_VALUE;
				new Thread() {
					public void run() {
						Values.sleep(800);
						mode = BattleManager.TALKING;
						dialog = ((Boss) monster).next(BossDialog.ENEMY_DEAD);
					}
				}.start();
				
				boolean switchMusic = true;
				if (nextPlace != null) {
					HashMap<String, String> info = 
						Organizer.getOrganizer().getInformationFor(nextPlace);
					switchMusic = info.get("music").compareToIgnoreCase(manager.music) != 0;
				}
				if (switchMusic) {
					manager.switchMusic("No Music");
				} else {
					manager.dontFadeBattleMusic();
				}
				glCharacters.setTarget(CharacterRow.NO_TARGET, false);
				hide();
				finishRoundForCharacters(true, false);
			} else if (nextPlace != null) {
				HashMap<String, String> info = 
					Organizer.getOrganizer().getInformationFor(nextPlace);
				if (info.get("music").compareToIgnoreCase(manager.music) == 0) {
					manager.dontFadeBattleMusic();
				}
				manager.setNextPlace(monster.getNextPlace());
				exit(BattleManager.EXIT_TO_NEXT);
				glCharacters.setTarget(CharacterRow.NO_TARGET, false);
				hide();
				finishRoundForCharacters(true, false);
			} else {
				finishRoundForCharacters(true, false);
				spoilsScreen = new SpoilsScreen(enemy, enemySize);
				mode = BattleManager.SPOILS;
			}
		} else if (endForCharacters) {
			finishRoundForCharacters(true, true);
		}
		return enemiesDead;
	}

	public static boolean calcMiss(Creature target, Creature attacker, float defenseBoost) {
		float hit = attacker.getAttribute(Creature.HIT) / 100f;
		float evade = (target.getAttribute(Creature.EVADE) / 100f) + defenseBoost;
		float actuallHit = hit - evade;
		float hitMiss = Values.rand.nextFloat();
		return hitMiss > actuallHit;
	}
	
	/**
	 * This method is called when the player presses the triangle button, 
	 * when in battle mode. This method attacks with the cards already in the
	 * weapon. If no cards has been played no attack will be made.
	 */
	public void trianglePressed() {
		SoundPlayer.playSound(SoundMap.BATTLE_FINISH_ROUND);
		finishRound();
	}

	/**
	 * This method is called when the player presses the 
	 * square button. This method does different thing depending 
	 * on the current mode. It acts as the "enter" or "select" button.
	 */
	public void crossPressed() {
		switch (mode) {
		case BattleManager.BATTLING :
			if (!currentDeck.isFull()) {
				currentDeck.chooseSelectedCard();
			}
			break;
		case BattleManager.RESULT : 
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT);
			checkIfPartyIsDead();
			checkIfEnemiesAreDead(true);
			break;
		case BattleManager.SPOILS : 
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT);
			if (spoilsScreen.crossPressed()) {
				exit();
			}
			break;
		case BattleManager.TUTORIAL : 
			SoundPlayer.playSound(SoundMap.BATTLE_NEXT);
			if (tutorial.crossedPressed()) {
				mode = BattleManager.BATTLING;
			}
			break;
		case BattleManager.TALKING :
			dialog = monster.next();
			if (dialog == null) {
				manager.setDialog(null);
				int i = monster.getDialogIndex();
				switch (i) {
				case BossDialog.ENEMY_DEAD :
					manager.setNextPlace(monster.getNextPlace());
					exit(BattleManager.EXIT_TO_NEXT);
					break;
				case BossDialog.PARTY_DEAD :
					gameOver(500);
					break;
				default :
					if (monster.shouldHitAfterTalk()) {
						switchMode(BattleManager.ENEMY_TURN);
					} else {
						mode = BattleManager.IDLING;
						glCharacters.show();
						glEnemies.show();
					}
					break;
				}
			}
			break;
		}
	}
	
	public void exitToNext() {
		manager.setNextPlace(monster.getNextPlace());
		exit(BattleManager.EXIT_TO_NEXT);
	}

	/**
	 * This method is called when the player presses the 
	 * circle button, when in the battle mode. This method
	 * discards the selected card in the deck.
	 */
	public void circlePressed() {
		SoundPlayer.playSound(SoundMap.BATTLE_DISCARD_CARD);
		currentDeck.discardCard();
	}

	/**
	 * This method is called when the player presses the 
	 * square button, when in the battle mode. This method
	 * saves the selected card in the deck.
	 */
	public void squarePressed() {
		SoundPlayer.playSound(SoundMap.BATTLE_SAVE_CARD);
		currentDeck.saveCard();
	}

	/**
	 * This method is called when the player presses the L2 button.
	 * It does exactly the same as the R2 button.
	 */
	public void L2Pressed() {
		R2Pressed();
	}

	/**
	 * This method is called when the player presses the R2 button, when in 
	 * battle mode. This method flips the weapon so that the other battle
	 * mode is available if no card has been played. This means that if the 
	 * mode was "attack" the mode would be switched to "defense" and vice versa.
	 */
	public void R2Pressed() {
		int mode = currentDeck.flipMode();
		if (mode != -1) {
			boolean defMode = mode == GLWeapon.DEFENSE_MODE;
			hand.setPos(defMode, Load.getCharacterIndex(attacker.getName()));
			if (defMode) {
				glCharacters.setTarget(hand.getIndex(), true);
			} else {
				glCharacters.setTarget(-1, false);
			}
			SoundPlayer.playSound(SoundMap.BATTLE_FLIP_MODE);
		}
	}
	
	private boolean isSupportMode() {
		return currentDeck.getMode() == GLWeapon.DEFENSE_MODE;
	}

	/**
	 * This method is called when the player presses the L1 button, when in 
	 * battle mode. This method moves the hand, that points to the creatures 
	 * in the battle, to the left.
	 */
	public void L1Pressed() {
		SoundPlayer.playSound(SoundMap.BATTLE_CHARACTER_NAVIGATE);
		//if (currentDeck.slotIsEmpty()) {
			hand.previous();
			if (isSupportMode()) {
				glCharacters.setTarget(hand.getIndex(), true);
			} else {
				glCharacters.setTarget(-1, false);
			}
		//}
	}

	/**
	 * This method is called when the player presses the R1 button, when in 
	 * battle mode. This method moves the hand, that points to the 
	 * creatures in the battle, to the right.
	 */
	public void R1Pressed() {
		SoundPlayer.playSound(SoundMap.BATTLE_CHARACTER_NAVIGATE);
		//if (currentDeck.slotIsEmpty()) {
			hand.next();
			if (isSupportMode()) {
				glCharacters.setTarget(hand.getIndex(), true);
			} else {
				glCharacters.setTarget(-1, false);
			}
		//}
	}

	/**
	 * This method is called when the player presses the left button, when in 
	 * battle mode. This method moves the select cursor to the left one step. 
	 * If the cursor is at the leftmost end of the cards it is moved to the 
	 * rightmost card.
	 */
	public void leftPressed() {
		currentDeck.selectLeft();
	}

	/**
	 * This method is called when the player presses the right button, when in 
	 * battle mode. This method moves the select cursor to the right one step.
	 * If the cursor is at the rightmost end of the cards it is moved to the 
	 * leftmost card.
	 */
	public void rightPressed() {
		currentDeck.selectRight();
	}

	/**
	 * This method shows (makes visible) the enemies 
	 * and the characters.
	 */
	private void show() {
		glEnemies.show();
		System.out.println("show");
		glCharacters.show();
	}
	
	public void testShowCharacters() {
		System.out.println("SHOW");
		glCharacters.testShowCharacters();
	}
	public void testHideCharacters() {
		System.out.println("HIDING");
		glCharacters.testHideCharacters();
// 		glCharacters.hide();
	}

	/**
	 * This method hides the enemies and the characters.
	 */
	private void hide() {
		System.out.println("hide");
		glEnemies.hide();
		glCharacters.hide();
	}
	
	public void toggleHelp() {
		legend.toggleLegend();
	}

	/**
	 * Flees from battle. If the Math.random() method generates a smaller
	 * value than .002f (currently) the enemies are hidden and the battle
	 * is exited. Because the small chance to flee this method should be
	 * called multiple times as long as the player is holding down the
	 * flee buttons (R2 + L2).
	 */
	protected void flee() {
		if (Math.random() < .002f) {
			hide();
			mode = BattleManager.EXIT;
		}
		if (firstTimeFlee) {
			clock.initFlee();
			firstTimeFlee = false;
		}
	}

	/**
	 * This resets the fleeing procedure. It removes the text "Fleeing"
	 * from the screen.
	 */
	protected void resetFlee() {
		firstTimeFlee = true;
		clock.resetFlee();
	}

	private Boss getBoss(Enemy enemy) {
		Boss b = null;
		try {
			String name = enemy.getDbName();
			String first = name.substring(0, 1);
			String rest = name.substring(1);
			Class<?> boss = Class.forName("battle.bosses." + first.toUpperCase() + rest);
			Constructor<?>[] cs = boss.getConstructors();
			b = (Boss) cs[0].newInstance(new Object[]{enemy});
		} catch (ClassNotFoundException e) {
			b = new Boss(enemy);
//			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		} catch (IllegalArgumentException e) {
			e.printStackTrace();
		} catch (InvocationTargetException e) {
			e.printStackTrace();
		}
		return b;
	}

	/**
	 * Gets the row of enemies.
	 * 
	 * @return the enemyRow for this battle.
	 */
	public EnemyRow getEnemyRow() {
		return glEnemies;
	}

	/**
	 * Gets the row of characters.
	 * 
	 * @return the characterRow for this battle.
	 */
	public CharacterRow getCharacterRow() {
		return glCharacters;
	}

	/**
	 * Gets the battle enemy for this battle. The battle enemy
	 * is the class that manages the texture and animation of the enemy.
	 * 
	 * @return the BattleEnemy for this battle.
	 */
	public BattleEnemy getEnemy() {
		return monster;
	}

	/**
	 * This method gets the current mode in the battle.
	 * 
	 * @return the mode of the battle.
	 */
	public int getMode() {
		return mode;
	}

	/**
	 * This method switches the current mode to the given one.
	 * 
	 * @param m the mode to switch to.
	 */
	public void switchMode(int m) {
		if (mode == BattleManager.ENEMY_TURN) {
			show();
		}
		mode = m;
		if (mode == BattleManager.ENEMY_TURN) {
			AttackInfo attack;
//			if (monster.shouldHit()) {
				monster.increment();
				if (monster.wouldLikeToTalk()) {
					mode = BattleManager.TALKING;
					dialog = ((Boss) monster).next();
					hide();
				} else {
					int target;
					if (monster instanceof Boss) {
						Boss b = (Boss) monster;
						attack = b.makeMove(
								(int) (enemies.get(0).getLifePrecent() * 100));
					} else {
						attack = EnemyLogic.makeMove(enemy, characters);
					}
					target = monster.getTarget(characters, attack);
					glCharacters.setTarget(target, false);
					if (target != CharacterRow.ON_ALL) {
						hide();
					} else {
						glEnemies.hide();
					}
					monster.hit(attack, target);
				}				
//			}
		}
	}

	/**
	 * Sets the update time of the creatures in the battle. This is the amount
	 * of time that the progress bar should take to fill for each creature.
	 * This time is calculated relatively between each creature in the battle.
	 * 
	 * Each creature chip in a time to a pot.
	 */
	public static void setUpdateTime(ArrayList<Creature> list) {
		float timePerPerson = 3.0f; // in seconds.
		
		float sum = 0;
		for (int i = 0; i < list.size(); i++) {
			Creature c = list.get(i);
			sum += c.getAttribute(Creature.AGILITY);
		}
		for (int i = 0; i < list.size(); i++) {
			Creature c = list.get(i);
			float updateTime = (c.getAttribute(Creature.AGILITY) / sum);
			updateTime *= list.size() * timePerPerson;
			c.setTime(updateTime);
		}
	}

	/**
	 * Sets all the character in the idling mode to either active or inactive
	 * depending on the given boolean. If a character is active, it is drawn 
	 * in color while inactive results in a black and white drawing.
	 * 
	 * @param active true if the characters should be activated.
	 * (drawn in color)
	 */
	private void setActiveForAll(boolean active) {
		for (int i = 0; i < idling.size(); i++) {
			if (idling.get(i) instanceof Character) {
				idling.get(i).setActive(active);
			}
		}
		queue.setActive(active);
	}

	/**
	 * Sets the battle manager to be used in this battle.
	 * 
	 * @param manager the battle manager to set.
	 */
	protected void setBsattleManager(BattleManager manager) {
		this.manager = manager;
	}

	public void changeMusic(String name) {
		manager.switchMusic(name);
	}
	
	public void changeMusic(String name, int time) {
		manager.switchMusic(name, time);
	}

	public void setDialog(String[] dialog) {
		manager.setDialog(new DialogSequence(dialog));
	}

	private void exit(int exitMode) {
		mode = exitMode;
		if (monster instanceof Boss) {
			Database.addStatus(enemy.getDbName(), 0);
			((Boss) monster).trigger();
		}
	}

	private void exit() {
		exit(BattleManager.EXIT);
	}

	private void gameOver(final int time) {
		mode = Integer.MAX_VALUE;
		new Thread() {
			public void run() {
				Values.sleep(time);
				mode = BattleManager.GAME_OVER;
			}
		}.start();
	}

	public void setMode(int mode) {
		this.mode = mode;
	}
}
