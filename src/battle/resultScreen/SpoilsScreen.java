/*
 * Classname: SpoilsScreen.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package battle.resultScreen;

import info.Database;
import info.Values;

import java.awt.Color;
import java.util.ArrayList;
import java.util.Random;

import battle.bars.LevelUpBar;
import character.Bestiary;
import character.Character;
import character.Creature;
import character.Enemy;
import equipment.Items;
import factories.Load;
import graphics.Graphics;

/**
 * The spoils screen is the one displaying the spoils of battle, how much 
 * gold and experience one found. The level up result screen is the one 
 * displaying the result of a level up.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 26 Dec 2008
 */
public class SpoilsScreen extends Screen {

	private static final int BAR_HEIGHT_DISTANCE = 35;
	private static final int[] x = new int[]{230, 335, 555, 680};
	private static final int[] y = new int[]{240, 275, 310, 345, 380, 415, 450, 485};

	public static final int HP = 0;
	public static final int DEFENSE = 1;
	public static final int MAGIC_DEFENSE = 2;
	public static final int ATTACK = 3;
	public static final int MAGIC_ATTACK = 4;
	public static final int SUPPORT = 5;
	public static final int LEVEL = 6;
	public static final int LAST_STEP = 6;

	private static final int DECREASE_MILLISECONDS = 700;

//	private ArrayList<Character> levelUps = new ArrayList<Character>();

	private LevelUpBar[] bars = new LevelUpBar[4];

	private int exp;
	private int gold;
	private int step = 0;
	private Items.Item droppedItem;
	private LevelInfo[] info = new LevelInfo[4]; 

	private boolean done = false;
	private boolean pause;

	/**
	 * Creates a new result screen that should display the spoils of battle.
	 * 
	 * @param enemy an instance of the enemy that the party defeated.
	 * @param enemySize the number of such enemy that the party has defeated.
	 */
	public SpoilsScreen(Enemy enemy, int enemySize) {
		for (int i = 0; i < info.length; i++) {
			info[i] = new LevelInfo();
		}
		calcSpoils(enemy, enemySize);
		new Thread() {
			public void run() {
				Values.sleep(200);
				while (!done) {
					if (pause) {
						Values.sleep(70);
					} else {
						Values.sleep(DECREASE_MILLISECONDS);
						next();
					}
				}
			}
		}.start();
	}

	/**
	 * Calculates the spoils gotten when defeating enemySize number of enemies
	 * of the same type as enemy.   
	 * 
	 * @param enemy an instance of the enemy that the party defeated.
	 * @param enemySize the number of such enemy that the party has defeated.
	 */
	private void calcSpoils(Enemy enemy, int enemySize) {
		getSpoils(enemy, enemySize);
		float totalNrOfRounds = 0;
		ArrayList<Character> characters = Load.getCharacters();
		for (int i = 0; i < characters.size(); i++) {
			totalNrOfRounds += characters.get(i).getRoundCounter();
		}
		float amountOfDecreases = DECREASE_MILLISECONDS / (float) Values.LOGIC_INTERVAL;
		
		Bestiary.getBestiary().updateStats(enemy, enemySize);
		Load.getPartyItems().incrementBattle();
		Load.getPartyItems().addGold(gold);
		float varryExp = .1f * exp;
		float staticExp = .9f * exp;
		float staticFraction = 1.0f / characters.size();
		exp = 0;
		for (int i = 0; i < characters.size(); i++) {
			Character c = characters.get(i);
			if (c.isAlive()) {
				float varryingFraction = c.getRoundCounter() / totalNrOfRounds;
				int gottenExp = Math.round(varryingFraction * varryExp + staticFraction * staticExp);
				info[i].expDecrease = gottenExp / amountOfDecreases;
				info[i].expCounter = info[i].recievedExp = gottenExp;
				info[i].canLevelUp = c.canLevelUp();
				info[i].expToNext = c.getExpToNextLevel();
				info[i].expLeftToNextLevel = c.getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL);
				
				exp += gottenExp;
				if (info[i].canLevelUp) {
					c.addAttribute(Creature.EXPERIANCE, gottenExp);
					int cnext = c.getAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL);
					if (gottenExp <= cnext) {
						c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -gottenExp);
						info[i].all = gottenExp;
					} else {
						c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -cnext);
						info[i].all = cnext;
						info[i].rest = gottenExp - cnext;
						Character.levelUp(c);
						c.addAttribute(Creature.EXP_LEFT_TO_NEXT_LEVEL, -info[i].rest);
					}
				}
				info[i].expToNextNext = c.getExpToNextLevel();
			}
		}
	}

	private void getSpoils(Enemy enemy, int enemySize) {
		exp = 0;
		gold = 0;
		Random r = new Random();
		for (int i = 0; i < enemySize; i++) {
			float number = r.nextFloat() / 5f; // get val between 0 and .2
			float precent = .9f + number; // between 90 % and 110 %
			exp += Math.round(enemy.getSpoilExp() * precent);

			number = r.nextFloat() / 5f;
			precent = .9f + number; // between 90 % and 110 %
			gold += Math.round(enemy.getSpoilGold() * precent);
		}
		int status = Database.getStatusFor(enemy.getDbName() + "drop");
		if (status != 0 && Math.random() < enemy.getDropRate()) {
			droppedItem = enemy.getSpoilItem();
			Load.getPartyItems().addItem(droppedItem);
			Database.addStatus(enemy.getDbName() + "drop", 0);
		}
	}

	public void update(float elapsedTime) {
		ArrayList<Character> characters = Load.getCharacters();
		for (int i = 0; i < characters.size(); i++) {
			if (step > 1 + i) {
				Character c = characters.get(i);
				if (c.isAlive()) {
					step = info[i].update(elapsedTime, step, i == characters.size() - 1);
				}
			}
		}
	}

	/**
	 * Draws the spoils of battle on the given graphics. This method will also
	 * draw the level up screen if the player has leveled up and already seen 
	 * the spoils. Just call this method to draw the spoils and level up screen
	 * until the next() returns true.
	 * 
	 * @see #next()
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawSpoils(Graphics g) {
		drawBackground(g);
		drawSpoil(g);
	}

	/**
	 * Draws the spoils of battle on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	private void drawSpoil(Graphics g) {
		g.setFontSize(26);
		g.drawWithShadow("Result", 200, y[0]);

		int totalgold = Load.getPartyItems().getGold();
		if (step > 0) {
			g.drawWithShadow("The enemy dropped " + gold + " gp, " + 
					"total: " + totalgold + " gp", x[0], y[1]);
			g.drawWithShadow("The party got " + exp + " exp.", x[0], y[2]);
		}

		ArrayList<Character> characters = Load.getCharacters();
		for (int i = 0; i < characters.size(); i++) {
			if (step > 1 + i) {
				Character c = characters.get(i);
				if (c.isAlive()) {
					Color color = Color.WHITE;
					boolean canLevelUp = info[i].canLevelUp;

					if (info[i].hasLeveledUp) {
						color = Color.GREEN;
						g.drawWithShadow("Level up!", x[3], y[3 + i], color);
						g.drawWithShadow(Math.round(info[i].recievedExp) + " exp", x[2], y[3 + i], color);
					} else if (!canLevelUp) {
						g.drawWithShadow("Max level", x[3], y[3 + i], Color.RED);
						g.drawWithShadow("0 exp", x[2], y[3 + i], Color.RED);
					} else {
						g.drawWithShadow(Math.round(info[i].recievedExp) + " exp", x[2], y[3 + i], Color.WHITE);
					}
					drawBars(g, i, info[i].etn, canLevelUp);

					g.drawWithShadow(c.getName(), x[0], y[3 + i], color);
				} else {
					g.drawWithShadow(c.getName(), x[0], y[3 + i], Color.RED);
				}
			}
		}
		if (step >= 2 + characters.size() && droppedItem != null) {
			g.drawWithShadow("You found " + droppedItem.getName() + " laying on the ground!", x[0], y[3 + 4]);
		}
	}

	/**
	 * Draws the experience bars showing the amount of experience left 
	 * for a level up.
	 *   
	 * @param g the graphics to draw on
	 * @param barIndex the index in bars for the bar to draw.
	 * @param progress the progress of this bar. The value between 0 and 1
	 * representing the percent of the bar to fill.
	 * @param b 
	 */
	private void drawBars(Graphics g, int barIndex, float progress, boolean canLevelUp) {
		if (bars[barIndex] == null) {
			bars[barIndex] = new LevelUpBar();
		}
		bars[barIndex].update(progress);
		bars[barIndex].draw(g, x[1], 330 + barIndex * BAR_HEIGHT_DISTANCE, canLevelUp);
	}

	/**
	 * Advances the screen one step. This will cause the screen to draw
	 * something new or to end if it is done.
	 */
	private void next() {
		step++;
		if (step > Load.getCharacters().size()) {
			pause = true;
		}
	}

	/**
	 * Called when the user presses the cross button. It wall cause the 
	 * spoils screen to skip ahead to the last piece of information.
	 * If the screen is already there it will return true because it is done.
	 *  
	 * @return true if the screen is done.
	 */
	public boolean crossPressed() {
		if (step > Load.getCharacters().size()) {
			pause = false;
			done = true;
		} else {
			step = 100;
			pause = true;
		}
		return done;
	}
	
	public class LevelInfo {
		
		public int rest;
		public int all;
		private float expCounter;
		private float expToNext;
		private float expToNextNext;
		private float expLeftToNextLevel;
		private float etn;
		private float expDecrease;
		private float recievedExp;
		private boolean hasLeveledUp;
		private boolean canLevelUp;
		
		public int update(float elapsedTime, int step, boolean updateStep) {
			if (canLevelUp) {
				if (expCounter > 0) {
					expCounter -= expDecrease;
					updateETN();
					
					if (etn >= 1) {
						expToNext = expToNextNext;
						expLeftToNextLevel = expToNextNext;
						all = rest;
						rest = 0;
						hasLeveledUp = true;
						
						updateETN();
					}
				} else if (updateStep) {
					step = Math.max(Load.getCharacters().size() + 2, step);
				}
			}
			return step;
		}
		
		private void updateETN() {
			float ec = expCounter - rest;
			float y = expLeftToNextLevel;
			y = y + (ec - all);
			float x = expToNext;
			etn = (x - y) / x;
		}
	}
}
