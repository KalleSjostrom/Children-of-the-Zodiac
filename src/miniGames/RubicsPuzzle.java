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
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public class RubicsPuzzle extends AbstractPuzzle {
	
	private boolean horizontal = true;
	
	private String[] marker;
	private int markeroffset = -2;
	
	@Override
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		marker = new String[]{
				ImageHandler.addToCurrentLoadNow(getNNPrefix() + "horizontal.png"),
				ImageHandler.addToCurrentLoadNow(getNNPrefix() + "vertical.png"),
		};
	}
	
	@Override
	protected void scramblePuzzle() {
		Random rand = new Random();
		for (int i = 0; i < 100; i++) {
			switch (rand.nextInt(N)) {
			case 0 : moveLineDown(rand.nextInt(N)); break;
			case 1 : moveLineUp(rand.nextInt(N)); break;
			case 2 : moveLineRight(rand.nextInt(N)); break;
			case 3 : moveLineLeft(rand.nextInt(N)); break;
			}
		}
	}

	protected void checkInput() {
		boolean somethingPressed = true;
		if (gameActions[UP].isPressed()) {
			if (!horizontal) {
				moveLineUp(cursorx);
			} else {
				cursory += ys.length - 1;
				cursory %= ys.length;
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			}
		} else if (gameActions[DOWN].isPressed()) {
			if (!horizontal) {
				moveLineDown(cursorx);
			} else {
				cursory += ys.length + 1;
				cursory %= ys.length;
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			}
		} else if (gameActions[LEFT].isPressed()) {
			if (horizontal) {
				moveLineLeft(cursory);
			} else {
				cursorx += xs.length - 1;
				cursorx %= xs.length;
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			}
		} else if (gameActions[RIGHT].isPressed()) {
			if (horizontal) {
				moveLineRight(cursory);
			} else {
				cursorx += xs.length + 1;
				cursorx %= xs.length;
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			}
		} else if (gameActions[TRIANGLE].isPressed()) {
		} else if (gameActions[CIRCLE].isPressed()) {
			fadingDown = true;
		} else if (gameActions[CROSS].isPressed()) {
			horizontal = !horizontal;
		} else {
			somethingPressed = false;
		}
		if (somethingPressed) {
			isRiddleDone();
		}
	}

	private void moveLineLeft(int x) {
		for (int i = 0; i < N - 1; i++) {
			moveLineRight(x);
		}
	}
	private void moveLineRight(int y) {
		Tile next = tiles[0][y];
		for (int i = 0; i < N; i++) {
			Tile current = next;
			int x = (i + 1) % N;
			next = tiles[x][y];
			tiles[x][y] = current;
			current.setCurrent(x, y);
		}
	}
	private void moveLineUp(int x) {
		for (int i = 0; i < N - 1; i++) {
			moveLineDown(x);
		}
	}
	private void moveLineDown(int x) {
		Tile next = tiles[x][0];
		for (int i = 0; i < N; i++) {
			Tile current = next;
			int y = (i + 1) % N;
			next = tiles[x][y];
			tiles[x][y] = current;
			current.setCurrent(x, y);
		}
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		if (horizontal) {
			g.drawImage(marker[0], xs[0] + markeroffset, ys[cursory] + markeroffset);
		} else {
			g.drawImage(marker[1], xs[cursorx] + markeroffset, ys[0] + markeroffset);
		}
	}
}
