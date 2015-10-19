/*
 * Classname: Landscape.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape;

import graphics.Graphics;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import java.util.logging.*;

import organizer.Organizer;

import villages.VillageLoader;
import villages.utils.Dialog;

/**
 * The landscape class. This class is in charge of the landscape game mode.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 14 May 2088
 */
public class Landscape extends LandscapeLoader {
	
	public static final int WEST_CONTINENT = 0;
	public static final int EAST_CONTINENT = 1;
	public static final int NORTH_CONTINENT = 2;
	
	public static final int NORMAL = 0;
	public static final int CONTINUE_MUSIC = 1;
	public static final int NIGHT_MUSIC = 2;

	public static int music = NORMAL;
	
	private Node currentNode;
	private Road currentRoad;
	private ArrayList<Node> visitedNodes = new ArrayList<Node>();
	private HashMap<Integer, Road> visitedRoads = new HashMap<Integer, Road>();
	private int speed = 40;
	private int stepTime = 0;
	private int playerAngle;
	private long zerotime;
	private boolean animate = false;
	private boolean message;
	private static Logger logger = Logger.getLogger("Landscape");

	/**
	 * Constructs a new landscape. The player is going to start from the node
	 * with the given name. The list of visited places is used to mark 
	 * the roads in different colors. 
	 * 
	 * @param info the information map containing the information 
	 * about the landscape. 
	 */
	public void init(HashMap<String, String> info) {
		HashMap<String, String> newInfo = info;
		if (music != NORMAL) {
			newInfo = new HashMap<String, String>();
			newInfo.putAll(info);
			String m = "";
			switch (music) {
			case NIGHT_MUSIC:
				m = info.get("music") + "night";
				break;
			case CONTINUE_MUSIC:
				m = "continue";
				break;
			default:
				m = info.get("music");
				break;
			}
			newInfo.put("music", m);
		}
		super.init(newInfo);
		String nodeName = newInfo.get("startNode");
		String zone = LandscapeLoader.checkPlace(nodeName);
		openRoads(zone);
		Visited v = Visited.getVisited();
		ArrayList<Integer> vRoads = v.getVroads(zone);
		for (int i : vRoads) {
			Road r = getRoad(i);
			visitedRoads.put(r.getAddress(), r);
			r.visit();
		}
		ArrayList<String> vNodes = v.getVnodes(zone);
		for (String s : vNodes) {
			Node n = getNode(s);
			n.visit();
			visitedNodes.add(n);
		}
		currentNode = getNode(nodeName.replace("_", " ").replace("night", ""));

		if (!currentNode.isVisited()) {
			visitedNodes.add(currentNode);
			currentNode.visit();
		}
		for (int i = 0; i < 4; i++) {
			Road r = currentNode.getRoad(i);
			if (r != null && !r.isClosed()) {
				visitedRoads.put(r.getAddress(), r);
				r.visit();
			}
		}
		player.setXandY(currentNode.getXpos(), currentNode.getYpos());
		player.standStill(Values.DOWN);
		inputManager.resetAllGameActions();
		
		music = NORMAL;
		logicLoading = false;
	}
	
	public void openRoads(String zone) {
		openClosedRoads(Database.getOpenedRoads(zone));		
	}

	/**
	 * Restore the landscape.
	 */
	public void resume() {
		resume(Values.DETECT_INIT, !resumedFromMenu());
	}

	/**
	 * Updates the positions if the player has pressed something.
	 * 
	 * @param elapsedTime the time that has elapsed since the last game update.
	 */
	public void update(float elapsedTime) {
		if (animate) {
			long step = (System.currentTimeMillis()-zerotime) / speed;
			if (step >= stepTime) {
				int ang = currentRoad.movePlayer(player, (int) step);
				if (ang == -1) {
					stopMoving();
				} else if (playerAngle != ang) {
					playerAngle = ang;
					player.move(playerAngle);
				}
				stepTime++;
			}
			player.update((int) elapsedTime);
		} else {
			checkGameInput();
		}
		super.update(elapsedTime);
	}

	/**
	 * Starts moving the landscape player in the given direction.
	 * 
	 * @param dir the direction to move to.
	 */
	private void startMoving(int dir) {
		animate = true;
		zerotime = System.currentTimeMillis();
		stepTime = 0;
		player.move(playerAngle = dir);
	}

	/**
	 * This method closes the animation and changes the current node.
	 */
	private void stopMoving() {
		animate = false;
		currentNode = currentRoad.getDest();
		if (!currentNode.isVisited()) {
			visitedNodes.add(currentNode);
			currentNode.visit();
		}
		
		for (int i = 0; i < 4; i++) {
			Road r = currentNode.getRoad(i);
			if (r != null && !r.isClosed() && r != currentRoad 
					&& !visitedRoads.containsKey(r.getAddress())) {
				visitedRoads.put(r.getAddress(), r);
				r.visit();
			}
		}
		
		player.standStill(playerAngle);
		currentRoad = null;
		resetAll();
	}

	/**
	 * Gets a list of all the visited nodes in the landscape.
	 * 
	 * @return an array list containing the names of all the visited places.
	 */
	public ArrayList<String> getVisitedNodes() {
		ArrayList<String> vn = new ArrayList<String>();
		for (int i = 0; i < visitedNodes.size(); i++) {
			vn.add(visitedNodes.get(i).getName());
		}
		return vn;
	}

	/**
	 * Gets a list of address of all the visited roads in the landscape.
	 * 
	 * @return an array list containing the address of all the visited roads.
	 */
	public ArrayList<Integer> getVisitedRoads() {
		ArrayList<Integer> retArray = new ArrayList<Integer>();
		Iterator<Integer> it = visitedRoads.keySet().iterator();
		while(it.hasNext()) {
			retArray.add(it.next());
		}
		return retArray;
	}

	/**
	 * Checks the game input.
	 */
	private void checkGameInput() {
		if (!animate) {
			int angle = -1;
			boolean somethingsPressed = true;
			if (gameActions[UP].isPressed()) {
				angle = Values.UP;
			} else if (gameActions[RIGHT].isPressed()) {
				angle = Values.RIGHT;
			} else if (gameActions[DOWN].isPressed()) {
				angle = Values.DOWN;
			} else if (gameActions[LEFT].isPressed()) {
				angle = Values.LEFT;
			} else if (gameActions[CROSS].isPressed()) {
				if (!message) {somethingsPressed = false;}
				crossPressed();
			} else if (gameActions[SQUARE].isPressed()) {
				if (Database.getStatusFor("airship") >= 1) {
					nextPlace = "air" + currentNode.getName().replace(" ", "_");
					exitLandscape(Values.EXIT, currentNode.getName());
				}
			} else if (isMenuButtonPressed(gameActions)) {
				super.queueEnterMenu();
			} else {
				somethingsPressed = false;
			}
			if (somethingsPressed && message) {
				message = false;
			}
			if (angle != -1) {
				Road r = currentNode.getRoad(angle);
				if (r != null && !r.isClosed()) {
					r.setIsSource(currentNode.isSource(angle));
					currentRoad = r;
					startMoving(angle);
				}
			}
		}
	}

	/**
	 * Executes the events when the cross button is pressed.
	 */
	private void crossPressed() {
		String s = currentNode.getName().replace(" ", "_") + "node";
		logger.log(Level.FINE, "Entering: " + s);
		int status = Database.getStatusFor(Organizer.convert(s));
		logger.log(Level.FINE, "Status: " + status);
		int mode = -1;
		String zone = currentNode.getName();
		if (status != -2) {
			if (status == -1 || status == 0) {
				nextPlace = currentNode.getName();//.replace(" ", "_");
				if (currentNode.getType().equals("village")) {
					nextPlace = nextPlace.split("-mark")[0];
					mode = Values.VILLAGE;
					VillageLoader.staticStartPos = 0;
				} else if (currentNode.getType().equals("labyrinth")) {
					mode = Values.LABYRINTH;
				}
			} else {
				nextPlace = s + status;
				mode = Values.VILLAGE_STORY;
				VillageLoader.staticStartPos = 0;
			}
			if (mode != -1) {
				exitLandscape(mode, zone);
			}
		} else {
			message = true;
		}
	}

	private void exitLandscape(int mode, String place) {
		String zone = LandscapeLoader.checkPlace(place);
		Visited.getVisited().setVnodes(zone, getVisitedNodes());
		Visited.getVisited().setVroads(zone, getVisitedRoads());
		exit(mode);
	}

	/**
	 * The drawing method of landscape.
	 * 
	 * @param g the graphics3D on which to draw.
	 */
	public void draw(Graphics g) {
		g.setColor(1);
		g.setFontSize(30);
		background.drawBottom(g);
		Iterator<Integer> it = visitedRoads.keySet().iterator();
		while (it.hasNext()) {
			int address = it.next();
			visitedRoads.get(address).drawRoad(g);
		}
		for (int i = 0; i < nodes.size(); i++) {
			if (nodes.get(i).isVisited()) {
				nodes.get(i).draw(g);
			}
		}
		player.draw(g);
		background.drawTop(g, false, null);
		g.drawCenteredImage(nameBackGround, 10);
		if (!animate) {
			if (!currentNode.getType().equals("crossroad")) {
				String name = currentNode.getName();
				if (name.contains("-")) {
					name = name.split("-")[0];
				}
				g.drawStringCentered(name, 60, 0);
			}
		}
		if (message) {
			Dialog.getDialog().draw(g, true, "Kin", "We can't enter now!", "", false);
		}
		super.checkMenu();
		super.draw(g);
	}
	
	public String getName() {
		return currentNode == null ? "Landscape" : currentNode.getName();
	}

	public static int convert(String zone) {
		int land = 0;
		if (zone.contains("0")) {
			land = WEST_CONTINENT;
		} else if (zone.contains("1")) {
			land = EAST_CONTINENT;
		} else if (zone.contains("2")) {
			land = NORTH_CONTINENT;
		}
		return land;
	}

	public static void setInfo(String string) {
		if (string.startsWith("normal")) {
			music = NORMAL;
		} else if (string.startsWith("continue")) {
			music = CONTINUE_MUSIC;
		} else if (string.startsWith("night")) {
			music = NIGHT_MUSIC;
		} 
	}

	public static boolean isNight() {
		return music != NORMAL;
	}
}