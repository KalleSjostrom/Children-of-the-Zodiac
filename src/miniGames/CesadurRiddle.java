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
import java.util.Stack;
import com.jogamp.opengl.GL2;
import organizer.GameMode;
import sound.SoundPlayer;
import labyrinth.Labyrinth;
import labyrinth.inventory.Button;
import labyrinth.inventory.Inventory;
import menu.AbstractPage;
import menu.MenuHand;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public class CesadurRiddle extends RiddleGame {
	
	private static final int MIDDLE = 6;
	private static final int LINE_LENGTH = 20;
	private static final int WORD_LENGTH = 7;
	
	private MenuHand hand = new MenuHand(Values.RIGHT);
	private MenuHand wordHand = new MenuHand(Values.RIGHT);
	private int[] ys = new int[]{250, 340, 430};
	private int[] xs = new int[]{220, 220 + (MIDDLE + WORD_LENGTH) * Text.OFFSET};
	private int cursory = 0;
	private int cursorx = 0;
	private Text[][] texts = new Text[xs.length][ys.length];
	private Stack<State> states = new Stack<State>();
	
	private static final int SELECT_WORD = 0;
	private static final int SELECT_LETTER = 1;
	private int mode = SELECT_WORD;
	private Text currentWord;
	
	/**
	 * Constructs a new riddle based on the information in the file with the
	 * given name. The given labyrinth is the labyrinth that the riddle is in.
	 * 
	 * @param name the name of the file containing the riddle. 
	 * @param lab the labyrinth where the riddle is.
	 */
	public CesadurRiddle() {}
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		super.init(name, lab, hinders);
		wordHand.setVisible(true);
		wordHand.setXpos(xs[cursorx]);
		wordHand.setYpos(ys[cursory]);
		hand.setVisible(false);
		hand.setXpos(xs[0]);
		hand.setYpos(ys[2]);
		
		for (int i = 0; i < xs.length; i++) {
			for (int j = 0; j < ys.length - 1; j++) {
				texts[i][j] = new Text("", xs[i], ys[j], WORD_LENGTH);
			}
		}
		
		texts[0][ys.length - 1] = new Text("HUMAN ATONE OR STREW", xs[0], ys[ys.length - 1], LINE_LENGTH);
	}

	/**
	 * Checks the input for changes.
	 */
	protected void checkInput() {
		switch (mode) {
		case SELECT_WORD:
			checkSelectWordInput();
			break;
		case SELECT_LETTER:
			checkSelectLetterInput();
			break;
		}
	}
	
	private void checkSelectWordInput() {
		Text t = getCurrentText();
		if (gameActions[UP].isPressed()) {
			if (cursory != 0) {
				cursory--;
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[DOWN].isPressed()) {
			if (cursory != ys.length - 2) {
				cursory++;
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[LEFT].isPressed()) {
			if (cursorx != 0) {
				cursorx--;
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[RIGHT].isPressed()) {
			if (cursorx != xs.length - 1) {
				cursorx++;
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[CIRCLE].isPressed()) {
			if (!states.isEmpty()) {
				State s = states.pop();
				s.reverse();
				SoundPlayer.playSound(SoundMap.MENU_BACK);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[SQUARE].isPressed()) {
			isRiddleDone();
		} else if (gameActions[TRIANGLE].isPressed()) {
			isRiddleDone();
			fadingDown = true;
		} else if (gameActions[CROSS].isPressed()) {
			if (!texts[0][2].isEmpty()) {
				currentWord = getCurrentText();
				mode = SELECT_LETTER;
				wordHand.setDimmed(true);
				hand.setVisible(true);
				hand.setDimmed(false);
				cursorx = 0;
				cursory = 2;
				t = getCurrentText();
				int offset = t != null ? t.getOffset() : 0;
				if (cursory == ys.length - 1) {
					hand.setXpos(xs[0] - hand.getXOffset() + offset);
				} else {
					hand.setXpos(xs[cursorx] - hand.getXOffset() + offset);
				}
				hand.setYpos(ys[cursory] - hand.getYOffset());
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		}
		if (!wordHand.isDimmed()) {
			t = getCurrentText();
			int offset = t != null ? t.getOffset() : 0;
			if (cursory == ys.length - 1) {
				wordHand.setXpos(xs[0] - wordHand.getXOffset() + offset);
			} else {
				wordHand.setXpos(xs[cursorx] - wordHand.getXOffset() + offset);
			}
			wordHand.setYpos(ys[cursory] - wordHand.getYOffset());
		}
	}
	
	private void checkSelectLetterInput() {
		Text t = getCurrentText();
		if (gameActions[UP].isPressed()) {
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			switchToWordMode(1);
			return;
		} else if (gameActions[DOWN].isPressed()) {
			SoundPlayer.playSound(SoundMap.ERROR);
		} else if (gameActions[LEFT].isPressed()) {
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			if (t != null) {
				t.left();
			}
		} else if (gameActions[RIGHT].isPressed()) {
			SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
			if (t != null) {
				t.right();
			}
		} else if (gameActions[CIRCLE].isPressed()) {
			if (!states.isEmpty()) {
				State s = states.pop();
				s.reverse();
				SoundPlayer.playSound(SoundMap.MENU_BACK);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
		} else if (gameActions[SQUARE].isPressed()) {
			isRiddleDone();
		} else if (gameActions[TRIANGLE].isPressed()) {
			isRiddleDone();
			fadingDown = true;
		} else if (gameActions[CROSS].isPressed()) {
			if (t != null && t.hasLetter()) {
				if (currentWord.hasRoom()) {
					Text.Letter l = new Text.Letter("", 0, 0);
					l.letter = t.pickUp();
					int insertIndex = currentWord.insert(l);

					State s = new State(l.letter, t.cursor, t, insertIndex, currentWord);
					states.push(s);
					SoundPlayer.playSound(SoundMap.MENU_ACCEPT);
					if (t.isEmpty()) {
						switchToWordMode(1);
						return;
					}
				} else {
					SoundPlayer.playSound(SoundMap.ERROR);
				}
			}
		}
		int offset = t != null ? t.getOffset() : 0;
		if (cursory == ys.length - 1) {
			hand.setXpos(xs[0] - hand.getXOffset() + offset);
		} else {
			hand.setXpos(xs[cursorx] - hand.getXOffset() + offset);
		}
		hand.setYpos(ys[cursory] - hand.getYOffset());
	}
	
	private void switchToWordMode(int i) {
		Text t = getCurrentText();
		cursory = i;
		mode = SELECT_WORD;
		wordHand.setDimmed(false);
		hand.setDimmed(true);
		t = getCurrentText();
		int offset = t != null ? t.getOffset() : 0;
		if (cursory == ys.length - 1) {
			wordHand.setXpos(xs[0] - wordHand.getXOffset() + offset);
		} else {
			wordHand.setXpos(xs[cursorx] - wordHand.getXOffset() + offset);
		}
		wordHand.setYpos(ys[cursory] - wordHand.getYOffset());
	}

	private boolean isRiddleDone() {
		boolean done = texts[0][0].toString().equals("SUN");
		done = done && texts[0][1].toString().equals("EARTH");
		done = done && texts[1][0].toString().equals("MOON");
		done = done && texts[1][1].toString().equals("WATER");
		if (done) {
			SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET);
			Button.updateDoorStatus(hinders, 1);
			fadingDown = true;
		} else {
			SoundPlayer.playSound(SoundMap.MENU_ERROR);
		}
		return done;
	}

	public void initDraw(GL2 gl) {
		// TODO
	}
	
	private Text getCurrentText() {
		Text t;
		if (cursory == ys.length - 1) {
			t = texts[0][cursory];
		} else {
			t = texts[cursorx][cursory];
		}
		return t;
	}
	
	/**
	 * Draws the riddle on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(float dt, Graphics g) {
		
	}

	public void drawTopLayer(Graphics g) {
		super.drawTopLayer(g);
		g.setColor(0, 0, 0, 1);
		for (int i = 0; i < xs.length; i++) {
			for (int j = 0; j < ys.length - 1; j++) {
				if (texts[i][j] != null) {
					texts[i][j].draw(g);
				}
			}
		}
		if (mode == SELECT_WORD) {
			g.setColor(0, 0, 0, .3f);
		}
		texts[0][ys.length - 1].draw(g);
		hand.drawHand(g);
		wordHand.drawHand(g);
		drawHelp(g);
	}
	
	private void drawHelp(Graphics g) {
		int helpx = xs[0] + 20;
		int helpy = 510;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;
		
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + 110, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], helpxicons + 295, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 500, helpyicons);
		
		g.drawString("Exit", helpx, helpy);
		g.drawString("Select " + (mode == SELECT_WORD ? "word" : "letter"), helpx + 110, helpy);
		g.drawString("Check solution", helpx + 295, helpy);
		g.drawString("Undo", helpx + 500, helpy);
	}
	
	public static class Text {
		
		private static final int OFFSET = 28;

		private Letter[] letters;
		private int cursor;
		private int length;
		private int offset;
		
		public Text(String text, int x, int y, int length) {
			char[] chars = text.toCharArray();
			letters = new Letter[length];
			for (int i = 0; i < length; i++) {
				String s = i < chars.length ? String.valueOf(chars[i]) : "";
				letters[i] = (new Letter(s, x + OFFSET * i, y));
			}
			this.length = length;
		}

		public void setCursor(int old, boolean right) {
			if (old > length) {
				old -= MIDDLE;
				old %= length;
			}
			cursor = (length == LINE_LENGTH && right) ? old + WORD_LENGTH + MIDDLE : old;
			offset = cursor * OFFSET;
		}

		public String pickUp() {
			String temp = letters[cursor].letter;
			letters[cursor].letter = "";
			return temp;
		}

		public boolean hasLetter() {
			return !letters[cursor].letter.equals("") && !letters[cursor].letter.equals(" ");
		}
		
		public int insert(Letter l) {
			boolean found = false;
			int i;
			for (i = 0; i < letters.length && !found; i++) {
				if (found = !letters[i].hasLetter()) {
					letters[i].letter = l.letter;
				}
			}
			return i - 1;
		}

		public void insert(String letter, int i) {
			letters[i].letter = letter;
		}
		
		public void remove(int i) {
			letters[i].letter = "";
		}
		
		public boolean hasRoom() {
			return !letters[letters.length - 1].hasLetter();
		}
		
		
		public boolean isEmpty() {
			boolean found = false;
			for (int i = 0; i < letters.length && !found; i++) {
				found = letters[i].hasLetter();
			}
			return !found;
		}

//		public String insert(Letter l) {
//			String temp = "";
//			if (letters[cursor].hasLetter()) {
//				temp = letters[cursor].letter;
//			}
//			letters[cursor].letter = l.letter;
//			return temp;
//		}

		public int getOffset() {
			return offset;
		}

		public void reset() {
			cursor = 0;
			offset = 0;
		}

		public void left() {
			cursor--;
			if (cursor < 0) {
				cursor = length - 1;
				offset = cursor * OFFSET;
			} else {
				offset -= OFFSET;
			}
			if (!letters[cursor].hasLetter()) {
				left();
			}
		}

		public void right() {
			cursor++;
			if (cursor >= length) {
				cursor = 0;
				offset = 0;
			} else {
				offset += OFFSET;
			}
			if (!letters[cursor].hasLetter()) {
				right();
			}
		}

		public void draw(Graphics g) {
			for (Letter l : letters) {
				l.draw(g);
			}
		}
		
		public String toString() {
			StringBuffer sb = new StringBuffer();
			for (Letter l : letters) {
				sb.append(l.letter);
			}
			return sb.toString();
		}
		
		private static class Letter {
			private String letter;
			private int x;
			private int y;

			public Letter(String s, int x, int y) {
				letter = s;
				this.x = x;
				this.y = y;
			}

			public boolean hasLetter() {
				return !letter.equals("") && !letter.equals(" ");
			}

			public void draw(Graphics g) {
				g.drawString(letter, x, y);
				g.drawString("__", x, y + 2);
			}
		}
	}
	
	private static class State {

		private String letter;
		private int fromIndex;
		private int toIndex;
		private Text fromWord;
		private Text toWord;

		public State(String letter, int fromIndex, Text fromWord, int toIndex, Text toWord) {
			this.letter = letter;
			this.fromIndex = fromIndex;
			this.fromWord = fromWord;
			this.toIndex = toIndex;
			this.toWord = toWord;
		}
		
		public void reverse() {
			toWord.remove(toIndex);
			fromWord.insert(letter, fromIndex);
		}
	}
}
