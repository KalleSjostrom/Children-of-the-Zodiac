/*
 * Classname: VillageStory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/10/2008
 */
package villages.villageStory;

import factories.Load;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import java.util.logging.*;

import organizer.GameMode;
import organizer.Organizer;

import sound.OggStreamer;
import sprite.Sprite;
import story.VillageStoryTimeLine;
import villages.Village;
import character.Character;

/**
 * Manages the story sequences that takes place in the villages.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 12 Oct 2008
 */
public class VillageStory extends GameMode {

	private Village village;
	private VillageStoryTimeLine timeLine;
	private static Logger logger = Logger.getLogger("VillageStory");

	/**
	 * Initiates the village story based on the information in the given map.
	 * 
	 * @param info the information to use when initiating the village story.
	 */
	public void init(HashMap<String, String> info) {
		checkPlayer();
		VillageStoryLoader vsl = new VillageStoryLoader();
		vsl.parseFile(info.get("map") + info.get("name"));
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		boolean fromVillage = gm instanceof Village;
		logger.log(Level.FINE, "Init " + fromVillage);
		village = null;
		if (!fromVillage) {
			fromVillage = gm instanceof VillageStory && vsl.getPassVillage();
			if (fromVillage) {
				logger.log(Level.FINE, "From "  +fromVillage);
				village = ((VillageStory) gm).village;
			}
		}
		if (village == null) {
			if (fromVillage) {
				village = (Village) gm;
				String n = vsl.newVillageInfo().get("name");
				logger.log(Level.FINE, "Name " + n + " " + village.getVillageFolderName());
				if (fromVillage = village.getVillageFolderName().startsWith(n)) {
					fadein = false;
					fadeValue = 1;
				}
				logger.log(Level.FINE, "After name " + fromVillage);
			}
			if (!fromVillage) {
				village = new Village();
				HashMap<String, String> newInfo = vsl.newVillageInfo();
				String status = newInfo.get("status");
				if (status != null) {
					int s = Integer.parseInt(status);
					Database.addStatus(newInfo.get("name"), s);
				}
				ImageHandler.setGameMode(Values.VILLAGE);
				village.init(newInfo);
				village.setReady();
				// Delete previous game mode!!
				Organizer.getOrganizer().overwritePreviousMode(village);
				ImageHandler.setGameMode(Values.VILLAGE_STORY);
				fadeValue = Integer.parseInt(newInfo.get("fadeValue"));
			}
		}
		super.init(info, Values.DETECT_INIT);
		timeLine = new VillageStoryTimeLine(vsl, village);
		timeLine.setVillagers(village.getVillagers());
		village.updateSpriteList();
		timeLine.setParty(village.getPlayer(), fromVillage);
		timeLine.setVillage(village);
		timeLine.init(this);

		logicLoading = false;
	}

	public void setOggplayerAsVillageCurrent(OggStreamer player) {
		village.oggPlayer = player;
		village.music = player.getName();
	}

	public void setOggplayerAsStoryCurrent(OggStreamer player) {
		oggPlayer = player;
		music = player.getName();
	}

	/**
	 * Checks the party members of the player. If any of these are dead they
	 * are resurrected with 1 in HP.
	 */
	private void checkPlayer() {
		ArrayList<Character> chars = Load.getCharacters();
		Character c;
		for (int i = 0; i < chars.size(); i++) {
			c = chars.get(i);
			if (!c.isAlive()) {
				c.cureFromDead();
				c.cure(1);
			}
		}
	}

	/**
	 * Updates this village story.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since the last
	 * call to this method,
	 */
	public void update(float elapsedTime) {
		checkGameInput();
		timeLine.update((int) elapsedTime);
		village.checkVillagers((int) elapsedTime);
		super.update(elapsedTime);
	}

	/**
	 * Checks the input from the player.
	 */
	private void checkGameInput() {
		if (gameActions[CROSS].isPressed()) {
			timeLine.crossPressed();
		} else if (gameActions[CIRCLE].isPressed()) {
			// switchGameMode(Values.SWITCH_BACK);
		} else if (gameActions[START].isPressed()) {
			exit(Values.EXIT);
		} else if (gameActions[UP].isPressed()) {
		} else if (gameActions[DOWN].isPressed()) {
		}
	}
	
	public void killOggPlayer() {
		super.killOggPlayer();
		if (village != null) {
			village.killOggPlayer();
		}
		if (timeLine != null) {
			timeLine.killOggPlayer();
		}
	}

	/**
	 * Draws the village story on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.setColor(1);
		timeLine.draw(g);
		super.draw(g);
	}

	/**
	 * This method ends the village story mode by centering the screen to 
	 * the player party (if needed) and re-initiates the village.
	 * 
	 * @param pos the position of the player party.
	 * @param removedVillagers the list of villagers that where removed
	 * from the village and turned into actors for the story.
	 * @param playersAdded true if the player was part of the story.
	 */
	public void end(float[] pos, ArrayList<Sprite> removedVillagers, 
			boolean playersAdded) {
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		Village v = null;
		if (gm instanceof Village) {
			v = (Village) gm;
		} else if (gm instanceof VillageStory) {
			v = ((VillageStory) gm).village;
			Organizer.getOrganizer().overwritePreviousMode(v);
		}
		
		logger.log(Level.FINE, "Ending Village " + v.getName() + " " + removedVillagers);
		if (playersAdded) {
			v.initFromStory(pos, removedVillagers, nextPlace);
			boolean switchMusic = 
				infoMap.get("music") != null && !infoMap.get("music").equals("continue");
			ImageHandler.setGameMode(Values.VILLAGE);
			logger.log(Level.FINE, infoMap+"");
			logger.log(Level.FINE, switchMusic+"");
//			super.exit(Values.SWITCH_BACK); // This results in the music and graphics fading in stories such as Alaresnode1.seq
			switchGameMode(Values.SWITCH_BACK, switchMusic, false);
		} else {
			v.addOnlyVillagers(removedVillagers);
			logger.log(Level.FINE, "Exit to labyrinth");
			v.exit();
			super.exit(Values.LABYRINTH);
		}
	}
	
	/**
	 * This method is called by the organizer when this game mode is about
	 * to be shut down. It removes all images associated with the village 
	 * story.
	 */
	public void finishOff() {
//		ImageHandler.clearList(Values.VILLAGE_STORY);
	}
}
