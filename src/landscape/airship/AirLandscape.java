/*
 * Classname: AirLandscape.java
 * 
 * Version information: 0.7.0
 *
 * Date: 14/05/2008
 */
package landscape.airship;

import graphics.Graphics;
import info.Database;
import info.Values;

import java.util.HashMap;

/**
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 14 May 2088
 */
public class AirLandscape extends AirLandscapeLoader {

	private AirLandNode currentNode;
	private String currentPlace;

	public void init(HashMap<String, String> info) {
		super.init(info);
		String nodeName = info.get("startNode");
		setCurrentNode(getNode(nodeName.replace("_", " ").replace("night", "")));
		airShip.setXandY(currentNode.getXpos(), currentNode.getYpos());
		if (currentNode.isCross()) {
			currentNode = null;
		}
		airShip.standStill(Values.DOWN);
		inputManager.resetAllGameActions();
		
		logicLoading = false;
	}

	public void resume() {
		resume(Values.DETECT_INIT);
	}

	public void update(float elapsedTime) {
		airShip.update(elapsedTime);
		checkNodes();
		checkGameInput();
		super.update(elapsedTime);
	}
	
	private void checkNodes() {
		float[] pos = airShip.getPos();
		if (currentNode == null || !checkNode(currentNode, pos)) {
			boolean found = false;
			for (int i = 0; i < nodes.size() && !found; i++) {
				AirLandNode n = nodes.get(i);
				if (!n.isCross() && (found = checkNode(n, pos))) {
					setCurrentNode(n);
				}
			}
			if (!found) {
				currentNode = null;
			}
		}
	}

	private void setCurrentNode(AirLandNode n) {
		currentNode = n;
		currentPlace = currentNode.getName();
		if (currentPlace.contains("-mark")) {
			currentPlace = currentPlace.split("-mark")[0];
		}
	}

	private boolean checkNode(AirLandNode n, float[] pos) {
		float x = Math.abs(pos[Values.X] - n.getXpos());
		float y = Math.abs(pos[Values.Y] - n.getYpos());
		float sqrdist = x * x + y * y;
		return sqrdist < 400;
	}

	private void checkGameInput() {
		if (airShip.isMoving()) {
			boolean shouldStop = true;
			for (int i = UP; i <= LEFT; i++) {
				if (!gameActions[i].isReleased()) {
					shouldStop = false;
				}
			}
			if (shouldStop) {
				airShip.standStill();
			}
		} else {
			airShip.standStill();
		}
		checkDirectionalButtons();
		if (gameActions[CROSS].isPressed()) {
			crossPressed();
		} else if (isMenuButtonPressed(gameActions)) {
			super.queueEnterMenu();
		}
	}
	
	private void checkDirectionalButtons() {
		for (int i = UP; i <= LEFT; i++) {
			if (gameActions[i].isPressed()) {
				airShip.go(i - UP);
			}
		}
	}

	private void crossPressed() {
		if (currentNode != null) {
			Graphics.setFadeImage(Graphics.FADE_TO_BLACK);
			Database.addStatus("Landscape", currentNode.getZone());
			nextPlace = currentNode.getName().replace(" ", "_").toLowerCase();
			mode = Values.EXIT;
			exit(mode);
		}
	}
	
	public void draw(Graphics g) {
		g.setColor(1);
		g.setFontSize(30);
		background.drawBottom(g);
		airShip.draw(g);
		background.drawTop(g, false, null);
		g.drawCenteredImage(nameBackGround, 10);
		if (currentNode != null) {
			String name = currentPlace;
			if (name.contains("-")) {
				name = name.split("-")[0];
			}
			if (name.startsWith("land")) {
				name = name.replace("land", "");
			}
			g.drawStringCentered(name, 60);
		}
		super.checkMenu();
		super.draw(g);
	}
}