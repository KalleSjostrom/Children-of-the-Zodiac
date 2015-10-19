/*
 * Classname: Door.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Utils3D;
import info.Database;
import info.LabyrinthMap;
import info.Values;

import java.util.ArrayList;
import java.util.StringTokenizer;

import organizer.Organizer;

import labyrinth.Labyrinth;
import labyrinth.Node;
import villages.VillageLoader;

/**
 * This class is the inventory door. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the player can enter the door and
 * be transported to the place named nextPlace in this class..
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class Door extends AbstractDoor {
	
	public static int doorCount = 0;

	protected ArrayList<String> nextPlaces = new ArrayList<String>();
	protected String[] openRoad;
	
	/**
	 * Creates a new door from the given information. The give string openRoad
	 * contains the road to open after the player has passed this door the
	 * first time. This string has the format C-R where C is the number of the
	 * Continent (0 = west continent, 1 = east continent, 2 = north (ice) 
	 * continent), and R is the number-id of the Road. The road to open should
	 * have the name roadC-R in the database.
	 * 
	 * @param node the node where the chest should be.
	 * @param dir the direction the texture should face. 
	 * (Values.UP, .RIGHT, .DOWN, .LEFT).
	 * @param openRoad the string containing the road to open after the player 
	 * has passed this door the first time.
	 * @param nextPlace the name of next place.
	 * @param status the status for this button according to the Database.
	 * @param tok the tokenizer containing some additional information about
	 * the door. 
	 */
	public Door(Node node, int dir, String openRoad, String nextPlace, int status,
			StringTokenizer tok) {
		this(node, dir, openRoad, nextPlace, status, tok, 0, null);
	}
	
	public Door(Node node, int dir, String openRoad, String nextPlace, int status,
			StringTokenizer tok, int nrImages, String texture) {
		super(node, dir, nrImages, texture, status);
		init(openRoad, nextPlace, tok);
	}
	
	public void setHaveBeen(String lastNodesName) {
		for (String np : nextPlaces) {
			if (lastNodesName == null || 
					Organizer.convert(np).equalsIgnoreCase(Organizer.convert(lastNodesName))) {
				setHaveBeen();
			}
		}
	}
	
	protected void init(String openRoad, String nextPlace, StringTokenizer tok) {
		index = doorCount;
		doorCount++;
		this.openRoad = openRoad.split(";");
		nextPlaces.add(nextPlace.replace("_", " "));
		while (tok.hasMoreTokens()) {
			nextPlaces.add(tok.nextToken().replace("_", " "));
		}
	}
	
	@Override
	public void initDraw(Graphics g) {
		if (this instanceof LadderDoor) {
			super.initDraw(g);
		}
	}

	/**
	 * @inheritDoc
	 */
	protected void setSettings() {
		scale = .0026f;
		zOff = 1.9999f;
	}
	
	/**
	 * Gets the index of this door. This is a number that is being assigned to 
	 * each door when they are created, so that they are separable. It is used
	 * when initiating a labyrinth to know where to put the player. 
	 * 
	 * @return the index of the door.
	 */
	public int getDoorIndex() {
		return index;
	}

	@Override
	public void draw(Graphics g) {
		// The door is just a texture which is drawn by the wall renderer.
		if (images.length > 0) {
			super.draw(g);
		}
	}
	
	@Override
	public boolean checkIfOpen() {
		return true;
	}
	
	public void drawInMap(Graphics g, float x, float y, int angle) {
		if (haveBeenIn) {
			GameTexture t = ImageHandler.getTexture(LabyrinthMap.entrance[0]);
			Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
		}
		super.drawInMap(g, x, y, angle);
	}

	/**
	 * Exits the given labyrinth, enters the door and sets the
	 * next place in the labyrinth by calling the setNextPlace()
	 * with nextPlace as argument.
	 * 
	 * @param lab the labyrinth where this door is. 
	 */
	public void activate(Labyrinth lab) {
		int playerDir = ((lab.getPlayerAngle() - 90) / 90 + 4) % 4;
		if (playerDir == dir) {
			for (int i = 0; i < openRoad.length; i++) {
				String road = openRoad[i];
				if (!road.equals("dontopen")) {
					Database.addStatus("road" + road, 1); // road
				}			
			}
			
			super.enter(lab, info);

			status = Database.getStatusFor(dataBaseName);
			lab.exitLabyrinth(Values.EXIT);
			status = status == -1 ? 0 : status;
			String next = nextPlaces.get(status);
			if (next.contains("-pos")) {
				String[] split = next.split("-pos");
				next = split[0];
				VillageLoader.staticStartPos = Integer.parseInt(split[1]);
			}
			lab.setNextPlace(next);
			if (status < nextPlaces.size() - 1) {
				Database.addStatus(dataBaseName, status + 1);
			}
			setHaveBeen();
		}
	}

	public static void reset() {
		doorCount = 0;
	}
}
