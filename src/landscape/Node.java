/*
 * Classname: Node.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

/**
 * This class represents a node in the landscape. This could be a village, 
 * crossroad or a labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 14 May 2008
 */
public class Node {

	private String im;
	private String type;
	private String name;
	private Road[] roads = new Road[4];
	private int x;
	private int y;
	private int drawx;
	private int drawy;
	private boolean visited = false;
	private boolean[] isSource = new boolean[4];

	/**
	 * Creates a new node.
	 * 
	 * @param X the x position of the node.
	 * @param Y the y position of the node.
	 * @param t the type of the node.
	 * @param n the name of the node.
	 */
	public Node(int X, int Y, String t, String n) {
		x = X;
		y = Y;
		type = t;
		name = n;
		im = Values.LandscapeImages + "crossroad.png";
		ImageHandler.addToCurrentLoadOnUse(im);
		drawx = x - 2;
		drawy = y - 4;
	}

	/**
	 * Draw this node.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw (Graphics g) {
		g.drawImage(im, drawx, drawy);
	}

	/**
	 * Connects a road with the given direction to this place.
	 *  
	 * @param dir the direction of this road.
	 * @param r the road to set.
	 * @param isSource true if this node should be marked as 
	 * source for the given road.
	 */
	protected void setRoad(int dir, Road r, boolean isSource) {
		this.isSource[dir] = isSource;
		roads[dir] = r;
	}

	/**
	 * Visit this place.
	 */
	protected void visit() {
		visited = true;
	}

	/**
	 * Get the road with the given direction.
	 * 
	 * @param dir the direction of the node.
	 * @return the road with direction dir.
	 */
	protected Road getRoad(int dir) {
		return roads[dir];
	}

	/**
	 * Get the road with the given direction.
	 * 
	 * @param dir the direction of the node.
	 * @return the road with direction dir.
	 */
	protected boolean isSource(int dir) {
		return isSource[dir];
	}

	/**
	 * Gets the name of this node.
	 * 
	 * @return the name of this node.
	 */
	protected String getName() {
		return name;
	}

	/**
	 * Gets the type of this node.
	 * 
	 * @return the type of this node.
	 */
	protected String getType() {
		return type;
	}

	/**
	 * Checks if this place (node) is visited.
	 * 
	 * @return true if this node is visited.
	 */
	protected boolean isVisited() {
		return visited;
	}

	/**
	 * Gets the x position of this node.
	 * 
	 * @return the xpos of this node.
	 */
	protected int getXpos() {
		return x;
	}

	/**
	 * Gets the y position of this node.
	 * 
	 * @return the ypos of this node.
	 */
	protected int getYpos() {
		return y;
	}
}