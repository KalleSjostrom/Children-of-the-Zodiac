/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import graphics.Graphics;

import java.util.ArrayList;

import labyrinth.Labyrinth;
import labyrinth.inventory.Inventory;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Sep 2008
 */
public class GriveraRiddle extends RiddleGame {
	
	private ArrayList<Page> pages = new ArrayList<Page>();
	private int pageNr;
	
	/**
	 * Constructs a new riddle based on the information in the file with the
	 * given name. The given labyrinth is the labyrinth that the riddle is in.
	 * 
	 * @param name the name of the file containing the riddle. 
	 * @param lab the labyrinth where the riddle is.
	 */
	public GriveraRiddle() {}
	
	protected void checkInput() {
		if (pageNr < pages.size()) {
			if (!isRiddleFading()) {
				if (gameActions[CROSS].isPressed()) {
					pageNr++;
					if (pageNr == pages.size()) {
						fadingDown = true;
					}
				}
			}
		}
	}
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		Page p = new Page();
		for (String t : texts) {
			if (t.equals("pagebreak")) {
				pages.add(p);
				p = new Page();
			} else if (t.equals("empty")) {
				p.text.add("");
			} else if (t.startsWith("distance")) {
				p.distance = Integer.parseInt(t.replace("distance=", ""));
			} else {
				p.text.add(t);
			}
		}
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		if (pageNr < pages.size()) {
			g.startText(fade, 0, 28);
			Page p = pages.get(pageNr);
			for (int i = 0; i < p.text.size(); i++) {
				g.drawMultiCenteredText(p.text.get(i), 250 + i * p.distance);
			}
			g.finishText();
		}
	}

	private class Page {
		public int distance = 60;
		ArrayList<String> text = new ArrayList<String>();
	}
}
