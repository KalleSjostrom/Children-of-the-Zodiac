/*
 * Classname: BattleValues.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package info;

import graphics.ImageHandler;

/**
 * This class is a static library for values concerning the battle.
 * It has values for scales, positions, speeds to name a few.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 21 July 2008
 */
public class BattleValues {

	// General
	/**
	 * The standard Z depth in the game.
	 */
	public static final float STANDARD_Z_DEPTH = -2;

	// BattleEnemy
	/**
	 * The standard Z depth of the enemies.
	 */
	public static final float ENEMY_DEPTH = -6;
	
	/**
	 * The standard height of the enemy.
	 */
	public static final float ENEMY_HEIGHT = -2;
	
	// GLCard
	/**
	 * The speed of the card flip. Used when flipping a card in battle.
	 */
	public static final float CARD_FLIP_SPEED = 0.6f;
	
	/**
	 * The speed of the card when it is moving.
	 */
	public static final float CARD_MOVE_SPEED = .0018f;
	public static final float CARD_MOVE_SPEED_2 = .0024f;
	
	/**
	 * The y (height) offset to use when drawing a selected card.
	 * The selected card will be drawn higher than it normally would.
	 */
	public static final float CARD_SELECTED_OFFSET = .025f;
	
	/**
	 * The scale of the card image.
	 */
	public static final float CARD_SCALE = 0.002f;
	
	/**
	 * The standard distance between the cards.
	 */
	public static final float CARD_DISTANCE_BETWEEN = .212f;

	// GLDeck
	/**
	 * The height of the slots images in the deck.
	 */
	public static final float DECK_HEIGHT_SLOTS = -.65f;
	
	/**
	 * The height of the cards in the deck.
	 */
	public static final float DECK_HEIGHT_CARDS = -.3f;
	
	/**
	 * The position of the deck in battle (bottom left).
	 */
	public static final float DECK_POSITION = -.95f;
	
	// Creature row
	/**
	 * The scale of the creature images.
	 */
	public static final float CREATURE_SCALE = .0017f;

	// Character row
	/**
	 * The distance between the characters on the x axle.
	 */
	public static float DISTANCE_BETWEEN_CHARACTERS_X;
	
	/**
	 * The array containing the positions of the characters in battle.
	 */
	public static float[] CHARACTER_POSITION = new float[3];
	public static final float CHARACTER_POS_Y = .5f;
	
	/**
	 * The number of characters in battle.
	 */
	public static int NR_CHARACTERS = 0;

	private static float[] CHARACTER_OFFSETS;
	
	// Enemy row
	/**
	 * The distance between the enemies on the y axle.
	 */
	public static final float DISTANCE_BETWEEN_ENEMIES = -.25f;
	
	/**
	 * The array containing the positions of the enemies in battle.
	 */
	public static final float[] ENEMY_ROW_POSITION = {.9f, .19f};
	
	private static final float[][] ENEMY_POS_FOR_TEXT = createEnemyPosForText();
	private static float[][] CHAR_POS_FOR_HAND;
	public static float[][] CHAR_POS_FOR_TEXT;
	
	// GLWeapon
	/**
	 * The scale of a slot in battle.
	 */
	public static final float SLOT_SCALE = .002f;
	
	/**
	 * The slot height in the weapon deck. The deck used to put the cards
	 * in when battling.
	 */
	public static final float WEAPON_SLOTHEIGHT = -.325f;
	
	/**
	 * The x position of the weapon deck. This is currently the same as the
	 * DECK_POSITION.
	 */
	public static final float WEAPON_SLOT_X = DECK_POSITION;
	
	/**
	 * The scale of the weapon mode icon.
	 */
	public static final float WEAPON_MODE_ICON_SCALE = .002f;

	// GLHand
	/**
	 * The scale of the menu hand that is pointing in battle.
	 */
	public static final float HAND_SCALE = 0.0025f;

	// Result screen
	/**
	 * The scale of the result screen. 
	 */
	public static final float RESULT_SCALE = 0.0015f;
	
	// Clock
	/**
	 * The position of the clock in battle.
	 */
	public static final float[] CLOCK_POSITION = new float[]{-1.0f, -.3f};
	
	public static final float[] ENEMY_POSITION = new float[]{-1.1f, -.2f};
	

	/**
	 * Representing the haste speed mode.
	 */
	public static final int HASTE = 0;

	/**
	 * Representing the slow speed mode.
	 */
	public static final int SLOW = 1;

	/**
	 * The image of the back of a card.
	 */
	public static final String CARD_BACK = 
		ImageHandler.addPermanentlyLoadNow(Values.Cards + "back.png");

	/**
	 * Sets the position of the characters based on the number of characters
	 * in the party.
	 *  
	 * @param size the size of the party.
	 * @return the position array containing the position of the characters.
	 */
	public static float[] setCharacterPosition(int size) {
		float[] ret;
		if (size == 4) {
			DISTANCE_BETWEEN_CHARACTERS_X = .53f;
			CHARACTER_OFFSETS = new float[]{-.16f, 1.25f};
			ret = new float[]{-1.03f, CHARACTER_POS_Y};
		} else if (size == 3) {
			DISTANCE_BETWEEN_CHARACTERS_X = .75f;
			CHARACTER_OFFSETS = new float[]{-.17f, 1.25f};
			ret = new float[]{-.95f, CHARACTER_POS_Y};
		} else if (size == 2) {
			DISTANCE_BETWEEN_CHARACTERS_X = 1f;
			CHARACTER_OFFSETS = new float[]{-.225f, 1.25f};
			ret = new float[]{-.7f, CHARACTER_POS_Y};
		} else {
			DISTANCE_BETWEEN_CHARACTERS_X = 1.2f;
			CHARACTER_OFFSETS = new float[]{0, 1.25f};
			ret = new float[]{-.2f, CHARACTER_POS_Y};
		}
		NR_CHARACTERS = size;
		CHARACTER_POSITION = ret;
		CHAR_POS_FOR_HAND = createCharPosForHand();
		CHAR_POS_FOR_TEXT = createCharPosForText();
		return CHARACTER_POSITION;
	}

	private static float[][] createCharPosForHand() {
		float[][] pos = new float[NR_CHARACTERS][2];
		for (int i = 0; i < NR_CHARACTERS; i++) {
			pos[i] = createCharPosForHand(i);
		}
		return pos;
	}

	private static float[][] createCharPosForText() {
		float[][] pos = new float[NR_CHARACTERS][2];
		for (int i = 0; i < NR_CHARACTERS; i++) {
			pos[i] = createCharPosForText(i);
		}
		return pos;
	}

	private static float[][] createEnemyPosForText() {
		float[][] pos = new float[3][2];
		for (int i = 0; i < 3; i++) {
			pos[i] = createEnemyPosForText(i);
		}
		return pos;
	}

	/**
	 * Gets the position of the character with the given index.
	 * 
	 * @param index the index of the character whose position to get.
	 * @return the position of the character with the given index.
	 */
	private static float[] createCharPosForHand(int index) {
		index = Math.min(NR_CHARACTERS - 1, index);
		float[] pos = createCharPosForText(index);
		pos[1] += .16f;
		return pos;
	}
	
	private static float[] createCharPosForText(int index) {
		float[] pos = new float[2];
		pos[0] = 
			(CHARACTER_POSITION[0] - CHARACTER_OFFSETS[0] - .15f) + 
			(index * DISTANCE_BETWEEN_CHARACTERS_X * CHARACTER_OFFSETS[1]);
		pos[1] = CHARACTER_POSITION[1] + .18f;
		return pos;
	}
	
	private static float[] createEnemyPosForText(int index) {
		float[] pos = new float[2];
		pos[0] = ENEMY_ROW_POSITION[0] + .1f;
		pos[1] = ENEMY_ROW_POSITION[1] + .05f + DISTANCE_BETWEEN_ENEMIES * index;
		return pos;
	}
	
	public static float[] getCharPosForHand(int index) {
		index = Math.min(CHAR_POS_FOR_HAND.length - 1, index);
		return CHAR_POS_FOR_HAND[index];
	}
	
	public static float[] getCharPosForText(int index) {
		index = Math.min(CHAR_POS_FOR_TEXT.length - 1, index);
		return CHAR_POS_FOR_TEXT[index];
	}
	
	public static float[] getEnemyPosForText(int index) {
		return ENEMY_POS_FOR_TEXT[index];
	}

	/**
	 * Gets the x position of the character with the given index.
	 * 
	 * @param index the index of the character whose position to get.
	 * @return the x position of the character with the given index.
	 */
	public static float getCharPosXForSupport(int index) {
		index = Math.min(CHAR_POS_FOR_TEXT.length - 1, index);
		if (CHARACTER_POSITION == null) {
			return 0;
		}
		return CHARACTER_POSITION[0] + index * DISTANCE_BETWEEN_CHARACTERS_X;
	}
}
