package story;

import java.util.ArrayList;

import graphics.Graphics;

public class ScrollableTexts {
	private ArrayList<ScrollableText> texts;
	private float y = 800;
	private float speed = 1;

	public ScrollableTexts() {
		texts = new ArrayList<ScrollableText>();
	}
	
	public void add(ScrollableText st) {
		texts.add(st);
	}
	
	public void update(int elapsedTime) {
		y -= speed;
	}

	public void draw(Graphics g) {
		g.setColor(1);
		float yVal = y;
		for (int i = 0; i < texts.size(); i++) {
			ScrollableText st = texts.get(i);
			if (yVal > -50) {
				st.draw(g, yVal);
			} else if (yVal > 800) {
				break;
			}
			yVal += st.distance;
		}
	}
	
	public void setSpeed(float speed) {
		this.speed = speed;
	}
	
	public static class ScrollableText {
		
		private String text;
		private int x;
		private float distance = 40;
		private int fontsize = 30;
		private boolean isBold = false;
		
		public void setText(String text) {
			this.text = text;
		}
		public void setX(int x) {
			this.x = x;
		}
		public void setDistance(float distance) {
			this.distance = distance;
		}
		public void setFontSize(int fontsize) {
			this.fontsize = fontsize;
		}
		public void setIsBold(boolean bold) {
			isBold = bold;
		}
		public void draw(Graphics g, float y) {
			g.setFontSize(fontsize, isBold);
			g.drawString(text, x, Math.round(y));
		}
	}
}
