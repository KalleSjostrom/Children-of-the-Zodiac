/*
 * Classname: Dialog.java
 * 
 * Version information: 0.7.0
 *
 * Date: 02/02/2008
 */
package villages.utils;

import factories.Load;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;
import java.util.ArrayList;
import java.util.HashMap;
import com.jogamp.opengl.GL2;
import menu.DeckPage;
import menu.MenuHand;
import menu.MenuValues;
import organizer.GameMode;
import cards.Card;

/**
 * This class manages a dialog between player and villager. It is design 
 * as a singleton class which means that there will be only one object of
 * this class.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 02 Feb 2008
 */
public class Dialog {
	
	private static final int FIRST = 0;
	private static final int SECOND = 1;
	
	private static final int DIALOG = 0;
	private static final int NAME = 1;
	private static final int FIRST_LINE = 2;
	private static final int SECOND_LINE = 3;
	
	private int[][] xs = new int[][]{{0, 30}, {45, 75}, {65, 95}, {65, 90}};
	private int[][] ys = new int[][]{{20, 50}, {75, 105}, {110, 140}, {145, 170}};

	private static Dialog dialog = new Dialog();

	private ArrayList<DialogSequence> dialogSec;
	public static final String DIALOG_1 = ImageHandler.addPermanentlyLoadNow(
			Values.MenuImages + "dialog/dialog1.png");
	public static final String DIALOG_2 = ImageHandler.addPermanentlyLoadNow(
			Values.MenuImages + "dialog/dialog2.png");
	private String hand;
	private String[] alternatives;
	
	private int[] handX = {25, 330};
	private int[] handY = {50, 110};
	
	private int index = 0;
	private int xChoice = 0;
	private int yChoice = 0;
	private boolean secondHasBeenShown = false;
	private boolean end;
	private HashMap<Integer, ArrayList<DialogSequence>> responses;
	private int questionNumer;
	private int input;
	private int current;
	private int[] inputNr = new int[4];
	private float alpha;
	private float speed = 0.03f;

	/**
	 * Creates a new Dialog, with four images.
	 */
	private Dialog() {
		/*shadow1 = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "dialog/shadow1.png");
		shadow2 = ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "dialog/shadow2.png");*/
		hand = MenuHand.handRight;
	}

	/**
	 * Gets the dialog object.
	 * 
	 * @return the dialog object.
	 */
	public static Dialog getDialog() {
		return dialog;
	}

	/**
	 * Resets the internal values for drawing back to default. 
	 */
	public void resetDialog() {
		secondHasBeenShown = false;
		end = false;
		input = 0;
		index = 0;
		inputNr = new int[4];
		alternatives = null;
		current = 0;
		xChoice = 0;
		yChoice = 0;
	}

	/**
	 * Moves the pointer hand, if the current dialog is a question.
	 * 
	 * @param i the input number. This value can range from GameMode.UP 
	 * to GameMode.LEFT.
	 */
	public void move(int i) {
		if (dialogSec.get(index).isInputQ()) {
			moveInputQ(i);
		} else {
			moveQuestion(i);
		}
	}

	private void moveInputQ(int i) {
		xChoice = -1;
		if (i == GameMode.UP || i == GameMode.DOWN) {
			inputNr[current] += i == GameMode.UP ? 1 : -1;
			inputNr[current] = (inputNr[current] + 10) % 10;
		} else {
			if (i == GameMode.RIGHT) {
				current++;
			} else {
				current--;
			}
			current = (current + 4) % 4;
		}
	}

	private void moveQuestion(int i) {
		if (isQuestion()) {
			if (i == GameMode.UP || i == GameMode.UP + 2) {
				yChoice = Math.abs(yChoice - 1);
				if (alternatives[xChoice + yChoice * 2].equals(" ")) {
					yChoice = Math.abs(yChoice - 1);
				}
			} else {
				xChoice = Math.abs(xChoice - 1);
				if (alternatives[xChoice + yChoice * 2].equals(" ")) {
					xChoice = Math.abs(xChoice - 1);
				}
			}
		}
	}

	/**
	 * Checks if this dialog is a question.
	 * 
	 * @return true if this dialog is a question.
	 */
	public boolean isQuestion() {
		return index < dialogSec.size() && dialogSec.get(index).question;
	}

	/**
	 * Checks if this dialog has finished.
	 * 
	 * @return true if it is finished.
	 */
	public boolean isFinished() {
		if (alpha > 0) {
			if (alpha >= 2) {
				speed = -speed;
			}
			return false;
		} else if (dialogSec != null && index < dialogSec.size() - 1 && !end) {
			DialogSequence DS = dialogSec.get(index);
			end = DS.end;
			if (!end) {
				index++;
			}
			if (!dialogSec.get(index).first && !secondHasBeenShown) {
				secondHasBeenShown = true;
			}
			return end;
		}
		return true;
	}

	/**
	 * This method checks if the dialog sequence set by setDS() 
	 * has finished.
	 * 
	 * @return true if the dialog sequence has finished.
	 */
	public boolean checkIsFinished() {
		return !(index < dialogSec.size() - 1 && !end);
	}

	/**
	 * Adds a list of dialog sequences.
	 * 
	 * @param ds the dialog sequences.
	 */
	public void setDS(
			ArrayList<DialogSequence> ds,
			HashMap<Integer, ArrayList<DialogSequence>> responses) {
		resetDialog();
		dialogSec = ds;
		this.responses = responses;
	}
	
	/**
	 * Creates a list of the given sequence and sets it as the 
	 * current dialog sequence.
	 * 
	 * @param ds the dialog sequences.
	 * 
	 * @see #setDS(ArrayList)
	 */
	public void setDS(DialogSequence ds) {
		ArrayList<DialogSequence> list = new ArrayList<DialogSequence>(1);
		list.add(ds);
		setDS(list, null);
	}

	/**
	 * Draws the dialog.
	 * 
	 * @param g the graphics2D to draw on.
	 */
	public void draw(Graphics g) {
		DialogSequence DS = dialogSec.get(index);
		if (DS.inputQ) {
			drawInputQuestion(g, DS);
			questionNumer = DS.questionNr;
		} else if (DS.question && !end) {
			drawQuestion(g, DS.first, DS.alternatives);
			questionNumer = DS.questionNr;
		} else if (DS.getGift() != null) { 
			drawGift(g, DS);
		} else if (DS.image) {
			g.setColor(1, 1, 1, alpha);
			g.drawImage(Graphics.fadeImage, 0, -384, 2, 1);
			if (speed > 0 && alpha <= 2) {
				alpha += speed;
			} else if (speed < 0 && alpha >= 0) {
				alpha += speed;
				if (alpha <= 0) {
					alpha = 0;
					isFinished();
				}
			}
			g.setColor(1, 1, 1, alpha - 1);
			g.drawCenteredImage(DS.getImage(), 0);
		} else {
			draw(g, DS.first, DS.name, DS.firstLine, DS.secondLine, DS.whisper);
		}
	}
	
	private void drawInputQuestion(Graphics g, DialogSequence ds) {
		input = inputNr[0] * 1000 + inputNr[1] * 100 + inputNr[2] * 10 + inputNr[3];
		xChoice = -1;
		g.setFontSize(26);
		if (secondHasBeenShown) {
			g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND]);
		}
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);

		g.drawString(ds.name, xs[NAME][FIRST], ys[NAME][FIRST]);
		g.drawString(String.valueOf(inputNr[0]), 70, 130);
		g.drawString(String.valueOf(inputNr[1]), 100, 130);
		g.drawString(String.valueOf(inputNr[2]), 130, 130);
		g.drawString(String.valueOf(inputNr[3]), 160, 130);
		int x = 0;
		switch (current) {
		case 0:
			x = 30;
			break;
		case 1:
			x = 60;
			break;
		case 2:
			x = 90;
			break;
		case 3:
			x = 120;
			break;
		}
		g.drawImage(hand, x, 110);

	}

	/**
	 * This method draws the current dialog in the sequence set by setDS()
	 * as a message. This means that the method drawMessages() will be
	 * called instead of draw() with the information in the current dialog.
	 * There are not many differences between messages and plain dialogs,
	 * but the text drawn as messages are larger and if the text contains 
	 * of only one line, the text's height is "centered".
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawAsMessage(Graphics g) {
		DialogSequence DS = dialogSec.get(index);
		drawMessages(g, DS.firstLine, DS.secondLine, true);
	}

	/**
	 * Draws this dialog.
	 * 
	 * @param g the graphics2D to draw on.
	 * @param first true if the first dialog background is to be used.
	 * @param name the name that will appear in the top left corner.
	 * @param fl the first line of text to be drawn.
	 * @param sl the second line of text to be drawn.
	 * @param small true if the text should be drawn with a smaller font.
	 */
	public void draw(Graphics g, boolean first, String name, 
			String fl, String sl, boolean small) {
		int fontSize = g.getFontSize();
		if (fontSize != 30) {
			g.setFontSize(30);
		}
		g.setColor(Graphics.BLACK);
		if (first) {
			if (secondHasBeenShown) {
				g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND]);
			}
			g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);
			draw(g, name, fl, sl, FIRST, small);
		} else {
			g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);
			g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND]);
			draw(g, name, fl, sl, SECOND, small);
		}
		if (fontSize != 30) {
			g.setFontSize(fontSize);
		}
	}

	private void draw(Graphics g, String name, String fl, String sl,
			int pos, boolean small) {
		int y1 = ys[FIRST_LINE][pos];
		int y2 = ys[SECOND_LINE][pos];
		int size = 24;
		if (name != null && !name.equals("")) {
			g.drawString(name + ":", xs[NAME][pos], ys[NAME][pos]);
		} else {
			//if (!sl.equals("")) {
				y1 -= 25;
				y2 -= 10;
				size = 24;
			//}
		}
		if (sl.equals("") && (name == null || name.equals(""))) {
			g.setFontSize(small ? size : size + 6);
			
//			g.setFontSize(small ? size + 4 : size + 10);
//			y1 += 20;
			g.drawString(fl, xs[FIRST_LINE][pos], y1);
		} else {
			g.setFontSize(small ? size : size + 6);
			g.drawString(fl, xs[FIRST_LINE][pos], y1);
			g.drawString(sl, xs[SECOND_LINE][pos], y2);
		}
	}

	/**
	 * Draws a message, like "The door is closed". If the second line
	 * equals "" the first line will be centered in height.
	 *  
	 * @param g the graphics on which to draw.
	 * @param fl the first line of text.
	 * @param sl the second line of text.
	 * @param loadIdent true if this method should begin with loading 
	 * the identity matrix.
	 */
	public void drawMessages(Graphics g, String fl, String sl, boolean loadIdent) {
		if (loadIdent) {
			g.loadIdentity();
			g.setBlendFunc(GL2.GL_ONE_MINUS_SRC_ALPHA);
			g.setAlphaFunc(.1f);
		}
		g.setColor(Graphics.BLACK);
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);
		g.setFontSize(MenuValues.MENU_FONT_SIZE_LARGE);
		int yValue = sl.equals("") ? 110 : 85;
		g.drawString(fl, 65, yValue);
		g.drawString(sl, 65, 135);
	}
	
	private void drawGift(Graphics g, DialogSequence ds) {
		if (ds.getName() != null && !ds.getName().trim().equals("")) {
			Dialog.getDialog().draw(g, ds.first, ds.name, ds.firstLine, ds.secondLine, ds.whisper);
		} else {
			Dialog.getDialog().drawMessages(g, ds.firstLine, ds.secondLine, true);
		}
		Object content = ds.getGift().getContent();
		if (content != null) {
			if (content instanceof Card) {
				DeckPage.drawCardInfo(g, (Card) content, 530);
			}
		}
	}
	
	public static void drawGift(Graphics g, String first, String second, Loot l) {
		Dialog.getDialog().drawMessages(g, first, second, true);
		Object content = l.getContent();
		if (content != null) {
			if (content instanceof Card) {
				DeckPage.drawCardInfo(g, (Card) content, 530);
			}
		}
	}

	/**
	 * Draws the question dialog.
	 * 
	 * @param g the graphics2D to draw on.
	 * @param first true if the first dialog background is to be used.
	 * @param alt the list of alternatives.
	 * @param i 
	 */
	private void drawQuestion(Graphics g, boolean first, String[] alt) {
		alternatives = alt;
		g.setFontSize(26);
		if (secondHasBeenShown) {
			g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND]);
		}
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);

		g.drawString(alt[0], 65, 75);
		g.drawString(alt[1], 370, 75);
		g.drawString(alt[2], 65, 135);
		g.drawString(alt[3], 370, 135);
		g.drawImage(hand, handX[xChoice], handY[yChoice]);
	}
	
	public void drawQuestion(Graphics g, boolean first, String[] alt, String title) {
		alternatives = alt;
		g.setFontSize(26);
		if (secondHasBeenShown) {
			g.drawImage(DIALOG_2, xs[DIALOG][SECOND], ys[DIALOG][SECOND]);
		}
		g.drawImage(DIALOG_1, xs[DIALOG][FIRST], ys[DIALOG][FIRST]);

		g.drawString(title, xs[NAME][FIRST], ys[NAME][FIRST]);
		g.drawString(alt[0], xs[FIRST_LINE][FIRST], ys[FIRST_LINE][FIRST]);
		g.drawString(alt[1], 370, ys[SECOND_LINE][FIRST]);
		g.drawString(alt[2], xs[SECOND_LINE][FIRST], ys[SECOND_LINE][FIRST]);
		g.drawString(alt[3], 370, ys[SECOND_LINE][FIRST]);
		g.drawImage(hand, handX[xChoice], handY[yChoice]);
	}

	public boolean shouldTrigger() {
		return !end;
	}

	public void loadResponse() {
		int index;
		if (xChoice == -1) {
			if (questionNumer == input) {
				index = input;
			} else {
				index = 0;
			}
		} else {
			index = questionNumer + (xChoice + yChoice * 2) + 1;
			DialogSequence ds = dialogSec.get(this.index);
			int[] priceChoices = ds.getPrices();
			int gold = Load.getPartyItems().getGold();
			int i = xChoice + yChoice * 2;
			int p = priceChoices[i];

			if (p > 0 && p > gold) {
				index = questionNumer + 5;
			}
		}
		ArrayList<DialogSequence> r = responses.get(index);
		ArrayList<DialogSequence> res = new ArrayList<DialogSequence>();
		for (int i = 0; i < r.size(); i++) {
			res.add(r.get(i));
		}
		for (int i = this.index + 1; i < dialogSec.size(); i++) {
			res.add(dialogSec.get(i));
		}
		res.add(0, dialogSec.get(this.index));
		this.index = 0;
		dialogSec = res;
	}

	public Loot getGift() {
		return dialogSec.get(index).getGift();
	}

	public HashMap<String, Integer> getTriggers() {
		return dialogSec.get(index).getTriggers();
	}
	
	public HashMap<String, Integer> getBeforeTriggers() {
		return dialogSec.get(index).getBeforeTriggers();
	}
	
	public HashMap<String, Integer> getTriggerAdds() {
		return dialogSec.get(index).getTriggerAdds();
	}

	public String getTakeName() {
		return dialogSec.get(index).takeName;
	}
	
	public int getTakeAmount() {
		return dialogSec.get(index).takeAmount;
	}
	
	public String toString() {
		return dialogSec.get(index).firstLine;
	}
	
	public String getCurrentAlternative() {
		return alternatives == null ? null : alternatives[xChoice + yChoice * 2];
	}
}