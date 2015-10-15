/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;


/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Sep 2008
 */
public class RotatePuzzle extends Puzzle {

	protected void crossPressed() {
		System.out.println("Rotate");
		Tile last = null;
		
		int xi;
		int yi;
		for (int x = 1; x >= -1; x--) {
			xi = cursorx + x;
			
			switch (x) {
			case -1:
				for (int y = 1; y >= -1; y--) {
					yi = cursory + y;
					last = test(last, xi, yi);
				}
				break;
			default:
				for (int y = 1 - x*2; y <= 1; y++) {
					yi = cursory + y;
					last = test(last, xi, yi);
				}
				break;
			}
		}
		
		xi = cursorx;
		yi = cursory - 1;
		last = test(last, xi, yi);
		
		xi = cursorx + 1;
		test(last, xi, yi);
		
		isRiddleDone();
	}

	private Tile test(Tile last, int xi, int yi) {
		Tile current;
		try {
			current = tiles[xi][yi];
			tiles[xi][yi] = last;
			if (last != null) {
				last.setCurrent(xi, yi);
			}
		} catch (IndexOutOfBoundsException e) {
			current = last;
		}
		return current;
	}
}
