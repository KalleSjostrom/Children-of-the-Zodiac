/*
 * Classname: Node.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Utils3D;
import info.LabyrinthMap;
import info.Values;

import com.jogamp.opengl.GL2;

import labyrinth.inventory.Button;
import labyrinth.inventory.Chest;
import labyrinth.inventory.Inventory;
import menu.MapPage;

/**
 * This class represents a position in the labyrinth.
 * The player can walk between these nodes via edges and the graph.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 24 May 2008
 */
public class Node {

	public static final int DISTANCE = 4;
	public static final int WIDTH = 4;

	public static final int FLOOR_HEIGHT = -2;
	public static final int ROOF_HEIGHT = 2;
	
	private static final int SIZE = 16;
	
	protected Node[] neighbors = new Node[4];
	
	
	private Inventory inventory;
	private Position position;
	private boolean visited = false;
	private boolean seen = false;

	private int[] walls;
	private int nrOfNeighbors;
	private int address;
	private int roof;
	private int floor;
	
	private Horizontal carpetFloor;

	public Node(int address) {
		this.address = address;
		int x = address / SIZE;
		int z = (address % SIZE) - (SIZE - 1);
		position = new Position(x, z);
		walls = new int[]{-1, -1, -1, -1};
	}

	public void setWall(int dir, int nr) {
		walls[dir] = nr;
	}
	
	public void setRoof(int nr) {
		roof = nr;
	}
	
	public void setFloor(boolean useCarpetFloor, int offset) {
		if (useCarpetFloor) {
			addCarpetFloor(offset);
		} else {
			floor = offset;
		}
	}
	
	private void addCarpetFloor(int offset) {
		carpetFloor = new Horizontal(position.getX(), position.getZ());

		int sum = 0;
		int[] array = new int[nrOfNeighbors];
		int j = 0;
		for (int i = 0; i < 4; i++) {
			if (neighbors[i] != null) {
				array[j] = i;
				sum += array[j++];
			}
		}
		switch (nrOfNeighbors) {
		case 1 : carpetFloor.setEnd(sum % 2 == 0 ? sum : Values.getCounterAngle(sum), offset); break;
		case 2 : 
			boolean even = sum % 2 == 0;
			if (even) {
				carpetFloor.setStraight(sum, offset);
			} else {
				if (sum == 3) {
					sum += array[1] == 3 ? 0 : 4; 
				}
				carpetFloor.setHook(sum, offset);
			} break;
		case 3 : carpetFloor.setTCross(sum, offset); break;
		case 4 : carpetFloor.setCross(offset); break;
		}	
	}

	public void setWalls(boolean usePillarWalls, int tex) {
		if (usePillarWalls) {
			PillarWalls.addPillarWalls(this, tex, nrOfNeighbors);
		} else {
			for (int i = 0; i < 4; i++) {
				if (neighbors[i] == null) {
					walls[i] = tex;
				}
			}
		}
	}
	
	public void drawRoof(Graphics g, int direction) {
		if (direction == roof) {
			draw(g, ROOF_HEIGHT);
		}
	}

	public void drawFloors(Graphics g, int direction) {
		if (carpetFloor != null) {
			carpetFloor.draw(g, -2, 4, direction);
		} else if (direction == floor) {
			draw(g, FLOOR_HEIGHT);
		}
	}
	
	public void drawOneFloor(Graphics g) {
		draw(g, FLOOR_HEIGHT);
	}

	private void draw(Graphics g, int height) {
		float x = position.getX() - 2;
		float z = position.getZ() + 2;
		GL2 gl = g.getGL();
		
		if (height == FLOOR_HEIGHT) {
			gl.glNormal3f(0, 1, 0);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, height, z);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + WIDTH, height, z);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + WIDTH, height, z - WIDTH);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, height, z - WIDTH);
		} else {
			gl.glNormal3f(0, -1, 0);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, height, z - WIDTH);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + WIDTH, height, z - WIDTH);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + WIDTH, height, z);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, height, z);
		}
	}
	
	public void drawWall(Graphics g, int texture, boolean flip, int tangent) {
		for (int i = 0; i < 4; i++) {
			if (walls[i] != -1 && walls[i] == texture) {
				drawOneWall(g, i, flip);
			}
		}
	}
	
	public void drawOneWall(Graphics g, int dir, boolean flip) {
		float x = position.getX() - 2;
		float z = position.getZ() + 2;
		flip = true;
		GL2 gl = g.getGL();
		switch (dir) {
		case 0 : 
		// Back wall // SOUTH
			gl.glNormal3f(0, 0, -1.0f);
			gl.glTexCoord2f(flip ? 0 : 1, 1); gl.glVertex3f(x, Node.FLOOR_HEIGHT, z);
			gl.glTexCoord2f(flip ? 0 : 1, 0); gl.glVertex3f(x, Node.ROOF_HEIGHT, z);
			gl.glTexCoord2f(flip ? 1 : 0, 0); gl.glVertex3f(x + Node.WIDTH, Node.ROOF_HEIGHT, z);
			gl.glTexCoord2f(flip ? 1 : 0, 1); gl.glVertex3f(x + Node.WIDTH, Node.FLOOR_HEIGHT, z);
		break;
		case 1 :
			// Left Wall // WEST
			gl.glNormal3f(1, 0, 0);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, Node.ROOF_HEIGHT, z);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, Node.FLOOR_HEIGHT, z);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, Node.FLOOR_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, Node.ROOF_HEIGHT, z - Node.WIDTH);
			break;
		case 2 :
			// Front Wall // NORTH
//			gl.glVertexAttrib3f(tang, 1, 0, 0);
			gl.glNormal3f(0, 0, 1.0f);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, Node.ROOF_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, Node.FLOOR_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x + Node.WIDTH, Node.FLOOR_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x + Node.WIDTH, Node.ROOF_HEIGHT, z - Node.WIDTH);
			break;
		case 3 :
			// Right Wall // EAST
//			gl.glVertexAttrib3f(tang, 0, 0, -1);
			gl.glNormal3f(-1.0f, 0, 0);
			gl.glTexCoord2f(flip ? 1 : 0, 0); gl.glVertex3f(x + Node.WIDTH, Node.ROOF_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(flip ? 1 : 0, 1); gl.glVertex3f(x + Node.WIDTH, Node.FLOOR_HEIGHT, z - Node.WIDTH);
			gl.glTexCoord2f(flip ? 0 : 1, 1); gl.glVertex3f(x + Node.WIDTH, Node.FLOOR_HEIGHT, z);
			gl.glTexCoord2f(flip ? 0 : 1, 0); gl.glVertex3f(x + Node.WIDTH, Node.ROOF_HEIGHT, z);
			break;
		}
	}

	/**
	 * Gets the neighbor node that lies with the given direction 
	 * from this node.
	 * 
	 * @param direction the direction to the adjacent node. 
	 * @return the adjacent node.
	 */
	public Node getNode(int direction) {
		return neighbors[direction];
	}

	public void putNeighbours(int direction, Node node) {
		neighbors[direction] = node;
		nrOfNeighbors++;
	}

	/**
	 * Gets the position of this node.
	 * 
	 * @return position the position to get.
	 */
	public Position getPos() {
		return position;
	}

	public boolean hasInventory() {
		return inventory != null;
	}
	
	public boolean checkInventory() {
		return inventory != null && (inventory instanceof Chest || inventory instanceof Button);
	}

	public void setInventory(Inventory inv) {
		inventory = inv;
	}
	
	public Inventory getInventory() {
		return inventory;
	}

	public void visit() {
		if (!visited) {
			visited = true;
			for (Node n : neighbors) {
				if (n != null) {
					n.setSeen(true);
				}
			}
		}
	}
	
	public void arrive(Labyrinth lab) {
		if (hasInventory()) {
			inventory.arrive(lab);
		}
	}
	
	private void setSeen(boolean seen) {
		this.seen = seen;
	}

	public boolean isVisited() {
		return visited;
	}

	public boolean isSeen() {
		return seen;
	}
	
	public void setVisitedAndSeen(boolean isVisited, boolean isSeen) {
		visited = isVisited;
		seen = isSeen;
	}

	public Node getNeighbor(int i) {
		return neighbors[i];
	}

	public void setWall(int direction, int i, int j) {
		walls[direction] = (walls[direction] == 0 ? i : j);		
	}

	public void addToWall(int direction, int offset) {
		walls[direction] += offset;		
	}

	public Node[] getNeighbors() {
		return neighbors;
	}

	public int getAddress() {
		return address;
	}
	
	public static final float scale = 1.4f;

	public void drawInMap(Graphics g, int x, int y, boolean onThis,
			int dir, boolean isOnFloor, boolean drawAll) {
		boolean drawAnyway = false;
		if (isSeen()) {
			if (hasInventory()) {
				Inventory inv = getInventory();
				drawAnyway = inv.shouldDrawWhenOnlySeen();
			}
		}
//		drawAnyway = true;
		if (isVisited() || drawAnyway) {
			g.setColor(1);
			g.drawImage(MapPage.mappiece2, x, y, scale);
			if (hasInventory()) {
				String s = getInventory().getMapImage();
				if (s != null) {
					if (getInventory().hasBeenIn()) {
						g.drawImage(LabyrinthMap.entrance[0], x, y, scale);
					}
					g.drawImage(s, x, y, scale);
				}
			}
			if (onThis) {
				g.setImageColor(1, .85f, 0, 1);
				if (drawAll) {
					g.drawImage(LabyrinthMap.arrows[(dir + 2) % 4], x-24, y-24, scale * 2.2f);
				} else {
					g.drawImage(LabyrinthMap.arrows[(dir + 2) % 4], x, y, scale * 1);
				}
				g.setImageColor(1, 1, 1, 1);
			}
		} else if (isSeen()) {
			g.drawImage(MapPage.mappiece, x, y, scale);
		}
	}

	public void drawInSmallMap(Graphics g, float x, float y, int angle) {
		boolean drawAnyway = false;
		if (isSeen()) {
			if (hasInventory()) {
				Inventory inv = getInventory();
				drawAnyway = inv.shouldDrawWhenOnlySeen();
			}
		}
		if (isVisited() || drawAnyway) {
			GameTexture t = ImageHandler.getTexture(MapPage.mappiece2);
			Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
			if (hasInventory()) {
				Inventory inv = getInventory();
				if (inv.hasBeenIn()) {
					t = ImageHandler.getTexture(LabyrinthMap.entrance[0]);
					Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
				}
				inv.drawInMap(g, x, y, angle);
			}
		} else if (isSeen()) {
			GameTexture t = ImageHandler.getTexture(MapPage.mappiece);
			Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
		}
	}
	
	public void test(Graphics g, float x, float y, int start, int angle) {
		boolean drawAnyway = false;
		if (isSeen()) {
			if (hasInventory()) {
				Inventory inv = getInventory();
				drawAnyway = inv.shouldDrawWhenOnlySeen();
			}
		}
		if (isVisited() || drawAnyway) {
			GameTexture t = ImageHandler.getTexture(MapPage.mappiece2);
			Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
			if (hasInventory()) {
				Inventory inv = getInventory();
				inv.drawInMap(g, x, y, angle);
			}
		} else if (isSeen()) {
			GameTexture t = ImageHandler.getTexture(MapPage.mappiece);
			Utils3D.draw3D(g, t.getTexture(), x, y, 0, .1f);
		}
	}
}
