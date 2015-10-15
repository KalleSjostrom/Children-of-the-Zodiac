/*
 * Classname: RiddleLoader.java
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
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;

import villages.utils.DialogSequence;

/**
 * This class loads the information and images used in the riddle.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 25 Sep 2008
 */
public class RiddleLoader extends AbstractMapLoader {
	
	private HashMap<String, String> info = new HashMap<String, String>();
	private String firstLine;
	private String secondLine;
	private ArrayList<DialogSequence> dialog = new ArrayList<DialogSequence>();
	private ArrayList<Image> images = new ArrayList<Image>();
	private ArrayList<String> texts = new ArrayList<String>();

	/**
	 * This method parses the file with the given name and executes the
	 * commands in the file. The commands is executed via the method
	 * executeCommand().
	 * 
	 * @param filename the name of the file where the information about
	 * the riddle is. 
	 */
	protected void parseFile(String filename) {
		super.parseFile(Values.MiniGamesMaps, filename);
	}

	/**
	 * Gets the information HashMap containing the information for
	 * the riddle.
	 * 
	 * @return the map containing the information about the riddle.
	 */
	public HashMap<String, String> getInfo() {
		return info;
	}
	
	/**
	 * Gets the dialog sequence that is used by the riddle.
	 * 
	 * @return the dialog sequence for the riddle.
	 */
	public ArrayList<DialogSequence> getDialog() {
		return dialog;
	}
	
	/**
	 * This method executes the given command.
	 * 
	 * @param command the command to execute.
	 * @param tok the string tokenizer containing the information from the 
	 * riddle-file.
	 */
	protected void executeCommand(String command, StringTokenizer tok) {
		if (command.equals("music")) {
			info.put("music", tok.nextToken());
		} else if (command.equals("image")) {
			String name = tok.nextToken();
			int x = Integer.parseInt(tok.nextToken());
			int y = Integer.parseInt(tok.nextToken());
			float scale = Float.parseFloat(tok.nextToken());
			float alpha = Float.parseFloat(tok.nextToken());
			if (name.equals("_")) {
				images.add(new Image(null, x, y, scale, alpha));
			} else {
				images.add(new Image(Values.MiniGamesImages + name, x, y, scale, alpha));
			}
		} else if (command.equals("fl")) {
			firstLine = lastLine.replace("fl ", "");
		} else if (command.equals("sl")) {
			String temp = tok.nextToken();
			if (temp.equals("end")) {
				secondLine = "";
			} else {
				secondLine = lastLine.replace("sl ", "");
			}
			DialogSequence ds = new DialogSequence(firstLine, secondLine);
			dialog.add(ds);
		} else if (command.equals("text")) {
			texts.add(lastLine.replace("text ", ""));
		}
	}
	
	public ArrayList<Image> getImages() {
		return images;
	}	
	
	public ArrayList<String> getText() {
		return texts;
	}
	
	public static class Image {

		private String name;
		private int x;
		private int y;
		private float scale;
		private float alpha;

		public Image(String name, int x, int y, float scale, float alpha) {
			this.name = name;
			this.x = x;
			this.y = y;
			this.scale = scale;
			this.alpha = alpha;
		}

		public String getName() {
			return name;
		}
		
		public float getAlpha() {
			return alpha;
		}

		public float getScale() {
			return scale;
		}

		public int getY() {
			return y;
		}

		public int getX() {
			return x;
		}

		public void draw(Graphics g) {
			g.drawImage(name, x, y, scale);
		}
	}
}
