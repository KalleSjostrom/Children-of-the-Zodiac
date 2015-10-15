package info;

import java.util.StringTokenizer;

import labyrinth.Node;
import labyrinth.inventory.Inventory;

import organizer.AbstractMapLoader;

public class MenuMapLoader extends AbstractMapLoader {
	
	private String labyrinthName;
	private LabyrinthMap map;
	
	public MenuMapLoader(String name) {
		labyrinthName = name;
		map = new LabyrinthMap();
	}
	
	protected void parseFile(String filename) {
		super.parseFile(Values.LabyrinthMaps, filename);
	}
	
	public LabyrinthMap getMap() {
		return map;
	}
	
	/**
	 * @inheritDoc
	 */
	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("dir")) {
			int source = Integer.parseInt(tokenizer.nextToken());
			int dir = Integer.parseInt(tokenizer.nextToken());
			int destination = Integer.parseInt(tokenizer.nextToken());
			InsertNodes(source, dir, destination);
		} else if (command.equals("inv")) {
			Inventory i = Inventory.createInventory(tokenizer, map, labyrinthName);
			if (i != null) {
				map.putInventory(i.getDatabaseName(), i);
			}
		} else if (command.equals("mapPos")) {
			int[] mapPos = new int[2];
			mapPos[0] = Integer.parseInt(tokenizer.nextToken());
			mapPos[1] = Integer.parseInt(tokenizer.nextToken());
			map.setMapPos(mapPos);
		}
	}

	/**
	 * This method creates the necessary nodes and binds them together.
	 * It takes two addresses and one direction, it then checks if the nodes
	 * have been created already, if not this method creates the nodes 
	 * and adds it to the node list. It then adds the destination node
	 * to the source nodes list of neighbors, with the given direction and
	 * vice versa with the exception that the opposite direction 
	 * is used instead.
	 * 
	 * @param source the address of the source node to be created and 
	 * bind together with the destination node.
	 * @param direction the direction between the source and the 
	 * destination node.
	 * @param destination the address of the destination node to be created and
	 * bind together with the source node.
	 */
	private void InsertNodes(int source, int direction, int destination) {
		Node sourceNode;
		Node destNode;
		sourceNode = map.getNode(source);
		if (sourceNode == null) {
			sourceNode = new Node(source);
			map.put(source, sourceNode);
		}
		destNode = map.getNode(destination);
		if (destNode == null) {
			destNode = new Node(destination);
			map.put(destination, destNode);
		}
		sourceNode.putNeighbours(Values.getCounterAngle(direction), destNode);
		destNode.putNeighbours(direction, sourceNode);
	}
}
