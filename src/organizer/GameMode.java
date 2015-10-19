/*
 * Classname: GameMode.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/05/2008
 */
package organizer;

import graphics.Graphics;
import info.Values;
import input.GameAction.GameActions;
import input.InputManager.InputManagers;

import java.awt.image.BufferedImage;
import java.util.HashMap;

import menu.MainMenu;

import java.util.logging.*;

import sound.OggStreamer;
import sound.SoundValues;
import story.Fadeable;

/**
 * This abstract class is the super class to all the different modes in 
 * the game. It is in charge of loading, fading in, playing and fading 
 * out music. It can also fade graphics, and initializes the input managers.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 11 May 2008
 */
public abstract class GameMode extends Fadeable {

	public static final int TRIANGLE = 0;
	public static final int CIRCLE = 1;
	public static final int CROSS = 2;
	public static final int SQUARE = 3;
	public static final int L2 = 4;
	public static final int R2 = 5;
	public static final int L1 = 6;
	public static final int R1 = 7;
	public static final int SELECT = 8;
	public static final int L1R1 = 9;
	public static final int L2R2 = 10;
	public static final int START = 11;
	public static final int UP = 12;
	public static final int UP_DOWN = 12;
	public static final int RIGHT = 13;
	public static final int LEFT_RIGHT = 13;
	public static final int DOWN = 14;
	public static final int LEFT = 15;
	public static final int NUMBER_OF_BUTTONS = 16;

	protected HashMap<String, String> infoMap;
	protected InputManagers inputManager = GameCore.inputManager;
	protected GameActions[] gameActions = GameCore.gameActions;
	protected String nextPlace = "";
	protected int mode;
	protected boolean suspended;
	protected boolean done;
	protected boolean fadeOutStarted;
	protected boolean pausable = true;
	protected boolean logicLoading = true;
	private boolean loading = true;

	public OggStreamer oggPlayer;
	public String music;
	private int musicFadeOutSpeed = SoundValues.SLOW;
	private static boolean mute = Values.check(Values.MUTE_MUSIC);
	
	private static Logger logger = Logger.getLogger("GameMode");

	/**
	 * This method initializes the game mode. It is used by the Organizer
	 * when a game mode is created. It must be implemented
	 * by any subclass and it is recommended that this method should
	 * call any of the initiating method in this class.
	 * 
	 * @param info contains the information about the game mode. 
	 */
	public abstract void init(HashMap<String, String> info);

	/**
	 * This method initializes the music and input detection according to the
	 * given parameters. 
	 * 
	 * @param info the information about the game mode.
	 * @param detectMode the detection mode used when creating 
	 * the input manager. Available modes are Values.DETECT_ALL 
	 * and Values.DETECT_INIT
	 * @param music true if music should be loaded.
	 */
	protected void init(HashMap<String, String> info, int detectMode, boolean music) {
		infoMap = info;
		if (infoMap != null) {
			nextPlace = infoMap.get("nextPlace");
			if (music) {
				String name = infoMap.get("music");
				String volume = infoMap.get("musicVolume");
				float initialVolume = Values.MAX_VOLUME;
				if (volume != null) {
					initialVolume = Float.parseFloat(volume);
				}
				initMusic(name, initialVolume);
			}
		} else {
			nextPlace = "";
		}
		initInput(detectMode);
		mode = Values.NO_MODE_IS_SELECTED;
		fadein = true;
		fadeout = done = fadeOutStarted = suspended = false;
	}

	/**
	 * This method initializes the music and input detection according to the
	 * given parameters. This method sets that music should be used and that
	 * the music should fade in.
	 * 
	 * @param info the information about the game mode.
	 * @param detectMode the detection mode used when creating 
	 * the input manager. Available modes are Values.DETECT_ALL 
	 * and Values.DETECT_INIT.
	 * @see organizer.GameMode#init(HashMap, int, boolean) init().
	 */
	protected void init(HashMap<String, String> info, int detectMode) {
		init(info, detectMode, true);
	}

	/**
	 * Initiates the input manager with the given detection mode.
	 * Available modes are Values.DETECT_ALL and Values.DETECT_INIT.
	 * 
	 * @param detectionMode the detection mode to use.
	 */
	protected void initInput(int detectionMode) {
		for (int i = UP; i <= LEFT; i++) {
			gameActions[i].changeBehavior(detectionMode);
		}
	}
	
	protected void changeInput(int[] buttons, int detectionMode) {
		for (int b : buttons) {
			gameActions[b].changeBehavior(detectionMode);
		}
	}

	/**
	 * Initializes the music. Creates a player and fades the music up.
	 * 
	 * @param music the name of the music to play.
	 * @param initialVolume the initial volume of the music.
	 */
	private void initMusic(final String music, final float initialVolume) {
		this.music = music;
		if (music != null && !mute) {
			final GameMode gm = Organizer.getOrganizer().getPreviousMode();
			logger.log(Level.FINE, "Initiate music: Previous game mode: " + gm);
			logger.log(Level.FINE, "Initiate music: New music: " + music);
			if (gm != null && gm.oggPlayer != null && gm.music != null && 
					(music.contains("continue") || music.equals(gm.music))) {
				logger.log(Level.FINE, "Initiate music: Previous game mode music: " + gm.music);
				logger.log(Level.FINE, "This game mode " + this.hashCode() + " " + this.getClass().getName());
				logger.log(Level.FINE, "Previous game mode " + gm.hashCode() + " " + gm.getClass().getName());
				logger.log(Level.FINE, "Previous ogg " + gm.oggPlayer.hashCode());
				oggPlayer = gm.oggPlayer;
				this.music = gm.music;
//				gm.oggPlayer = null;
				logger.log(Level.FINE, "This ogg " + oggPlayer.hashCode());
			} else if (music.equals("No Music")) {
			} else {
				logger.log(Level.FINE, "Creating ogg for " + this.getName() + " " + music + " " + this.hashCode());
				oggPlayer = new OggStreamer(music);
				logger.log(Level.FINE, "Creating ogg, ogg player hash code " + oggPlayer.hashCode());
				oggPlayer.setInitVolume(initialVolume);
				if (oggPlayer.isURLValid()) {
					while (gm != null && gm.isMusicFadingDown()) {
						Values.sleep(100);
					}
					new Thread(music) {
						public void run() {
							while (isLoading()) {
								Values.sleep(30);
							}
							oggPlayer.play(false, true);
						}
					}.start();
				}
			}
		}
	}

	/**
	 * Checks if the music is fading down.
	 * 
	 * @return true if the music is fading down.
	 */
	public boolean isMusicFadingDown() {
		boolean fadingDown = false;
		if (oggPlayer != null) {
			fadingDown = oggPlayer.isFadingDown();
		}
		return fadingDown;
	}

	/**
	 * Checks if the game mode is fading the graphics. This will return true
	 * if either the game mode is fading in or out.
	 * 
	 * @return true if the game mode is fading.
	 */
	protected boolean isFading() {
		return fadein || fadeout;
	}

	/**
	 * This method fades the music either in or out depending if
	 * the given value is SoundValues.FADE_IN or .FADEOUT. This method
	 * fades the music all the way (to silent or max volume) with
	 * the given fadeSpeed.
	 * 
	 * @param mode either SoundValues.FADE_IN or .FADEOUT.
	 * @param fadeSpeed the speed of the fade. Either SoundValues.SLOW
	 * or .FAST
	 */
	public void setMusicMode(int mode, int fadeSpeed) {
		setMusicMode(mode, fadeSpeed, SoundValues.ALL_THE_WAY);
	}

	/**
	 * This method fades the music either in or out depending if
	 * the given value is SoundValues.FADE_IN or .FADEOUT. This method
	 * fades the music either all the way (to silent or max volume) 
	 * or to half volume depending on the given fadeLength.
	 * 
	 * @param mode either SoundValues.FADE_IN or .FADEOUT.
	 * @param fadeSpeed the speed of the fade. Either SoundValues.SLOW
	 * or .FAST
	 * @param fadeLength the length of the fade. 
	 * Either SoundValues.ALL_THE_WAY or .HALF.
	 */
	public void setMusicMode(int mode, int fadeSpeed, float fadeLength) {
		setMusicMode(mode, fadeSpeed, fadeLength, SoundValues.NORMAL);
	}

	/**
	 * This method fades the music either in or out depending if
	 * the given value is SoundValues.FADE_IN or .FADEOUT. This method
	 * fades the music either all the way (to silent or max volume) 
	 * or to half volume depending on the given fadeLength. The given value
	 * playMode indicates if the music should resume before fading,
	 * pause the music after fading or do nothing. The values to choose
	 * for playMode is SoundValues.RESUME, .PAUSE or NORMAL.
	 * 
	 * @param mode either SoundValues.FADE_IN or .FADEOUT.
	 * @param fadeSpeed the speed of the fade. Either SoundValues.SLOW
	 * or .FAST
	 * @param fadeLength the percentage of volume to fade.
	 * @param playMode which mode to play the music. Either of 
	 * SoundValues.RESUME, .PAUSE or NORMAL.
	 */
	public void setMusicMode(int mode, int fadeSpeed, float fadeLength, int playMode) {
		logger.log(Level.FINE, "This game mode " + this.hashCode() + " " + this.getClass().getName());
		logger.log(Level.FINE, "Ogg player " + oggPlayer);
		if (oggPlayer != null) {
			logger.log(Level.FINE, "Music " + oggPlayer.getName());
			if (mode == SoundValues.FADE_OUT) {
				fadeLength = SoundValues.ALL_THE_WAY - fadeLength;
			}
			oggPlayer.fade(mode, fadeSpeed, fadeLength, playMode);
		}
	}

	/**
	 * This method resumes the music and fades it in. This method fades the 
	 * music all the way (to silent or max volume) with the given speed.
	 * 
	 * @param fadeSpeed either SoundValues.FADE_IN or .FADEOUT.
	 */
	public void resumeMusicWithFade(int fadeSpeed) {
		setMusicMode(SoundValues.FADE_IN, fadeSpeed, 
				SoundValues.ALL_THE_WAY, SoundValues.RESUME_PLAY);
	}

	/**
	 * This method fades out the music and pauses it. This method fades the  
	 * music all the way (to silent or max volume) with the given speed.
	 * 
	 * @param fadeSpeed either SoundValues.FADE_IN or .FADEOUT.
	 */
	protected void pauseMusicWithFade(int fadeSpeed) {
		setMusicMode(SoundValues.FADE_OUT, fadeSpeed, 
				SoundValues.ALL_THE_WAY, SoundValues.PAUSE);
	}

	/**
	 * Fades out the music as well as the graphics. 
	 * 
	 * @return true if the fade out is done.
	 */
	private boolean fadeOutGameMode() {
		if (!mute) {
			if (!fadeOutStarted) {
				if (!suspended) {
					boolean cont = true;
					if (mode == Values.SWITCH_BACK) {
						GameMode gm = Organizer.getOrganizer().getNextSuspendedMode();
						if (gm != null) {
							String lastMusic = gm.infoMap.get("music");
							logger.log(Level.FINE, "Last music " + lastMusic);
							String music = infoMap.get("music");
							logger.log(Level.FINE, "Music " + music);
							if (lastMusic.equals(music)) {
								cont = false;
							}
						}
					}
					if (cont) {
						HashMap<String, String> info = 
							Organizer.getOrganizer().getInformationFor(nextPlace);
						logger.log(Level.FINE, "Next place in Game Mode " + nextPlace);
						logger.log(Level.FINE, "Info " + info);
						if (info == null) {
							info = this.getInfoForNextPlace();
							logger.log(Level.FINE, "Info " + info);
						}
						String m = null;
						boolean dontFade = nextPlace != null && nextPlace.contains("::continue::");
						if (info != null) {
							m = info.get("music");
							logger.log(Level.FINE, "Music " + m);
							if (!dontFade) {
								if (m != null && !m.equals(music) && !m.equals("continue")) { 
									logger.log(Level.FINE, "Setting music 1");
									setMusicMode(
											SoundValues.FADE_OUT, 
											musicFadeOutSpeed, 
											SoundValues.ALL_THE_WAY,
											SoundValues.KILL_MUSIC_ON_FADE_DOWN);
								}
							}
						}
						String c = this.infoMap.get("music");
						logger.log(Level.FINE, "This music " + c);
						logger.log(Level.FINE, "Info " + info);
						logger.log(Level.FINE, "Music " + m);
						if (!dontFade) {
							if (info == null || m == null) {
								logger.log(Level.FINE, "Setting music mode");
								setMusicMode(
										SoundValues.FADE_OUT, 
										musicFadeOutSpeed, 
										SoundValues.ALL_THE_WAY,
										SoundValues.KILL_MUSIC_ON_FADE_DOWN);
							}
						}
					}
				}
				fadeOutStarted = true;
			}
		}
		fadeOut();
		done = !fadeout;
		return done;
	}

	/**
	 * Releases all the buttons.
	 */
	protected void releaseAll() {
		for (int i = 0; i < NUMBER_OF_BUTTONS; i++) {
			gameActions[i].release();
		}
	}

	/**
	 * Resets all the game actions so that they appear 
	 * to have never been pressed
	 */
	protected void resetAll() {
		for (int i = 0; i < NUMBER_OF_BUTTONS; i++) {
			gameActions[i].reset();
		}
	}

	/**
	 * Changes the behavior for the directional buttons to the given
	 * behavior mode. This mode is either GameAction.DETECT_INITAL_PRESS_ONLY
	 * or GameAction.NORMAL.
	 * 
	 * @param behavior the behavior to change to.
	 */
	protected void changeDirBehaviour(int behavior) {
		for (int i = UP; i <= LEFT; i++) {
			gameActions[i].changeBehavior(behavior);
		}
	}
	
	/**
	 * This method updates the game mode.
	 * 
	 * @param elapsedTime the elapsed time (in milliseconds) since the last 
	 * call to this method.
	 */
	public void update(float elapsedTime) {
		//updateFadeValue();
	}
	
	protected void updateFadeValue() {
		if (fadein) {
			fadeIn();
			if (fadeValue >= 1) {
				Graphics.setFadeImage(Graphics.FADE_TO_BLACK);
			}
		} else if (fadeout) {
			fadeOutGameMode();
		}
	}

	public void draw(Graphics g) {
		updateFadeValue();
		g.fadeOldSchool(fadeValue);
	}
	
	/**
	 * Pauses this game mode and sets the mode to the given one.
	 * This will cause the Organizer to initiated the given mode, 
	 * while keeping this mode paused.
	 * 
	 * @param mode the mode to switch to.
	 */
	public void switchGameMode(int mode) {
		switchGameMode(mode, mode != Values.MENU);
	}

	/**
	 * Pauses this game mode and sets the mode to the given one. This will 
	 * cause the Organizer to initiated the given mode, while keeping this
	 * mode paused. If the switchMusic is true, then the music of the new
	 * game mode will be played, otherwise this game modes music will still
	 * play. This is the normal case when entering the menu, the game mode
	 * where the menu was entered should still play music while the new mode
	 * (the menu) should not.
	 * 
	 * @param mode the mode to switch to.
	 * @param switchMusic true if the music should switch to new music
	 * or if this game modes music should still play.
	 */
	public void switchGameMode(int mode, boolean switchMusic) {
		setSuspended(true, switchMusic, true);
		this.mode = mode;
	}

	public void switchGameMode(int mode, boolean switchMusic, boolean fade) {
		setSuspended(true, switchMusic, fade);
		this.mode = mode;
	}

	/**
	 * Checks if this game mode has been suspended (paused).
	 * 
	 * @return true if this game mode is suspended.
	 */
	protected boolean isSuspended() {
		return suspended;
	}

	/**
	 * Pauses / resumes this game mode.
	 * 
	 * @param pause true if the game mode should be paused.
	 */
	protected void setSuspended(boolean pause) {
		setSuspended(pause, true, true);
	}

	/**
	 * Pauses / resumes this game mode.
	 * 
	 * @param pause true if the game mode should be paused.
	 * @param fadeMusic true if the music should be faded in or out.
	 * @param fade true if the graphics should fade.
	 */
	protected void setSuspended(boolean pause, boolean fadeMusic, boolean fade) {
		if (!pause) {
			mode = Values.NO_MODE_IS_SELECTED;
			inputManager.resetAllGameActions();
			fadeValue = fade ? 0 : 1;
			fadein = fade;
			fadeout = fadeOutStarted = done = suspended = false;
			if (fadeMusic) {
				resumeMusicWithFade(SoundValues.FAST);
			}
		} else {
			suspended = true;
			fadeout = fade;
			done = !fade;
			if (fadeMusic) {
				pauseMusicWithFade(SoundValues.FAST);
			}
		}
	}

	/**
	 * Resumes this game mode.
	 */
	public void resume() {
		setSuspended(false);
	}

	/**
	 * Resumes this game mode and initializes the input manager with the
	 * given detection mode.
	 * 
	 * @param detectionMode the detection mode to use when checking the input.
	 */
	protected void resume(int detectionMode) {
		setSuspended(false);
		initInput(detectionMode);
	}

	/**
	 * Resumes this game mode and initializes the input manager with the
	 * given detection mode.
	 * 
	 * @param detectionMode the detection mode to use when checking the input.
	 * @param fadein true if the graphics should fade in.
	 */
	protected void resume(int detectionMode, boolean fadein) {
		setSuspended(false, true, fadein);
		initInput(detectionMode);
	}
	
	protected void resume(int detectionMode, boolean fadeMusic, boolean fadein) {
		setSuspended(false, fadeMusic, fadein);
		initInput(detectionMode);
	}
	
	protected boolean resumedFromMenu() {
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		if (gm != null) {
			return gm instanceof MainMenu;
		}
		return false;
	}

	/**
	 * This exit method forces the game mode to exit. This is used by the 
	 * cheater class to interrupt the old mode, before starting a new.
	 */
	public void killOggPlayer() {
		if (oggPlayer != null) {
			oggPlayer.exit();
		}
	}

	/**
	 * Exits the game mode without fading and sets the next mode
	 * to the given mode.
	 * 
	 * @param mode the mode to be initiated after this. 
	 */
	protected void exitWithoutFading(int mode) {
		done = true;
		this.mode = mode;
		killOggPlayer();
	}

	/**
	 * This method tries to enter the menu. If the game mode is fading it will
	 * not succeed and null will be returned. If the game mode is not fading 
	 * the miniature screen shot will be returned and the menu will be entered. 
	 * 
	 * @return the miniature screen shot if the game mode is not fading, null
	 * otherwise.
	 */
	protected BufferedImage enterMenu() {
		BufferedImage screenShot = null;
		if (!isFading()) {
			screenShot = Values.getMenuScreenShot();
			nextPlace = null;
			switchGameMode(Values.MENU);
		}
		return screenShot;
	}

	/**
	 * This method exits the current mode and sets the given mode to be
	 * the next game mode. This method fades out the music and graphics.
	 * 
	 * @param mode the next mode.
	 */
	protected void exit(int mode) {
		fadeout = true;
		this.mode = mode;
	}

	/**
	 * Gets which mode this game mode exited with.
	 * 
	 * @return the exit mode.
	 */
	public int getExitMode() {
		return mode;
	}

	/**
	 * Checks to see if the player has exited the title screen.
	 * It is used by the organizer.
	 * 
	 * @return the place to lookup after this story sequence
	 */
	public int checkExit() {
		if (isDone() || mode == Values.MENU) {
			return mode;
		}
		return Values.NO_MODE_IS_SELECTED;
	}

	/**
	 * Checks if the game mode is done. The game mode is done
	 * after the sound has faded away and the possibly the graphics.
	 * 
	 * @return true if the game mode has finished.
	 */
	protected boolean isDone() {
		return done;
	}

	/**
	 * Checks if the organizer should get the information about next place 
	 * from the main information source or just to initiated the next mode.
	 * 
	 * @return true if the organizer should get the next information from the
	 * main file.
	 */
	public boolean shouldGetInfoFromMain() {
		return !getNextPlace().equals("") && !getNextPlace().equals("_");
	}

	/**
	 * Gets the name of the next place or the empty string if the next 
	 * place should not be looked up by the organizer.
	 * 
	 * @return the name of the next place.
	 */
	public String getNextPlace() {
		return nextPlace == null ? "" : nextPlace;
	}

	public boolean isPausable() {
		return pausable;
	}
	
	protected void switchMusic(final String name, final int fadeSpeed) {
		if (oggPlayer != null) {
			setMusicMode(SoundValues.FADE_OUT, fadeSpeed);
			new Thread() {
				public void run() {
					while (oggPlayer.isFadingDown()) {
						Values.sleep(20);
					}
					oggPlayer.exit();
					if (!name.equals("No Music")) {
						oggPlayer = new OggStreamer(name);
						oggPlayer.play(false, true);
					}
				}
			}.start();
		} else {
			new Thread() {
				public void run() {
					Values.sleep(fadeSpeed);
					if (!name.equals("No Music")) {
						oggPlayer = new OggStreamer(name);
						oggPlayer.play(false, true);
					}
				}
			}.start();
		}
	}

	/**
	 * This method is called by the organizer when this game mode is to
	 * be exited and another should take over. This could be overridden if 
	 * the current game mode would like to create the information map
	 * for the next game mode instead of the Organizer getting it from the
	 * main source. For the Organizer to actually use this information one 
	 * MUST make sure that the getNextPlace() method returns the empty 
	 * string: "". This could easily be done by either setting the 
	 * nextPlace to null or to "".
	 * 
	 * @return the information about the next place if this method is 
	 * implemented by the current game mode. If it is not, this method
	 * will return null.
	 */
	public HashMap<String, String> getInfoForNextPlace() {
		return null;
	}

	/**
	 * This method is called by the organizer when this game mode is about
	 * to be shut down. This method could be overridden to do some last 
	 * minute clean up.
	 */
	public void finishOff() {
		// Override to implement effect.
	}

	public boolean isLoading() {
//		if (this.getClass().getName().contains("Labyrinth")) {
//			new IndexOutOfBoundsException().printStackTrace();
//		}
		return loading;
	}
	
	public boolean isLogicLoading() {
		return logicLoading;
	}
	
	public void loadingDone() {
		if (!logicLoading) {
			if (loading) {
				System.out.println("All Loading done");
			}
			loading = false;
		}
	}
	
	protected void setMusicFadeOutSpeed(int time) {
		musicFadeOutSpeed = time;
	}

	public static boolean isMuted() {
		return mute;
	}
	
	public String getName() {
		if (infoMap != null) {
			return infoMap.get("name");
		}
		return "";
	}
	
	public void setGameAction() {
		GameCore.setGameAction();
		gameActions = GameCore.gameActions;
	}
}
