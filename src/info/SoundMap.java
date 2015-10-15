/*
 * Classname: SoundMap.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/09/2008
 */
package info;

/**
 * This class is a static library for values concerning the sound effects.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 24 Sep 2008
 */
public class SoundMap {
    
    private static final String m = "Menu/";
    private static final String b = "Battle/";
    private static final String bm = "Battle/Magics/";
    private static final String l = "Labyrinth/";
    private static final String s = "Story/";
    private static final String v = "Village/";
    
    public static final String ACCEPT = m + "Accept.wav";
    public static final String ERROR = m + "Error.wav";
    public static final String NAVIAGATE = m + "Navigate.wav";
    public static final String LOOT = l + "Stub and Loot.wav";
    
    public static final String MENU_ACCEPT = ACCEPT;
    public static final String MENU_BACK = m + "Back.wav";
    public static final String MENU_ENTER_MENU = m + "Enter Menu.wav";
    public static final String MENU_ENTER_SUB_MENU = m + "Enter Submenu.wav";
    public static final String MENU_EQUIP_ARMOR = m + "Equip Armor.wav";
    public static final String MENU_EQUIP_SHIELD = m + "Equip Shield.wav";
    public static final String MENU_EQUIP_WEAPON = m + "Equip Weapon.wav";
    public static final String MENU_UNEQUIP_ARMOR = MENU_EQUIP_ARMOR;
    public static final String MENU_UNEQUIP_SHIELD = MENU_EQUIP_SHIELD;
    public static final String MENU_UNEQUIP_WEAPON = MENU_EQUIP_WEAPON;
    public static final String MENU_ERROR = ERROR;
    public static final String MENU_NAVIAGATE = NAVIAGATE;
    public static final String MENU_NAVIAGATE_IN_DECK = NAVIAGATE;    
    public static final String MENU_QUEST_LOG_ENTRY = m + "Questlog Entry.wav";
    public static final String MENU_SAVE = m + "Save.wav";
    public static final String MENU_SWITCH_CHARACTER = m + "Switch Character.wav";
	public static final String MENU_CHOOSE_CARD = ACCEPT;
	public static final String MENU_EXIT = MENU_BACK;
	public static final String MENU_SWITCH_DECK = MENU_SWITCH_CHARACTER;
    
    public static final String BATTLE_NAVIAGATE = NAVIAGATE;
    public static final String BATTLE_FINISH_ROUND = MENU_SWITCH_CHARACTER;
    public static final String BATTLE_CHARACTER_NAVIGATE = NAVIAGATE;
    public static final String BATTLE_FLIP_MODE = MENU_EQUIP_WEAPON;
    public static final String BATTLE_SAVE_CARD = ACCEPT;
    public static final String BATTLE_DISCARD_CARD = MENU_BACK;
    public static final String BATTLE_CHOOSE_CARD = ACCEPT;
    public static final String BATTLE_NEXT = ACCEPT;
    public static final String BATTLE_ERROR = ERROR;
    
    public static final String LABYRINTH_NOTE_1 = l + "Note 1.wav";
    public static final String LABYRINTH_NOTE_2 = l + "Note 2.wav";
    public static final String LABYRINTH_NOTE_3 = l + "Note 3.wav";
    public static final String LABYRINTH_NOTE_4 = l + "Note 4.wav";
    public static final String LABYRINTH_NOTE_5 = l + "Note 5.wav";
    public static final String LABYRINTH_NOTES = l + "Notes.wav";
    public static final String LABYRINTH_NOTES_DONE = l + "Notes Done.wav";
    
	public static final String LABYRINTH_LEVER_PRESSED = l + "Lever.wav"; // Check, not the best
    public static final String LABYRINTH_OPEN_CRATE = l + "Crate.wav"; // Check
    public static final String LABYRINTH_OPEN_STONE_BOX = l + "Stone Box.wav"; // Check,
    public static final String LABYRINTH_OPEN_WOODEN_CHEST = l + "Wooden Chest.wav"; // Check,
    public static final String LABYRINTH_OPEN_CHEST = LABYRINTH_OPEN_WOODEN_CHEST;
    public static final String LABYRINTH_OPEN_STUB = LOOT; // Check, in labyrinth not as loot in villages
    // Volcano?
    
    public static final String LABYRINTH_SAVE_PLACE = l + "Save Place.wav"; // Check
    // Too LOOOOOOONG...
    public static final String LABYRINTH_ACTIVATE_SYMBOL = l + "Activate Symbol.wav"; // Check,
    public static final String LABYRINTH_DOOR_ICE = l + "Ice Door.wav";
    public static final String LABYRINTH_DOOR_MOSS = l + "Moss Door.wav";
    public static final String LABYRINTH_DOOR_SLIDING_STONE = l + "Sliding Stone Door.wav";
    public static final String LABYRINTH_DOOR_STONE = l + "Stone Door.wav";
    public static final String LABYRINTH_DOOR_WOODEN = l + "Wooden Door.wav";
    public static final String LABYRINTH_LADDER = l + "Ladder.wav"; // Check
    public static final String LABYRINTH_STONE_STAIRS = l + "Stone Stairs.wav"; // Check
    public static final String LABYRINTH_SECRET = l + "Secret.wav"; // Check, Strong volume.
    
    // No sound for stichman
    // No sound for tunnleworm
    
    // Three different Kin attacks
    public static final String BATTLE_ATTACK_KIN = b + "Kin attack";
    // Two different Celis attacks
    public static final String BATTLE_ATTACK_CELIS = b + "Celis attack";
    // Two different Borealis attacks
    public static final String BATTLE_ATTACK_BOREALIS = b + "Borealis attack";
    // Two different Zalzi attacks
    public static final String BATTLE_ATTACK_ZALZI = b + "Zalzi attack";
    
    // Three different team misses.
    public static final String BATTLsE_MISS = b + "Miss";
    // Two different enemy misses.
    // What to do if the monster misses, if the sound is long.
    public static final String BATTLE_MISS_MONSTER = b + "Monstermiss";
    
    // Really??
    public static final String BATTLE_KIN_BOREALIS_DYING = b + "Kin or Borealis Dying.wav";
    // Low volume
    public static final String BATTLE_CELIS_ZALZI_DYING = b + "Celis or Zalzi Dying.wav";
    
    public static final String MAGICS_BLIZZARD = bm + "Blizzard2.wav";
    public static final String MAGICS_COLLIDING = bm + "Colliding2.wav";
    public static final String MAGICS_DEATH = bm + "Death2.wav";
    public static final String MAGICS_DEMOLISH = bm + "Demolish2.wav";
    public static final String MAGICS_EARTH = bm + "Earth2.wav";
    public static final String MAGICS_FIRE = bm + "Fire2.wav";
    public static final String MAGICS_FLARE = bm + "Flare2.wav";
    public static final String MAGICS_ICE = bm + "Ice2.wav";
    public static final String MAGICS_SACRED_BEAM = bm + "Sacred Beam2.wav";
    public static final String MAGICS_SLOW = bm + "Slow.wav";
    public static final String MAGICS_TORNADO = bm + "Tornado2.wav";
    public static final String MAGICS_ULTIMA = bm + "Ultima.wav";
    public static final String MAGICS_WIND = bm + "Wind2.wav";
    
    // Element changes?
    // Offenses ?? Drain?
    
    public static final String MAGICS_CURE = bm + "Cure.wav";
    public static final String MAGICS_HASTE = bm + "Haste.wav";
    public static final String MAGICS_RESURRECT = bm + "Resurrect.wav";
    public static final String MAGICS_STATUS_DOWN = bm + "Status Down.wav";
    public static final String MAGICS_STATUS_UP = bm + "Status Up.wav";
    
    public static final String VILLAGE_SLEEP = v + "Sleep.wav";
    public static final String VILLAGE_GODS_PORTAL = v + "Gods Portal.wav";
    
    public static final String STORY_BOAT = s + "Boat.wav";
    public static final String STORY_MENTHU_PICTURE = s + "Menthu Picture.wav";
    public static final String STORY_IMPRISPONED = s + "Imprisoned.wav";
}
