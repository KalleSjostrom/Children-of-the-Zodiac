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

import java.awt.Color;

import com.jogamp.opengl.GLAutoDrawable;

import java.util.logging.*;

import menu.Node;

/**
 * This class is the game core. It initializes the screen and the 
 * input managers and start the game loop.
 * 
 * @author 		Kalle Sj�str�m.
 * @version 	0.7.0 - 11 May 2008
 */
public abstract class GameCore {

	public static Screen screen;
	public static InputManagers inputManager = new InputManagers();
	public static GameActions[] gameActions;
	
	private static boolean paused;
	private static String[] strings;
	private static String[] values;
	private static long zeroTime;
	private static Logger logger = Logger.getLogger("GameCore");
	
	private Node activeNode;
		
	/**
	 * Uses the screen manager to set the window in full screen mode.
	 * It also connects the input manager to the window and removes the cursor.
	 */
	protected void init() {
		screen = Screen.getScreen();
		activeNode = new Node(null, "");
		activeNode.setEnableColor(Color.WHITE);
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
		zeroTime = System.currentTimeMillis();
	}

	boolean firstTimeIn = true;
	
	public void update() {
		long elapsedTime = System.currentTimeMillis() - zeroTime;
		zeroTime = System.currentTimeMillis();
		update(elapsedTime);
	}
	
	public void testDraw(Graphics g, GLAutoDrawable drawable) {
		preDraw(g);
		draw(g);
		g.checkError();

		if (inputManager.connectionLost()) {
			if (firstTimeIn) {
				for (int i = GameMode.UP; i <= GameMode.LEFT; i++) {
					gameActions[i].changeBehavior(GameAction.DETECT_INITAL_PRESS_ONLY);
				}
			}
			firstTimeIn = false;
			g.fadeOldSchool(.5f);
			g.drawSingleCenteredText("Connection to game pad lost", 250, 1, 1, 50, Values.ORIGINAL_RESOLUTION[Values.X] / 2);
			g.drawSingleCenteredText("Please reconnect the game pad in a USB port", 320, 1, 1, 30, Values.ORIGINAL_RESOLUTION[Values.X] / 2);
			g.drawSingleCenteredText("(You can connect to the gamepad from the menu (Settings) later)", 350, 1, 1, 20, Values.ORIGINAL_RESOLUTION[Values.X] / 2);
			
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
			int fs = g.getFontSize();
			g.drawSingleCenteredText("Paused", 250, 1, 1, 50, Values.ORIGINAL_RESOLUTION[Values.X] / 2);
			g.setFontSize(fs);
		}
	}
	
	int counter = 0;
	int counter2 = 0;
	int counter3 = 0;

	private void preDraw(Graphics g) {
		if (isPausable() && inputManager.hasStartBeenPressed()) {
			paused = !paused;
		}
		if (paused) {
//			g.drawImage(pauseScreen, 0, 0, 2);
//			g.drawCenteredText("Paused", 500, 50, 1, 1);
		}
	}
	
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
		logger .info("Exiting game");
		System.exit(0);
	}
	
	public static void setFullScreen() {
		screen.swapFullScreen();
	}
	/*
	public static void setsFPS(int fps) {
		if (fps != Values.FPS) {
			screen.setFPS(fps);
		}
	}*/

	/**
	 * Updates the state of the game/animation based on the
	 * amount of elapsed time that has passed.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since the
	 * last update.
	 */
	protected abstract void update(float elapsedTime);

	/**
	 * Draws to the screen.
	 * 
	 * @param g the Graphics3D object on which to draw.
	 */
	protected abstract void draw(Graphics g);
	
	protected abstract boolean isPausable();

}
