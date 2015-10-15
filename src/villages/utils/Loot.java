/*
 * Classname: Loot.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/01/2008
 */
package villages.utils;

import info.Database;
import info.Values;

import java.awt.geom.Point2D;
import java.util.HashMap;
import java.util.StringTokenizer;

import cards.Card;
import equipment.Items.Item;
import factories.EquipmentFactory;

/**
 * This class represents a sequence in a dialog.
 * The text to be displayed.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 1 Jan 2009
 */
public class Loot {
	
	public static final int GOLD = 0;
	public static final int ITEM = 1;
	public static final int CARD = 2;
	public static final int EQUIPMENT = 3;
	public static final int LIFE = 4;
	
	private static final int TAKEN = 1;
	private static final int AVAILABLE = 0;
	
	public int[] position;
	
	private Object content;
	private String name;
	private String contentName;
	private String[] text = new String[2];
	private int type;
	private int[] playerDir;
	private HashMap<String, Integer> triggers;

	/**
	 * Creates a loot from the given information.
	 * 
	 * @param name the name of the loot.
	 * @param dir 
	 * @param position the position where the loot will be placed in the 
	 * village.
	 * @param type the type of the loot. Could be either of Loot.GOLD, .ITEM
	 * .CARD, .WEAPON or .ARMOR.
	 * @param content the content of the loot. The actual object. If the type
	 * is a card then the content will be the actual card and an instance of
	 * AbstractCard.
	 * @param triggers 
	 */
	public Loot(String name, int type, Object content) {
		this(name, null, null, type, content, null);
	}
	
	public Loot(
			String name, int[] dir, int[] position, int type, 
			Object content, HashMap<String, Integer> triggers) {
		this.name = name;
		this.playerDir = dir;
		this.position = position;
		this.type = type;
		this.content = content;
		this.triggers = triggers;
	}
	
	/**
	 * Adds a string to this loot's message. The message will be displayed
	 * in the form of a dialog when the player finds it in a village.
	 *  
	 * @param s the text to add to this loot's message.
	 */
	public void addString(String s) {
		if (text[0] == null) {
			text[0] = s;
		} else {
			text[1] = s;
		}
	}

	/**
	 * Checks if this loot is in range of the player. It checks if the given 
	 * position is less than 25 pixels away from the loots.
	 * 
	 * @param pos the position to check against.
	 * @return true if the given position is in range of this loot.
	 */
	public boolean isInRange(float[] pos) {
		int dist = 
			(int) Math.round(Point2D.distance(
					position[Values.X], position[Values.Y], 
					pos[Values.X], pos[Values.Y]));
		return dist < 35;
	}

	/**
	 * Gets the content of this loot.
	 * 
	 * @return the content of this loot.
	 */
	public Object getContent() {
		return content;
	}

	/**
	 * Gets the type of this loot. This could be either of Loot.GOLD, .ITEM
	 * .CARD, .WEAPON or .ARMOR.
	 * 
	 * @return the type of this loot.
	 */
	public int getType() {
		return type;
	}
	
	public boolean checkPlayerDir(int dir) {
		boolean found = false;
		for (int i = 0; i < playerDir.length && !found; i++) {
			found = playerDir[i] == dir;
		}
		return found;
	}

	/**
	 * This will remove the loot from the database which will make the loot
	 * unavailable to the player. This, to make sure that the same loot can
	 * not be found twice.
	 */
	public void takeLoot() {
		Database.addStatus(name, TAKEN);
		Database.addStatus(triggers);
	}
	
	public boolean decrementStatus() {
		int status = Database.getStatusFor(name);
		if (status <= AVAILABLE) {
			return true;
		} else if (status != TAKEN) {
			status--;
			if (status == 1) {
				status = AVAILABLE;
			}
			Database.addStatus(name, status);
		}
		return false;
	}
	
	/**
	 * Gets the line of the message with the given index. The given index
	 * must be either 0, for the first line, or 1, for the second line.
	 * Any other value will result in an ArrayIndexOutOfBoundsException.
	 * 
	 * @param i the index of the text to get.
	 * @return the text with the given index.
	 */
	public String getLine(int i) {
		return text[i];
	}
	
	/**
	 * Creates a loot from the information in the given tokenizer.
	 * 
	 * @param tok the tokenizer containing the information about the loot.
	 * @param villageName the name of the village where the loot is placed.
	 * @return the newly created loot.
	 */
	public static Loot getLoot(StringTokenizer tok, String villageName) {
		Loot l = null;
		String name = villageName + tok.nextToken();
		int status = Database.getStatusFor(name);
		if (status != TAKEN) {
			int x = Integer.parseInt(tok.nextToken());
			int y = Integer.parseInt(tok.nextToken());
			int[] position = Values.createNormalPoint(x, y);
			int[] pDir = convert(tok.nextToken());
			String contentName = tok.nextToken();
			HashMap<String, Integer> triggers = new HashMap<String, Integer>();
			if (contentName.startsWith("trigger=")) {
				contentName = contentName.replace("trigger=", "");
				String[] triggerStrings = contentName.split("--");
				for (String s : triggerStrings) {
					String[] temp = s.split(":");
					triggers.put(temp[0], Integer.parseInt(temp[1]));
				}
				contentName = tok.nextToken();
			}
			
			int type = Integer.parseInt(tok.nextToken());
			Object content = createContent(contentName, type, tok);
			l = new Loot(name, pDir, position, type, content, triggers);
			l.contentName = contentName;
		}
		return l;
	}

	private static int[] convert(String dir) {
		String[] dirs = dir.split(";");
		int[] pDirs = new int[dirs.length];
		for (int i = 0; i < pDirs.length; i++) {
			pDirs[i] = Integer.parseInt(dirs[i]);
		}
		return pDirs;
	}

	/**
	 * Creates the content from the information in the given tokenizer.
	 * 
	 * @param contentName the name of the content
	 * @param type the type of the content.
	 * @param tok the tokenizer containing the information about the loot.
	 * @return the newly created loot.
	 */
	public static Object createContent(
			String contentName, int type, StringTokenizer tok) {
		Object content = null;
		contentName = contentName.replace("_", " ");
		switch(type) {
		case GOLD : 
			content = Integer.parseInt(contentName);
			break;
		case ITEM : 
			int amount = 1;
			if (tok.hasMoreTokens()) {
				amount = Integer.parseInt(tok.nextToken());
			}
			content = new Item(contentName, amount);
			break;
		case CARD : 
			int level = Integer.parseInt(tok.nextToken());
			boolean all = false;
			if (tok.hasMoreTokens()) {
				all = Boolean.parseBoolean(tok.nextToken());
			}
			content = Card.createCard(contentName, level, all);
			break;
		case EQUIPMENT : 
			content = EquipmentFactory.getEquipment(contentName);
			break;
		case LIFE : 
			content = Float.parseFloat(contentName);
			break;
		}
		return content;
	}

	public String getContentName() {
		return contentName;
	}

	public void setContentName(String name) {
		contentName = name;
	}
}
