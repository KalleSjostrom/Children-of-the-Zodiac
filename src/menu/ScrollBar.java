package menu;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Values;

public class ScrollBar {
	
	private int x;
	private int y;
	private int height;
	private static final String triangle = 
		 ImageHandler.addPermanentlyLoadNow(
				 Values.MenuImages + "triang.png");
	private static final String ball = 
		ImageHandler.addPermanentlyLoadNow(
				Values.MenuImages + "ball.png");
	private static int IM_HEIGHT;
	private static float SCALE = .4f;

	private static final int BALL_HEIGHT_REL_BAR = 35;
	private int minBallY;
	private int ballRange;
	
	private boolean initiated = false;
	
	public ScrollBar(int x, int y, int height) {
		this.x = x;
		this.y = y;
		this.height = height;
	}

	public void draw(Graphics g, int current, int total) {
		if (!initiated) {
			init();
			initiated = true;
		}
		g.loadIdentity();
		g.drawImage(triangle, x, y, SCALE);
		total--;
		float percent = total == 0 ? 0 : (current / (float) total);
		float ballY = minBallY + percent * ballRange;
		g.drawImage(ball, x + 8, ballY, SCALE);
		g.drawImage(Values.MenuImages + "triangDown.png", x, y + height, SCALE);
	}
	
	private void init() {
		GameTexture gt = ImageHandler.getTexture(triangle);
		IM_HEIGHT = (int) (gt.getHeight() * SCALE);
		y = y - IM_HEIGHT/2 - 5;
		minBallY = y + BALL_HEIGHT_REL_BAR;
		ballRange = height - (2 * (BALL_HEIGHT_REL_BAR)) + IM_HEIGHT / 2;
	}
}
