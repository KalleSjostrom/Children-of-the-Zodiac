/*
 * Classname: GLWeapon.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/06/2008
 */
package battle.equipment;

import graphics.Graphics;
import info.BattleValues;

import java.util.ArrayList;

import battle.Hideable;
import character.Character;
import equipment.Slot;
import equipment.Weapon;

/**
 * This deck is the slots residing in the weapon. It is therefore an empty deck
 * where the player can put the selected cards. When this deck is full or the
 * players turn is over for some other reason, this deck is sent to a 
 * battle calculator to calculate the damage made on the enemy.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 12 June 2008
 */
public class GLWeapon extends Hideable {
	
	public static final int OFFENSE_MODE = 0;
	public static final int DEFENSE_MODE = 1;

	private ArrayList<GLCard> cards = new ArrayList<GLCard>();
	private ArrayList<GLSlot> slots = new ArrayList<GLSlot>();
	private WeaponModeIcon icon;
	
	private int[] sizes;
	private int[] enabled;
	private int currentMode = OFFENSE_MODE;

	/**
	 * Creates a new GLWeapon based on the information in the given character.
	 * 
	 * @param c the character to create the weapon for.
	 */
	public GLWeapon(Character c) {
		super(2);
		setSlots(c);
		setAxis(Y_AXIS);
		setLimit(false);
		setMovementSpeed(false);
		setPos(BattleValues.DECK_POSITION - .065f, BattleValues.WEAPON_SLOTHEIGHT);
		instantHide();
	}

	/**
	 * Fills the list of GLSlots with the slots in the given weapon.
	 * 
	 * @param c the character to get the slots from.
	 */
	private void setSlots(Character c) {
		Weapon w = c.getWeapon();
		ArrayList<Slot> as = new ArrayList<Slot>();
		if (w != null) {
			as = w.getSlots();
		}
		ArrayList<Slot> ds = Slot.merge(c.getArmor(), c.getLeftHand());
		
		icon = new WeaponModeIcon(BattleValues.WEAPON_SLOT_X);
		sizes = new int[]{as.size(), ds.size()};
		int size = Math.max(as.size(), ds.size());
		Slot s1, s2 = null;
		for (int i = 0; i < size; i++) {
			s1 = i < as.size() ? as.get(i) : null;
			s2 = i < ds.size() ? ds.get(i) : null;
			slots.add(new GLSlot(s1, s2, AbstractDeck.xs[i]));
		}
		setFreeSlots();
	}

	/**
	 * Initiates the drawings of the GLWeapon.
	 * 
	 * @param gl the GL object to use when initiating.
	 */
	public void initDraw(Graphics g) {
		icon.initDraw(g);
		for (int i = 0; i < slots.size(); i++) {
			slots.get(i).initDraw(g);
		}
	}

	/**
	 * Overrides the draw method in the AbstractDeck so that the
	 * drawDeck() method can be called.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(float dt, Graphics g) {
		super.translate(g);
		icon.draw(dt, g, getYtrans());
		for (int i = 0; i < slots.size(); i++) {
			slots.get(i).draw(dt, g, getYtrans());
		}
		g.setAlphaFunc(.5f);
		drawDeck(g, cards);
		g.setAlphaFunc(0);
	}

	/**
	 * This method will draw all the cards in the given deck.
	 * 
	 * @param g the GL object to draw the deck on.
	 * @param deck the deck to draw.
	 */
	public void drawDeck(Graphics g, ArrayList<GLCard> deck) {
		for (int i = 0; i < deck.size(); i++) {
			deck.get(i).draw(g, getYtrans());
		}
	}

	/**
	 * This method gets a list of the free slots in the weapon.
	 * Use the types in the class Slots as indices in the produced list 
	 * to get how many free slots there are for that type.
	 * 
	 * @return a list of the free slots in this weapon.
	 */
	private int[] setFreeSlots() {
		enabled = new int[3];
		for (int i = 0; i < sizes[currentMode]; i++) {
			if (slots.get(i).isFree(currentMode)) {
				enabled[slots.get(i).getKind(currentMode)]++;
			}
		}
		return enabled;
	}

	/**
	 * This method receives a card. It adds the card to one of the slots.
	 * and sets the cards target so it will travel there on its own. The 
	 * returned array contains three values, one for each type of slot.
	 * These values represents how many slots this weapon has left of a certain
	 * type. If the weapon has 2 offense slots, 1 magic slots and 0 support
	 * slots and the player has played 1 offense and 1 magic the returned array
	 * will contain 1, 0, 0.
	 * 
	 * @param card the card to add.
	 * @return the list of enabled cards of the different types. 
	 */
	public int[] receive(GLCard card) {
		if (card.isEnabled() && cards.size() < slots.size()) {
			int index = -1;
			for (int i = 0; i < slots.size() && index == -1; i++) {
				GLSlot slot = slots.get(i);
				if (slot.doesFit(card, currentMode)) {
					index = i;
					slot.setCard(card.card);
					card.card.putInSlot(slot.getKind(currentMode));
				}
			}
			if (index != -1) {
				card.setInSlot(AbstractDeck.xs[index]);
				cards.add(card);
				enabled[card.getType()]--;
				return enabled;
			}
		}
		return null;
	}

	/**
	 * This method empties the weapon deck.
	 */
	public void empty() {
		for (int i = 0; i < slots.size(); i++) {
			slots.get(i).clearSlot();
		}
		cards.clear();
		setFreeSlots();
	}

	/**
	 * Switches the mode for the player. This means that if the player was in 
	 * the offense mode it is switched to defense mode.
	 * 
	 * @return the mode after the switch if the switch was made or -1 if the
	 * weapon is not empty.
	 */
	public int switchSide() {
		if (cards.size() == 0) {
			currentMode = (currentMode + 1) % 2;
			icon.toggleSide();
			for (int i = 0; i < slots.size(); i++) {
				slots.get(i).toggleSide();
			}
			setFreeSlots();
			return currentMode;
		}
		return -1;
	}
	
	/**
	 * This method switches the side to attack mode if the current mode
	 * is the defense mode.
	 */
	public void setToAttackMode() {
		if (currentMode == DEFENSE_MODE) {
			switchSide();
		}
	}

	/**
	 * Checks if the weapon decks slots is filled with cards.
	 * 
	 * @return true if every slot has a card.
	 */
	public boolean isFull() {
		return cards.size() == sizes[currentMode];
	}

	/**
	 * Gets the cards put in the weapon.
	 * 
	 * @return the list of cards in this weapon.
	 */
	protected ArrayList<GLCard> getCards() {
		return cards;
	}

	/**
	 * Gets an array containing the information about which slots are free.
	 * 
	 * @return an array which contains information about which slots are free.
	 */
	public int[] getFreeSlots() {
		return enabled;
	}

	/**
	 * Gets the current mode that this weapon is in. This can be either of 
	 * GLWeapon.OFFENSE_MODE, or GLWeapon.DEFENSE_MODE.
	 *  
	 * @return the mode that this weapon is in.
	 */
	public int getMode() {
		return currentMode;
	}

	/**
	 * Updates the cards in this weapon, if there are any.
	 */
	public void updatePos(float dt) {
		for (int i = 0; i < cards.size(); i++) {
			cards.get(i).update(dt);
		}		
	}
}
