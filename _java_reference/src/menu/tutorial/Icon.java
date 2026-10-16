package menu.tutorial;

import graphics.Graphics;

public class Icon {
	
	private String icon;
	private int xoffset = 0;
	private int yoffset = 0;
	private float scale;
	
	public Icon(String icon) {
		this.icon = icon;
	}

	public Icon(String icon, int x, int y, float scale) {
		this.icon = icon;
		xoffset = x;
		yoffset = y;
		this.scale = scale;
	}
	
	public void draw(Graphics g, int x, int y) {
		g.drawImage(icon, x + xoffset, y + yoffset, scale);
	}
}
