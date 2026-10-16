package miniGames;

import graphics.Graphics;

public class Tile {

	private int correctX;
	private int correctY;
	private int currentY;
	private int currentX;
	
	private String image;

	public Tile(int x, int y, String image) {
		correctX = x;
		correctY = y;
		currentX = x;
		currentY = y;
		this.image = image;
	}

	public void draw(Graphics g, int[] xs, int[] ys) {
		g.drawImage(image, xs[currentX], ys[currentY]);
	}

	public void setImage(String im) {
		image = im;
	}
	
	public String getImage() {
		return image;
	}

	public void setCurrent(int bx, int by) {
		currentX = bx;
		currentY = by;
	}

	public boolean isCorrect() {
		return currentX == correctX && currentY == correctY;
	}
}
