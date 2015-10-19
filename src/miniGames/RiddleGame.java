/*
 * Classname: RiddleGame.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/09/2008
 */
package miniGames;

import graphics.Graphics;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import labyrinth.Labyrinth;
import labyrinth.LabyrinthDrawable;
import labyrinth.inventory.Inventory;
import miniGames.RiddleLoader.Image;

import organizer.GameMode;

import villages.utils.Dialog;

/**
 * This class manages the riddles in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 Sep 2008
 */
public class RiddleGame extends GameMode implements LabyrinthDrawable {
	
	private Dialog dialog = Dialog.getDialog();
	private Labyrinth labyrinth;
	
	protected float fade = 0;
	private boolean fadingUp = true;
	protected boolean fadingDown = false;
	private Image image;
	protected Inventory[] hinders;
	protected ArrayList<String> texts;
	
	/**
	 * Constructs a new riddle based on the information in the file with the
	 * given name. The given labyrinth is the labyrinth that the riddle is in.
	 * 
	 * @param name the name of the file containing the riddle. 
	 * @param lab the labyrinth where the riddle is.
	 */
	public RiddleGame() {
	}
	
	public void init(String name, Labyrinth lab, Inventory[] hinders) {
		RiddleLoader rl = new RiddleLoader();
		rl.parseFile(name);
		HashMap<String, String> info = rl.getInfo();
		init(info);
		this.hinders = hinders;
		dialog.setDS(rl.getDialog(), null);
		texts = rl.getText();
		labyrinth = lab;
		ArrayList<Image> images = rl.getImages();
		image = images.get(0);
		logicLoading = false;
	}
	
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_AS_KEY, false);
	}

	/**
	 * This method updates the riddle.
	 * 
	 * @param elapsedTime the amount of time that has passed since the riddle
	 * where last updated.
	 */
	public void update(float elapsedTime) {
		checkInput();
		if (fadingDown) {
			fade -= .12f;
			if (fade < 0) {
				labyrinth.exitRiddle();
			}
		} else if (fadingUp) {
			fade += .1f;
			if (fade >= 1) {
				fadingUp = false;
			}
		}
		super.update(elapsedTime);
	}
	
	/**
	 * Checks the input for changes.
	 */
	protected void checkInput() {
		if (!isRiddleFading()) {
			if (gameActions[CROSS].isPressed()) {
				fadingDown = true;
			}
		}
	}
	
	public Image getImage() {
		return image;
	}

	protected boolean isRiddleFading() {
		return fadingDown || fadingUp;
	}

	public void initDraw(Graphics g) {
		// TODO
	}
	
	public void draw(Graphics g) {
		
	}
	
	public void drawTopLayer(Graphics g) {
		float fos = fade * image.getAlpha();
		g.fadeOldSchool(1 - fos);
		g.setColor(1, 1, 1, fade);
		image.draw(g);
	}
}
