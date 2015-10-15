package menu;

import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.LabyrinthInfo;
import info.LabyrinthMap;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;

import labyrinth.Labyrinth;
import labyrinth.Node;

import organizer.GameMode;
import organizer.Organizer;

import sound.SoundPlayer;

public class MapPage extends AbstractPage {

	private LabyrinthMap map;
	private Labyrinth lab;
	private ArrayList<LabyrinthMap> currentFloors;
	private Node currentNode = null;

	public static String mappiece = ImageHandler.addPermanentlyLoadNow(
			Values.MenuImages + "mappiece.png");
	public static String mappiece2 = ImageHandler.addPermanentlyLoadNow(
			Values.MenuImages + "mappiece2.png");
	public static String mappiece3[] = new String[4];
	static {
		for (int i = 0; i < 4; i++) {
			mappiece3[i] = ImageHandler.addPermanentlyLoadNow(
					Values.MenuImages + "mappiece3" + i + ".png");
		}
	}

	private String floor = null;

	protected MapPage() {
		super();
		String name = null;
		GameMode gameMode = Organizer.getOrganizer().getPreviousMode();
		activeNode = getRootNode();
		if (gameMode instanceof Labyrinth) {
			lab = (Labyrinth) gameMode;
			name = lab.getSimpleName();
			floor = lab.getFloorName();
			currentNode = lab.getCurrentNode();
			boolean found = false;
			for (int i = 0; i < activeNode.getSize() && !found; i++) {
				String n = activeNode.getChild(i).getName();
				found = n.equalsIgnoreCase(name);
				if (!found) {
					downPressed(false);
				}
			}
//			activeNode.setCurrentChild(name);
			crossPressed(false);
			if (floor != null) {
				activeNode.setCurrentChild(floor);
				update();
			}
		} else {
			String[] lab = Database.getLastVisitedLabyrinth();
			name = lab[0];
			floor = lab[1];
			activeNode.setCurrentChild(name);
			crossPressed(false);
			if (floor != null) {
				activeNode.setCurrentChild(floor);
				update();
			}
		}
		setPage(BESTIARY_PAGE);
	}

	private menu.Node getRootNode() {
		menu.Node n = new menu.Node(null, "Map");
		if (!n.hasChildren()) {
			ArrayList<String> list = Database.getVisitedLabyrinthsList();
			for (int i = 0; i < list.size(); i++) {
				n.insertChild(list.get(i));
			}
			n.setStandardWithBB();
		}
		return n;
	}
	
	public void crossPressed() {
		crossPressed(true);
	}

	public void crossPressed(boolean playSound) {
		String name = activeNode.getCurrentChild().getName();
		LabyrinthInfo li = Database.getMap(name);
		if (li != null) {
			map = li.getFirstFloor();
			if (playSound) {
				SoundPlayer.playSound(SoundMap.ACCEPT);
			}
			setCurrent(li, name);
		}
	}

	private void setCurrent(LabyrinthInfo li, String name) {
		menu.Node n = new menu.Node(activeNode, name);
		if (!n.hasChildren()) {
			currentFloors = li.getFloors();
			for (int i = 0; i < currentFloors.size(); i++) {
				n.insertChild(currentFloors.get(i).getName());
			}
			n.setDistance(MenuValues.DISTANCE);
			n.setPositions(
					MenuValues.MENU_TEXT_X, 
					MenuValues.MENU_TEXT_Y);
			n.setCurrentChild(floor);
			boolean found = false;
			for (int i = 0; i < currentFloors.size() && !found; i++) {
				found = floor.equals(currentFloors.get(i).getName());
				if (found) {
					map = currentFloors.get(i);
				}
			}
		}
		activeNode = n;
	}

	/**
	 * This method moves the menu hand one step upwards in the currently 
	 * active menu. To do this, it simply calls the previousChild() method
	 * in the Node class. This method is called when the player presses up.
	 */
	public void upPressed() {
		activeNode.previousChild();
		if (isZoomedOut()) {
			update();
			crossPressed(false);
			circlePressed();
		} else {
			update();
		}
	}

	private void update() {
		String name = activeNode.getCurrentChild().getName();
		LabyrinthInfo li = Database.getMap(name);
		if (li != null) {
			map = li.getFirstFloor();
		} else {
			map = currentFloors.get(activeNode.getMenuCursor());
		}
	}
	
	public void downPressed() {
		downPressed(true);
	}

	/**
	 * This method moves the menu hand one step downwards in the currently
	 * active menu. To do this, it simply calls the nextChild() method
	 * in the Node class. This method is called when the player presses down.
	 */
	public void downPressed(boolean playSound) {
		activeNode.nextChild(playSound);
		if (isZoomedOut()) {
			update();
			crossPressed(false);
			circlePressed();
		} else {
			update();
		}
	}

	public void R1Pressed() {
		// Change floor in the map
	}

	public void L1Pressed() {
		// Change floor in the map
	}

	public void circlePressed() {
		menu.Node n = activeNode.getParent(); 
		if (n != null) {
			activeNode = menu.Node.switchNode(activeNode, n);
			activeNode.updateHandPos();
			// parentNode = activeNode;
		} else {
			MainMenu.getMainMenu().initStartPage(5);
		}
	}

	protected void draw3D(Graphics g) {
		super.drawStandard(g);
		g.drawString(activeNode.getName(), MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y);
		activeNode.drawAllChildren(g);
		int percent = 0;
		if (isZoomedOut()) {
			percent = drawAll(g);
			drawHelp(g, true);
		} else {
			percent = drawSingle(g);
			drawHelp(g, false);
		}
		g.drawString("Explored: " + percent + " %", 40, 50);
		StartPage.drawScreenShot(g);
		StartPage.drawInfo(g);
	}

	private boolean isZoomedOut() {
		return activeNode.getName().equals("Map"); // Fulhack...
	}

	private int drawSingle(Graphics g) {
		int currentDir = -1;
		if (lab != null) {
			currentDir = lab.getPlayerDirection();
		}
		return map.draw(g, currentNode, currentDir, null, false, true);	
	}

	private int drawAll(Graphics g) {
		g.push();
		g.translate(25, 80, 0);
		g.scale(1f / 3);
		int percent = 0;
		int size = 0;
		for (int i = 0; i < currentFloors.size(); i++) {
			LabyrinthMap m = currentFloors.get(i);
			size = m.getSize();
			int[] pos = m.getMapPos();
			int currentDir = -1;
			if (lab != null) {
				currentDir = lab.getPlayerDirection();
			}
			g.push();
			g.translate(pos[0] * 700, pos[1] * 1000, 0);
			percent += m.draw(g, currentNode, currentDir, pos, true, false);
			g.pop();
		}
		g.scale(3);
		g.pop();
		percent = Math.round((percent / (float) size) * 100);
		return percent;
	}

	private void drawHelp(Graphics g, boolean drawAll) {
		int helpx = 90;
		int step = 125;
		int helpy = 720;
		int helpxicons = helpx - 28;
		int helpyicons = helpy - 23;

		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], helpxicons, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], helpxicons + step, helpyicons);
		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], helpxicons + 2 * step, helpyicons);

		g.drawString("Exit", helpx, helpy);
		g.drawString("Select", helpx + step, helpy);
		g.drawString(drawAll ? "To main menu" : "Zoom out", helpx + 2 * step, helpy);
//
//		helpx += 3 * step + 100;
//		helpxicons += 3 * step + 90;
//		step += 70;
//
//		g.drawString("Change lab", helpx, helpy);
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], helpxicons, helpyicons);
	}
}
