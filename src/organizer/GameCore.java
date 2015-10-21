/*
 * Classname: GameCore.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/05/2008
 */
package organizer;

import graphics.Graphics;
import info.Database;
import info.Values;
import input.GameAction;
import input.GamePadController;
import input.InputGamePadManager;
import input.InputKeyBoardManager;
import input.InputManager;
import input.GameAction.GameActions;
import input.InputManager.InputManagers;
import com.jogamp.opengl.GLAutoDrawable;
import java.util.logging.*;
import menu.Node;

/**
 * This class is the game core. It initializes the screen and the 
 * input managers and start the game loop.
 * 
 * @author 		Kalle Sjöström.
 * @version 	0.7.0 - 11 May 2008
 */
public abstract class GameCore {

	public static Screen screen;
	public static InputManagers inputManager = new InputManagers();
	public static GameActions[] gameActions;
	
	private static boolean paused;
	private static String[] strings;
	private static String[] values;
	private static Logger logger = Logger.getLogger("GameCore");
	
	private Node activeNode;
		
	/**
	 * Uses the screen manager to set the window in full screen mode.
	 * It also connects the input manager to the window and removes the cursor.
	 */
	protected void init() {
		screen = Screen.getScreen();
		activeNode = new Node(null, "");
		fillRoot();
	}
	
	/**
	 * Fills the root menu used in the title screen.
	 */
	private void fillRoot() {
		Node n = activeNode;
		n.insertChild("Try to reconnect");
		n.insertChild("Use keyboard instead");
		n.setDistance(50);
		n.setPositions(Values.createNormalPoint(400, 600));
	}
	
	protected void init2(Object[] obs) {
		if (GamePadController.areThereAnyGamePadControllers()) {
			inputManager.addInputManager(new InputGamePadManager());
		}
		if (obs != null) {
			for (Object o : obs) {
				if (o instanceof InputManager) {
					inputManager.addInputManager((InputManager) o);
				}
			}
		}
		inputManager.addInputManager(new InputKeyBoardManager(screen));
		screen.init(this);
		inputManager.createGameActions();
		setGameAction();
	}
	
	public static void setGameAction() {
		gameActions = inputManager.getGameActions();
	}

	public static void enterCheat() {
		strings = Database.getStoredKeys();
		values = new String[strings.length];
		for (int i = 0; i < strings.length; i++) {
			String s = strings[i].toString();
			int v = Database.getStatusFor(s);
			values[i] = String.valueOf(v);
		}
	}

	boolean firstTimeIn = true;
	
	public void coreUpdate(float dt) {
		if (isPausable() && inputManager.hasStartBeenPressed()) {
			paused = !paused;
		}
		
		if (paused)
			dt = 0;

		update(dt);
	}
	
	protected void render(float dt, Graphics g, GLAutoDrawable drawable) {
		draw(dt, g);
		g.checkError();

		if (inputManager.connectionLost()) {
			if (firstTimeIn) {
				for (int i = GameMode.UP; i <= GameMode.LEFT; i++) {
					gameActions[i].changeBehavior(GameAction.DETECT_INITAL_PRESS_ONLY);
				}
			}
			firstTimeIn = false;
			g.fadeOldSchool(.5f);
			g.setFontSize(50);
			g.drawStringCentered("Connection to game pad lost", 250);
			g.setFontSize(30);
			g.drawStringCentered("Please reconnect the game pad in a USB port", 320);
			g.drawStringCentered("(You can connect to the gamepad from the menu (Settings) later)", 350);
			
			if (gameActions[GameMode.UP].isPressed()) {
				activeNode.previousChild();
			} else if (gameActions[GameMode.DOWN].isPressed()) {
				activeNode.nextChild();
			} else if (gameActions[GameMode.CROSS].isPressed()) {
				Node n = activeNode.getCurrentChild();
				if (n.getName().contains("keyboard")) {
					inputManager.disconnectGamePad();
				} else {
					inputManager.reset();
				}
				for (int i = GameMode.UP; i <= GameMode.LEFT; i++) {
					gameActions[i].changeBehaviorBack();
				}
				firstTimeIn = true;
			}
			activeNode.drawAllChildren(g);
		} else if (paused) {
			g.fadeOldSchool(.5f);
			g.drawStringCentered("Paused", 250);
		}
	}
	int x = 78;
	int y = 59;

	
	/**
	 * Checks if the game is paused.
	 * 
	 * @return true if the game is paused.
	 */
	public static boolean isPaused() {
		return paused;
	}
	
	public static void exitGame() {
		screen.exitScreen();
		inputManager.exit();
		logger.info("Exiting game");
		System.exit(0);
	}
	
	public static void setFullScreen() {
		screen.swapFullScreen();
	}

	/**
	 * Updates the state of the game/animation based on the
	 * amount of elapsed time that has passed.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since the
	 * last update.
	 */
	protected abstract void update(float dt);
	protected abstract void draw(float dt, Graphics g);
	protected abstract boolean isPausable();

}
