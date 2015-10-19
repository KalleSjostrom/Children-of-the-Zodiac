/*
 * Classname: Boss.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.Graphics;
import info.Database;

import com.jogamp.opengl.GL2;

import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;

/**
 * This class is the inventory boss. It is an inventory, thing in the labyrinth
 * that the player can find. If the player finds the node where this inventory
 * resides, the Database class is called to find out whether the boss is
 * alive or not. This inventory does not have any textures but is only a 
 * launcher for the boss battle.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class Boss extends Inventory {

	private String name;

	/**
	 * Creates a new boss inventory which will reside on the given node.
	 * This means that if the player walks on the given node, the boss
	 * battle will be initiated if the boss is alive.
	 * 
	 * @param node the node to place the boss on.
	 * @param image 
	 */
	public Boss(Node node, String name) {
		super(node, 1, 0, null, 0);
		this.name = name;
	}
	
	/**
	 * Enters the boss battle. It uses the given labyrinth to execute
	 * the boss battle if the boss is alive.
	 * 
	 * @param labyrinth the labyrinth to start the boss battle in.
	 */
	public void enterBossBattle(Labyrinth labyrinth) {
		if (isAlive()) {
			labyrinth.enterBattle(true, name);
		}
	}

	protected void setSettings() {
		// Not used by boss
	}
	public void activate(Labyrinth labyrinth) {
		// Not used by Boss
	}
	public void initDraw(GL2 gl) {
		// Not used by Boss
	}
	
	/**
	 * This method does nothing because the actual drawings of the boss 
	 * is taken care of by the battle. But it must be overridden to hinder
	 * the extends class Object2D to try and render it.
	 * 
	 * @param g the Graphics to draw with.
	 */
	public void draw(Graphics g) {
		// The boss is just a texture which is drawn by the wall renderer.
	}

	/**
	 * This method checks in the database if the boss is alive or not.
	 * 
	 * @return true if the boss is alive.
	 */
	public boolean isAlive() {
		status = Database.getStatusFor(dataBaseName);
		return status == 1;
	}

	@Override
	public String getMapImage() {
		return null;
	}
	
	public void drawInMap(Graphics g, float x, float y, int angle) {}

	public boolean isPassable(int dir) {return true;}
	public boolean isPassableOnThis(int dir) {return true;}

	@Override
	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return false;
	}
}
