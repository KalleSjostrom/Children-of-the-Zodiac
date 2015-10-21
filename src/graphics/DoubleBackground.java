package graphics;

import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import organizer.ResourceLoader;
import bodies.system.ParticleSystem;

/**
 * This class manages the backgrounds a village or the landscape.
 * 
 * @author     Kalle Sjöström
 * @version    0.7.0 - 13 May 2008
 */
public class DoubleBackground {

	public static final int BOTTOM_LAYER = -1;
	public static final int VILLAGER_LAYER = 0;
	public static final int UPPER_LAYER = 1;
	public static final int WEATHER_LAYER = 2;
	
	private static final int POS = 0;
	private static final int TARGET = 1;
	private static final int VELOCITY = 2;
	private static final int ACC = 3;
	private double velocityTarget;

	protected float[] pos = new float[2];
	private double[][] target;
	private boolean[] accelerating = new boolean[2];
	
	private boolean moving;
	private String nightTop = null;
	
	private HashMap<Integer, ArrayList<ParticleSystem>> systems = new HashMap<Integer, ArrayList<ParticleSystem>>();
	private int height;
	private int width;
	
	static {
		ImageHandler.addPermanentlyLoadOnUse(Values.VillageImages + "top/greentree.png");
	}
	
	public DoubleBackground(int bw, int bh) {
		this(bw, bh, bw, bh);
	}
	
	public DoubleBackground(int backgroundWidth, int backgroundHeight, int actualWidth, int actualHeight) {
		width = backgroundWidth;
		height = backgroundHeight;
		target = new double[2][5];
	}

	public void init(String name, boolean nightLayer) {
		load(name, name, nightLayer);
	}
	public void init(String path, String name, boolean nightLayer) {
		load(path, name, nightLayer);
	}
	public void setLandscapeImages(String name, boolean night) {
		load(Values.LandscapeImages, "", name, night);
	}
	
	private String background;
	private String foreground;
	
	private void load(String path, String name, boolean nightLayer) {
		load(Values.VillageImages, path, name, nightLayer);
	}
	private void load(String folder, String path, String name, boolean nightLayer) {
		String fullPath = folder + path + (path.equals("") ? "" : "/");
		ResourceLoader rl = ResourceLoader.getResourceLoader();
		if (nightLayer) {
			background = fullPath + name + " at Night.jpg";
			foreground = fullPath + name + " at Night.png";

			String nightTopName = fullPath + name + " at Night - 1.png";
			if (rl.exists(nightTopName)) {
				nightTop = nightTopName;
			} else {
				nightTop = folder + "standardOvernight.png";
			}
			ImageHandler.addToCurrentLoadNow(nightTop);
		} else {
			background = fullPath + name + ".jpg";
			foreground = fullPath + name + ".png";
		}
	}
	
	/**
	 * Sets either the x or y position depending on the first argument.
	 *  
	 * @param XorY 1 if the x position or 0 if the y value should change.
	 * @param newPos the new position of the background.
	 */
	public void setPos(int XorY, int newPos) {
		moving = pos[XorY] != newPos;
		pos[XorY] = newPos;
		updatePos(XorY);
	}

	/**
	 * Moves this background in either the x or y position depending
	 * on the given parameter.
	 * 
	 * @param XorY Values.X if the background are to be moved in x direction.
	 * @param amount the amount of length units to move.
	 */
	public void move(int XorY, int amount) {
		moving = true;
		pos[XorY] += amount;
		updatePos(XorY);
	}

	private void updatePos(int XorY) {
		target[XorY][TARGET] = target[XorY][POS] = pos[XorY];
	}
	
	/**
	 * Gets the position of this Background.
	 * 
	 * @return pos the position of the background.
	 */
	public float[] getPos() {
		return pos;
	}

	/**
	 * Draws the bottom layer of the background on the given graphics.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawBottom(graphics.Graphics g) {
		drawSystem(g, systems.get(BOTTOM_LAYER));
		g.drawImage(background, pos[Values.X], pos[Values.Y]);
	}
	
	/**
	 * This method draws the top layer in the village. It draws every static
	 * object in the village that should be drawn on top of the player. These
	 * include roofs and treetops but also the dark night layer, 
	 * with window lights.
	 * 
	 * @param g the graphics to draw on.
	 * @param removeAlpha true the alpha value less than 90 % should 
	 * be removed.
	 */
	public void drawTop(graphics.Graphics g) {
		g.drawImage(foreground, pos[Values.X], pos[Values.Y]);
		if (nightTop != null) {
			if (nightTop.contains("standard")) {
				g.drawImage(nightTop, 0, 0, 2);
			} else {
				g.drawImage(nightTop, pos[Values.X], pos[Values.Y], 2);
			}
		}
		drawSystem(g, systems.get(UPPER_LAYER));
		drawSystem(g, systems.get(WEATHER_LAYER));
	}
	
	private void drawSystem(graphics.Graphics g, ArrayList<ParticleSystem> systems) {
		if (systems != null) {
			for (ParticleSystem p : systems) {
				p.draw(g, (int) pos[Values.X], (int) pos[Values.Y]);
			}
		}
	}
	
	private void updateSystem(float elapsedTime, ArrayList<ParticleSystem> systems) {
		if (systems != null) {
			for (ParticleSystem p : systems) {
				p.update(elapsedTime);
			}
		}
	}

	public void update(float dt) {
		for (int i = 0; i < 2; i++) {
			double p = target[i][POS];
			double t = target[i][TARGET];
			double v = target[i][VELOCITY];
			double a = target[i][ACC];

			if (accelerating[i] && Math.abs(v) >= Math.abs(velocityTarget)) {
				target[i][ACC] = 0;
				accelerating[i] = false;
			}
			if (p != t) {
				if (Math.abs(p - t) <= Math.abs((p + v + a) - t)) {
					target[i][POS] = t;
					target[i][ACC] = 0;
				} else {
					target[i][VELOCITY] += target[i][ACC] * dt;
					target[i][POS] += target[i][VELOCITY] * dt;
				}
				pos[i] = (int) Math.round(target[i][POS]);
			}
		}
		updateSystem(dt, systems.get(UPPER_LAYER));
		updateSystem(dt, systems.get(WEATHER_LAYER));
	}

	public void moveTo(int x, int y, int time) {
		double distX = x - pos[Values.X];
		double distY = y - pos[Values.Y];
		target[Values.X][TARGET] = x;
		target[Values.Y][TARGET] = y;
		target[Values.X][VELOCITY] = distX / time;
		target[Values.Y][VELOCITY] = distY / time;
	}
	
	public void move(int distance, int direction, float duration) {
		int index = direction % 2;
		target[index][TARGET] = pos[index] + (distance * Values.DIRECTIONS[direction]);
		index = Math.abs(index - 1);
		target[index][TARGET] = pos[index];
		for (int i = 0; i < pos.length; i++) {
			target[i][VELOCITY] = Math.abs(target[i][TARGET] - pos[i]) / duration;
			target[i][VELOCITY] *= Values.DIRECTIONS[direction];
		}
	}
	
	/**
	 * v^2 - v0^2 = 2as
	 * a = (v^2 - v0^2) / (2 * s)
	 * since v = 0 (we should stop the screen)
	 * a = -v0^2 / (2 * s)
	 * v0 is the current step size
	 */
	public void stopScreen() {
		for (int i = 0; i < 2; i++) {
			double p = target[i][POS];
			double t = target[i][TARGET];
			if (p != t) {
				double s = Math.abs(p - t);
				target[i][ACC] = (target[i][VELOCITY] * target[i][VELOCITY]) / (2*s);
				target[i][ACC] *= target[i][VELOCITY] < 0 ? 1 : -1;
			}
		}
	}
	
	public void moveScreen(double a, int s, double t, int direction) {
		for (int i = 0; i < 2; i++) {
			target[i][ACC] = 0;
			target[i][VELOCITY] = 0;
			target[i][TARGET] = 0;
		}
		
		double first = a*t;
		double second = a*a*t*t-2*a*s;
		double sqrt = Math.sqrt(second);
		velocityTarget = first - sqrt; // Choose this root instead of first + sqrt. (Why?)
		int index = direction % 2;
		accelerating[index] = true;
		target[index][TARGET] = pos[index] + (s * Values.DIRECTIONS[direction]);
		target[index][ACC] = target[index][TARGET] < pos[index] ? -a : a;
		index = Math.abs(index - 1);
		target[index][TARGET] = pos[index];
	}


	/**
	 * This method stops the movement of the background.
	 */
	public void stop() {
		moving = false;
	}

	/**
	 * This method checks if the background is moving.
	 * 
	 * @return true if the background is moving.
	 */
	public boolean isMoving() {
		return moving;
	}

	/**
	 * This method will cause the background to be centered around the given
	 * positions.
	 * 
	 * @param playerPos the position to center the background around.
	 */
	public void centerAround(float[] playerPos) {
		if (playerPos != null) {
			int hx = Values.ORIGINAL_RESOLUTION[Values.X] / 2;
			int hy = Values.ORIGINAL_RESOLUTION[Values.Y] / 2;
			double y = Math.max(playerPos[Values.Y], hy);
			double x = Math.max(playerPos[Values.X], hx);
			y = Math.min(y, getHeight() - hy);
			x = Math.min(x, getWidth() - hx);
			pos[Values.X] = (int) -Math.round(x - hx);
			pos[Values.Y] = (int) -Math.round(y - hy);
		}
	}
	
	public boolean checkUpRight(int axis) {
		boolean ret;
		if (axis == Values.X) {
			ret = pos[axis] <= -(getWidth() - Values.ORIGINAL_RESOLUTION[Values.X]);
		} else {
			ret = pos[axis] <= -(getHeight() - Values.ORIGINAL_RESOLUTION[Values.Y]);
		}
		return ret;
	}
	
	public boolean checkDownLeft(int axis) {
		return pos[axis] >= 0;
	}
	
	public int getHeight() {
		return height;
	}
	
	public int getWidth() {
		return width;
	}
	
	public void addSystem(ParticleSystem p, int layer) {
		ArrayList<ParticleSystem> sys = systems.get(layer);
		if (sys == null) {
			sys = new ArrayList<ParticleSystem>();
			systems.put(layer, sys);
		}
		sys.add(p);
	}

	public void setOffset(int x, int y) {
		//offsetx = x;
		//offsety = y;
	}

	public ParticleSystem getParticleSystem(String name) {
		Iterator<ArrayList<ParticleSystem>> it = systems.values().iterator();
		while (it.hasNext()) {
			ArrayList<ParticleSystem> ps = it.next();
			for (ParticleSystem p : ps) {
				if (p.name.equals(name)) {
					return p;
				}
			}
		}
		return null;
	}
}
