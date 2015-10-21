/*
 * Classname: Labyrinth.java
 * 
 * Version information: 0.7.0
 *
 * Date: 24/05/2008
 */
package labyrinth;

import factories.EnemyFactory;
import factories.Load;
import factories.EnemyFactory.EnemyGroup;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.LabyrinthInfo;
import info.LabyrinthMap;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

import com.jogamp.opengl.GL2;

import labyrinth.inventory.AbstractDoor;
import labyrinth.inventory.Door;
import labyrinth.inventory.HinderDoor;
import labyrinth.inventory.Inventory;
import labyrinth.mission.Mission;
import labyrinth.mission.MissionFactory;
import menu.DeckPage;
import miniGames.RiddleGame;

import organizer.GameEventListener;
import organizer.GameMode;
import organizer.MenuStarter;
import organizer.Organizer;

import sound.OggStreamer;
import sound.SoundValues;
import villages.utils.Dialog;
import villages.utils.DialogSequence;
import weather.WeatherSystem;
import battle.BattleManager;
import battle.BattleStarter;
import battle.equipment.GLDeck;
import cards.Card;
import character.Character;

/**
 * This class represents the labyrinth in the game. It can be viewed as 
 * a graph of nodes, where each node is one step in the labyrinth. 
 * First, the walls with textures is drawn and then the players path 
 * is created. The player can not move outside of this path. The walls 
 * have no collision detection so, if the path goes through a wall then 
 * so does the player. The labyrinth uses open GL to render the textures.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 24 May 2008.
 */
public class Labyrinth extends MenuStarter implements BattleStarter {

	private Graph graph;
	private LabyrinthPlayer player;
	private Node currentNode;
	private labyrinth.MapLoader mapLoader;
	private LabyrinthRenderer renderer;
	private String name;
	private DialogSequence dialog;
	private Card card;
	
	private LabyrinthDrawable labDrawable;
	private MapRenderer mapRenderer;
	private Mission mission;
	private boolean subGameModeInitiated = false;
	private boolean labyrinthInitiaded = false;
	
	private int dir;
//	private int startAddress;
	private int lastAddress;
	private int drawList;
	private int steps;
	private int currentStepsToBattle;
	private int[] stepsToBattle;
	private boolean hasEnemies;
	private boolean runSubGameMode = false;
	private WeatherSystem weatherSystem;
	private boolean noEncounters = false;
	private String[] battleMusic;
	private ArrayList<DialogSequence> dialogSequence;
	
	/**
	 * Creates, loads and starts the labyrinth.
	 * 
	 * @param info a hash map containing some information, like which map to
	 * load, which start node to load, and the name of the music.
	 */
	public void init(HashMap<String, String> info) {
		super.init(info, Values.DETECT_AS_KEY);
		if (ImageHandler.isCurrentGameModeCleared()) {
			updateCharacterDecks();
		}
		infoMap.get("name");
		String mapName = info.get("map");
		name = mapName.replace(".map", "").replace("_", " ");
		EnemyFactory ef = EnemyFactory.getEnemyFactory();
		EnemyGroup eg = ef.getEnemyGroup(name);
		hasEnemies = (eg != null) && eg.hasEnemies();
		if (hasEnemies) {
			eg.loadTextures();
		}
		LabyrinthInfo labInfo = Database.getMap(mapName);
		mapLoader = new labyrinth.MapLoader(mapName);
		mission = MissionFactory.createMission(mapLoader.getMission());
		
		LabyrinthMap map = mapLoader.getMap();
		if (labInfo != null) {
			LabyrinthMap m = labInfo.getFloor(mapName, true);
			if (m != null) {
				map = m;
			}
		}
		graph = new Graph(mapName, map);
		mapRenderer = new MapRenderer(map);
		stepsToBattle = mapLoader.getStepsToBattle();
		resetSteps();
		GameMode gm = Organizer.getOrganizer().getPreviousMode();
		String lastNameInMain = null;
		if (gm instanceof Labyrinth) {
			steps = ((Labyrinth) gm).steps - 2;
			Node n = ((Labyrinth) gm).currentNode;
			if (n.hasInventory()) {
				Inventory inv = n.getInventory();
				if (inv instanceof AbstractDoor) {
					lastNameInMain = ((AbstractDoor) inv).getNameInMain();
				}
			}
		}
		int start = Integer.parseInt(info.get("start"));
		currentNode = graph.getStartNode(start);
		currentNode.visit();
		if (currentNode.hasInventory()) {
			Inventory inv = currentNode.getInventory();
			if (inv instanceof AbstractDoor) {
				inv.setHaveBeen(lastNameInMain);
			}
		}
//		startAddress = currentNode.getAddress();
		renderer = mapLoader.getRenderer();
		weatherSystem = renderer.getWeatherSystem();
		dir = graph.getAngle();
		graph.setLabyrinth(this);
		graph.sortInventory();
		Position nodePos = currentNode.getPos();
		Position pos = new Position(
				nodePos.getX(), nodePos.getZ(), Values.TO_ANGLE[dir]);
		player = new LabyrinthPlayer(pos);
		battleMusic = mapLoader.getBattleMusic();
		
		logicLoading = false;
		System.out.println("Logic loading done");
		if (currentNode.getInventory() instanceof AbstractDoor) {
			currentNode.arrive(this);
		}
	}

	private void updateCharacterDecks() {
		ArrayList<Character> chars = Load.getCharacters();
		for (int i = 0; i < chars.size(); i++) {
			GLDeck deck = chars.get(i).get2DDeck();
			if (deck != null) {
				deck.setNeedUpdate(true);
			}
		}		
	}

	/**
	 * This method overrides the empty method in the GameMode class.
	 * It initiates the GL object. It sets light, fog and draws the
	 * labyrinth into a GL generated list.
	 * 
	 * @param gl the GL object to initiate.
	 */
	protected void init3D(Graphics g) {
		renderer.addLight(g);
		renderer.setMaterial(g);
		renderer.addFog(g);
		
		renderer.init(g);
		
		drawList = ImageHandler.generateDrawList(g);
		g.compileDrawList(drawList);
		g.setTextureEnabled(false);
		g.setLightEnabled(false);
		
		renderer.renderSky(g);
		g.setTextureEnabled(true);
		g.setLightEnabled(true);
		renderer.draw(0, g);
		g.endList();
		
		renderer.setLight(g);
		graph.initDrawInventory(g);
//		graph.setInventoryMaterial(renderer.getSettingValue(MapLoader.INV_MATERIAL));

		mapRenderer.initDraw(g);
	}
	
	/**
	 * This method resumes the labyrinth. This method is used when the
	 * player has been in the menu and wants to resume the labyrinth.
	 */
	public void resume() {
		super.resume(Values.DETECT_ALL, false);
		GameEventListener.set3D();
	}
	
	/**
	 * Updates the labyrinth. This method checks the input and moves
	 * the player if any button has been pressed.
	 * 
	 * @param elapsedTime the amount of time since the game was last updated.
	 */
	public void update(float dt) {
		mapRenderer.update(dt);
		if (weatherSystem != null) {
			weatherSystem.update();
		}
		if (runSubGameMode) {
			labDrawable.update(dt);
			super.update(dt);
			return;
		}
		if (!fadeout) {
		if (player.isMoving()) {
			player.update(dt);
		} else {
			if (!checkBossFight() && checkSteps()) {
				if (checkEnterBattle(dir)) {
					enterBattle(false, null);
				} else {
					checkButtons();
				}
			} else {
				checkButtons();
			}
		}
		}
		super.update(dt);
	}
	
	/**
	 * Checks the players position to see if the player has reached the 
	 * end of the labyrinth and should exit.
	 * 
	 * @param dir the direction of the node, relative the current node,
	 * to check. 
	 */
	private void checkNode(int dir) {
		if (!player.isMoving()) {
			boolean temp = false;
			if (currentNode.hasInventory()) {
				Inventory inv = currentNode.getInventory();
				if (inv instanceof Door || inv instanceof HinderDoor) {
					temp = graph.isDirectedTowards(currentNode, dir);
				}
				if (temp) {
					graph.activateInventory(currentNode, this);
				}
			} 
			if (!temp) {
				Node n = currentNode.getNode(dir);
				if (n != null && n.hasInventory()) { // && !n.getInventory().isPassable(dir)) {
					graph.activateInventory(n, this);
				}
			}
		}
	}
	
	/**
	 * This method checks if the current node is a boss fight.
	 * 
	 * @return true if the current node is a boss fight.
	 */
	private boolean checkBossFight() {
		if (!player.isMoving()) {
			return graph.checkBossNode(currentNode, this);
		}
		return false;
	}
	
	/**
	 * Checks if the player can enter the battle. This method does not
	 * consider how many steps the player has taken, only if the current
	 * nodes next node and the node after that (two nodes away in the 
	 * given direction from the current node), allows the player to battle.
	 * One of these nodes could be an inventory of some kind or maybe a wall.
	 * This method returns true if the two nodes ahead exists and if they 
	 * contain no inventories.
	 * 
	 * @param dir the direction of the player.
	 * @return true if the player can enter a battle.
	 */
	private boolean checkEnterBattle(int dir) {
		boolean freeToBattle = false;
		if (!currentNode.hasInventory()) {
			Node n = currentNode.getNode(dir);
			if (n != null && !n.hasInventory()) {
				n = n.getNode(dir);
				if (n != null && !n.hasInventory()) {
					freeToBattle = true;
				}
			}
		}
		return freeToBattle;
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
	public void enterBattle(boolean boss, String bossName) {
		push();
		if (!battleMusic[0].equalsIgnoreCase("No Music")) {
			setMusicMode(SoundValues.FADE_OUT, 1000, 
					SoundValues.ALL_THE_WAY, SoundValues.PAUSE);
		}
		BattleManager bm;
		labDrawable = bm = new BattleManager();
		bm.setBattleStarter(this);
		bm.init(getBattleInfo(boss, bossName));
		runSubGameMode = true;
		subGameModeInitiated = false;
		// leaveBattle();
	}
	
	/**
	 * This method exits the battle mode and resumes the labyrinth.
	 * This is called after the player has defeated the enemies.
	 */
	public void leaveBattle() {
		pop();
		runSubGameMode = false;
		if (!battleMusic[0].equalsIgnoreCase("No Music")) {
			((BattleManager) labDrawable).setMusicMode(
					SoundValues.FADE_OUT, SoundValues.FAST, 
					SoundValues.NORMAL, SoundValues.KILL_MUSIC_ON_FADE_DOWN);
		}
		ArrayList<Character> chars = Load.getCharacters();
		for (Character c : chars) {
			if (!c.isAlive()) {
				c.cureFromDead();
				c.cure(1);
			}
		}
		resetSteps();
		resume();
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
			resetSteps();
			if (fadeBattleMusic && labDrawable != null && labDrawable instanceof BattleManager) {
				((BattleManager) labDrawable).setMusicMode(
						SoundValues.FADE_OUT, 4000, 
						SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN);
			}
//			runSubGameMode = false;
			setFadeOutSpeed(.01f);	
//			resume();
			nextPlace = next;
			exit(Values.EXIT);
		}
	}

	/**
	 * This method enters the riddle mode and loads the riddle 
	 * file with the given name.
	 * 
	 * @param name the name of the riddle file to load.
	 * @param hinders 
	 */
	public void enterRiddle(String name, String riddleClassName, Inventory[] hinders) {
		push();
		runSubGameMode = true;
		setMusicMode(SoundValues.FADE_OUT, SoundValues.SLOW, SoundValues.HALF);
		try {
			Class<?> riddleClass = Class.forName(riddleClassName);
			RiddleGame riddle = (RiddleGame) riddleClass.newInstance();
			riddle.init(name, this, hinders);
			labDrawable = riddle;
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * This method exits the riddle mode and resumes the labyrinth.
	 */
	public void exitRiddle() {
		runSubGameMode = false;
		setMusicMode(SoundValues.FADE_IN, SoundValues.SLOW, SoundValues.ALL_THE_WAY);
		labDrawable = null;
		resume();
		pop();
	}

	/**
	 * Gets the battle information.
	 * 
	 * @param boss true if the battle is a boss battle.
	 * @param bossName 
	 * @return the information used to start the battle.
	 */
	private HashMap<String, String> getBattleInfo(boolean boss, String bossName) {
		HashMap<String, String> info = new HashMap<String, String>();
		info.put("music", boss ? battleMusic[1] : battleMusic[0]);
		info.put("boss", String.valueOf(boss));
		info.put("name", boss ? bossName : name);
		return info;
	}
	
	/**
	 * Checks the buttons and moves the player if any directional buttons
	 * has been pressed. This method also enters the menu if the player
	 * presses the triangular button.
	 */
	private void checkButtons() {
		if (dialog == null) {
			if (gameActions[UP].isPressed()) {
				move(dir);
			} else if (gameActions[DOWN].isPressed()) {
				move(Values.getCounterAngle(dir));
			} else if (gameActions[LEFT].isPressed()) {
				turn(LabyrinthPlayer.LEFT_TURN);
			} else if (gameActions[RIGHT].isPressed()) {
				turn(LabyrinthPlayer.RIGHT_TURN);
			} 
			if (isMenuButtonPressed(gameActions)) {
				super.queueEnterMenu();
			}
		} else {
			int button = -1;
			if (gameActions[UP].isPressed()) {
				button = UP;
			} else if (gameActions[DOWN].isPressed()) {
				button = DOWN;
			} else if (gameActions[LEFT].isPressed()) {
				button = LEFT;
			} else if (gameActions[RIGHT].isPressed()) {
				button = RIGHT;
			} 
			if (button != -1) {
				Dialog.getDialog().move(button);
			}
		}
		if (gameActions[CROSS].isPressed()) {
			exitDialog();
			checkNode(dir);
		}
	}

//	private void checkConrolButtons() {
//		if (gameActions[R2].isPressed() || gameActions[L2].isPressed()) {
//			toggle();
//		}
//	}
	
	/**
	 * Moves the player one node in the given direction if there is
	 * a node there. This method also checks if the player has reached
	 * an exit node.
	 * 
	 * @param dir the direction the player should move.
	 */
	private void move(int dir) {
		Node n = currentNode.getNode(dir);
		if (n != null && !graph.checkForHinder(currentNode, n, dir) && !graph.checkBossNode(n, this)) {
			lastAddress = currentNode.getAddress();
			currentNode = n;
			player.moveTo(currentNode, this);
			Load.getPartyItems().takeStep();
			steps++;
			Load.cureParty();
			inputManager.resetAllGameActions();
		}
	}
	
	/**
	 * Gets the direction of the player.
	 * 
	 * @return the direction of the player.
	 */
	public int getPlayerAngle() {
		return player.getDirection();
	}
	
	public int getPlayerDirection() {
		return dir;
	}
	
	/**
	 * Turns the players view 90 degrees to the left or right.
	 * 
	 * @param turnDir can either be LabyrinthPlayer.LEFT_TURN or 
	 * LabyrinthPlayer.RIGHT_TURN.
	 */
	private void turn(int turnDir) {
		dir += turnDir;
		if (dir < 0) {
			dir = Values.LEFT;
		} else if (dir > Values.LEFT) {
			dir = Values.UP;
		}
		player.turnYTo(Values.TO_ANGLE[dir], turnDir);
		inputManager.resetAllGameActions();
	}
	
	/**
	 * Draws the labyrinth.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void draw(float dt, Graphics g) {
		if (!labyrinthInitiaded) {
			init3D(g);
			labyrinthInitiaded = true;
		}
		
		player.lookAt(g);
		g.callList(drawList);
		graph.drawInventory(dt, g);
		g.setLightEnabled(false);
		
		if (weatherSystem != null) {
			weatherSystem.draw(g, player, false);
		}
		if (runSubGameMode) {
			g.push();
			drawExtra(dt, g, false);
			g.pop();
		}
		
		if (weatherSystem != null) {
			weatherSystem.draw(g, player, true);
		}
		g.loadIdentity();
		Graphics.gl.glDepthMask(false);
		Graphics.gl.glDisable(GL2.GL_DEPTH_TEST);
		mapRenderer.draw(
				g, player.get(), player.getDirection(), 
				currentNode.getAddress(), lastAddress);
		
		g.loadIdentity();
		GameEventListener.set2DNow(g);
		if (mission != null) {
			mission.draw(dt, g);
		}
		if (dialog != null) {
			g.setColor(1);
			Dialog.getDialog().draw(dt, g);
			if (card != null) {
				DeckPage.drawCardInfo(g, card, 530);
			}
		}
		if (runSubGameMode) {
			g.push();
			drawExtra(dt, g, true);
			g.pop();
		}
		if (!topLayer.isEmpty()) {
			g.push();
			Iterator<Inventory> it = topLayer.values().iterator();
			while (it.hasNext()) {
				Inventory i = it.next();
				i.drawTopLayer(g);
			}
			g.pop();
		}
//		g.drawString("Steps: " + steps, 50, 300);
//		g.drawString("Steps to: " + Arrays.toString(stepsToBattle), 50, 350);
//		g.drawString("currentStepsToBattle: " + currentStepsToBattle, 50, 400);
//		g.drawString("hasEnemies: " + hasEnemies, 50, 450);
//		g.drawString("checkSteps: " + checkSteps(), 50, 500);
		super.draw(dt, g);
		
		// TODO: Don't think this is necessary...
		g.setLightEnabled(true);
		super.checkMenu();
	}
	
	private ConcurrentHashMap<String, Inventory> topLayer = new ConcurrentHashMap<String, Inventory>();
	
	public void addTopLayer(Inventory i) {
		topLayer.put(i.getClass().getName(), i);
	}
	
	public void removeFromTopLayer(Inventory i) {
		topLayer.remove(i.getClass().getName());
	}
	
	/**
	 * Draws the battle.
	 * 
	 * @param g the graphics to draw on.
	 */
	private void drawExtra(float dt, Graphics g, boolean topLayer) {
		if (!subGameModeInitiated) {
			labDrawable.initDraw(g);
			subGameModeInitiated = true;
		}
		if (topLayer) {
			labDrawable.drawTopLayer(g);
		} else {
			labDrawable.draw(dt, g);
		}
	}
	
	/**
	 * Checks to see if the player has walked to far.
	 * 
	 * @return true, if the player has used up all his steps.
	 */
	private boolean checkSteps() {
		if (currentStepsToBattle == -1) {
			return false;
		}
		return !noEncounters && (steps >= currentStepsToBattle && hasEnemies);
	}
	
	public boolean isFading() {
		return super.isFading();
	}
	
	/**
	 * Resets the step counter and calculates the number of
	 * steps until the next battle.
	 */
	private void resetSteps() {
		steps = 0;
		if (stepsToBattle[0] == -1) {
			currentStepsToBattle = -1;
		} else {
			currentStepsToBattle = new Random().nextInt(
					stepsToBattle[1]) + stepsToBattle[0];
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
	
	public void drawDialog(
			boolean firstDialogImage, String name, String first, 
			String second, boolean whisper) {
		drawDialog(new DialogSequence(name, first, second, firstDialogImage, whisper));
	}
	
	public void drawDialog(DialogSequence dia) {
		dialog = dia;
		Dialog.getDialog().setDS(dialog);
		push();
	}
	
	public void drawDialog(ArrayList<DialogSequence> dia) {
		dialog = dia.get(0);
		dialogSequence = dia;
		Dialog.getDialog().resetDialog();
		Dialog.getDialog().setDS(dialogSequence, null);
		push();
	}
	
	public void exitDialog() {
		if (Dialog.getDialog().isFinished()) {
			if (dialog != null) {
				pop();
				dialog = null;
				card = null;
			}
		}
	}

	private void push() {
		mapRenderer.pushState();
		mapRenderer.hide();
		if (mission != null) {
			mission.pushState();
			mission.hide();
		}
	}
		
	private void pop() {
		mapRenderer.popState();
		if (mission != null) {
			mission.popState();
		}
	}

	public void drawCard(Card c) {
		card = c;
	}
	
	public String getName() {
		return name;
	}
	
	public String getSimpleName() {
		return name.split("--")[0];
	}
	
	public String getMainName() {
		return infoMap.get("name");
	}
	
	public String getFloorName() {
		String[] s = name.split("--");
		if (s.length > 1) {
			return s[1];
		}
		return null;
	}
	
	public Node getCurrentNode() {
		return currentNode;
	}

	public Mission getMission() {
		return mission;
	}

	public String getMissionNext() {
		if (mission != null) {
			return mission.getNext();
		}
		return null;
	}

	public void resetMissionNext() {
		if (mission != null) {
			mission.resetNext();
		}
	}

	public void notifySwitchMusic(String music, int fadeSpeed) {
		// Do nothing
	}

	public void overwriteStarterMusic(String music, OggStreamer oggPlayer) {
		System.out.println("Overwrite");
		this.oggPlayer.exit();
		this.oggPlayer = oggPlayer;
		this.music = music;
	}
}
