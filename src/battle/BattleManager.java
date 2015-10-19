/*
 * Classname: BattleManager.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package battle;

import factories.EnemyFactory;
import factories.Load;
import factories.EnemyFactory.EnemyGroup;
import graphics.Graphics;
import graphics.Object2D;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import java.util.logging.*;

import labyrinth.LabyrinthDrawable;

import organizer.GameMode;

import villages.utils.DialogSequence;
import battle.character.CharacterRow;
import battle.character.EnemyRow;
import battle.enemy.BattleEnemy;
import character.Character;
import character.Enemy;

/**
 * This class manages the battle. The battle is taking place inside the 
 * labyrinths so it is in 3D. The battles are updated by the labyrinth 
 * and the organizer has nothing to do with it. This class has some
 * object2D's that it draws, like the enemy in the middle, the characters
 * on both sides of the screen. It uses an instance of Battle to do
 * most of the logic behind the battle.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 24 May 2008.
 */
public class BattleManager extends GameMode implements LabyrinthDrawable {
	
	public static final int IDLING = 0;
	public static final int BATTLING = 1;
	public static final int ENEMY_TURN = 2;
	public static final int GAME_OVER = 3;
	public static final int ANIMATE = 4;
	public static final int RESULT = 5;
	public static final int EXIT = 6;
	public static final int TALKING = 7;
	public static final int EXIT_TO_NEXT = 8;
	public static final int SPOILS = 9;
	public static final int WAITING = 10;
	public static final int TUTORIAL = 11;

	protected static final int THREE_ENEMIES = 1;
	protected static final int TWO_ENEMIES = 0;
	
	private static Logger logger = Logger.getLogger("BattleManager");
	
	public Battle battle;

	private ArrayList<Object2D> objects;
	private BattleEnemy enemy;
	private CharacterRow characters;
	private EnemyRow enemies;
	private BattleStarter starter;
	private boolean fadeBattleMusic = true;

	/**
	 * initiates the game mode with the given information.
	 * 
	 * @param info the information to base the manager on. 
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_INIT);
		objects = new ArrayList<Object2D>();
		boolean boss = Boolean.parseBoolean(info.get("boss"));
		EnemyFactory ef = EnemyFactory.getEnemyFactory();
		Enemy en;
		float[] freq;
		if (boss) {
			en = ef.getBoss(info.get("name"));
			freq = new float[]{0, 0};
		} else {
			EnemyGroup eg = ef.getEnemyGroup(info.get("name"));
			en = eg.getRandomEnemy();
			freq = eg.getFrequency(en);
		}
		
		battle = new Battle(boss, en, freq, this);
		characters = battle.getCharacterRow();
		enemies = battle.getEnemyRow();
		enemy = battle.getEnemy();
		ArrayList<Character> chars = Load.getCharacters();
		for (int i = 0; i < chars.size(); i++) {
			Character c = chars.get(i);
			c.resetBattleStats();
			logger.log(Level.FINE, "Character " + c.getName() + " has hp: " + c.getLife());
		}
		objects.add(enemy);
		objects.add(characters);
		objects.add(enemies);
		gameActions[GameMode.RIGHT].changeBehavior(Values.DETECT_AS_KEY);
		gameActions[GameMode.LEFT].changeBehavior(Values.DETECT_AS_KEY);
		
		logicLoading = false;
		loadingDone();
		battle.init();
	}

	/**
	 * Sets the labyrinth that initiated this battle so that, when the
	 * battle is over, this given labyrinths method leaveBattle() can be 
	 * called.
	 * 
	 * @param labyrinth the labyrinth to set.
	 */
	public void setBattleStarter(BattleStarter starter) {
		this.starter = starter;
	}

	/**
	 * Implements the update method from the GameMode class. 
	 * This method is called as long as the battle is active and with the
	 * interval from the StaticValues class. Normally between 30 and 50 
	 * milliseconds.
	 * 
	 * @param elapsedTime the time that has elapsed since the game was 
	 * last updated.
	 */
	public void update(float elapsedTime) {
		battle.update(elapsedTime);
		
		switch (battle.getMode()) {
		case BATTLING : 
			if (gameActions[GameMode.UP].isPressed()) {
				battle.upPressed();
			} else if (gameActions[GameMode.RIGHT].isPressed()) {
				battle.rightPressed();
			} else if (gameActions[GameMode.DOWN].isPressed()) {
				battle.downPressed();
			} else if (gameActions[GameMode.LEFT].isPressed()) {
				battle.leftPressed();
			} else if (gameActions[GameMode.TRIANGLE].isPressed()) {
				battle.trianglePressed();
			} else if (gameActions[GameMode.CIRCLE].isPressed()) {
				battle.circlePressed();
			} else if (gameActions[GameMode.CROSS].isPressed()) {
				battle.crossPressed();
			} else if (gameActions[GameMode.SQUARE].isPressed()) {
				battle.squarePressed();
			} else if (gameActions[GameMode.R1].isPressed()) {
				battle.R1Pressed();
			} else if (gameActions[GameMode.L1].isPressed()) {
				battle.L1Pressed();
			} else if (gameActions[GameMode.SELECT].isPressed()) {
//				battle.toggleHelp();
				battle.switchMode(BattleManager.EXIT);
				mode = BattleManager.EXIT;
				exit();
			} else {
				boolean r2 = gameActions[GameMode.R2].isPressedDontReset();
				boolean l2 = gameActions[GameMode.L2].isPressedDontReset();

				if (r2 && l2) {
					battle.flee();
				} else if (gameActions[GameMode.R2].isPressed()) {
					battle.R2Pressed();
				} else if (gameActions[GameMode.L2].isPressed()) {
					battle.L2Pressed();
				} else {
					battle.resetFlee();
				}
			}
			break;
		case EXIT :
			exit();
			break;
		case EXIT_TO_NEXT :
			starter.exit(nextPlace, fadeBattleMusic );
			break;
		case GAME_OVER :
			starter.gameOver();
			battle.setMode(WAITING);
			break;
		default : 
			if (gameActions[GameMode.CROSS].isPressed()) {
				battle.crossPressed();
			}
		}
		super.update(elapsedTime);
	}
	
	private void exit() {
		if (starter != null) {
			starter.leaveBattle();
		}
		ArrayList<Character> list = Load.getCharacters();
		for (int i = 0; i < list.size(); i++) {
			list.get(i).resetBattleStats();
		}
	}

	public int getBattleMode() {
		return battle.getMode();
	}

	/**
	 * This method initiates the drawing of all the objects in this manager.
	 * It also initiates the drawing in the battle.
	 * 
	 * @param gl the GL to initiate the drawings on.
	 */
	public void initDraw(Graphics g) {
		for (int i = 0; i < objects.size(); i++) {
			Object2D o = objects.get(i);
			o.initDraw(g);
		}
		battle.initDraw(g);
	}

	/**
	 * Draws the battle.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.loadIdentity();
		for (int i = 0; i < objects.size(); i++) {
			objects.get(i).draw(g);
		}
		battle.drawBattle(g);
	}

	/**
	 * This method pauses the battle music and resumes the music
	 * in the labyrinth.
	 */
	public void switchMusic(String music) {
		switchMusic(music, 500);
	}

	public void switchMusic(String music, int fadeSpeed) {
		System.out.println("Switch music " + music);
		starter.notifySwitchMusic(music, fadeSpeed);
	// 	super.switchMusic(music, fadeSpeed);
	}

	public void setNextPlace(String next) {
		nextPlace = next;
	}
	
	String prevName = "";
	boolean first = false;

	public void setDialog(DialogSequence dialog) {
		if (dialog == null) {
			starter.exitDialog();
		} else {
			starter.drawDialog(dialog);
		}
	}

	public void drawTopLayer(Graphics g) {
		for (int i = 0; i < objects.size(); i++) {
			objects.get(i).drawTopLayer(g);
		}
		battle.drawTopLayer(g);
	}

	public void dontFadeBattleMusic() {
		fadeBattleMusic = false;
		starter.overwriteStarterMusic(music, oggPlayer);
	}
//	public void overwriteStarterMusic() {
//	}
}
