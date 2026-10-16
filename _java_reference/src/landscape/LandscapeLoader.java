/*
 * Classname: Landscape.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape;

import graphics.DoubleBackground;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import java.util.logging.*;

import organizer.AbstractMapLoader;
import organizer.MenuStarter;
import organizer.Organizer;

/**
 * The Landscape Loader class.
 * This class loads the landscape from the world1.map file.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 14 May 2008
 */
public abstract class LandscapeLoader extends MenuStarter {

	protected ArrayList<Road> roads = new ArrayList<Road>();
	protected String nameBackGround;
	protected DoubleBackground background;
	protected LandPlayer player;

	private MapLoader mapLoader;
	private Road loadRoad;
	protected ArrayList<Node> nodes = new ArrayList<Node>();
	private static Logger logger = Logger.getLogger("LandscapeLoader");
	private static final HashMap<String, String> placeMap = createMap();

	/**
	 * Initializes the village. Gets information from the organizer and 
	 * loads accordingly.
	 * 
	 * @param info the information map containing the information 
	 * about the landscape.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_ALL);
		mapLoader = new MapLoader();
		try {
			String sn = info.get("startNode");
			String landscape = placeMap.get(sn);
			mapLoader.parseFile(landscape);
		}
		catch (Exception e){
			e.printStackTrace();
		}
		releaseAll();
	}

	/**
	 * This method loads all images.
	 * 
	 * @param name the name of the background image to load.
	 */
	private void loadImages(String name) {
		player = new LandPlayer();
		player.init();
		background = new DoubleBackground(
				Values.ORIGINAL_RESOLUTION[Values.X], 
				Values.ORIGINAL_RESOLUTION[Values.Y]);
		String[] bg = new String[2];
		bg[0] = name + "/" + name;
		bg[1] = name;
		boolean night = Landscape.isNight();
		background.setLandscapeImages(bg, night);
		nameBackGround = 
			ImageHandler.addToCurrentLoadOnUse(
					Values.MenuImages + "Pieces/1.png");
	}

	/**
	 * Gets the place (node) with the given name.
	 * 
	 * @param name the name of the place.
	 * @return the node with the given name.
	 */
	protected Node getNode(String name) {
		name = name.trim();
		for (int i = 0; i < nodes.size(); i++) {
			if (nodes.get(i).getName().equalsIgnoreCase(name)) {
				return nodes.get(i); 
			}
		}
		logger.log(Level.WARNING, "Could not find the node: " + name);
		return null;
	}

	/**
	 * Gets the road with the given address.
	 * 
	 * @param address the address to search for.
	 * @return the road with the given address.
	 */
	protected Road getRoad(int address) {
		for (int i = 0; i < roads.size(); i++) {
			if (roads.get(i).getAddress() == address) {
				return roads.get(i); 
			}
		}
		return null;
	}

	/**
	 * This method opens all the roads in the given list.
	 * 
	 * @param roads the list of open roads.
	 */
	protected void openClosedRoads(HashMap<Integer, Integer> roads) {
		Iterator<Integer> it = roads.keySet().iterator();
		while (it.hasNext()) {
			int key = it.next();
			int val = roads.get(key);
			Road r = getRoad(key);
			if (r != null) {
				r.setClosed(val == 0);
			}
		}
	}

	/**
	 * The private class MapLoader
	 * 
	 * This class loads the information about the landscape from a *.map file.
	 * 
	 * @author      Kalle Sj�str�m
	 * @version     0.7.0 - 14 May 2008
	 */
	private class MapLoader extends AbstractMapLoader {

		/**
		 * This method parses the file with the given filename.
		 * This file must be in the Values.LandscapeMaps folder. 
		 * 
		 * @param filename the name of the file to parse.
		 */
		protected void parseFile(String filename) {
			super.parseFile(Values.LandscapeMaps, filename);
		}

		/**
		 * This method implements the executeCommand() method from the 
		 * abstract map loader class. It is called with the first word of
		 * every line of text in the loaded file. Except for empty lines
		 * and lines that starts with "#".
		 * 
		 * @param command the command to execute.
		 * @param tok the tokenizer containing the reset of the line.
		 */
		protected void executeCommand(String command, StringTokenizer tok) {
			if (command.equals("node")) {
				int X = Integer.parseInt(tok.nextToken());
				int Y = Integer.parseInt(tok.nextToken());
				String type = tok.nextToken();
				String name = tok.nextToken();
				Node node = new Node(X, Y, type, name.replace("_", " "));
				nodes.add(node);
			} else if (command.equals("road")) {
				int address = getInt(tok);
				Node source = getNode(tok.nextToken().replace("_", " "));
				int dirToDest = getInt(tok);
				Node dest = getNode(tok.nextToken().replace("_", " "));
				int dirToSource = getInt(tok);
				boolean closed;
				closed = Database.getStatusFor("road" + address) == 0;
				loadRoad = new Road(address, source, dest, closed);
				source.setRoad(dirToDest, loadRoad, true);
				dest.setRoad(dirToSource, loadRoad, false);
				roads.add(loadRoad);
			} else if (command.equals("co")) {
				loadRoad.addCoordinates(getInt(tok), getInt(tok));
			} else if (command.equals("oc")) {
				loadRoad.done();
			} else if (command.equals("background")) {
				loadImages(tok.nextToken());
			}
		}

		/**
		 * Gets the integer that the given t parses.
		 * 
		 * @param t the string tokenizer.
		 * @return the integer value of the string that the tokenizer returns.  
		 */
		private int getInt(StringTokenizer t) {
			return Integer.parseInt(t.nextToken());
		}
	}
	
	private static class PlaceMapLoader extends AbstractMapLoader {
		
		private HashMap<String, String> map;
		private String current;

		public PlaceMapLoader(HashMap<String, String> map) {
			this.map = map;
			parseFile(null);
		}

		protected void parseFile(String filename) {
			current = "world0.map";
			super.parseFile(Values.LandscapeMaps, current);
			current = "world1.map";
			super.parseFile(Values.LandscapeMaps, current);
			current = "world2.map";
			super.parseFile(Values.LandscapeMaps, current);
		}

		protected void executeCommand(String command, StringTokenizer t) {
			if (command.equals("node")) {
				while (t.hasMoreTokens()) {
					command = t.nextToken();
				}
				String s = Organizer.convert(command);
				map.put(s, current);
			}
		}
	}
	
	private static HashMap<String, String> createMap() {
		HashMap<String, String> map = new HashMap<String, String>();
		new PlaceMapLoader(map);
		return map;
	}

	public static String checkPlace(String startNode) {
		return placeMap.get(Organizer.convert(startNode));
	}
}
