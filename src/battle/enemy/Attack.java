/*
 * Classname: Clock.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle.enemy;

import graphics.Graphics;
import graphics.TextManager;

import java.awt.Color;
import java.awt.geom.Rectangle2D;

/**
 * This class manages the time in battle. Each character has a limited time
 * to put all the cards in the weapon and attack. This limited time is
 * managed by the clock and the turn is finished when the time has run out.
 * The clock is Hideable and will show when a players turn is initiated.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 21 July 2008
 */
public class Attack {

	private static final int Y_POS = 735;
	private static final int SPEED = 60;
	private int pos;
	private int startPos;
	private boolean visible;
	private int dest;
	private String name;
	
	private AttackBackground ab;

	/**
	 * Constructs a new hideable clock.
	 * It uses an instance of TimeBar to illustrate the time.
	 */
	public Attack() {
		ab = new AttackBackground();
		setAttackName("Death Claw Super");
	}
	
	public void setAttackName(String name) {
		this.name = name;
		Rectangle2D r = 
			TextManager.createRenderer(50).getBounds(name);
		int width = (int) Math.round(r.getWidth() / 2);
		startPos = -width;
		pos = startPos;
		dest = (int) (512 - width);
	}
	
	public void update(float dt) {
		ab.update(dt);
	}

	/**
	 * Initiates the drawing of the clock.
	 * 
	 * @param gl the GL object to initiates the drawing on.
	 */
	public void initDraw(Graphics g) {
		ab.initDraw(g);
	}
	
	public void show() {
		visible = true;
		ab.show();
	}
	
	public void hide() {
		pos = startPos;
		visible = false;
		ab.hide();
	}
	
	/**
	 * This method draws the time on the screen.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(float dt, Graphics g) {
		ab.draw(dt, g);
		if (visible) {
			g.loadIdentity();
			g.setFontSize(46);
			if (pos + SPEED < dest) {
				pos = pos + SPEED;
			} else {
				pos = dest;
			}
			int shadowX = Math.round(dest + (Math.abs(pos - dest)));
			g.setColor(Graphics.BLACK);
			g.drawString(name, shadowX + 3, Y_POS + 3);
			g.setColor(Graphics.WHITE);
			g.drawString(name, Math.round(pos), Y_POS);
		}
	}
}
