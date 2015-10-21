package info;

import factories.Load;
import graphics.Graphics;
import graphics.ImageHandler;

import java.util.HashMap;
import java.util.Iterator;

import labyrinth.Node;
import labyrinth.inventory.Boss;
import labyrinth.inventory.Inventory;
import menu.MenuValues;

import organizer.Organizer;

public class LabyrinthMap {
	
	private String name;
	private HashMap<Integer, Node> nodes = new HashMap<Integer, Node>();
	private HashMap<String, Inventory> inve = 
		new HashMap<String, Inventory>();
	private int[] mapPos;
	private int size;
	public static String[] arrows = get(4, "arrow");
	public static String[] doorClosed = get(4, "closed");
	public static String[] doorOpen = get(4, "open");
	public static String[] stairs = get(2, "stairs");
	public static String[] chest = get(2, "chest");
	public static String[] entrance = get(1, "entrance");
	public static String[] tool = get(2, "tool");
	public static String[] lever = get(2, "lever");
	public static String[] bomb = get(2, "bomb");
	public static String[] riddle = get(1, "riddle");
	public static String[] save = get(1, "save");
	public static String[] aegisOn = get(4, "aegis");
	public static String[] aegisOff = get(4, "aegisoff");
	public static String[] notes = get(2, "smallnote");
	public static String[] miner = get(2, "miner");
	public static String[] directions = get(1, "direction");
	
	private static String[] get(int size, String name) {
		String[] s = new String[size];
		if (size == 1) {
			s[0] = ImageHandler.addPermanentlyLoadOnUse(
					Values.MenuImages + name + ".png");
		} else {
			for (int i = 0; i < size; i++) {
				s[i] = ImageHandler.addPermanentlyLoadOnUse(
						Values.MenuImages + name + i + ".png");
			}
		}
		return s;
	}
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}
	
	/**
	 * Gets the hash map of all the nodes in the graph.
	 * 
	 * @return the nodes in the graph.
	 */
	public HashMap<Integer, Node> getNodes() {
		return nodes;
	}
	
	/**
	 * Gets the node with the given address
	 * 
	 * @param address the address to search for.
	 * @return the node with the given address, 
	 * null if it does not exist.
	 */
	public Node getNode(int address) {
		return nodes.get(address);
	}

	public void put(int source, Node sourceNode) {
		nodes.put(source, sourceNode);
	}
	
	private static int SIZE = 47;
	private static int OFFSET_X = 80;
	private static int OFFSET_Y = -70;

	private static float SIZE2 = .12f;
	private static float[] ON_FLOOR_COLOR = new float[]{.2f, .8f, .2f, 1.0f};
	
	public int draw(
			Graphics g, Node currentNode, int currentDir,
			int[] pos, boolean drawAll, boolean calcPercent) {
		int address, y, x, counter;
		Iterator<Integer> it;
		counter = 0;
		it = nodes.keySet().iterator();
		boolean isOnFloor = false;
		while (it.hasNext()) {
			address = it.next();
			Node n = nodes.get(address);
			if (n.isVisited() || (n.isSeen() && n.hasInventory())) {
				counter++;
				if (n == currentNode) {
					isOnFloor = true;
				}
			}
		}
		if (pos != null) {
			if (isOnFloor) {
				String string = getName();
				int center = g.calcAlignCenter(string, pos[0] * 215 + 170);
				g.drawStringWithShadow(string, pos[1] * 330 + 85, center, ON_FLOOR_COLOR);
			} else {
				g.drawStringCentered(this.getName(), pos[1] * 330 + 85, pos[0] * 215 + 170);
			}
		} else {
			g.drawStringCentered(this.getName(), 60, 380);
		}
		g.setFontSize(MenuValues.MENU_FONT_SIZE);
		it = nodes.keySet().iterator();
		while (it.hasNext()) {
			address = it.next();
			Node n = nodes.get(address);
			y = (address % 16) * SIZE + OFFSET_Y;
			x = (address / 16) * SIZE + OFFSET_X;
			n.drawInMap(g, x, y, currentNode == n, currentDir, isOnFloor, drawAll);
		}
		int percent;
		if (calcPercent) {
			percent = Math.round((counter / (float) nodes.size()) * 100);
		} else {
			percent = counter;
		}
		return percent;
	}
	
	public void draw2(Graphics g, float f, int orig, int lastOrig, int angle) {
		int address;
		float x, y;
		Iterator<Integer> it;
		it = nodes.keySet().iterator();
		while (it.hasNext()) {
			Node n = nodes.get(it.next());
			address = n.getAddress();
			if (n.isVisited() || n.isSeen()) {
				y = address % 16;
				x = address / 16;

				float oy = (1 - f) * (orig % 16) + f * (lastOrig % 16);
				float ox = (1 - f) * (orig / 16) + f * (lastOrig / 16);

				float yDist = Math.abs(y - oy);
				float xDist = Math.abs(x - ox);
				if (yDist < 4 && xDist < 4) {
					y -= oy;
					x -= ox;
					y *= -SIZE2;
					x *= SIZE2;
					float dist = yDist + xDist;
					float step = 1f / 4f;
					g.setColor(1, 1, 1, 1 - dist * step);
					n.drawInSmallMap(g, x, y, angle);
					g.setColor(1);
				}
			}
		}
	}

	public Iterator<String> getInventories() {
		return inve.keySet().iterator();
	}
	
	public Inventory getInventory(String name) {
		return inve.get(name);
	}

	public void putInventory(String databaseName, Inventory i) {
		inve.put(databaseName, i);
	}

	public int[] getMapPos() {
		return mapPos;
	}

	public void setMapPos(int[] mapPos) {
		this.mapPos = mapPos;
	}

	public int getNrOfInventories() {
		return inve.size();
	}

	public static String[] convert(String name) {
		String[] s = name.split("--");
		String[] lab = new String[2];
		lab[0] = Organizer.convertKeepCase(s[0]);
		lab[1] = Load.prepare(s[1]);
		return lab;
	}
	
	public static String convertForSave(String[] lab) {
		return Organizer.convertBack(lab[0]) + "--" + Organizer.convertBack(lab[1]);
	}

	public int getNrVisitedNode() {
		Iterator<Node> it = nodes.values().iterator();
		int v = 0;
		while (it.hasNext()) {
			Node n = it.next();
			if (n.hasInventory()) {
				Inventory inv = n.getInventory();
				boolean visited = n.isVisited();
				boolean seen = inv.shouldDrawWhenOnlySeen() && n.isSeen();
				boolean special = (inv instanceof Boss) && n.isSeen();
				v += (visited || seen || special) ? 1 : 0;
			} else {
				v += n.isVisited() ? 1 : 0;
			}
		}
		return v;
	}
	
	public boolean isFullyVisited() {
		int nrVisited = getNrVisitedNode();
		return nodes.size() == nrVisited;
	}

	public void setSize(int size) {
		this.size = size;
	}

	public int getSize() {
		return size;
	}
}
