/*
 * Classname: BestiaryPage.java
 * 
 * Version information: 0.7.0
 *
 * Date: 17/02/2008
 */
package menu;

import graphics.Graphics;
import info.Values;
import character.Bestiary;
import character.Enemy;
import character.Bestiary.Stats;

/**
 * This menu page displays the enemies in the game. Here, the player
 * can look at the images of the enemies and see their stats, if the
 * player has encountered an enemy enough times. 
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 17 Feb 2008
 */
public class BestiaryPage extends AbstractPage {

	private String[] stats;
	private Thread anim;
	private Enemy enemy;
	private int enemyIndex;
	private int enemyImage = 0;
	private int nrOfEnemies;
	private boolean animate = false;
	private boolean animateButtonJustPressed = false;
	private boolean showEnemy = false;

	/**
	 * This method initiates the bestiary page which will contain
	 * information about the given enemyIndex:th enemy in the bestiary.
	 * 
	 * @param enemyIndex the index of the enemy to display.
	 * @param currentChild the index of the hand in the menu.
	 */
	protected BestiaryPage(int enemyIndex, int currentChild) {
		super();
		activeNode = getRootNode();
		activeNode.setMenuCursor(currentChild);
		changeEnemy(enemyIndex);
		nrOfEnemies = Bestiary.getBestiary().getSize();
		this.enemyIndex = enemyIndex;
		setPage(BESTIARY_PAGE);
	}

	/**
	 * This method creates the root node and returns it.
	 * This nodes children is the menu displayed on the bestiary page.
	 * 
	 * @return the root node of the bestiary page.
	 */
	private Node getRootNode() {
		Node n = new Node(null, "Bestiary");
		if (!n.hasChildren()) {
			n.insertChild("Next");
			n.insertChild("Previous");
			n.insertChild("Animate");
			n.insertChild("Next Image");
			n.setDistance(MenuValues.DISTANCE);
			n.setPositions(
					MenuValues.MENU_TEXT_X, 
					MenuValues.MENU_TEXT_Y);
		}
		return n;
	}

	/**
	 * This enemy changes the information displayed on the page to the 
	 * information about the enemy with the given index. This index is
	 * the one used in the list of enemies in the Bestiary class.
	 * 
	 * @param index the index of the enemy to show information about.
	 */
	public void changeEnemy(int index) {
		enemyIndex = MainMenu.getMainMenu().checkEnemyInRange(index);
		Stats s = Bestiary.getBestiary().getStats(enemyIndex);
		enemy = s.getEnemy();
		stats = s.getInfo();
		showEnemy = s.shouldShowImage();
		enemyImage = 0;
	}
	
	/**
	 * This method draws the bestiary page.
	 * 
	 * @param g3D the graphics to draw on.
	 */
	protected void draw3D(Graphics g3D) {
		super.drawStandard(g3D);
		g3D.drawString((enemyIndex + 1) + " / " + nrOfEnemies, 50, MenuValues.MENU_TITLE_Y);
		g3D.drawString(activeNode.getName(), MenuValues.MENU_TEXT_X, MenuValues.MENU_TITLE_Y);
		activeNode.drawAllChildren(g3D);
		if (showEnemy) {
			g3D.drawImage(enemy.getImage(enemyImage), 0, 120, .9f);
		}
		drawStats(g3D);
		StartPage.drawScreenShot(g3D);
		StartPage.drawInfo(g3D);
	}

	/**
	 * This method draws all the stats about the enemy.
	 * 
	 * @param g the graphics to draw on.
	 */
	private void drawStats(Graphics g) {
		int x = MenuValues.BESTIARY_STATS_X;
		g.drawString("Name: " + stats[Stats.NAME], x, getY(0) - 76);
		g.drawString("Hp: " + stats[Stats.HP], x, getY(0));
		g.drawString("Agility: " + stats[Stats.AGILITY], x, getY(1));
		g.drawString("Attack: " + stats[Stats.ATTACK], x, getY(2));
		g.drawString("Magic: " + stats[Stats.MAGIC], x, getY(3));
		g.drawString("Support: " + stats[Stats.SUPPORT], x, getY(4));
		g.drawString("Defence: " + stats[Stats.DEFENSE], x, getY(5));
		g.drawString("Magic Def.: " + stats[Stats.MAGIC_DEFENSE], x, getY(6));
		g.drawString("Evade: " + stats[Stats.EVADE] + " %", x, getY(7));
		g.drawString("Exp. dropped: " + stats[Stats.EXPERIANCE], x, getY(8));
		g.drawString("Gold dropped: " + stats[Stats.GOLD], x, getY(9));
		g.drawString("Times encountered: " + stats[Stats.BATTLE_COUNTER], x, getY(10));
	}

	/**
	 * Gets the height of the stats with the given index.
	 * 
	 * @param index the index of the stat to get the height for.
	 * @return the height of the stat with the given index. 
	 */
	private int getY(int index) {
		return MenuValues.BESTIARY_STATS_Y + MenuValues.DISTANCE * index;
	}

	/**
	 * This method moves the menu hand one step upwards in the currently 
	 * active menu. To do this, it simply calls the previousChild() method
	 * in the Node class. This method is called when the player presses up.
	 */
	public void upPressed() {
		activeNode.previousChild();
	}

	/**
	 * This method moves the menu hand one step downwards in the currently
	 * active menu. To do this, it simply calls the nextChild() method
	 * in the Node class. This method is called when the player presses down.
	 */
	public void downPressed() {
		activeNode.nextChild();
	}

	/**
	 * This method changes so that the next enemy in the bestiary will
	 * have its status shown on the page. If there is no next enemy 
	 * in the list, the first enemy (index 0) will be used instead.
	 */
	public void R1Pressed() {
		changeEnemy(++enemyIndex);
	}

	/**
	 * This method changes so that the previous enemy in the bestiary will
	 * have its status shown on the page. If there is no previous enemy 
	 * in the party the last enemy will be used instead.
	 */
	public void L1Pressed() {
		changeEnemy(--enemyIndex);
	}

	/**
	 * This method activates the current node in the menu tree. It then 
	 * calls the MainMenu.initXXXPage(), where the X:es is the name
	 * of the page to initiate.
	 */
	public void crossPressed() {
		String mode = activeNode.getCurrentChild().getName();
		if (mode.equals("Next")) {
			changeEnemy(++enemyIndex);
		} else if (mode.equals("Previous")) {
			changeEnemy(--enemyIndex);
		} else if (mode.equals("Animate")) {
			stopAnimating();
			animateButtonJustPressed = true;
			startAnimating();
		} else if (mode.equals("Next Image")) {
			enemyImage = enemy.nextImage(enemyImage);
		}
	}

	/**
	 * This method is called when the player presses a button in the menu
	 * This will interrupt the animation of the current enemy if the current
	 * enemy was being animated.
	 */
	public void buttonPressed() {
		if (animateButtonJustPressed) {
			animateButtonJustPressed = false;
		} else {
			stopAnimating();
		}
	}

	/**
	 * This method is called if the player presses the circle button, and
	 * it will cause the start page to be initiated.
	 */
	public void circlePressed() {
		MainMenu.getMainMenu().initStartPage(4);
	}

	/**
	 * This method starts the animation of the current enemy.
	 */
	private void startAnimating() {
		animate = true;
		anim = new Thread() {
			public void run() {
				while (animate) {
					Values.sleep(1000);
					enemyImage = enemy.nextImage(enemyImage);
				}
			}
		};
		anim.start();
	}
	
	/**
	 * This method stops the animation of the current enemy.
	 */
	private void stopAnimating() {
		animate = false;
		if (anim != null) {
			anim.interrupt();
			try {
				anim.join();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			anim = null;
			enemyImage = 0;
		}
	}
}
