/*
 * Classname: Graph.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import graphics.Graphics;
import info.Database;
import info.LabyrinthMap;
import info.Values;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

import labyrinth.inventory.Boss;
import labyrinth.inventory.Door;
import labyrinth.inventory.HinderDoor;
import labyrinth.inventory.Inventory;
import labyrinth.inventory.Save;

/**
 * This class represents the path in a labyrinth as a graph. 
 * It contains nodes and edges where a node is a "stop place" the player can 
 * move to and the edges is vectors that the player walks via. A "stop place"
 * is where the player can stop and make a decision on where to go next
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 24 May 2008
 */
public class Graph {

	private int angle;
	private LabyrinthMap map;
	private Labyrinth labyrinth;
	private Inventory[] inventories;

	/**
	 * The constructor of graph. This manages the graph of nodes that 
	 * constitute the given labyrinth map. 
	 * 
	 * @param name the name of the map.
	 * @param labyrinthMap the map of the labyrinth.
	 */
	protected Graph(String name, LabyrinthMap labyrinthMap) {
		Door.doorCount = 0;
		Database.visitLabyrinth(
				name.replace("_", " ").replace(".map", ""), labyrinthMap);
		map = labyrinthMap;
		updateMap();
	}

	/**
	 * Gets the hash map of all the nodes in the graph.
	 * 
	 * @return the nodes in the graph.
	 */
	protected HashMap<Integer, Node> getNodes() {
		return map.getNodes();
	}

	/**
	 * Gets the node with the given address
	 * 
	 * @param address the address to search for.
	 * @return the node with the given address, 
	 * null if it does not exist.
	 */
	public Node getNode(int address) {
		return map.getNode(address);
	}

	/**
	 * Get the exit node with index i to be used as start node.
	 * It checks in which direction the labyrinth goes and sets the
	 * angle of the player accordingly.
	 * 
	 * @param i the index of the exit node.
	 * @return one of the start nodes of this labyrinth.
	 */
	protected Node getStartNode(int i) {
		if (i == -1) {
			return saveLocation();
		}
		return doorLocation(i);
	}

	private Node saveLocation() {
		Iterator<String> its = map.getInventories();
		while (its.hasNext()) {
			String invs = its.next();
			Inventory inv = map.getInventory(invs);
			if (inv instanceof Save) {
				Save d = (Save) inv;
				angle = d.getDirection();
				Node n = d.getNode();
				return n;
//				int i = 0;
//				for (Node neig : n.getNeighbors()) {
//					if (neig != null) {
//						angle = i;
//						return n;
//					}
//					i++;
//				}
			}
		}
		return null;
	}

	private Node doorLocation(int index) {
		Iterator<String> its = map.getInventories();
		while (its.hasNext()) {
			String invs = its.next();
			Inventory inv = map.getInventory(invs);
			if (inv instanceof Door) {
				Door d = (Door) inv;
				if (d.getDoorIndex() == index) {
					angle = Values.getCounterAngle(d.getDirection());
					return d.getNode();
				}
			} else if (inv instanceof HinderDoor) {
				HinderDoor d = (HinderDoor) inv;
				if (d.getDoorIndex() == index) {
					angle = Values.getCounterAngle(d.getDirection());
					return d.getNode();
				}
			}
		}
		return null;
	}
		
	/**
	 * Gets the angle produced in the previous method.
	 * 
	 * @return the starting angle of the player.
	 */
	protected int getAngle() {
		return angle;
	}

	/**
	 * Activates the inventory that resides in the given node. The given
	 * node must contain an inventory, otherwise this method will
	 * cause a NullPointerException.
	 * 
	 * @param currentNode the node to get the inventory from. 
	 * @param labyrinth the labyrinth to activate the inventory in.
	 */
	public void activateInventory(Node currentNode, Labyrinth labyrinth) {
		Inventory inv = getInventory(currentNode);
		inv.activate(labyrinth);
	}
	
	/**
	 * Gets the inventory from the given node. This method will return null
	 * if the given node does not contain an inventory.
	 * 
	 * @param node the node to get the inventory from.
	 * @return the inventory in this node.
	 */
	private Inventory getInventory(Node node) {
		Iterator<String> it = map.getInventories();
		while (it.hasNext()) {
			Inventory inv = map.getInventory(it.next());
			if (inv.getNode() == node) {
				return inv;
			}
		}
		return null;
	}
	
	/**
	 * This method checks if current node contains a non passable inventory.
	 * 
	 * @param currentNode the node to check if contains a hinder.
	 * @param nextNode the node at the given direction from the currentNode.
	 * @param dir the direction from the current node to the next node.
	 * @return true if a hinder has been found.
	 */
	public boolean checkForHinder(Node currentNode, Node nextNode, int dir) {
		Inventory inv = currentNode.getInventory();
		boolean hinderFound = false;
		if (inv != null) {
			if (inv instanceof HinderDoor) {
				boolean hinderIsPassable = ((HinderDoor) inv).isPassableOnThis(dir);
				hinderFound = hinderIsPassable ? (check(nextNode, dir)) : true;
			} else if (inv instanceof Door) {
				boolean hinderIsPassable = ((Door) inv).isPassableOnThis(dir);
				hinderFound = hinderIsPassable ? (check(nextNode, dir)) : true;
			}
		} else {
			hinderFound = check(nextNode, dir);
		}
		return hinderFound;
	}
	
	private boolean check(Node node, int dir) {
		Inventory inv = node.getInventory();
		boolean hinderFound = false;
		if (inv != null) {
			hinderFound = !inv.isPassable(dir);
			/*
			if (inv instanceof Chest) {
				hinderFound = true;
			} else if (inv instanceof Button) {
				hinderFound = true;
			} else if (inv instanceof LadderDoor) {
				hinderFound = true;
			} else if (inv instanceof HinderDoor) {
				// ?
			} else if (inv instanceof Hinder) {
				Hinder hinder = (Hinder) getInventory(node);
				hinderFound = !hinder.isPassable();
			}
			*/
		}
		return hinderFound;
	}
	
	/**
	 * Checks if the given node is a boss node. If the given node is
	 * a boss node and the boss is alive, the battle is entered via
	 * the given labyrinth. If the boss is not alive, the nodes boss
	 * mark is removed.
	 * 
	 * @param currentNode the node to check.
	 * @param labyrinth the labyrinth to execute the battle in.
	 * @return true if the given node had an alive boss. 
	 */
	public boolean checkBossNode(Node currentNode, Labyrinth labyrinth) {
		Inventory inv = currentNode.getInventory();
		if (inv != null && inv instanceof Boss) {
			Boss boss = (Boss) inv;
			if (boss.isAlive()) {
				boss.enterBossBattle(labyrinth);
				return true;
			}
			currentNode.setInventory(null);
		}
		return false;
	}

	public void sortInventory() {
		inventories = new Inventory[map.getNrOfInventories()];
		Iterator<String> it = map.getInventories();
		int i = 0;
		while (it.hasNext()) {
			inventories[i++] = map.getInventory(it.next());
		}
		Arrays.sort(inventories);
	}

	/**
	 * This method initiates the drawing in each inventory in this graph.
	 * 
	 * @param gl the open GL instance to initiate the inventory on.
	 */
	public void initDrawInventory(Graphics g) {
		Iterator<String> it = map.getInventories();
		while (it.hasNext()) {
			g.loadIdentity();
			Inventory in = map.getInventory(it.next());
			in.initDraw(g);
		}
	}
	
	/**
	 * This method draws each inventory in this graph.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void drawInventory(Graphics g) {
		int i;
		boolean found = false;
		for (i = 0; i < inventories.length && !found; i++) {
			Inventory inv = inventories[i];
			if (inv instanceof Save) {
				((Save) inv).draw(g, labyrinth.getPlayerAngle());
			} else {
				inv.draw(g);
			}
		}
	}
	
	
	public void setLabyrinth(Labyrinth lab) {
		labyrinth = lab;
	}
	
	public boolean isNodeVisible(Node target) {
		int dir = labyrinth.getPlayerAngle();
		int ca = labyrinth.getCurrentNode().getAddress();
		int ta = target.getAddress();
		
		if (dir > -45 && dir <= 45) {
			return ta % 16 == ca % 16 && ta >= ca;
		} else if (dir < 135 && dir > 45) {
			return ta / 16 == ca / 16 && ta >= ca;
		} else if (dir < -45 && dir >= -135) {
			return ta / 16 == ca / 16 && ta <= ca;
		} else {
			return ta % 16 == ca % 16 && ta <= ca;
		}
	}

	
	public boolean isDirectedTowards(Node n, int dir) {
		return getInventory(n).isDirectedTowards(dir);
	}

	private void updateMap() {
		Iterator<String> it = map.getInventories();
		while (it.hasNext()) {
			Inventory inv = map.getInventory(it.next());
			inv.updateStatus();
		}
	}
}