/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import graphics.Graphics;
import info.SoundMap;
import info.Values;

import java.awt.Color;

import com.jogamp.opengl.GL2;

import sound.SoundPlayer;

import labyrinth.Labyrinth;
import labyrinth.inventory.Button;
import labyrinth.inventory.Inventory;
import menu.MenuHand;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 25 Sep 2008
 */
public class HateRiddle extends RiddleGame {
	
	private MenuHand hand = new MenuHand(Values.RIGHT);
	private int[] ys = new int[]{260, 340, 420};
	private int[] xs = new int[]{435, 505, 565};
	private int cursory = 0;
	private int cursorx = 0;
	private String choosenCode = "____";
	
	/**
	 * Constructs a new riddle based on the information in the file with the
	 * given name. The given labyrinth is the labyrinth that the riddle is in.
	 * 
	 * @param name the name of the file containing the riddle. 
	 * @param lab the labyrinth where the riddle is.
	 */
	public HateRiddle() {}
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		hand.setVisible(true);
		hand.setXpos(xs[cursorx]);
		hand.setYpos(ys[cursory]);
	}

	/**
	 * Checks the input for changes.
	 */
	protected void checkInput() {
		if (gameActions[UP].isPressed()) {
			cursory += ys.length - 1;
			cursory %= ys.length;
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		} else if (gameActions[DOWN].isPressed()) {
			cursory += ys.length + 1;
			cursory %= ys.length;
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		} else if (gameActions[LEFT].isPressed()) {
			cursorx += xs.length - 1;
			cursorx %= xs.length;
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		} else if (gameActions[RIGHT].isPressed()) {
			cursorx += xs.length + 1;
			cursorx %= xs.length;
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
		} else if (gameActions[TRIANGLE].isPressed()) {
			isRiddleDone();
		} else if (gameActions[CIRCLE].isPressed()) {
			isRiddleDone();
			fadingDown = true;
		} else if (gameActions[CROSS].isPressed()) {
			if (choosenCode.contains("_")) {
				choosenCode = choosenCode.replace("_", "");
				choosenCode += (cursory * 3 + cursorx + 1);
				while (choosenCode.length() < 4) {
					choosenCode += "_";
				}
			}
			if (!isRiddleDone() && !choosenCode.contains("_")) {
				choosenCode = "____";
				SoundPlayer.playSound(SoundMap.ERROR);
			}
		}

		hand.setXpos(xs[cursorx] - hand.getXOffset());
		hand.setYpos(ys[cursory] - hand.getYOffset());
	}
	
	private boolean isRiddleDone() {
		boolean done = choosenCode.equals("8145");
		if (done) {
			SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET);
			Button.updateDoorStatus(hinders, 1);
			fadingDown = true;
		}
		return done;
	}

	public void initDraw(GL2 gl) {
		// TODO
	}
	
	/**
	 * Draws the riddle on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		g.setFontSize(36);
		Graphics.setTextColor(Color.BLACK);
		g.startText(fade, -1);
		for (int j = 0; j < ys.length; j++) {
			for (int i = 0; i < xs.length; i++) {
				g.drawMultiString((j * 3 + i + 1) + "", xs[i], ys[j]);
			}
		}
		char[] ca = choosenCode.toCharArray();
		StringBuffer sb = new StringBuffer();
		for (char c : ca) {
			sb.append(c + " ");
		}
		g.drawMultiCenteredText(sb.toString(), ys[2] + 80);
		g.finishText();
		hand.drawHand(g);
	}
}
