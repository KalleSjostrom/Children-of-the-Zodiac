/*
 * Classname: Clock.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle;

import graphics.Graphics;
import info.BattleValues;
import info.Values;

import java.awt.Color;

import battle.bars.TimeBar;

/**
 * This class manages the time in battle. Each character has a limited time
 * to put all the cards in the weapon and attack. This limited time is
 * managed by the clock and the turn is finished when the time has run out.
 * The clock is Hideable and will show when a players turn is initiated.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 21 July 2008
 */
public class Clock extends Hideable {

	private static final int FLEE_SPEED = 60;
	private static final int FLEE_DESTINATION_X = 440;
	private static final int DEFAULT_X_POS = Values.ORIGINAL_RESOLUTION[Values.X];
	
	private TimeBar timeBar;
	private boolean abort = false;
	private boolean fleeing = false;
	private float timeLeft;
	private float fleeXpos = DEFAULT_X_POS;
	private int maxTime;
	private static final int TIME = 10; 

	/**
	 * Constructs a new hideable clock.
	 * It uses an instance of TimeBar to illustrate the time.
	 */
	public Clock() {
		super(1);
		setLimit(false);
		setMovementSpeed(false);
		instantHide();
		timeBar = new TimeBar(0);
		timeBar.update(1);
	}

	/**
	 * Resets the clock and sets the time to the given value.
	 * The time is the amount of seconds before this clock
	 * finishes the current round.
	 */
	public void reset() {
		timeBar.update(1);
		timeLeft = maxTime = TIME;
		new Thread() {
			public void run() {
				abort = false;
				while (timeLeft > 0 && !abort) {
//					timeLeft -= .03;
					timeBar.update(timeLeft / maxTime);
					Values.sleep(30);
				}
			}
		}.start();
	}

	/**
	 * This method finishes the current clock so that a new
	 * one is ready to be reseted.
	 */
	public void finish() {
		abort = true;
	}

	/**
	 * Initiates the drawing of the clock.
	 * 
	 * @param gl the GL object to initiates the drawing on.
	 */
	public void initDraw(Graphics g) {
		setPos(BattleValues.CLOCK_POSITION);
		timeBar.initDraw(g);
	}
	
	/**
	 * Initiates the flee procedure by setting some values.
	 */
	public void initFlee() {
		fleeXpos = DEFAULT_X_POS;
		fleeing = true;
	}
	
	/**
	 * Resets the flee procedure.
	 */
	public void resetFlee() {
		fleeing = false;
	}

	/**
	 * This method draws the time on the screen.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.loadIdentity();
		g.setFontSize(40);
		if (visible && fleeing) {
			if (fleeXpos - FLEE_SPEED > FLEE_DESTINATION_X) {
				fleeXpos = fleeXpos - FLEE_SPEED;
			} else {
				fleeXpos = FLEE_DESTINATION_X;
			}
			int shadowX = Math.round(DEFAULT_X_POS - (fleeXpos + 144));
			int hy = Values.ORIGINAL_RESOLUTION[Values.Y];
			g.drawWithShadow("Fleeing",  shadowX + 4, hy, Color.BLACK);
			g.drawWithShadow("Fleeing", Math.round(fleeXpos), hy);
		}
		translate(g);
		timeBar.draw(g);
	}

	/**
	 * This method checks if the time is up.
	 * 
	 * @return true if the time is up.
	 */
	public boolean timesUp() {
		return false; //timeLeft <= 0;
	}

	public float getTime() {
		return TIME - timeLeft;
	}
}
