/*
 * Classname: Visited.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * This class stores the status for the roads and nodes. In this
 * class the landscape can store information about where the 
 * player has been between the times the player is in the landscape.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 14 May 2008
 */
public class Visited {
	
	private HashMap<String, ArrayList<String>> visitedNodes = 
		new HashMap<String, ArrayList<String>>();
	private HashMap<String, ArrayList<Integer>> visitedRoads = 
		new HashMap<String, ArrayList<Integer>>();
	private static Visited visited = new Visited();

	/**
	 * A private constructor making sure there are only one
	 * object of this class.
	 */
	private Visited() {
		clearVisited();
	}
	
	public void clearVisited() {
		visitedNodes.clear();
		visitedRoads.clear();
		for (int i = 0; i < 3; i++) {
			visitedNodes.put("world" + i + ".map", new ArrayList<String>());
			visitedRoads.put("world" + i + ".map", new ArrayList<Integer>());
		}
	}

	/**
	 * Gets the object containing the status for the roads and nodes.
	 * 
	 * @return the object used for getting the visited places in the game.
	 */
	public static Visited getVisited() {
		return visited;
	}

	/**
	 * Gets the visited nodes (places).
	 * 
	 * @return the list of nodes names that the player has visited.
	 */
	public ArrayList<String> getVnodes(String zone) {
		return visitedNodes.get(zone);
	}

	/**
	 * Gets the visited roads represented by their address.
	 * 
	 * @return the list of roads that the player has visited.
	 */
	public ArrayList<Integer> getVroads(String zone) {
		return visitedRoads.get(zone);
	}
	
	/**
	 * Stores the given array list as the list of visited nodes.
	 * 
	 * @param Vnodes the list of visited nodes.
	 */
	public void setVnodes(String zone, ArrayList<String> Vnodes) {
		visitedNodes.put(zone, Vnodes);
	}

	/**
	 * Stores the given array list as the list of visited roads.
	 * 
	 * @param roads the list of roads.
	 */
	public void setVroads(String zone, ArrayList<Integer> roads) {
		visitedRoads.put(zone, roads);
	}
}
