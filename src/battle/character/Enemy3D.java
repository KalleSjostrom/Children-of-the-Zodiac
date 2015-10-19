/*
 * Classname: Enemy3D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import graphics.GraphicHelp;
import graphics.Graphics;
import info.Values;

import java.awt.Color;
import java.awt.Graphics2D;

import character.Bestiary;
import character.Creature;
import character.Enemy;
import character.Bestiary.Stats;

/**
 * This class represents a enemy in the 3D battle. It shows information
 * about life and progress.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 19 June 2008
 */
public class Enemy3D extends Creature3D {

	private boolean showLife;
	private boolean showName;
	private String[] info;

	/**
	 * Creates a new character3D which wraps the given character.
	 *  
	 * @param side the side on which to put the enemy3D. 
	 * (ProgressBar.LEFT, .RIGHT)
	 * @param e the enemy to wrap.
	 */
	public Enemy3D(float side, Enemy e) {
		super(side, e);
		info = new String[2];
		setInfo();
		showLife = !info[Stats.HP].equals("???");
		showName = !info[Stats.NAME].equals("???");
	}
	
	protected void setInfo() {
		Stats stats = Bestiary.getBestiary().getStats((Enemy) creature);
		String[] stat = stats.getInfo();
		info[0] = stat[Stats.NAME];
		info[1] = stat[Stats.HP];
	}
	
	/**
	 * Draws the character if the timer is equal to zero. If one would like
	 * to hide this character, all that is needed is a call to the method
	 * setHideTimer(), in this class.
	 * 
	 * @see #setHideTimer(int, boolean)
	 * 
	 * @param g the Graphics object to use when rendering the character.
	 */
	@Override
	public void draw(Graphics g) {
		if (isVisible()) {
			super.draw(g);
		}
	}

	/**
	 * Draws the information about the character on the given graphics.
	 * 
	 * @param g the graphics2D to draw on.
	 */
	@Override
	protected void drawInfo(Graphics2D g) {
		showLife = !info[Stats.HP].equals("???");
		showName = !info[Stats.NAME].equals("???");
		
		String name = showName ? creature.getName() : "???";
		
		GraphicHelp.drawStringWithBlackFrame(g, name, 5, 30, 34, Color.WHITE, 3, Values.BOLD);
		GraphicHelp.drawStringWithBlackFrame(g, "Elem:", 5, 70, 26, Color.WHITE, 3, Values.BOLD);
		
		String life = showLife ? creature.getLife() : "???";
		float hp = creature.getAttribute(Creature.HP);
		float max = creature.getAttribute(Creature.MAX_HP);
		Color c = null;
		if (showLife && (hp / max < .2f)) {
			c = Color.red;
		} else {
			c = Color.white;
		}
		GraphicHelp.drawStringWithBlackFrame(g, life, 5, 100, 30, c, 3, Values.BOLD);
	}
	
	/**
	 * This method initiated the creature. It implements the method from
	 * the super class but it does not do anything for objects of Enemy3D.
	 * 
	 * @param gl the openGL object to use when initiating the creature.
	 */
	@Override
	protected void initCreature(Graphics g) {
		// Not used.
	}
	

	/**
	 * This method does nothing because the design team does not want 
	 * the enemy image to be shown.
	 * 
	 * @param gl the GL object to use when rendering.
	 */
	@Override
	protected void drawImage(Graphics g) {
		// Not used.
	}
}
