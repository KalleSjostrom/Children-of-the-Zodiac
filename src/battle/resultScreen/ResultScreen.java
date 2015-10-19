/*
 * Classname: ResultScreen.java
 * 
 * Version information: 0.7.0
 *
 * Date: 26/12/2008
 */
package battle.resultScreen;

import graphics.Graphics;

import java.awt.Color;
import java.util.ArrayList;

import java.util.logging.*;

import battle.HitElement;
import cards.Card;
import character.Creature;
import character.Enemy;

/**
 * Manages the result screen in battle. The basic result screen
 * is the one displaying the result of a normal attack
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 26 Dec 2008
 */
public class ResultScreen extends Screen {
	
	private static final int[] X_POS = new int[]{200, 330, 460, 590, 720};
	private static final int[] Y_POS = new int[]{240, 275, 310, 345, 380};
	
	private ArrayList<Card> cards = new ArrayList<Card>();
	private ArrayList<Creature> team = new ArrayList<Creature>();
	
	private static Logger logger = Logger.getLogger("ResultScreen");
	
	private int[][] attack;

	/**
	 * Creates a new result screen with the given target team and
	 * index of the targeted creature.
	 *  
	 * @param selTeam the list of creature in the team containing the 
	 * targeted creature.
	 */
	public void init(ArrayList<Creature> selTeam) {
		team.clear();
		for (int i = 0; i < selTeam.size(); i++) {
			Creature c = selTeam.get(i);
			if (c instanceof Enemy) {
				Enemy e = (Enemy) c;
				c = e.copy();
			}
			team.add(c);
		}
	}
	
	/**
	 * Sets the list of hit elements that the result should be based upon.
	 * 
	 * @param list the list of hit elements to set.
	 */
	public void setHitElements(ArrayList<HitElement> list) {
		cards.clear();
		for (int i = 0; i < team.size(); i++) {
			team.get(i).resetTempValues();
		}	
		for (int i = 0; i < list.size(); i++) {
			cards.add(list.get(i).getCard());
		}
		calcResult(list);
	}
	
	/**
	 * Calculates the result of one round of battle.
	 * 
	 * @param hitElements the list of hit elements that the result should be
	 * based upon.
	 */
	private void calcResult(ArrayList<HitElement> hitElements) {
		attack = new int[team.size()][3];
		
		logger.log(Level.FINE, "Hitting creature: " + team.get(0).getName());
		for (int i = 0; i < hitElements.size(); i++) {
			HitElement h = hitElements.get(i);
			int att = h.getAttackDamage(0);
			int index = h.getTest();
			if (h.onAll()) {
				for (int j = 0; j < team.size(); j++) {
					if (!h.isMiss(j)) {
						attack[j][h.getType()] += h.getAttackDamage(j);
					} else {
						logger.log(Level.FINE, "Missing creature " + j);
					}
				}
			} else if (!h.isMiss(index)) {
				attack[index][h.getType()] += att == -2 ? 0 : att;
			} else {
				logger.log(Level.FINE, "Miss!");
			}
		}
	}
	
	private Color selectColor(int value, Color high, Color low) {
		if (value > 0)
			return high;
		if (value < 0)
			return low;
		return Color.white;
	}

	public void drawResult(Graphics g) {
		drawBackground(g);

		int[] x = X_POS;
		int[] y = Y_POS;

		g.setFontSize(26);
		g.drawWithShadow("Result", x[0], y[0]);
		g.drawWithShadow("Attack", x[0], y[1]);
		g.drawWithShadow("Magic", x[0], y[2]);
		g.drawWithShadow("Support", x[0], y[3]);
		g.drawWithShadow("Total", x[0], y[4]);
		
		for (int i = 0; i < team.size(); i++) {
			Creature c = team.get(i);
			g.drawWithShadow(c.getName(), x[i + 1], y[0]);
			for (int j = 0; j < 3; j++) {
				int value = attack[i][j];
				g.drawWithShadow(String.valueOf(value), x[1 + i], y[j + 1], selectColor(value, j < 2 ? Color.red : Color.green, j < 2 ? Color.green : Color.red));
			}
			int total = attack[i][0] + attack[i][1] - attack[i][2];
			g.drawWithShadow(String.valueOf(Math.abs(total)), x[i + 1], y[4], selectColor(total, Color.red, Color.green));
		}
//		g.loadIdentity();
		for (int i = 0; i < cards.size(); i++) {
			Card c = cards.get(i);
			if (c != null) {
				c.drawCard(g, 175 + (i * 80), 385);
			}
		}
	}
}
