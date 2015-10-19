package battle;

import graphics.Graphics;
import info.BattleValues;
import menu.AbstractPage;

import organizer.GameMode;

import battle.character.CreatureRow;
import bodies.Vector3f;

public class Legend extends Hideable {

	private static final int STEP = 40;
	private static final int IMAGE_HEIGHT = 220;
	private static final int IMAGE_TEXT_STEP = 24;
	private static final int TEXT_HEIGHT = IMAGE_HEIGHT + IMAGE_TEXT_STEP;
	private static final float IMAGE_X = 210;
	private static final float TEXT_X = 680;
	private static final String[] INFO = 
		new String[]{"Execute", "Choose", "Store", "Discard", "Support", "Offense", "Target"};
	
	private static boolean BATTLE_LEGEND_ACTIVE = true;
	private boolean support;

	/**
	 * Constructs a new hideable clock.
	 * It uses an instance of TimeBar to illustrate the time.
	 */
	public Legend() {
		super(4);
		setLimit(false);
		setMovementSpeed(false);
		instantHide();
	}

	/**
	 * Initiates the drawing of the clock.
	 * 
	 * @param gl the GL object to initiates the drawing on.
	 */
	public void initDraw(Graphics g) {
		setPos(BattleValues.CLOCK_POSITION);
	}
	
	public void setSupport(boolean support) {
		this.support = support;
	}
	
	/**
	 * This method draws the time on the screen.
	 * 
	 * @param g the Graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.loadIdentity();
		g.setFontSize(40);
		
		translate(g);
		
		float xl = -.079f + getXtrans();
		float xr = .26f + getXtrans();
		float ybottom = -.19f;// -.145f;
		float ytop = .4f;
		g.drawGradient(
				Vector3f.ZERO, CreatureRow.BACK_ALPHA_TOP, CreatureRow.BACK_ALPHA_BOTTOM, 
				xr, xl, ybottom, ytop, true, true);
		
		int x = (int) (TEXT_X + super.getXtrans() * 600);
		
		g.drawString(INFO[0], x, TEXT_HEIGHT);
		g.drawString(INFO[1], x, TEXT_HEIGHT + STEP);
		g.drawString(INFO[2], x, TEXT_HEIGHT + 2 * STEP);
		g.drawString(INFO[3], x, TEXT_HEIGHT + 3 * STEP);
		g.drawString(INFO[support ? 5 : 4], x, TEXT_HEIGHT + 4 * STEP);
		g.drawString(INFO[6], x, TEXT_HEIGHT + 5 * STEP);
		g.setColor(1.0f);
		x -= 2;
		int y = TEXT_HEIGHT - 2;
		g.drawString(INFO[0], x, y);
		g.drawString(INFO[1], x, y + STEP);
		g.drawString(INFO[2], x, y + 2 * STEP);
		g.drawString(INFO[3], x, y + 3 * STEP);
		g.drawString(INFO[support ? 5 : 4], x, y + 4 * STEP);
		g.drawString(INFO[6], x, y + 5 * STEP);
	}

	public void drawTopLayer(Graphics g) {
		g.setColor(1);
		int x = (int) (IMAGE_X + super.getXtrans() * 200) + AbstractPage.xoffset;
		g.drawImage(AbstractPage.getExecuteButtonIcon(), x, IMAGE_HEIGHT);
		g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], x, IMAGE_HEIGHT + STEP);
		g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], x, IMAGE_HEIGHT + 2 * STEP);
		g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], x, IMAGE_HEIGHT + 3 * STEP);
		g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.L2R2], x, IMAGE_HEIGHT + 4 * STEP);
		g.drawImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], x, IMAGE_HEIGHT + 5 * STEP);
	}
	
	public static void toggleActive() {
		BATTLE_LEGEND_ACTIVE = !BATTLE_LEGEND_ACTIVE;
	}

	public void toggleLegend() {
		BATTLE_LEGEND_ACTIVE = !BATTLE_LEGEND_ACTIVE;
		if (BATTLE_LEGEND_ACTIVE && !visible) {
			show();
		} else if (!BATTLE_LEGEND_ACTIVE && visible) {
			hide();
		}
	}
}
