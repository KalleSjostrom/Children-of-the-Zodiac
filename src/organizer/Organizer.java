package organizer;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.HashMap;

import landscape.Landscape;
import landscape.LandscapeLoader;

import java.util.logging.*;

/**
 * This class organizes everything. It keeps track of the main game loop.
 * It extends GameCore which helps organize things, such as windows,
 * full screen modes and input. It reads the main.txt which has information
 * about where to "go" next, and the mode variable which switches the mode
 * between the mode values in the class StaticValues. This class initiate
 * all the modes, like the battle, villages, landscapes and so on. This class
 * also draws them, updates them and check whether or not the player has 
 * exit them. If that is the case this class checks if the current mode
 * would like to switch to a certain place or get the next place via the 
 * main.txt file. This class is constructed as a singleton which will make
 * sure that only one object of this class can be constructed. This is done
 * by inserting a private constructor.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 May 2008
 */
public class Organizer extends GameCore {

	private static Organizer o;
	private String nextPlace = "Title Screen";
	private HashMap<String, HashMap<String, String>> mainInfo;
	private HashMap<String, String> currentInfo;
	private HashMap<Integer, String> classMap;
	private GameMode currentGameMode;
	private GameMode previousGameMode;
//	private String previousGameModeName;
	private GameModeQueue suspendedGameModes = new GameModeQueue();
	private int mode;
	private boolean next = true;
	private static boolean continueMusic;
	
	private static Logger logger = Logger.getLogger("Organizer");

	/**
	 * The private constructor of the Organizer. This is a vital part in the
	 * design pattern "Singleton".
	 * @param obs 
	 */
	protected Organizer() {
		super.init();
		classMap = Values.getClassMap();
		o = this;
	}

	/**
	 * Gets the only organizer object.
	 * 
	 * @return the organizer.
	 */
	public static Organizer getOrganizer() {
		return o;
	}
	
	/**
	 * This method initializes the game. It loads the font,
	 * parses the main.txt and calls the initOther to start a game mode.
	 * Usually the Title mode.
	 */
	protected void init(Object[] obs) {
//		Values.sleep(1000);
		super.init2(obs);
		classMap = Values.getClassMap();
		mainInfo = ResourceLoader.getResourceLoader().getMainInfo("main.bank");
		Values.init();
		initNext();
	}

	/**
	 * This method initiates the next mode in the game.
	 */
	private void initNext() {
		checkNext();
		try {
			ImageHandler.setGameMode(mode);
			if (mode == Values.LABYRINTH || mode == Values.BOSS_BATTLE_AREA) {
				Values.zoom(false);
				GameEventListener.set3D();
			} else if (mode == Values.VILLAGE || mode == Values.VILLAGE_STORY) {
				Values.zoom(true);
				GameEventListener.set2D();
			} else {
				Values.zoom(false);
				GameEventListener.set2D();
			}
			Class<?> gameMode = Class.forName(classMap.get(mode));
			
			previousGameMode = currentGameMode;
			
			if (currentGameMode != null && currentGameMode.isSuspended()) {
				suspendedGameModes.push(currentGameMode);
			}
			currentGameMode = (GameMode) gameMode.newInstance();
			HashMap<String, String> newInfo;
			if (continueMusic) {
				newInfo = new HashMap<String, String>();
				newInfo.putAll(currentInfo);
				newInfo.put("music", "continue");
				continueMusic = false;
			} else {
				newInfo = currentInfo;
			}
			currentGameMode.init(newInfo);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Checks if the information about the next place should be gotten from
	 * the main source (mainInfo) or not. If it should, it fills the 
	 * information currently used (currentInfo). This is used before the next
	 * game mode is actualized.
	 */
	private void checkNext() {
		if (next) {
			logger.log(Level.FINE, "Checking for next place " + nextPlace);
			currentInfo = getInformationFor(nextPlace);
			mode = Integer.parseInt(currentInfo.get("mode"));
			next = false;
		}
	}
	
	public static String convert(String s) {
		return convert(s.replace("_", " ").toLowerCase().toCharArray());
	}
	
	public static String convertKeepCase(String s) {
		return convert(s.replace("_", " ").toCharArray());
	}
	
	private static String convert(char[] c) {
		StringBuffer sb = new StringBuffer();
		for (int i = 0; i < c.length; i++) {
			if (c[i] != 0) {
				sb.append(c[i]);
			}
		}
		return sb.toString();
	}
	
	public static String convertBack(String string) {
		return string.replace(" ", "_");
	}
	
	/**
	 * Initiates a gets the game mode created by looking up the given name in 
	 * the main info.
	 * 
	 * @param name the name of the game mode to create as found in 
	 * the main Info.
	 * @return the newly created game mode.
	 */
	public GameMode getGameMode(String name) {
		HashMap<String, String> info = mainInfo.get(Organizer.convert(name));
		int mode = Integer.parseInt(info.get("mode"));
		GameMode gameMode = null;
		try {
			Class<?> gameModeClass = Class.forName(classMap.get(mode));
			gameMode = (GameMode) gameModeClass.newInstance();
			gameMode.init(info);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
		return gameMode;
	}
	
	public static void continueMeusic() {
		continueMusic = true;
	}
	
	public HashMap<String, String> getInformationFor(String nextPlace) {
		HashMap<String, String> info = null;
		if (nextPlace != null) {
			nextPlace = convert(nextPlace);
			logger.log(Level.FINE, "Converted Next place: " + nextPlace);
			info = new HashMap<String, String>();
			if (nextPlace.startsWith("land")) {
				String startNode;
				if (nextPlace.startsWith("land::")) {
					String[] i = nextPlace.split("::");
					startNode = i[2];
					Landscape.setInfo(i[1]);
				} else {
					startNode = nextPlace.replace("land", "");
				}
				String world = LandscapeLoader.checkPlace(startNode);
				info = mainInfo.get(world);
				info.put("startNode", startNode);
			} else if (nextPlace.startsWith("air")) {
				info = mainInfo.get("airworld");
				info.put("startNode", nextPlace.replace("air", ""));
			} else {
				info = mainInfo.get(nextPlace);
			}
			logger.log(Level.FINE, "Info for " + nextPlace + " is " + info);
		}
		return info;
	}

	/**
	 * This method sets the supendedGameMode (the previous game mode) to
	 * be the current game mode and calls the GameMode.resume() method.
	 * 
	 * @param backFromMenu true if the game should return from the menu.
	 */
	private void goBackToSuspendedMode() {
		ImageHandler.swapGameMode();
		if (suspendedGameModes.size() == 0) {
			GameMode temp = currentGameMode;
			currentGameMode = previousGameMode;
			previousGameMode = temp;
		} else {
			previousGameMode = currentGameMode;
			currentGameMode = suspendedGameModes.pop();
			logger.log(Level.FINE, "Suspended Game Mode " + suspendedGameModes.size());
			logger.log(Level.FINE, "Prev gm " + previousGameMode.getName());
			logger.log(Level.FINE, "current gm " + currentGameMode.getName());
		}
		currentGameMode.resume();
	}
	
	public GameMode getNextSuspendedMode() {
		return suspendedGameModes.peek();
	}

	/**
	 * Sets the boolean value that indicates if the organizer should get the
	 * next place information from the main.txt file.
	 * 
	 * @param next true if the information should be gotten from the 
	 * main.txt file.
	 */
	protected void setNext(boolean next) {
		this.next = next;
	}
	
	public void updateNextPlaceFor(String infoName, String nextPlace) {
		HashMap<String, String> info = mainInfo.get(convert(infoName));
		info.put("nextPlace", nextPlace);
	}
	
	public void deleteSuspended() {
		suspendedGameModes.delete();
	}

	/**
	 * This is one of the core methods in the game. This is the most 
	 * frequent method called. It updates the current mode and checks
	 * if it is time to exit it. If that should be the case it
	 * calls initNext() or goBackToSuspendedMode(). 
	 * 
	 * @param elapsedTime the amount of time (in milliseconds) that has elapsed
	 * since this method was last called.
	 */
	public void update(float dt) {
		if (currentGameMode == null || currentGameMode.isLoading()) {return;}
		
		currentGameMode.update(dt);
		if (GameCore.inputManager.hasSelectDownBeenPressed() && !(currentGameMode instanceof Cheater)) {
			currentGameMode.exitWithoutFading(Values.CHEATER);
			mode = currentGameMode.getExitMode();
			initNext();
			return;
		}
		if (currentGameMode.checkExit() != Values.NO_MODE_IS_SELECTED) {
			currentGameMode.finishOff();
			logger.log(Level.FINE, "Finish off");
			mode = currentGameMode.getExitMode();
			logger.log(Level.FINE, "Exit mode " + mode);
			next = currentGameMode.shouldGetInfoFromMain();
			logger.log(Level.FINE, "Should get info from main " + next);
			nextPlace = currentGameMode.getNextPlace();
			logger.log(Level.FINE, "Next place " + nextPlace);
			currentInfo = currentGameMode.getInfoForNextPlace();
			logger.log(Level.FINE, "Info for next " + currentInfo);
			if (mode == Values.SWITCH_BACK) {
				goBackToSuspendedMode();
			} else {
				initNext();
			}
		}
	}

	/**
	 * The main draw method of the game. It draws the current game mode.
	 * 
	 * @param g the graphics which is used for drawing.
	 */
	public void draw(float dt, Graphics g) {
		ImageHandler.load(g);
		if (ImageHandler.getLoadQueueSize() == 0) {
			currentGameMode.loadingDone();
		}
		if (currentGameMode == null || currentGameMode.isLoading()) {
			return;
		}
		currentGameMode.draw(dt, g);
	}
	
	/**
	 * Closes the game.
	 * 
	 * @param status the termination status.
	 */
	protected void closeGame(int status) {
		logger.info("Closing game");
		System.exit(status);
	}

	/**
	 * Gets the suspended mode.
	 * 
	 * @return the previous game mode.
	 */
	public GameMode getPreviousMode() {
		return previousGameMode;
	}
	
	public GameMode getCurrentMode() {
		return currentGameMode;
	}

	/**
	 * This method overwrites the previous game mode with the given one.
	 * The "previous" game mode is the paused or suspended game mode. 
	 * For example, if the village is the current game mode and the menu
	 * is entered the village is placed as the suspended game mode and
	 * the menu as the current mode.
	 * 
	 * @param mode the mode to set as the suspended game mode.
	 */
	public void overwritePreviousMode(GameMode mode) {
		previousGameMode = mode;
	}

	public static void reset() {
		Database.reset();
	}

	protected boolean isPausable() {
		if (currentGameMode != null) {
			return currentGameMode.isPausable();
		}
		return false; 
	}
	
//	public void gameOver() {
//		if (currentGameMode != null) {
//			currentGameMode.setMusicMode(
//					SoundValues.FADE_OUT, 4000, 
//					SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN);
//		}
//		currentGameMode.setFadeOutSpeed(.015f);
//		nextPlace = "Game Over Screen";
//		currentGameMode.exit(Values.EXIT);
//	}
}