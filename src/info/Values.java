/*
 * Classname: Values.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package info;

import graphics.GraphicHelp;
import graphics.Graphics;

import java.awt.DisplayMode;
import java.awt.Font;
import java.awt.FontFormatException;
import java.awt.GraphicsEnvironment;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.HashMap;
import java.util.Random;
import java.util.StringTokenizer;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sound.sampled.AudioFormat;

import com.jogamp.openal.AL;
import com.jogamp.openal.ALC;
import com.jogamp.openal.ALException;
import com.jogamp.openal.ALFactory;
import com.jogamp.openal.util.ALut;

import organizer.GameEventListener;
import organizer.ResourceLoader;

import villages.villageStory.Parser;
import character.Creature;

/**
 * This is a class with the values concerning the game.
 * All the values is declared static and final. There are also
 * some static methods like getFont() or other methods which are 
 * frequently used.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 21 Jan 2008
 */
public class Values {

	private static final String s = "/";
	public static final String res = "res" + s;
	public static final String maps = "maps" + s;
	public static final String lib = "lib" + s;

	/* The paths to the different resource folders */
	public static final String MainRes = res + "Main" + s;
	public static final String MainMap = maps + "Main" + s;
	public static final String TitleImages = res + "Title" + s;
	public static final String Music = res + "Music" + s;
	public static final String StoryImages = res + "Story" + s;
	public static final String Banks = maps + "Banks" + s;
	public static final String BattleImages = res + "Battle" + s;
	public static final String EnemyMaps = maps + "Battle" + s + "EnemyMaps" + s;
	public static final String LabyrinthMaps = maps + "Labyrinth" + s;
	public static final String LabyrinthTriggers = maps + "Labyrinth" + s + "Triggers" + s;
	public static final String LabyrinthTextures = res + "Labyrinth" + s;
	public static final String VillageImages = res + "Village" + s;
	public static final String VillageMaps = maps + "Village" + s;
	public static final String LandscapeMaps = maps + "Landscape" + s;
	public static final String LandscapeImages = res + "Landscape" + s;
	public static final String MenuImages = res + "Menu" + s;
	public static final String StoreImages = res + "Store" + s;
	public static final String Cards = res + "Cards" + s;
	public static final String SoundEffects = res + "SoundEffects" + s;
	public static final String BattleSoundEffects = "Battle" + s;
	public static final String BattleBarImages = res + "Battle" + s + "bar" + s;
	public static final String EnemyImages = res + "Battle" + s + "enemies" + s;
	public static final String MiniGamesImages = res + "MiniGames" + s;
	public static final String MiniGamesMaps = maps + "MiniGames" + s;
	public static final String AnimationImages = VillageImages + "Characters" + s + "Animation" + s;
	public static final String Shaders = res + "Shaders" + s;
	public static final String Emotions = res + "Emotions" + s;
	public static final String StorySequences = maps + "Story" + s + "Sequences" + s;
	public static final String ParticleSystemsImages = res + "ParticleSystems" + s;
	public static final String ParticleSystemsMaps = maps + "ParticleSystems" + s;
	public static final String Tutorials = maps + "Tutorials" + s;
		
	/* The audio format */
	public static final AudioFormat PLAYBACK_FORMAT =
		new AudioFormat(44100, 16, 2, true, false);
	public static final float MAX_VOLUME = .9f; // .75
	public static AL al;

	/* The different modes in the game */
	public static final int TITLE = 0;
	public static final int STORY = 1;
	public static final int VILLAGE = 2;
	public static final int LANDSCAPE = 3;
	public static final int LABYRINTH = 4;
	public static final int BATTLE = 5;
	public static final int MENU = 6;
	public static final int WEAPONSTORE = 7;
	public static final int CHURCH = 8;
	public static final int HOUSE = 9;
	public static final int INN = 10;
	public static final int CARDSTORE = 11;
	public static final int LIBRARY = 12;
	public static final int STORY_SEQUENSE = 13;
	public static final int VILLAGE_STORY = 14;
	public static final int AIR_SHIP = 15;
	public static final int CHEATER = 16;
	public static final int SWITCH_BACK = 17;
	public static final int EXIT = 18;
	public static final int GAME_OVER = 19;
	public static final int LANDSCAPE_TEST = 20;
	public static final int BATTLE_TEST = 21;
	public static final int NEW_MENU = 22;
	public static final int BOSS_BATTLE_AREA = 23;
	public static final int NO_MODE_IS_SELECTED = -1;

	/* Input controll */
	public static final int DETECT_ALL = 0;
	public static final int DETECT_INIT = 1;
	public static final int DETECT_AS_KEY = 2;

	/* Locations and directions */ 
	public static final int[] DIRECTIONS = {-1, 1, 1, -1};
	public static final int[] COUNTER_DIRECTIONS = {1, 1, -1, -1};
	public static final float[] TO_ANGLE = {90, 180, -90, 0};
	public static final int X = 1;
	public static final int Y = 0;
	public static final int UP = 0;
	public static final int RIGHT = 1;
	public static final int DOWN = 2;
	public static final int LEFT = 3;
	
		/* Frame rate */
	public static int FPS = 60;
	public static float INTERVAL = 1000f / FPS;
	public static float LOGIC_INTERVAL = INTERVAL; // 1000f / 30;
	
	/* The resolution */
	public static int[] RESOLUTIONS;
	public static int[] ORIGINAL_RESOLUTION = {768, 1024};
	public static float WIDE_SCREEN_HEIGHT = 576;
	public static float RESOLUTION_X_PRECENT;
	public static float RESOLUTION_Y_PRECENT;
	private static final int SMALLER = 600;
	private static final int SMALL = 800;
	private static final int MEDIUM = 1024;
	private static final int LARGE = 1152;
	private static final int LARGER = 1280;
	private static final int DYNAMIC_SIZE = 0;
	private static final int MANUAL = -1;
	public static int resMode = 0;
	public static final float ASPECT_RATIO_16_9 = 16f / 9f;
	public static final float ASPECT_RATIO_8_5 = 8f / 5f;
	public static final float ASPECT_RATIO_4_3 = 4f / 3f;

	public static final int[] ATTRIBUTE_MAP = createAttributeMap();
	public static final boolean[] SETTINGS_MAP = createSettingsMap();
//	static {
//		parseFile("settings.txt");
//	}
	public static final int FULL_SCREEN = 0;
	public static final int MUTE_MUSIC = 1;
	public static final int SOUND_EFFECTS = 2;

	public static final int LEVEL_UP_LEVEL = 25;

	/* The font */
	private static Font[] font = new Font[2];
	private static Logger logger = Logger.getLogger("Values");
	public static final int PLAIN = 0;
	public static final int BOLD = 1;

	public static final float WHITE = 1;
	
	public static final Random rand = new Random();
	
	public static enum characters {
		KIN(0, "Kin"), 
		CELIS(1, "Celis"),
		BOREALIS(2, "Borealis"),
		ZALZI(3, "Zalzi"),
		NO_CHARACTER(-1, "No Char");
		
		private int index;
		private String name;
		
		characters(int index, String name) {
			this.index = index;
			this.name = name;
		}
		
		public int getIndex() {
			return index;
		}

		public String getName() {
			return name;
		}

		public static characters getCharacter(String name) {
			if (name.equals(KIN.name)) {
				return KIN;
			} else if (name.equals(CELIS.name)) {
				return CELIS;
			} else if (name.equals(BOREALIS.name)) {
				return BOREALIS;
			} else if (name.equals(ZALZI.name)) {
				return ZALZI;
			} else {
				return NO_CHARACTER;
			}
		}
		
		public static characters getCharacter(int index) {
			if (index == KIN.index) {
				return KIN;
			} else if (index == CELIS.index) {
				return CELIS;
			} else if (index == BOREALIS.index) {
				return BOREALIS;
			} else if (index == ZALZI.index) {
				return ZALZI;
			} else {
				return NO_CHARACTER;
			}
		}
	};

	/**
	 * Initiates the open AL and returns the AL object.
	 * 
	 * @return the AL instance returned by ALFactory.getAL().
	 */
	public static void initAL() {
		try {
			ALut.alutInit();
			al = ALFactory.getAL();
			al.alGetError();
		} catch (ALException e) {
			logger.log(Level.SEVERE, "Error initializing OpenAL");
			e.printStackTrace();
		}
	}
	
	public static boolean soundEnabled() {
		return SETTINGS_MAP[SOUND_EFFECTS];
	}
	
	public static void init() {
//		SETTINGS_MAP[MUTE_MUSIC] = true;
		if (!SETTINGS_MAP[MUTE_MUSIC] || !SETTINGS_MAP[SOUND_EFFECTS]) {
			initAL();
		}
	}
	
	public static HashMap<Integer, String> drawLists = 
		new HashMap<Integer, String>();

	/**
	 * Loads a font from the resources.
	 * 
	 * @return the loaded font.
	 */
	public static Font loadFont() {
		try {
			font[PLAIN] = Font.createFont(Font.TRUETYPE_FONT, 
					ResourceLoader.getResourceLoader().getFontAsStream(PLAIN));
			font[BOLD] = Font.createFont(Font.TRUETYPE_FONT, 
					ResourceLoader.getResourceLoader().getFontAsStream(BOLD));
		} catch (FontFormatException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return font[0];
	}

	/**
	 * Gets the game font with the given size.
	 *  
	 * @param size the size of the font.
	 * @param size2 
	 * @return the font with the new size.
	 */
	public static Font getFont(int f, int size) {
		return font[f].deriveFont(Font.PLAIN, size);
	}
	
	public static Font getFont(int size) {
		return font[PLAIN].deriveFont(Font.PLAIN, size);
	}
	
	/**
	 * Puts the thread to sleep for the given amount of time
	 * 
	 * @param time the time to sleep
	 */
	public static void sleep(int time) {
		try {
			Thread.sleep(time);
		} catch (InterruptedException e) {
			logger.log(Level.WARNING, "Sleep interrupted...");
		}
	}

	/**
	 * Creates an integer array which is used to store an x, y position.
	 * This method does not recalculates the input values.
	 * 
	 * @param x the x value to be stored as an integer array.
	 * @param y the y value to be stored as an integer array.
	 * @return the newly created integer array.
	 */
	public static int[] createNormalPoint(int x, int y) {
		int[] p = new int[2];
		p[X] = x;
		p[Y] = y;
		return p;
	}

	/**
	 * Creates an float array which is used to store an x, y position.
	 * This method does not recalculates the input values.
	 * 
	 * @param x the x value to be stored as an float array.
	 * @param y the y value to be stored as an float array.
	 * @return the newly created float array.
	 */
	public static float[] createNormalFloatPoint(int x, int y) {
		float[] p = new float[2];
		p[X] = x;
		p[Y] = y;
		return p;
	}

	/**
	 * Converts the given integer array representing a position to
	 * a float array representing the same position. A position array
	 * is two values stored so that [0] = Y, [1] = X.
	 * 
	 * @param pos the position to convert.
	 * @return a float array representing the given position.
	 */
	public static float[] convertToFloatArray(int[] pos) {
		return createNormalFloatPoint(pos[Values.X], pos[Values.Y]);
	}

	/**
	 * Gets the direction opposite from the given direction. It
	 * returns StaticValues.UP if it is called with .DOWN and so on.
	 * 
	 * @param dir the direction to reverse.
	 * @return the direction opposite the given one.
	 */
	public static int getCounterAngle(int dir) {
		return Math.abs((dir + 2) % 4);
	}

	/**
	 * Gets the hash map containing a map from the integer values representing
	 * a game mode to the actual class name.
	 * 
	 * @return a hash map mapping integers to class names.
	 */
	public static HashMap<Integer, String> getClassMap() {
		HashMap<Integer, String> classMap = new HashMap<Integer, String>();
		classMap.put(TITLE, "title.TitleScreen");
		classMap.put(STORY, "story.Story");
		classMap.put(CHEATER, "organizer.Cheater");
		classMap.put(LABYRINTH, "labyrinth.Labyrinth");
		classMap.put(CHURCH, "store.Church");
		classMap.put(LANDSCAPE, "landscape.Landscape");
		classMap.put(STORY_SEQUENSE, "story.StorySequence");
		classMap.put(VILLAGE, "villages.Village");
		classMap.put(WEAPONSTORE, "store.WeaponStore");
		classMap.put(CHURCH, "store.Church");
		classMap.put(INN, "store.Inn");
		classMap.put(CARDSTORE, "store.CardStore");
		classMap.put(LIBRARY, "store.Library");
		classMap.put(HOUSE, "store.House");
		classMap.put(MENU, "menu.MainMenu");
		classMap.put(VILLAGE_STORY, "villages.villageStory.VillageStory");
		classMap.put(GAME_OVER, "title.GameOver");
		classMap.put(AIR_SHIP, "landscape.airship.AirLandscape");
		classMap.put(LANDSCAPE_TEST, "villages.Landscape");
		classMap.put(BATTLE_TEST, "battleTest.BattleTest");
		classMap.put(BOSS_BATTLE_AREA, "battle.BossBattleArea");
		return classMap;
	}

	/**
	 * Creates a map containing the attributes of a creature.
	 *  
	 * @return a map containing the attributes of a creature.
	 */
	private static int[] createAttributeMap() {
		int[] map = new int[8];
		map[0] = Creature.ATTACK;
		map[1] = Creature.MAGIC_ATTACK;
		map[2] = Creature.SUPPORT_ATTACK;
		map[3] = Creature.AGILITY;
		map[4] = Creature.DEFENSE;
		map[5] = Creature.MAGIC_DEFENSE;
		map[6] = Creature.HIT;
		map[7] = Creature.EVADE;
		return map;
	}
	
	private static boolean[] createSettingsMap() {
		boolean[] map = new boolean[5];
		map[FULL_SCREEN] = true;
		map[MUTE_MUSIC] = false;
		map[SOUND_EFFECTS] = true;
		return map;
	}

	/**
	 * Parses a line in the file and executes the commands in the file.
	 * These commands is executed via the executeCommand() method,
	 * which all the subclasses of the AbstractFatory must implement.
	 * 
	 * @param line the line to read.
	 */
	public static void parseLine(String line) {
		StringTokenizer tokenizer = new StringTokenizer(line);
		boolean lineOk = !line.equals("") && !line.equals(" ") && !line.equals("\t");
		if (lineOk && tokenizer.hasMoreTokens()) {
			String command = tokenizer.nextToken();
			executeCommand(command, tokenizer);
		}
	}
	
	private static void executeCommand(
			String command, StringTokenizer t) {
		if (command.equals("set")) {
			String[] args = Parser.getArgument(t.nextToken());
			String setting = args[0];
			if (setting.equals("fps")) {
				try {
					FPS = Integer.parseInt(args[1]);
					INTERVAL = Math.round(1000.0 / FPS);
				} catch (NumberFormatException e) {
					error("It must be an integer number after fps in settings.txt");
				}
			} else if (setting.equals("resolution")) {
				if (args[1].equals("dynamic")) {
					resMode = DYNAMIC_SIZE;
				} else if (args[1].equals("smallest")) {
					resMode = SMALLER;
				} else if (args[1].equals("small")) {
					resMode = SMALL;
				} else if (args[1].equals("medium")) {
					resMode = MEDIUM;
				} else if (args[1].equals("large")) {
					resMode = LARGE;
				} else if (args[1].equals("largest")) {
					resMode = LARGER;
				} else {
					resMode = MANUAL;
					String[] size = args[1].split(":");
					RESOLUTIONS = createNormalPoint(
							Integer.parseInt(size[0]),
							Integer.parseInt(size[1]));
				}
			} else if (setting.equals("fullscreen")) {
				SETTINGS_MAP[FULL_SCREEN] = Boolean.parseBoolean(args[1]);
			}
			
		}
		ALC alc = ALFactory.getALC();

	       System.out.println("Available devices: " + alc.alcGetString(null, ALC.ALC_DEFAULT_DEVICE_SPECIFIER));
		// SETTINGS_MAP[MUTE_MUSIC] = true;
//			String s = t.nextToken();
//			if (s.equals("music")) {
//				SETTINGS_MAP[MUTE_MUSIC] = true;
//			} else if (s.equals("soundEffects")) {
//				SETTINGS_MAP[SOUND_EFFECTS] = false;
//			} else if (s.equals("fullscreen")) {
//			} else if (s.equals("allSound")) {
//				SETTINGS_MAP[MUTE_MUSIC] = true;
//				SETTINGS_MAP[SOUND_EFFECTS] = false;
//			}
//		}
	}

	private static void error(String string) {
		logger.log(Level.SEVERE, "Fatal error: " + string);
		logger.info("Setting default");
	}

	/**
	 * Sets the resolution of the screen to the given width and height.
	 * 
	 * @param width the width of the screen.
	 * @param height the height of the screen.
	 */
	public static void setResolution(int width, int height) {
		RESOLUTIONS = createNormalPoint(width, height);
		RESOLUTION_X_PRECENT = RESOLUTIONS[X] / (float) ORIGINAL_RESOLUTION[X];
		RESOLUTION_Y_PRECENT = RESOLUTIONS[Y] / (float) ORIGINAL_RESOLUTION[Y];
	}

	/**
	 * This method takes a screen shot and scales it to 183 * 137.
	 * This is used by game modes that implements the MenuStarter class,
	 * so that they can take a screen shot when starting the menu and 
	 * display it in the menu.
	 * 
	 * @return the thumb nail screen shot of the game.
	 */
	public static BufferedImage getMenuScreenShot() {
		try {
			BufferedImage im = GameEventListener.getG().copyFrame(Graphics.gl);
			return GraphicHelp.scaleImage(im, 183, 137);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
	

	/**
	 * Gets the display mode to use as screen resolution in full screen mode.
	 * 
	 * @param size the size of display mode. This could be Values.SMALLER 
	 * up to Values.LARGER.
	 * @param aspectRatio the aspect ratio of the resolution to use.
	 * @return the display mode with the given attributes.
	 */
	private static DisplayMode getDisplayMode(int size, float aspectRatio) {
		int width = size;
		int height = Math.round(size / aspectRatio);
		return new DisplayMode(width, height, 32, 0);
	}

	/**
	 * Gets the display mode to use as screen resolution in full screen mode.
	 * This method calculates the aspect ratio from the current display mode.
	 * 
	 * @return the display mode with the given attributes.
	 */
	public static DisplayMode getDisplayMode() {
		GraphicsEnvironment ge = 
			GraphicsEnvironment.getLocalGraphicsEnvironment();
		DisplayMode displayMode = 
			ge.getDefaultScreenDevice().getDisplayMode();
		if (resMode == Values.MANUAL) {
			return new DisplayMode(
					RESOLUTIONS[Values.X], RESOLUTIONS[Values.Y], 32, 0);
		} else if (resMode != Values.DYNAMIC_SIZE) {
			int width = displayMode.getWidth();
			int height = displayMode.getHeight();
			float aspectRatio = (float) width / (float) height;
			displayMode = getDisplayMode(resMode, aspectRatio);
		}
		return displayMode;
	}

	/**
	 * Adds the element in the array two, to the array one while
	 * multiplying the element in two by the given constant.
	 * 
	 * @param one the array to add to.
	 * @param two the array to add to one.
	 * @param constant the constant to multiply two with.
	 */
	public static void add(float[] one, float[] two, float constant) {
		for (int i = 0; i < one.length; i++) {
			one[i] += two[i] * constant;
		}
	}

	/**
	 * Copies the given array into a new one. This results in
	 * a hard copy.
	 * 
	 * @param y the array to copy.
	 * @return the copy of the given array.
	 */
	public static float[] copyArray(float[] y) {
		float[] copy = new float[y.length]; 
		for (int i = 0; i < y.length; i++) {
			copy[i] = y[i];
		}
		return copy;
	}

	/**
	 * Copies the given array into a new one. This results in
	 * a hard copy.
	 * 
	 * @param y the array to copy.
	 * @return the copy of the given array.
	 */
	public static int[] copyArray(int[] y) {
		int[] copy = new int[y.length]; 
		for (int i = 0; i < y.length; i++) {
			copy[i] = y[i];
		}
		return copy;
	}

	/**
	 * This method swaps the integer at position first with 
	 * the integer at position second.
	 * 
	 * @param array the array which contains the integers to swap.
	 * @param first the index of one of the integers to swap.
	 * @param second the index of one of the integers to swap.
	 */
	public static void swapInt(int[] array, int first, int second) {
		int temp = array[first];
		array[first] = array[second];
		array[second] = temp;
	}

	/**
	 * This method loads the identity matrix for the given gl object.
	 * (calls glLoadIdentity()). It also scales the identity matrix so
	 * that it will fit the current resolution.
	 * 
	 * @param gl the GL to load the matrix on.
	 */
//	public static void loadIdentity(GL2 gl) {
//		gl.glLoadIdentity();
//		gl.glScalef(ASPECT_RATIO, 1, 1);
//	}

	public static boolean check(int setting) {
		return SETTINGS_MAP[setting];
	}
	
	public static int angleToDirection(float angle) {
		return (int) (((angle - 90) / 90 + 4) % 4);
	}
	
	public static int angleToDirection2(float angle) {
		return (int) (((angle + 90) / 90 + 4) % 4);
	}

	public static void printStackTrace(int size) {
		StackTraceElement[] st = new IndexOutOfBoundsException().getStackTrace();
		for (int i = 0; i < Math.min(size, st.length); i++) {
			System.out.println(st[i]);
		}
	}

	public static void zoom(boolean small) {
		if (small) {
			float percent = 1; //.6f;
			int x = Math.round(1024 * percent); int y = Math.round(768 * percent);
			
			ORIGINAL_RESOLUTION = Values.createNormalPoint(x, y);
			WIDE_SCREEN_HEIGHT = .75f * y;
		} else {
			ORIGINAL_RESOLUTION = Values.createNormalPoint(1024, 768);
		}
	}
}
