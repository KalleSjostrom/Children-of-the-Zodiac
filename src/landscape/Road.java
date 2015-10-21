/*
 * Classname: Road.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

import java.util.ArrayList;

/**
 * This class manages the links between places in the landscape.
 * It connects nodes (places), with walkable roads.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 14 May 2008
 */
public class Road {

	private ArrayList<Coordinate> line = new ArrayList<Coordinate>();
	private ArrayList<MoveDot> dots = new ArrayList<MoveDot>();
	private Node destNode;
	private Node sourceNode;
	private boolean isSource;
	private boolean closed;
	private int X = -1;
	private int Y = -1;
	private int address;

	/**
	 * Creates a new road with the given attributes.
	 * 
	 * @param a the address of this road.
	 * @param s the source node.
	 * @param d the destination node.
	 * @param close true if this road is closed.
	 */
	protected Road(int a, Node s, Node d, boolean close) {
		address = a;
		sourceNode = s;
		destNode = d;
		closed = close;
	}

	/**
	 * Sets if this road is the source.
	 * 
	 * @param s true if this method should set source to true. 
	 */
	protected void setIsSource(boolean s) {
		isSource = s;
	}

	/**
	 * Get the destination node.
	 * 
	 * @return destNode.
	 */
	protected Node getDest() {
		return isSource ? destNode : sourceNode;
	}
	
	public void visit() {
		destNode.visit();
		sourceNode.visit();
	}

	/**
	 * Gets the address of this road.
	 * 
	 * @return the address of this road.
	 */
	protected int getAddress() {
		return address;
	}
	
	int step = 0;

	/**
	 * Move the player on this road. 
	 * 
	 * @param player the player to move.
	 * @param step the amount of steps the player has taken.
	 * @return the angle of the player.
	 */
	protected int movePlayer(LandPlayer player, int step) {
		int angle = -1;
		if (!closed) {
			if (isSource && step < line.size()) {
				Coordinate l = line.get(step);
				player.setXandY(l.x, l.y);
				angle = l.angle;
			} else if (step >=  0 && step < line.size()) {
				Coordinate l = line.get((line.size() - 1) - step);
				player.setXandY(l.x, l.y);
				angle = (l.angle + 2) % 4;
			}
		}
		return angle;
	}

	/**
	 * Add one coordinate to this road.
	 * 
	 * @param x the x coordinate.
	 * @param y the y coordinate.
	 */
	protected void addCoordinates(int x, int y) {
		dots.add(new MoveDot(x, y));
		if (X != -1) {
			addCoordinates(X, Y, x, y);
		}
		X = x;
		Y = y;
	}

	/**
	 * Add two coordinate to this road.
	 * 
	 * @param x1 the first x coordinate.
	 * @param y1 the first y coordinate.
	 * @param x2 the second x coordinate.
	 * @param y2 the second y coordinate.
	 */
	protected void addCoordinates(int x1, int y1, int x2, int y2) {
		int angle = 0;
		if (Math.abs(x2 - x1) > Math.abs(y2 - y1)) {
			angle = x1 > x2 ? Values.LEFT : Values.RIGHT;
		} else {
			angle = y1 > y2 ? Values.UP : Values.DOWN;
		}

		float splitNumber = 7.0f;

		float Xtemp = (x2 - x1) / splitNumber;
		float Ytemp = (y2 - y1) / splitNumber;
		for (int i = 0; i <= splitNumber; i++) {
			line.add(new Coordinate(x1+(int)(Xtemp*i), y1+(int)(Ytemp*i), angle));
		}
	}

	/**
	 * This method is called by the loader at the end of each road.
	 * It removes the first and last dot in the road. These are 
	 * the source and destination node.
	 */
	protected void done() {
		dots.remove(0);
		dots.remove(dots.size()-1);
	}

	/**
	 * Draws this road on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void drawRoad(float dt, Graphics g) {
		for (int i = 0; i < dots.size(); i++) {
			dots.get(i).draw(dt, g);
		}
	}

	/**
	 * Checks if this road is closed.
	 * 
	 * @return true if this road is closed.
	 */
	protected boolean isClosed() {
		return closed;
	}

	/**
	 * Opens this road.
	 */
	protected void open() {
		closed = false;
	}
	
	public void setClosed(boolean close) {
		closed = close;
	}

	/**
	 * This class stores values about the coordinate.
	 * Its x, and y position and the angle of the player, 
	 * if the player should stand on this coordinate.
	 * 
	 * @author      Kalle Sjöström
	 * @version     0.7.0 - 14 May 2008
	 */
	private class Coordinate {

		private int x;
		private int y;
		private int angle = 0;

		/**
		 * The constructor of coordinates.
		 * 
		 * @param x the x position.
		 * @param y the y position.
		 * @param a the angle.
		 */
		private Coordinate(int x, int y, int a) {
			this.x = x;
			this.y = y;
			angle = a;
		}
	}

	/**
	 * This class represents a small dot in between of each nodes.
	 * 
	 * @author      Kalle Sjöström
	 * @version     0.7.0 - 14 May 2008
	 */
	private class MoveDot {

		private String dot;
		private int xpos;
		private int ypos;

		/**
		 * Creates a new move dot at the given position.
		 * 
		 * @param x the x position of the move dot.
		 * @param y the y position of the move dot.
		 */
		private MoveDot(int x, int y) {
			xpos = x;
			ypos = y;
			dot = Values.LandscapeImages + "movedot.png";
			ImageHandler.addToCurrentLoadOnUse(dot);
		}

		/**
		 * Draws the move dot at the given graphics.
		 * 
		 * @param g the graphics to draw the dot on.
		 */
		private void draw(float dt, Graphics g) {
			g.drawImage(dot, xpos, ypos);
		}
	}
}
