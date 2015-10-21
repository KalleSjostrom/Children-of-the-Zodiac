package sprite;

import info.Values;
import graphics.Graphics;

public class DefaultSprite extends Sprite {
	
	private static final int BOTTOM_LAYER = 0;
	private static final int VILLAGER_LAYER = -1;
	private static final int TOP_LAYER = 1;
	private int layer = VILLAGER_LAYER;
	private int offset; 
	private static int OFFSET_COUNTER = 0;

	public DefaultSprite(String path) {
		name = path;
	}

	public void draw(float dt, Graphics g, int x, int y) {
		super.draw(dt, g, (int) pos[Values.X] + x, (int) pos[Values.Y] + y);
	}
	
	public void placeOnTopLevel() {
		layer = TOP_LAYER;
	}
	public void placeOnBottomLevel() {
		layer = BOTTOM_LAYER;
		offset = OFFSET_COUNTER;
		OFFSET_COUNTER++;
	}
	
	public float getY() {
		float y = 0;
		switch (layer) {
		case BOTTOM_LAYER:
			y = -10000 + offset;
			break;
		case VILLAGER_LAYER:
			y = pos[Values.Y];
			break;
		case TOP_LAYER:
			y = 10000 - offset;
			break;
		}
		return y;
	}

	public static void reset() {
		OFFSET_COUNTER = 0;
	}
}
