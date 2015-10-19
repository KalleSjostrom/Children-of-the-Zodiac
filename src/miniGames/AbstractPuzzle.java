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
import info.Values;

import java.util.StringTokenizer;

import labyrinth.Labyrinth;
import labyrinth.inventory.Button;
import labyrinth.inventory.Inventory;
import sound.SoundPlayer;
import villages.villageStory.Parser;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public abstract class AbstractPuzzle extends RiddleGame {
	
	protected int distance = 125;
	protected int N = 4;
	
	protected Tile[][] tiles;
	
	protected int[] ys;
	protected int[] xs;
	
	protected int cursory = 0;
	protected int cursorx = 0;
	protected String folder = "";
	
	protected String getNNPrefix() {
		return Values.MiniGamesImages + "TileGames/" + folder + "/" + N + "x" + N;
	}
	
	protected void setArray(int[] a, int start) {
		a[0] = start;
		for (int i = 1; i < a.length; i++) {
			a[i] = a[i - 1] + distance;
		}
	}
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		String t = texts.get(0);
		StringTokenizer st = new StringTokenizer(t);
		while (st.hasMoreTokens()) {
			String[] args = Parser.getArgument(st.nextToken());
			String command = args[0];
			String val = args[1];
			if (command.equals("n")) {
				N = Integer.parseInt(val);
			} else if (command.equals("distance")) {
				distance = Integer.parseInt(val);
			} else if (command.equals("folder")) {
				folder = val;
			}
		}
		
		tiles = new Tile[N][N];
		xs = new int[N];
		ys = new int[N];
		
		int x = getImage().getX() + 24;
		int y = getImage().getY() + 24;
		
		setArray(xs, x);
		setArray(ys, y);
		
		for (int i = 0; i < N * N; i++) {
			tiles[i % N][i / N] = new Tile(i % N, i / N,
				ImageHandler.addToCurrentLoadNow(
						getNNPrefix() + (i < 9 ? "0" : "") + (i + 1) + ".png"));
		}
		scramblePuzzle();
	}

	protected abstract void scramblePuzzle();

	protected boolean isRiddleDone() {
		boolean found = false;
		for (int x = 0; x < N && !found; x++) {
			for (int y = 0; y < N && !found; y++) {
				found = !tiles[x][y].isCorrect();
			}
		}
		if (!found) {
			SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET);
			Button.updateDoorStatus(hinders, 1);
			fadingDown = true;
		}
		return !found;
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		for (Tile[] ts : tiles) {
			for (Tile t : ts) {
				t.draw(g, xs, ys);
			}
		}
	}
}
