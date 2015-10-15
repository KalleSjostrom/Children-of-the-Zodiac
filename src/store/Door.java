/*
 * Classname: Door.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package store;

import info.Database;
import info.Values;

import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.StringTokenizer;

import villages.utils.Sign;

/**
 * This class represents a door in a building. This door can be connected 
 * to any building via the type argument. When the player presses the cross
 * button in front of a door, the doors attributes are gotten and the player
 * enters the building.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 13 May 2008
 */
public class Door {

	public static final int LOCKED = -1;
	public static final int DONT_FADE = 0;
	public static final int FADE_UP = 1;
	public static final int FADE_TO_HALF = 2;
	public static final int FADE_DOWN = 3;
	
	private String[] name;
	private String dbName;
	private Sign sign;
	private int[] pos;
	private int[] mode;
	private int width;
	private int fade;

	private float[] toPos;
	private ArrayList<Integer> directions;
	private int activateStatus = -1;
	private boolean active = true;

	/**
	 * Creates a new door with the given parameters.
	 * 
	 * @param type the type of the building as a string.
	 * @param name the name of the building.
	 * @param x the x position of the door.
	 * @param y the y position of the door.
	 * @param w the width of the door.
	 * @param directionList the direction that the player must have to open the door.
	 * @param villageName the name of the village.
	 */
	private Door(String[] type, String[] name, int x, int y,
			int w, ArrayList<Integer> directionList, int f, String villageName) {
		mode = new int[type.length];
		for (int i = 0; i < type.length; i++) {
			String t = type[i];
			if (t.equals("church")) {
				mode[i] = Values.CHURCH;
			} else if (t.equals("weapon")) {
				mode[i] = Values.WEAPONSTORE;
			} else if (t.equals("house")) {
				mode[i] = Values.HOUSE;
			} else if (t.equals("inn")) {
				mode[i] = Values.INN;
			} else if (t.equals("card")) {
				mode[i] = Values.CARDSTORE;
			} else if (t.equals("library")) {
				mode[i] = Values.LIBRARY;
			} else if (t.equals("labyrinth")) {
				mode[i] = Values.LABYRINTH;
			} else if (t.equals("village")) {
				mode[i] = Values.VILLAGE;
			} else if (t.equals("switch")) {
				mode[i] = Values.SWITCH_BACK;
			} else if (t.equals("story")) {
				mode[i] = Values.STORY_SEQUENSE;
			}
			name[i] = name[i].replace("_", " ");
		}
		this.name = name;
		directions = directionList;
		fade = f;
		dbName = (villageName + name[0]);
		pos = Values.createNormalPoint(x, y);
		width = w;
	}

	/**
	 * Sets the sign of the door. This sign can be gotten and displayed when
	 * the player tires to enter the building.
	 * 
	 * @param s the sign to set.
	 */
	public void setSign(Sign s) {
		sign = s;
	}

	/**
	 * Gets the sign of the door. This sign can tell the player that
	 * the door is locked for example.
	 * 
	 * @return the sign on the door.
	 */
	public Sign getSign() {
		return sign;
	}

	/**
	 * Checks if the door is in range of the given position.
	 * This is used to check if the player is in range of the door.
	 * If a player is in range of the door, the door can be opened
	 * if it is not locked.
	 * 
	 * @param p the position of the player.
	 * @return true if the player is in range of the door.
	 */
	public boolean isInRange(float[] p) {
		int dist = 
			(int) Math.round(Point2D.distance(
					p[Values.X], p[Values.Y], pos[Values.X], pos[Values.Y]));
		return dist < width;
	}

	/**
	 * Gets the name of the building.
	 * 
	 * @return the name of the building.
	 */
	public String getBuildingName() {
		int status = Database.getStatusFor(dbName);
		if (dbName.contains("CardShop") && status != -1) {
			status = 0;
		}
		if (status != -1) {
			return name[status];
		}
		return null;
	}

	/**
	 * Gets the mode of the building that this door leads to.
	 * This mode is any of the modes in the Values class. It represents
	 * which type of building that the player has entered. 
	 * 
	 * @return the game mode to enter. For example Values.INN.
	 */
	public int getMode() {
		int status = Database.getStatusFor(dbName);
		if (dbName.contains("CardShop") && status != -1) {
			status = 0;
		}
		if (status != -1) {
			return mode[status];
		}
		return -1;
	}

	/**
	 * Checks if the door is locked.
	 * 
	 * @return true if the door is locked.
	 */
	public boolean isLocked() {
		int status = Database.getStatusFor(dbName);
		return status == Door.LOCKED;
	}

	/**
	 * Creates a new door with the information in the given StringTokenizer.
	 * 
	 * @param tok the tokenizer containing the information about the door.
	 * @param villageName the name of the village where this door resides.
	 * @return the newly created door.
	 */
	public static Door getDoor(StringTokenizer tok, String villageName) {
		String[] type = tok.nextToken().split(";");
		String[] name = tok.nextToken().split(";");
		int x = Integer.parseInt(tok.nextToken());
		int y = Integer.parseInt(tok.nextToken());
		int w = Integer.parseInt(tok.nextToken());
		String directions = tok.nextToken();
		ArrayList<Integer> directionList = new ArrayList<Integer>();
		int activationStatus = -1;
		if (directions.contains(";")) {
			String[] dirs = directions.split(";");
			for (String d : dirs) {
				if (d.contains("s")) {
					activationStatus = Integer.parseInt(d.replace("s", ""));
				} else {
					directionList.add(Integer.parseInt(d));
				}
			}
		} else {
			directionList.add(Integer.parseInt(directions));
		}
		
		int f = FADE_DOWN;
		if (tok.hasMoreTokens()) {
			f = Integer.parseInt(tok.nextToken());
		}
		
		float[] startPos = null;
		if (tok.hasMoreTokens()) {
			startPos = new float[]{-1, -1, -1, -1};
			startPos[0] = Float.parseFloat(tok.nextToken());
			if (tok.hasMoreTokens()) {
				startPos[1] = Float.parseFloat(tok.nextToken());
				startPos[2] = Float.parseFloat(tok.nextToken());
				float temp = startPos[0];
				startPos[0] = startPos[1];
				startPos[1] = temp;
			}
			if (tok.hasMoreTokens()) {
				startPos[3] = Float.parseFloat(tok.nextToken());
			}
		}
		Door door = new Door(type, name, x, y, w, directionList, f, villageName);
		door.setToPos(startPos);
		door.setActivateStatus(activationStatus);
		return door;
	}
	

	private void setActivateStatus(int i) {
		if (i != -1) {
			activateStatus = i;
			active = false;
			checkStatus();
		}
	}
	
	private void checkStatus() {
		if (activateStatus != -1) {
			if (Database.getStatusFor(dbName + "activation") == activateStatus) {
				active = true;
			}
		}
	}

	private void setToPos(float[] pos) {
		toPos = pos;	
	}

	public boolean canBeOpened(int dir) {
		if (!active) {
			checkStatus();
		}
		if (active) {
			boolean found = false;
			for (int i = 0; i < directions.size() && !found; i++) {
				found = directions.get(i) == dir;
			}
			return found;
		} else {
			return false;
		}
	}
	
	public int getFadeMode() {
		return fade;
	}

	public float[] getToPos() {
		return toPos;
	}

	public String getName() {
		return name[0];
	}
}