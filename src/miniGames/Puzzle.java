/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import graphics.Graphics;
import graphics.ImageHandler;
import info.SoundMap;

import java.util.Random;

import labyrinth.Labyrinth;
import labyrinth.inventory.Inventory;
import sound.SoundPlayer;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Sep 2008
 */
public class Puzzle extends AbstractPuzzle {
	
	private String marker;
	
	protected int freex; 
	protected int freey;

	private int markeroffset = -2;
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		
		freex = N - 1;
		freey = N - 1;
		
		tiles[N - 1][N - 1].setImage(null);
		
		marker = ImageHandler.addToCurrentLoadNow(getNNPrefix() + "single.png");
	}

	@Override
	protected void scramblePuzzle() {
		int testx = N - 2;
		int testy = N - 1;
		Random rand = new Random();
		for (int i = 0; i < 500; i++) {
			swapTiles(testx, testy, freex, freey);
			switch (rand.nextInt(N)) {
			case 0 : testx++; break;
			case 1 : testx--; break;
			case 2 : testy++; break;
			case 3 : testy--; break;
			}
			if (testx < 0) {testx = 1;}
			if (testx == N) {testx = N - 2;}
			if (testy < 0) {testy = 1;}
			if (testy == N) {testy = N - 2;}
		}
	}

	@Override
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
		} else if (gameActions[CIRCLE].isPressed()) {
			fadingDown = true;
		} else if (gameActions[CROSS].isPressed()) {
			crossPressed();
		}
	}

	protected void crossPressed() {
		if (Math.abs(cursorx - freex) == 1 && cursory == freey) {
			swapTiles(cursorx, cursory, freex, freey);
		} else if (Math.abs(cursory - freey) == 1 && cursorx == freex) {
			swapTiles(cursorx, cursory, freex, freey);
		}
		isRiddleDone();
	}

	private void swapTiles(int ax, int ay, int bx, int by) {
		Tile t = tiles[ax][ay];
		tiles[ax][ay] = tiles[bx][by];
		tiles[bx][by] = t;
		tiles[ax][ay].setCurrent(ax, ay);
		tiles[bx][by].setCurrent(bx, by);
		freex = ax;
		freey = ay;
	}

	@Override
	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		g.drawImage(marker, xs[cursorx] + markeroffset , ys[cursory] + markeroffset);
	}
}
