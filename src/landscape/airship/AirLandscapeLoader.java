/*
 * Classname: AirLandscapeLoader.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape.airship;

import graphics.DoubleBackground;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import landscape.Landscape;

import organizer.AbstractMapLoader;
import organizer.MenuStarter;

/**
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 14 May 2008
 */
public abstract class AirLandscapeLoader extends MenuStarter {

	protected ArrayList<AirLandNode> nodes = new ArrayList<AirLandNode>();
	protected String nameBackGround;
	protected AirShip airShip;
	protected DoubleBackground background;
	
	private MapLoader mapLoader;
	
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_ALL);
		loadImages();
		String map = "land" + Database.getStatusFor("airship") + ".map";
		mapLoader = new MapLoader();
		try {
			mapLoader.parseFile(map);
		}
		catch (Exception e){
			e.printStackTrace();
		}
		releaseAll();
	}

	private void loadImages() {
		airShip = new AirShip();
		airShip.init();
		background = new DoubleBackground(
				Values.ORIGINAL_RESOLUTION[Values.X], 
				Values.ORIGINAL_RESOLUTION[Values.Y]);
		String[] bg = new String[2];
		bg[0] = "World/World" + Database.getStatusFor("airship");
		bg[1] = "World";
		background.setLandscapeImages(bg, false);
		nameBackGround = 
			ImageHandler.addToCurrentLoadOnUse(
					Values.MenuImages + "Pieces/1.png");
	}

	protected AirLandNode getNode(String name) {
		name = name.trim();
		for (int i = 0; i < nodes.size(); i++) {
			String s = nodes.get(i).getName();
			if (s.startsWith("land")) {
				s = s.replace("land", "");
			}
			if (s.equalsIgnoreCase(name)) {
				return nodes.get(i); 
			}
		}
		return null;
	}

	/**
	 * The private class MapLoader
	 * 
	 * This class loads the information about the landscape from a *.map file.
	 * 
	 * @author      Kalle Sjöström
	 * @version     0.7.0 - 14 May 2008
	 */
	private class MapLoader extends AbstractMapLoader {

		private int currentZone;

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
				AirLandNode node = new AirLandNode(X, Y, type, name.replace("_", " "));
				node.setZone(currentZone);
				nodes.add(node);
			} else if (command.equals("start")) {
				String zone = tok.nextToken();
				if (zone.equals("west")) {
					currentZone = Landscape.WEST_CONTINENT;
				} else if (zone.equals("east")) {
					currentZone = Landscape.EAST_CONTINENT;
				} else if (zone.equals("north")) {
					currentZone = Landscape.NORTH_CONTINENT;
				}
			}
		}
	}
}
