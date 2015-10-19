/*
 * Classname: Village.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages;

import factories.Load;
import graphics.DoubleBackground;
import graphics.Graphics;
import info.Database;
import info.Values;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.logging.*;
import bodies.system.ParticleSystem;
import menu.DeckPage;
import organizer.GameMode;
import organizer.Organizer;
import sound.SoundValues;
import sprite.Sprite;
import store.Door;
import villages.utils.Dialog;
import villages.utils.DialogSequence;
import villages.utils.Loot;
import villages.utils.PartyMember;
import villages.utils.Player;
import villages.utils.Sign;
import villages.utils.SortingElement;
import cards.Card;
import character.Creature;

/**
 * This class coordinates the graphics, input and animation for the village.
 * When the player is in the middle of the screen, the background moves
 * instead of the player, to put focus on the player. 
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 13 May 2008
 */
public class Village extends VillageLoader {

	private Villager talkingVillager;
	private HashMap<String, String> storyInfo;
	private Sign sign;
	private SortingElement[] elements;
	private String exitName;
	private String buildingName;
	
	private boolean showSignDialog = false;
	private boolean inStore = false;
	private boolean fromStory = false;
	private boolean question = false;
	private boolean talkmode = false;
	private static float[] fromHouse;
	private boolean inHouse;
	private static Logger logger = Logger.getLogger("Village");
	
	/**
	 * Constructs a new village from the file with the given name.
	 * This file contains information about the images to use, positions,
	 * villagers, stores and so on. This information might be gotten 
	 * from a database in the future.
	 * 
	 * @param info a hash map containing some information like, which map to 
	 * load, and the name of the music to play.
	 */
	public void init(final HashMap<String, String> info) {
		logger.log(Level.FINE, "Init " + inStore + " " + inHouse + " " + Arrays.toString(fromHouse));
		loadVillage(info);
		setDrawPos(0);
		setDrawPos(1);
		createSpritesList();
		exitName = infoMap.get("landname");
		logger.log(Level.FINE, "Init " + inStore + " " + inHouse + " " + Arrays.toString(fromHouse));
		int delay = 0;
		if (info.containsKey("delay")) {
			delay = Integer.parseInt(info.get("delay"));
		}
		if (delay > 0) {
			final int delayLoading = delay;
			new Thread() {
				public void run() {
					Values.sleep(delayLoading);
					logicLoading = false;
				}
			}.start();
		} else {
			logicLoading = false;
		}
	}
	
	/**
	 * Creates the list containing the sprites in this village. These includes
	 * the villagers as well as the party members.
	 */
	private void createSpritesList() {
		ArrayList<PartyMember> pmList = player.getPartyMembers();
		for (int i = 0; i < pmList.size(); i++) {
			Sprite as = pmList.get(i);
			sprites.put(as.hashCode(), as);
		}
		elements = new SortingElement[sprites.size()];
		Iterator<Integer> it = sprites.keySet().iterator();
		int i = 0;
		while (it.hasNext()) {
			int index = it.next();
			Sprite as = sprites.get(index);
			elements[i++] = new SortingElement(as.getY(), index);
		}
	}

	/**
	 * This method is a shortcut to the init() method in VillageLoader.
	 * This is done so that the init() method can be called from within
	 * a thread or any other place where the reserved word "super" does
	 * not reference the correct object.
	 * 
	 * @param info the info to initiate.
	 */
	private void loadVillage(HashMap<String, String> info) {
		super.init(info);
	}
	
	/**
	 * Resumes and restores this village.
	 */
	public void resume() {
		logger.log(Level.FINE, "Resume " + fromStory + " " + inStore + " " + inHouse + " " + inside + " " + Arrays.toString(fromHouse) + " " + this.hashCode());
		
		boolean fade = true;
		if (inHouse || inside) {
			fade = false;
		}
		super.resume(Values.DETECT_ALL, fade, fromStory || inStore || inHouse);
		if (inStore) {
			player.setPartyMembers();
			player.setDirectionForAll(Values.DOWN);
			inStore = false;
		} else if (inHouse) {
			int dir = Values.DOWN;
			if (fromHouse != null) {
				dir = (int) (fromHouse[2] != -1 ? fromHouse[2] : Values.DOWN);
			} else {
				fromHouse = new float[3];
				fromHouse[0] = player.getPos()[0];
				fromHouse[1] = player.getPos()[1];
			}
			fromHouse[2] = dir;
			player.setPos(fromHouse);
			player.setPartyMembers();
			inHouse = false;	
		}
		player.standStill();
	}

	/**
	 * Updates the village. It checks the player input and updates the
	 * villagers and player. It puts all the villagers that are higher up than
	 * the player in one hash map and the others so they can be drawn on
	 * different layers. If the player is in the edge of the screen the village
	 * is exited and the landscape is normally initiated. 
	 * 
	 * @param elapsedTime the amount of time that has elapsed since this 
	 * method was last called.
	 */
	public synchronized void update(float elapsedTime) {
		background.update(elapsedTime);
		if (mode == Values.NO_MODE_IS_SELECTED) {
			float x = player.getPos()[Values.X];
			float y = player.getPos()[Values.Y];
			
			if (x < 0 || x > backgroundWidth || y < 0 || y > backgroundHeight) {
				if (!checkDoors(holeDoors, player.getDirection())) {
					Organizer.getOrganizer().deleteSuspended();
					exit();
				}
				return;
			}
			checkGameInput();
			player.update(elapsedTime);
		}
		checkVillagers(elapsedTime);
		super.update(elapsedTime);
	}

	private boolean checkDoor(Door d, int direction) {
		boolean entered = false;
		if (d.canBeOpened(direction)) {
			if (d.isLocked()){
				logger.log(Level.FINE, "Door name: " + d.getName());
				setSign(d.getSign());
				if (sign == null) {
					createSign("The door is locked.", "", null);
				}
			} else {
				entered = true;
				mode = d.getMode();
				if (mode == Values.VILLAGE || mode == Values.SWITCH_BACK || mode == Values.HOUSE) {
					setFade(d.getFadeMode());
				}
				
				fromHouse = d.getToPos();
				if (mode == Values.SWITCH_BACK) {
					GameMode gm = Organizer.getOrganizer().getNextSuspendedMode();
					if (gm == null || !gm.getName().equals(d.getBuildingName())) {
						mode = Values.HOUSE;
						if (fromHouse != null) {
							fromHouse[2] = fromHouse[3];
						}
					} else {
						nextPlace = null;
						exit(mode);
						return entered;
					}
				}
				if (mode == Values.LABYRINTH || mode == Values.STORY_SEQUENSE) {
					nextPlace = d.getBuildingName();
					exit(mode);
				} else if (mode == Values.VILLAGE) {
					nextPlace = d.getBuildingName();
					logger.log(Level.FINE, "Next place village " + nextPlace);
					staticStartPos = (int) (fromHouse != null ? fromHouse[2] : 0);
					inHouse = true;
					exit(mode);
				} else if (mode == Values.HOUSE) {
					nextPlace = d.getBuildingName();
					logger.log(Level.FINE, "Next place house " + nextPlace);
					staticStartPos = (int) (fromHouse != null ? fromHouse[2] : 0);
					inHouse = true;
					setSuspended(true, false, true);
					
					exit(Values.VILLAGE);
				} else {
					buildingName = d.getBuildingName();
					nextPlace = null;
					inStore = true;
					setSuspended(true, true, true);
					exit(mode);
				}
			}
		}
		return entered;
	}

	private void setFade(int fadeMode) {
		switch (fadeMode) {
		case Door.FADE_UP :
			setMusicMode(SoundValues.FADE_IN, SoundValues.FAST, 
					SoundValues.ALL_THE_WAY, SoundValues.RESUME_PLAY);
			break;
		case Door.FADE_DOWN :
			setMusicMode(SoundValues.FADE_OUT, SoundValues.FAST, 
					SoundValues.ALL_THE_WAY, SoundValues.PAUSE);
			break;
		case Door.FADE_TO_HALF :
			setMusicMode(SoundValues.FADE_OUT, SoundValues.FAST, 
					SoundValues.HALF, SoundValues.NORMAL);
			break;
		}
	}

	/**
	 * Updates the villagers.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since this 
	 * method was last called.
	 */
	public void checkVillagers(float elapsedTime) {
		Iterator<Integer> it = sprites.keySet().iterator();
		while (it.hasNext()) {
			Sprite as = sprites.get(it.next());
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				v.update(elapsedTime, player, true);
			} else if (as instanceof ParticleSystem) {
				as.update(elapsedTime);
			} else if (!(as instanceof PartyMember)) {
				as.update(elapsedTime);
			}
		}
	}

	/**
	 * Initiates the question dialog. This dialog is used when the villager
	 * ask the player a question which the player can answer.
	 */
	private void initQuestionDialog() {
		question = true;
		changeDirBehaviour(Values.DETECT_INIT);
	}

	/**
	 * Quits the question dialog. This is used when the player has answered a
	 * question from the villager. 
	 */
	private void exitQuestionDialog() {
		question = false;
		dialog.loadResponse();
		changeDirBehaviour(Values.DETECT_ALL);
	}

	/**
	 * Checks the input from the user and acts according to the button.
	 * When a button is pressed the screen is repainted.
	 */
	private void checkGameInput() {
		if (!(talkmode || showSignDialog)) {
			if (player.isMoving()) {
				boolean shouldStop = true;
				for (int i = UP; i <= LEFT; i++) {
					if (!gameActions[i].isReleased()) {
						shouldStop = false;
					}
				}
				if (shouldStop) {
					player.standStill();
				}
			}
			
			checkDirectionalButtons();
			if (isMenuButtonPressed(gameActions)) {
				super.queueEnterMenu();
			}
		} else if (question) {
			checkDirectionalButtonsForQuestion();
		}
		if (gameActions[CROSS].isPressed()) {
			if (showSignDialog) {
				showSignDialog = false;
				return;
			}
			crossPressed();
		}
	}

	/**
	 * Sets whether or not the villager and the player has engaged in a
	 * conversation.
	 * 
	 * @param talking true if the player and the villagers should start 
	 * talking, false if they just stopped talking.
	 */
	private void setTalking(boolean talking) {
		talkmode = talking;
		talkingVillager.setTalking(talking, 
				Values.getCounterAngle(player.getDirection()));
		player.standStill();
	}

	/**
	 * Checks if any directional buttons has been pressed.
	 * This method does not break the loop if one of the buttons has been
	 * pressed, but keeps looping to check the rest. This is because the player
	 * should be able to press both down and left to go south west.
	 */
	private void checkDirectionalButtons() {
		int dir = -1;
		int count = gameActions[LEFT].isPressed() ? 1 : 0;
		boolean found = false;
		for (int i = UP; i <= LEFT; i++) {
			if (gameActions[i].isPressed()) {
				count++;	
			} else {
				if (count == 2) {
					found = true;
				} else {
					count = 0;
				}
			}
		}
		if (!found) {
			found = count == 2;
		}
		for (int i = UP; i <= LEFT; i++) {
			if (gameActions[i].isPressed()) {
				move(dir = (i - UP), found);
			}
		}
		if (dir != -1) {
			player.setPartyMembersPositions();
//			showSignDialog = false;
//			doorSign = null;
		} else {
			background.stop();
		}
	}

	/**
	 * Checks the directional buttons when the player is answering a
	 * question from the villager. This will cause the dialog to move
	 * the pointer hand.
	 */
	private void checkDirectionalButtonsForQuestion() {
		for (int i = UP; i <= LEFT; i++) {
			if (gameActions[i].isPressed()) {
				dialog.move(i);
			}
		}
	}

	/**
	 * Moves the player around in the village. The given argument is the 
	 * direction of the player, i.e. the direction to move the player.
	 * 
	 * @param direction the direction of the player.
	 */
	private void move(int direction, boolean diagonal) {
		if (!checkDoors(holeDoors, direction)) {
			if (checkVillagerCollision(direction)) {
				player.move(direction);
			} else if (!showSignDialog) {
				player.go(direction, diagonal, obstacleHandler);
				if (setDrawPos(direction % 2)) {
					int XorY = direction % 2;
					background.setPos(XorY, BACK_POS[XorY]);
				} else {
					background.stop();
				}
			}
		}
	}
	
	private boolean setDrawPos(int XorY) {
		float[] pos = player.getPos();
		if (obstacleHandler.isInMiddle(pos[XorY], XorY)) {
			BACK_POS[XorY] = obstacleHandler.getBackPos(pos[XorY], XorY);
			return true;
		}
		return false;
	}
	
	/**
	 * This method is called when the action button (cross button) is pressed.
	 * It checks if there are any villagers present to talk to or if the 
	 * player wanted to enter a building. When the player talks the 
	 * next dialog screen will be shown.
	 */
	private void crossPressed() {
		if (!talkmode) {
			if (checkLoot() || checkNearbyVillagers() || 
					checkDoors(doors, player.getDirection()) || checkSigns()) {
				return;
			}
		} else {
			if (question) {
				exitQuestionDialog();
			}
			
			Loot g = dialog.getGift();
			if (g != null) {
				Load.collectLoot(g);
			}
			String takeName = dialog.getTakeName();
			if (takeName != null) {
				int takeAmount = dialog.getTakeAmount();
				if (takeName.equals("gold")) {
					Load.getPartyItems().addGold(-takeAmount);
				} else {
					Load.getPartyItems().take(takeName, takeAmount);
				}
			}
			HashMap<String, Integer> t = dialog.getBeforeTriggers();
			HashMap<String, Integer> triggerAdds = dialog.getTriggerAdds();
			boolean finished = dialog.isFinished();
			doTriggers(t);
			if (triggerAdds != null) {
				Database.incrementStatus(triggerAdds);
			}
			if (finished) {
				setTalking(false);
				if (dialog.shouldTrigger()) {
					t = dialog.getTriggers();
					doTriggers(t);
					executeTrigger(talkingVillager);
				} else {
					dialog.resetDialog();
				}
			} else {
				if (dialog.isQuestion()) {
					initQuestionDialog();
				}
			}
		}
	}

	private void doTriggers(HashMap<String, Integer> t) {
		if (t != null) {
			Database.updateStatus(t);
			Iterator<String> it = t.keySet().iterator();
			while (it.hasNext()) {
				String name = it.next();
				updateVillagerDialog(name, t.get(name));
			}
		}
	}

	/**
	 * Checks if there are any loots nearby to take. This is checked when the
	 * player presses the actions button (cross button).
	 * 
	 * @return true if there are any loots nearby.
	 */
	private boolean checkLoot() {
		boolean found = false;
		for (int i = 0; i < loots.size() && !found; i++) {
			Loot l = loots.get(i);
			if (l.isInRange(player.getPos()) && l.checkPlayerDir(player.getDirection())) {
				if (l.decrementStatus()) {
					loots.remove(i);
					Load.collectLoot(l);
					createSign(l.getLine(0), l.getLine(1), l.getContent());
					player.standStill();
				}
				found = true;
			}
		}
		return found;
	}
	
	private void createSign(String fl, String sl, Object content) {
		setSign(new Sign(fl, sl, content));
	}
	
	private void setSign(Sign s) {
		showSignDialog = true;
		sign = s;
		player.standStill();
	}

	/**
	 * Checks if there are any villagers nearby to talk to. This is checked
	 * when the player presses the actions button (cross button).
	 * 
	 * @return true if there are any villagers to talk to.
	 */
	private boolean checkNearbyVillagers() {
		Iterator<Integer> it = sprites.keySet().iterator();
		while (it.hasNext()) {
			Sprite as = sprites.get(it.next());
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				if (v.checkTalkable(player.getPos(), player.getDirection())) {
					return executeTalkableVillager(v);
				}
			}
		}
		return false;
	}

	/**
	 * Executes the dialog sequence that the given villager has. This method
	 * is called when the given villager is in range and the player has pressed
	 * the cross button, wanting to talk to this villager. If the given 
	 * villagers next dialog is a story sequence, one is initiated.
	 * 
	 * @param v the villager whose dialog sequence to execute.
	 */
	private boolean executeTalkableVillager(Villager v) {
		boolean ans = false;
		
		if (v.isDialogSequence()) {
			logger.log(Level.FINE, "Is dialog");
			ans = true;
			if (Creature.isOneInTeamDead(
					Load.getCharactersAsCreatures())) {
				// Can't happen in current version...
				dialog.resetDialog();
				dialog.setDS(new DialogSequence(
								v.getName(), "...", "", true, false, false));
			} else {
				buildingName = null;
				String filename = v.getSequenceFilename();
				if (filename.startsWith("exit")) {
					nextPlace = filename.replace("exit", "");
					exit(Values.STORY_SEQUENSE);
				} else {
					logger.log(Level.FINE, "Execute talk ");
					storyInfo = Organizer.getOrganizer().getInformationFor(filename);
					logger.log(Level.FINE, "Story info " + storyInfo);
					String mus = storyInfo.get("music");
					nextPlace = null;
					switchGameMode(Values.VILLAGE_STORY, mus != null && !mus.equals("continue"), false);
				}
				return true;
			}
		} else if (v.getDialog().size() > 0) {
			dialog.setDS(v.getDialog(), v.getResponses());
			ans = true;
			HashMap<String, Integer> t = dialog.getBeforeTriggers();
			if (t != null) {
				Database.updateStatus(t);
			}
		} else {
			return false;
		}
		logger.log(Level.FINE, "Set talking ");
		talkingVillager = v;
		setTalking(true);
		return ans;
	}
	
	/**
	 * Checks if there are any sings nearby to read. This is checked
	 * when the player presses the actions button (cross button).
	 * 
	 * @return true if there are any sings to read.
	 */
	private boolean checkSigns() {
		for (int i = 0; i < signs.size(); i++) {
			if (signs.get(i).isInRange(
					player.getPos(), player.getDirection())) {
				setSign(signs.get(i));
				return true;
			}
		}
		return false;
	}

	/**
	 * Checks if there are any doors around to enter. This is checked
	 * when the player presses the actions button (cross button).
	 * @param direction 
	 * 
	 * @return true if there are any doors around to enter.
	 */
	private boolean checkDoors(ArrayList<Door> doors, int direction) {
		boolean stopSeaching = false;
		boolean found = false;
		for (int i = 0; i < doors.size() && !stopSeaching; i++) {
			stopSeaching = doors.get(i).isInRange(player.getPos());
			if (stopSeaching) {
				found = checkDoor(doors.get(i), direction);
			}
		}
		return found;
	}
	
	/**
	 * Executes the trigger associated with the given villager.
	 * 
	 * @param vil the villager which trigger to execute.
	 */
	public void executeTrigger(Villager vil) {
		String s = vil.getStoredTriggers();
		if (s != null) {
			Database.storeTriggers("inn", s);
		}
		
		dialog.resetDialog();
	}
	
	
	public void updateVillagerDialog(String name, int value) {
		logger.log(Level.FINE, "Update villager dialog " + name + " " + value);
		Villager v = getVillager(name);
		logger.log(Level.FINE, "Villager " + v);
		if (v != null) {
			v.updateDialog(value);
		}
	}

	/**
	 * This method gets the information map for the next place, 
	 * if the next place is one of this villages buildings.
	 * If the next place to enter is the landscape this
	 * method will return null.
	 * 
	 * @return the information about the next place.
	 */
	public HashMap<String, String> getInfoForNextPlace() {
		if (buildingName != null) {
			return buildingInfo.get(buildingName);
		}
		return storyInfo;
	}
	
	public HashMap<String, String> getTestInfoForType(String name) {
		Iterator<String> it = buildingInfo.keySet().iterator();
		while (it.hasNext()) {
			String next = it.next();
			if (next.contains(name)) {
				return buildingInfo.get(next);
			}
		}
		return null;
	}

	/**
	 * Checks if the player has collided with a villager.
	 * 
	 * @param direction the direction of the player.
	 * @return true if a collision has occurred.
	 */
	private boolean checkVillagerCollision(int direction) {
		boolean found = false;
		Iterator<Integer> it = sprites.keySet().iterator();
		while (it.hasNext() && !found) {
			Sprite as = sprites.get(it.next());
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				found = player.checkCollision(v, direction);
			}
		}
		return found;
	}
	
	/**
	 * This method draws the village. It uses the game mode super class, to 
	 * fade in and out. 
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(Graphics g) {
//		Graphics.gl.glTranslatef(-.25f * Values.RESOLUTIONS[Values.X], -.25f * Values.RESOLUTIONS[Values.Y], 1);
		//super.drawNew(g);
		g.setColor(1);
		synchronized (this) {
			drawBottom(g);
			drawTop(g, sprites);
		}
//		if (Math.random() < .01f) {
//			color[3] = 0;
//		}
//		if (color[3] <= .5f) {
//			color[3]+=.08f;
//			g.fadeOldSchoolColorWhite(1, .9f, 0, .3f - color[3]);
//		} else {
//			g.fadeOldSchoolColor(color[0], color[1], color[2], color[3]);
//		}
		super.checkMenu();
		super.draw(g);
	}
		

	/**
	 * This method draws the bottom layer of the village on the given 
	 * graphics. The things drawn on this layer are background, animated 
	 * objects and villagers.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawBottom(Graphics g) {
		background.drawBottom(g);
		int x = (int) background.getPos()[Values.X];
		int y = (int) background.getPos()[Values.Y];
		Iterator<Integer> it = sprites.keySet().iterator();
		int index = 0;
		while (it.hasNext()) {
			Sprite as = sprites.get(it.next());
			float asy = as.getY();
			elements[index].setYpos(asy);
			elements[index++].setIndex(as.hashCode());
		}
		Arrays.sort(elements);
		if (sprites.size() != elements.length) {
			logger.log(Level.WARNING, "Error: the sprite list and elements are not of equal length");
		}
		for (int i = 0; i < index; i++) {
			Sprite as = sprites.get(elements[i].getIndex());
			if (as instanceof PartyMember) {
				int asx = Math.round(as.getX() + x);
				int asy = Math.round(as.getY() + y);
				as.draw(g, asx, asy);
			} else {
				as.draw(g, x, y);
			}
		}
	}

	/**
	 * This method draws the top layer of the village on the given 
	 * graphics. The things drawn on this layer are roofs and treetops,
	 * dialogs and villagers that have a lower Y-value than the player.
	 * 
	 * @param g the graphics to draw on.
	 * @param sprites 
	 */
	public void drawTop(Graphics g, HashMap<Integer, Sprite> sprites) {
		background.drawTop(g, true, sprites);
		if (sprites != null) {
			Iterator<Integer> it = sprites.keySet().iterator();
			while (it.hasNext()) {
				sprites.get(it.next()).drawEmotions(g);
			}
		}
		
		if (talkmode) {
			dialog.draw(g);
		} else if (showSignDialog) {
			Dialog.getDialog().drawMessages(
					g, sign.getText()[0], sign.getText()[1], true);
			Object content = sign.getContent();
			if (content != null) {
				if (content instanceof Card) {
					DeckPage.drawCardInfo(g, (Card) content, 530);
				}
			}
		}
	}

	/**
	 * The player in the village.
	 * 
	 * @return the player in the village.
	 */
	public Player getPlayer() {
		return player;
	}

	/**
	 * Gets the name of the folder where images and maps for this village is.
	 * 
	 * @return the name of the folder where the information about 
	 * this village is.
	 */
	public String getVillageFolderName() {
		return folderName;
	}

	/**
	 * Gets the background object of this village.
	 * 
	 * @return the object that stores the background images for this village.
	 */
	public DoubleBackground getBackground() {
		return background;
	}

	/**
	 * Gets a map of all the villagers in the village.
	 * 
	 * @return all the villagers in the village.
	 */
	public HashMap<Integer, Sprite> getVillagers() {
		for (int i = 0; i < player.getPartyMembers().size(); i++) {
			int h = player.getPartyMembers().get(i).hashCode();
			sprites.remove(h);
		}
		updateSpriteList();
		return sprites;
	}

	/**
	 * Adds the given list of villagers to this village.
	 * 
	 * @param removedVillagers the villagers to add.
	 */
	public void addVillagers(ArrayList<Sprite> removedVillagers) {
		for (int i = 0; i < removedVillagers.size(); i++) {
			Sprite as = removedVillagers.get(i);
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				//v.setStartToPos(v.getPos());
				//v.reset();
				sprites.put(v.hashCode(), v);
				//executeTrigger(v);
			}
		}
		for (int i = 0; i < player.getPartyMembers().size(); i++) {
			Sprite as = player.getPartyMembers().get(i);
			sprites.put(as.hashCode(), as);
		}
		updateSpriteList();
	}
	
	public void addOnlyVillagers(ArrayList<Sprite> removedVillagers) {
		for (int i = 0; i < removedVillagers.size(); i++) {
			Sprite as = removedVillagers.get(i);
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				//v.setStartToPos(v.getPos());
				//v.reset();
				sprites.put(v.hashCode(), v);
				//executeTrigger(v);
			}
		}
		updateSpriteList();
	}
	
	public void addSprite(Sprite s) {
		sprites.put(s.hashCode(), s);
		updateSpriteList();
	}

	/**
	 * Updates the sprite lists "z-buffering". Every sprite in the sprite list
	 * is make sure to have a SortingElement which is used to draw them in
	 * a sorted order. This will result in the sprites with low y-positions
	 * to be drawn first.
	 */
	public void updateSpriteList() {
		if (sprites.size() != elements.length) {
			elements = new SortingElement[sprites.size()];
			Iterator<Integer> it = sprites.keySet().iterator();
			int i = 0;
			while (it.hasNext()) {
				int index = it.next();
				Sprite as = sprites.get(index);
				elements[i] = new SortingElement(as.getY(), index);
				i++;
			}
		}
	}

	/**
	 * This method is called when the story mode has finished and
	 * the village should be initiated. The given position is the
	 * position of the player when the store mode ended and the list
	 * of villagers are those villagers who acted as actors in the story.
	 * 
	 * @param pos the position to set the player to. This is normally the
	 * position that the player have when the story is ended.
	 * @param removedVillagers the list of villagers to add to the village.
	 * @param nextPlace the nextPlace to set.
	 */
	public void initFromStory(float[] pos, 
			ArrayList<Sprite> removedVillagers, String nextPlace) {
		logger.log(Level.FINE, "Init from story " + Arrays.toString(pos) + " " + this.hashCode());
		logger.log(Level.FINE, "Next " + nextPlace);
		player.setPos(pos);
		player.update(Values.LOGIC_INTERVAL);
		addVillagers(removedVillagers);
		if (nextPlace != null && !nextPlace.equals(" ") && !nextPlace.equals("_")) {
			this.exitName = nextPlace;
		}
	}

	/**
	 * Sets this village to be ready. This means that if it is started, the
	 * village should not fade in (or out). It is used by village story modes
	 * which initiates villages and when the story is through, the village
	 * should continue as usual.
	 */
	public void setReady() {
		fadein = fadeout = false;
		fadeValue = 1;
		loadingDone();
	}

	/**
	 * Exits the village. The destination depends on the value of the 
	 * nextPlace. If this is null, the destination is the landscape.
	 */
	public void exit() {
		nextPlace = exitName;
		Organizer.getOrganizer().deleteSuspended();
		exit(Values.LANDSCAPE);
	}

	public void setBackground(String string) {
		background.setExtraBack(string); 
	}

	public ParticleSystem getParticleSystem(String name) {
		Iterator<Sprite> it = sprites.values().iterator();
		while (it.hasNext()) {
			Sprite s = it.next();
			if (s instanceof ParticleSystem) {
				if (s.getName().equals(name)) {
					return (ParticleSystem) s;
				}
			}
		}
		return background.getParticleSystem(name);
	}
}
