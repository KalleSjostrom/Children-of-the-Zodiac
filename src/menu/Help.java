package menu;

import graphics.Graphics;

public class Help {

	private int[] settings;
	private int x;
	private int y;
	private int step;
	private int iconx;
	private int icony;
	private String[] text;

	public void setSettings(int[] settings) {
		this.settings = settings;
		x = settings[0];
		y = settings[1];
		step = settings[2];
		iconx = x - settings[3];
		icony = y - settings[4];
	}
	
	public void setText(String[] text) {
		this.text = text;
	}

	public void draw(Graphics g) {
//		for (int i = 0; i < text.length; i++) {
//			g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.TRIANGLE], iconx + i * step, icony);
//		}
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CROSS], iconx + step, icony);
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.SQUARE], iconx + 2 * step, icony);
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.CIRCLE], iconx + 3 * step, icony);
//		
//		for (int i = 0; i < text.length; i++) {
//			g.drawString(text[i], x + i * step, y);
//		}
//		
//		x += 4 * step + 50;
//		iconx += 4 * step + 40;
//		step += 70;
//		
//		g.drawString("Change deck", x, y);
//		g.drawString("Change character", x + step, y);
//		
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L2R2], iconx, icony);
//		g.drawCenteredImage(AbstractPage.BUTTON_ICONS[GameMode.L1R1], iconx + step, icony);
	}

}
