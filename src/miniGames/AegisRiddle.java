/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import graphics.Graphics;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public class AegisRiddle extends RiddleGame {
	
	private static final int SPLIT = 2;
	private int pageNr = 0;
	
	/**
	 * Constructs a new riddle based on the information in the file with the
	 * given name. The given labyrinth is the labyrinth that the riddle is in.
	 * 
	 * @param name the name of the file containing the riddle. 
	 * @param lab the labyrinth where the riddle is.
	 */
	public AegisRiddle() {}
	
	protected void checkInput() {
		if (pageNr < SPLIT) {
			if (!isRiddleFading()) {
				if (gameActions[CROSS].isPressed()) {
					pageNr++;
					if (pageNr == SPLIT) {
						fadingDown = true;
					}
				}
			}
		}
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		if (pageNr < SPLIT) {
			g.setFontSize(28);
			int half = texts.size() / 2;
			int start = pageNr * half;
			int end = start + half;
			for (int i = start; i < end; i++) {
				g.drawStringCentered(texts.get(i), 250 + (i - start) * 50);
			}
		}
	}
}
