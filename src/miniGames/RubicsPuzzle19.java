/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import java.util.Arrays;

import info.SoundMap;
import labyrinth.inventory.Button;
import sound.SoundPlayer;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public class RubicsPuzzle19 extends RubicsPuzzle {
	
	@Override
	protected void scramblePuzzle() {}
	
	@Override
	protected boolean isRiddleDone() {
		int[] row = new int[N];
		int[] col = new int[N];
		int[] dia = new int[N];
		int diaIndex = 0;
		int[] dia2 = new int[N];
		int diaIndex2 = 0;
		int A = N - 1;
		for (int x = 0; x < N; x++) {
			for (int y = 0; y < N; y++) {
				String s = tiles[x][y].getImage();
				s = s.replace(N + "x" + N, "");
				s = s.replace(".png", "");
				String[] sa = s.split("/");
				int nr = Integer.parseInt(sa[sa.length - 1]);
				col[x] += nr;
				row[y] += nr; 
				if (x == y) {
					dia[diaIndex++] += nr;
				}
				if (y == A) {
					dia2[diaIndex2++] += nr;
					A--;
				}
			}
		}
		boolean found = false;
		switch (N) {
		case 3:
			found = isFound(15, row, col, dia, dia2);
			break;
		case 5:
			found = isFound(65, row, col, dia, dia2);
			break;
		}
		if (!found) {
			SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET);
			Button.updateDoorStatus(hinders, 1);
			fadingDown = true;
		}
		return !found;
	}

	private boolean isFound(int magicSum, int[] row, int[] col, int[] dia, int[] dia2) {
		boolean found = false;
		System.out.println();
		System.out.println("Row " + Arrays.toString(row));
		System.out.println("Col " + Arrays.toString(col));
		for (int i = 0; i < row.length && !found; i++) {
			found = row[i] != magicSum;
		}
		if (found) return true;
		
		for (int i = 0; i < col.length && !found; i++) {
			found = col[i] != magicSum;
		}
		if (found) return true;
		
		int sum = 0;
		for (int i = 0; i < dia.length; i++) {
			sum += dia[i];
		}
		found = sum != magicSum;
		if (found) return true;
		
		System.out.println("Dia " + sum);
		sum = 0;
		for (int i = 0; i < col.length; i++) {
			sum += dia2[i];
		}
		found = sum != magicSum;
		System.out.println("Dia2 " + sum);
		System.out.println("Found errors " + found);
		return found;
	}
	
}
