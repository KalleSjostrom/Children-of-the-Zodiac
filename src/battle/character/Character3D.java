/*
 * Classname: Character3D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/06/2008
 */
package battle.character;

import graphics.GraphicHelp;
import graphics.Graphics;
import info.BattleValues;
import info.Values;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;

import battle.equipment.GLDeck;
import battle.equipment.GLWeapon;
import character.Character;
import character.Creature;

/**
 * This class represents the character in the 3D battle. It shows information
 * about HP and progress.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 19 June 2008
 */
public class Character3D extends Creature3D {

	private Character character;

	private static final BufferedImage imW = 
		GraphicHelp.getImage(1, 1, Color.WHITE);

	/**
	 * Creates a new character3D which wraps the given character.
	 *  
	 * @param side the side on which to put the character3D. (ProgressBar.LEFT, .RIGHT)
	 * @param c the character to wrap.
	 */
	public Character3D(float side, Character c) {
		super(side, c);
		setImage(c.getImage());
		character = c;
		if (character.get2DDeck() == null) {
			GLDeck deck = new GLDeck();
			deck.setDeck(character.getDeck(), Character.HAND_SIZE);
			GLWeapon glWeapon = new GLWeapon(character);
			deck.setWeaponDeck(glWeapon);
			deck.shuffleAndDeal();
			character.set2DDeck(deck);
		}
	}
	
	/**
	 * Sets the given image as the texture for the creature. This image
	 * will be drawn next to the creature.
	 * 
	 * @param image the image to use when drawing the creature.
	 */
	protected void setImage(String image) {
		super.loadTexture(image, 0);
		setSize(0, BattleValues.CREATURE_SCALE);
	}

	/**
	 * This method sets the deck and weapon deck on the character.
	 * It also initiates the graphic of the deck.
	 * 
	 * @param gl the GL object to use when initializing the character.
	 */
	@Override
	protected void initCreature(Graphics g) {
		GLDeck deck = character.get2DDeck();
		if (deck.getNeedUpdate()) {
			deck.initDraw(g);
			deck.setNeedUpdate(false);
		}
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
			g.push();
			if (creature.hasTurn()) {
				g.translate(-.03f, -.02f, 0);
				g.scale(SCALE);
			}
			super.draw(g);
			g.pop();
		} else {
			if (criticalHit) {
				g.loadIdentity();
				g.setImageColor(.7f, 0, 0, .5f);
				g.drawImage(imW, 0, 0);
			}
		}
	}
	
	/**
	 * Draws the information about the character.
	 * This includes the name and life.
	 * 
	 * @param g the graphics2D object to draw the information on.
	 */
	@Override
	protected void drawInfo(Graphics2D g) {
		Color c = character.isAlive() ? Color.WHITE : Color.RED;
		
		GraphicHelp.drawStringWithBlackFrame(g, getName(), 5, 50, 40, c, 3, Values.BOLD);
		//GraphicHelp.drawStringWithBlackFrame(g, "Off:", 5, 73, 26, c, 3, Values.BOLD);
		GraphicHelp.drawStringWithBlackFrame(g, "Elem:", 5, 100, 26, c, 3, Values.BOLD);
		
		float hp = creature.getAttribute(Creature.HP);
		float max = creature.getAttribute(Creature.MAX_HP);
		if (hp / max < .2f) {
			c = Color.RED;
		}
		String s = character.getLife();
		String life = hp == 0 ? "Dead" : s;
		GraphicHelp.drawStringWithBlackFrame(g, life, 5, 139, 30, c, 3, Values.BOLD);
	}

	@Override
	protected void drawImage(Graphics g) {
		draw(g, 0, 0);
	}
}
