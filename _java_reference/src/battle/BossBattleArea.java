package battle;

import graphics.Graphics;
import info.Values;

import java.util.HashMap;
import java.util.Iterator;

import menu.DeckPage;

import organizer.GameEventListener;
import organizer.GameMode;

import sound.OggStreamer;
import sound.SoundValues;
import villages.utils.Dialog;
import villages.utils.DialogSequence;
import battleBacks.BattleSystem;
import cards.Card;

public class BossBattleArea extends GameMode implements BattleStarter {

	private DialogSequence dialog;
	private Card card;
	private BattleSystem weatherSystem;
	private BattleManager bm;
	private boolean subGameModeInitiated = false;
	
	/**
	 * Creates, loads and starts the labyrinth.
	 * 
	 * @param info a hash map containing some information, like which map to
	 * load, which start node to load, and the name of the music.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_ALL);
		enterBattle(info);
		fixWeather(info.get("particles"));
		logicLoading = false;
	}

	private void fixWeather(String name) {
		if (name != null) {
			try {
				Class<?> c = Class.forName("battleBacks." + name);
				weatherSystem = (BattleSystem) c.newInstance();
			} catch (ClassNotFoundException e) {
				e.printStackTrace();
			} catch (InstantiationException e) {
				e.printStackTrace();
			} catch (IllegalAccessException e) {
				e.printStackTrace();
			}
		}
	}

	/**
	 * Updates the labyrinth. This method checks the input and moves
	 * the player if any button has been pressed.
	 * 
	 * @param elapsedTime the amount of time since the game was last updated.
	 */
	public void update(float elapsedTime) {
		if (weatherSystem != null) {
			weatherSystem.update();
		}
		bm.update(elapsedTime);
		super.update(elapsedTime);
	}

	/**
	 * This method enters the battle mode, starts battling.
	 * If the given argument is true, the enemy is a boss and
	 * the battle is created with the current enemy groups boss
	 * as enemy.
	 * 
	 * @param boss true if this battle should be against a boss.
	 * @param name2 
	 */
	public void enterBattle(final HashMap<String, String> info) {
//		setMusicMode(SoundValues.FADE_OUT, 500, 
//				SoundValues.ALL_THE_WAY, SoundValues.PAUSE);
		bm = new BattleManager();
		bm.setBattleStarter(this);
//		HashMap<String, String> info = getBattleInfo(bossName);
		HashMap<String, String> newInfo = new HashMap<String, String>();
		
		Iterator<String> it = info.keySet().iterator();
		while (it.hasNext()) {
			String s = it.next();
			if (!s.equals("music")) {
				newInfo.put(s, info.get(s));
			} else {
				newInfo.put("music", "No Music");
			}
		}
		
		bm.init(newInfo);
		subGameModeInitiated = false;
	}
	
	/**
	 * This method ends the game. It fades out the battle mode (the game ended
	 * there), sets the next place to "gameover" and exits.
	 */
	public void gameOver() {
		exit("Game Over Screen", true);
	}
	
	public void exit(String next, boolean fadeBattleMusic) {
		if (!isFading()) {
			if (fadeBattleMusic && bm != null && bm instanceof BattleManager) {
				bm.setMusicMode(
						SoundValues.FADE_OUT, 4000, 
						SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN);
			}
			setFadeOutSpeed(.01f);
			nextPlace = next;
			exit(Values.EXIT);
		}
	}

//	/**
//	 * Gets the battle information.
//	 * 
//	 * @param boss true if the battle is a boss battle.
//	 * @param bossName 
//	 * @return the information used to start the battle.
//	 */
//	private HashMap<String, String> getBattleInfo(String bossName) {
//		return Organizer.getOrganizer().getInformationFor(bossName);
//	}
	
	/**
	 * Draws the labyrinth.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		if (weatherSystem != null) {
			weatherSystem.draw(g, false);
		}
		drawExtra(g, false);
		
		GameEventListener.set2DNow(g);
		if (dialog != null) {
			g.setColor(1);
			Dialog.getDialog().draw(g);
			if (card != null) {
				DeckPage.drawCardInfo(g, card, 530);
			}
		}
		g.push();
		drawExtra(g, true);
		g.pop();
		super.draw(g);
	}
	
	/**
	 * Draws the battle.
	 * 
	 * @param g the graphics to draw on.
	 */
	private void drawExtra(Graphics g, boolean topLayer) {
		if (!subGameModeInitiated) {
			bm.initDraw(g);
			subGameModeInitiated = true;
		}
		if (topLayer) {
			bm.drawTopLayer(g);
		} else {
			bm.draw(g);
		}
	}
	
	/**
	 * Sets the name of the next place.
	 * 
	 * @param nextPlace the name of the next place
	 */
	public void setNextPlace(String nextPlace) {
		this.nextPlace = nextPlace;
	}
	
	/**
	 * This method is used by the organizer to check what to initialize 
	 * after the labyrinth.
	 * 
	 * @return nextPlace, the next place to initialize;
	 */
	public String checkNextPlace() {
		return nextPlace;
	}
	
	/**
	 * Exits the labyrinth with the given exit code.
	 * 
	 * @param exitMode the code to exit with.  
	 */
	public void exitLabyrinth(int exitMode) {
		exit(exitMode);
	}
	
	/**
	 * Saves the dialog information for drawing in the labyrinth.
	 * 
	 * @param first the first line of text to be displayed in the dialog.
	 * @param second the second line of text to be displayed in the dialog.
	 */
	public void drawDialog(String first, String second) {
		drawDialog(new DialogSequence(first, second));
	}
	
	public void drawDialog(boolean firstDialogImage, String name, String first, String second) {
		drawDialog(new DialogSequence(name, first, second, firstDialogImage, false));
	}
	
	public void drawDialog(DialogSequence dia) {
		dialog = dia;
		Dialog.getDialog().setDS(dialog);
	}
	
	public void exitDialog() {
		if (dialog != null) {
			dialog = null;
			card = null;
		}
	}

	public void leaveBattle() {}

	public void notifySwitchMusic(String music, int fadeSpeed) {
		super.switchMusic(music, fadeSpeed);
	}

	public void overwriteStarterMusic(String music, OggStreamer oggPlayer) {
		System.out.println("Overwrite");
		this.oggPlayer.exit();
		this.oggPlayer = oggPlayer;
		this.music = music;
	}
}
