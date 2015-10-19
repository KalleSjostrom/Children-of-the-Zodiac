package graphics;

import info.Values;

import java.awt.Graphics;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import javax.imageio.ImageIO;

import java.util.logging.*;

import organizer.ResourceLoader;

import sprite.Sprite;
import villages.utils.PartyMember;
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
	private static final int STEP = 2;
	private static final int ACC = 3;
	private double velocityTarget;

	protected float[] pos = new float[2];
	private double[][] target;
	private boolean[] accelerating = new boolean[2];
	
	private boolean moving;
	
	private String nightTop = null;
	
	private int imageWidth;
	private int imageHeight;
	
	private int HORIZONTAL_IMAGES;
	private int VERTICAL_IMAGES;
	
	private String[][] bg;
	private String extraBackground;
	private HashMap<int[], String> top = new HashMap<int[], String>();
	private HashMap<int[], String> bottom = new HashMap<int[], String>();
	
	private HashMap<Integer, ArrayList<ParticleSystem>> systems = new HashMap<Integer, ArrayList<ParticleSystem>>();
	private int height;
	private int width;
	private int offsetx;
	private int offsety;
	private int actualHeight;
	private int actualWidth;
	private Logger logger = Logger.getLogger("DoubleBackground");
	
	public static final boolean USE_CUT = true;
	
	static {
		ImageHandler.addPermanentlyLoadOnUse(
				Values.VillageImages + "top/greentree.png");
	}
	
	public DoubleBackground(int bw, int bh) {
		this(bw, bh, bw, bh);
	}
	
	public DoubleBackground(int backgroundWidth, int backgroundHeight,
			int actualWidth, int actualHeight) {
		width = backgroundWidth;
		height = backgroundHeight;
		this.actualHeight = actualHeight;
		this.actualWidth = actualWidth;
		target = new double[2][5];
	}

	/**
	 * Initiates the double background by loading the image with the given name
	 * and setting it as the background image.
	 * 
	 * @param name the name of the image to load.
	 * @param extra 
	 */
	public void init(String name, boolean nightLayer) {
		loadImages(name, name, nightLayer);
	}
	
	public void init(String path, String name, boolean nightLayer) {
		loadImages(path, name, nightLayer);
	}
		
	public void setLandscapeImages(String[] names, boolean night) {
		if (USE_CUT) {
			String n = doit(Values.LandscapeImages, "", names[0], night);
			bg = cutImage(n, 0, BufferedImage.TYPE_INT_RGB);
			doTopLayer(Values.LandscapeImages, names[1]);
		} else {
			bottom.put(new int[2], doit(Values.LandscapeImages, "", names[0], night));
			doTopLayer(Values.LandscapeImages, names[1]);
		}
	}
	
	private void loadImages(String path, String name, boolean nightLayer) {
		String n = doit(path, name, nightLayer);
		bg = cutImage(n, 0, n.endsWith(".jpg") ? BufferedImage.TYPE_INT_RGB : BufferedImage.TYPE_INT_ARGB);
		doTopLayer(Values.VillageImages, path);
	}
	
	private String doit(String folder, String path, String name, boolean nightLayer) {
		String name2;
		String name1 = name2 = folder + path + (path.equals("") ? "" : "/");
		ResourceLoader rl = ResourceLoader.getResourceLoader();
		if (nightLayer) {
			String jpgFileName = name1 + name + " at Night.jpg";
			if (rl.exists(jpgFileName) || 
					rl.exists(name1 + name + " at Nightfolder")) {
				name1 = jpgFileName;
			} else {
				name1 += name + ".jpg";
			}
			String topFileName = name2 + name + " at Night - 1.png";
			if (rl.exists(topFileName)) {
				nightTop = topFileName;
			} else {
				nightTop = folder + "standardOvernight.png";
			}
			ImageHandler.addToCurrentLoadNow(nightTop);
		} else {
			String temp = name1 + name + ".png";
			if (rl.exists(temp) || 
					(rl.exists(name1 + name + "folder") && rl.exists(name1 + name + "folder/x0y0.png"))) {
				name1 = temp;
			} else {
				temp = name1 + name + ".jpg";
				name1 = temp;
			}
		}
//		ImageHandler.addToCurrentLoadNow(name1);
		return name1;
	}
	
	private String doit(String path, String name, boolean nightLayer) {
		return doit(Values.VillageImages, path, name, nightLayer);
	}
	
	private void doTopLayer(String path, String name) {
		try {
			BufferedReader reader = 
				ResourceLoader.getResourceLoader().getBufferedReader(
						path + name, "/top/top.info");
			String line = "";
			while (line != null) {
				line = reader.readLine();
				if (line != null) {
					String[] args = line.split(":");
					String n = args[0];
					int[] pos = new int[2];
					pos[Values.X] = Integer.parseInt(args[1]);
					pos[Values.Y] = Integer.parseInt(args[2]);
					if (n.startsWith("i")) {
						n = n.replace("i/", "");
						top.put(pos, path + "/top/" + n);
					} else {
						top.put(pos, path + name + "/top/" + n);
					}
				}
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private String[][] cutImage(String im, int layer, int type) {
		String[][] bga;
		if (!im.equals("No Place")) {
			long zeroTime = System.currentTimeMillis();
			boolean jpg = im.endsWith(".jpg");
			String pathen = im.replace(jpg ? ".jpg" : ".png", "folder");
			boolean b = ResourceLoader.getResourceLoader().exists(pathen + "/x0y0"+ (jpg ? ".jpg" : ".png"));
			if (b) {
				bga = generateNames(pathen, jpg);
			} else {
				File f = new File(pathen);
				bga = cutImage2(im, layer, type, f, pathen, jpg);
			}
			logger .info("It took " + (System.currentTimeMillis() - zeroTime) + " to load the image " + im);
		} else {
			bga = new String[0][0];
		}
		return bga;
	}
	
	private String[][] cutImage2(String im, int layer, int type, File f, String pathen, boolean jpg) {
		f.mkdir();
		BufferedImage image = 
			ResourceLoader.getResourceLoader().getBufferedImage(im);

		if (this.bg == null) {
			imageWidth = 256;
			imageHeight = 256;
			HORIZONTAL_IMAGES = (int) Math.ceil(image.getWidth() / (double) imageWidth);
			VERTICAL_IMAGES = (int) Math.ceil(image.getHeight() / (double) imageHeight);
			this.bg = new String[HORIZONTAL_IMAGES][VERTICAL_IMAGES];
		}
		String[][] bg = new String[HORIZONTAL_IMAGES][VERTICAL_IMAGES];

		int usedWidth = imageWidth;
		int usedHeight = imageHeight;

		for (int i = 0; i < HORIZONTAL_IMAGES; i++) {
			if (i == (HORIZONTAL_IMAGES - 1)) {
				usedWidth = image.getWidth() - (i * imageWidth);
			} else {
				usedWidth = imageWidth + (i == (HORIZONTAL_IMAGES - 1) ? image.getWidth() % HORIZONTAL_IMAGES : 0);
			}
			for (int j = 0; j < VERTICAL_IMAGES; j++) {
				BufferedImage one = null;
				if (j == (VERTICAL_IMAGES - 1)) {
					usedHeight = image.getHeight() - (j * imageHeight);
				} else {
					usedHeight = imageHeight + (j == (VERTICAL_IMAGES - 1) ? image.getHeight() : 0);
				}
				one = new BufferedImage(usedWidth, usedHeight, type);
				Graphics g = one.createGraphics();
				g.drawImage(image, -(i * imageWidth), -(j * imageHeight), null);
//				if (one == null) {
//					one = new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB);
//				}
				try {
					String filetype = jpg ? "jpg" : "png";
					ImageIO.write(one, filetype, new File(pathen + "/"+ "x" + i + "y" + j + "." + filetype));
				} catch (IOException e) {
					e.printStackTrace();
				}
				bg[i][j] = ImageHandler.addToCurrentConvertNow(im + "x" + i + "y" + j, one);
			}
		}
		return bg;
	}
	
	private String[][] generateNames(String path, boolean jpg) {
		if (this.bg == null) {
			imageWidth = 256;
			imageHeight = 256;
			HORIZONTAL_IMAGES = (int) Math.ceil(actualWidth / (double) imageWidth);
			VERTICAL_IMAGES = (int) Math.ceil(actualHeight / (double) imageHeight);
			this.bg = new String[HORIZONTAL_IMAGES][VERTICAL_IMAGES];
		}
		String[][] bg = new String[HORIZONTAL_IMAGES][VERTICAL_IMAGES];

		for (int i = 0; i < HORIZONTAL_IMAGES; i++) {
			for (int j = 0; j < VERTICAL_IMAGES; j++) {
				System.out.println("Loading images");
				bg[i][j] = 
					ImageHandler.addToCurrentLoadNow(
							path + "/" + "x" + i + "y" + j + (jpg ? ".jpg" : ".png"));
			}
		}
		return bg;
	}

	public void init(String name, boolean nightLayer, int extra) {
		loadImages(name, name, nightLayer, extra);
	}
	
	public void init(String path, String name, boolean nightLayer, int extra) {
		loadImages(path, name, nightLayer, extra);
	}
		
	private void loadImages(String path, String name, boolean nightLayer, int extra) {
		String temp = name + "0";
		String fullTemp = Values.VillageImages + path + "/" + temp + ".jpg";
		if (!ResourceLoader.getResourceLoader().exists(fullTemp)) {
			temp = name;
		}
		putextra(path, temp, nightLayer, new int[]{0, 0});
		if (extra == 1) {
			int w = Math.round((getWidth()+.1f) / 2f);
			int[] p = new int[2];
			p[Values.X] = w;
			putextra(path, name + "1", nightLayer, p);
		} else if (extra == 2) {
			int h = Math.round((getHeight()+.1f) / 2f);
			int[] p = new int[2];
			p[Values.Y] = h;
			putextra(path, name + "1", nightLayer, p);
		}
		doTopLayer(Values.VillageImages, path);
	}
	
	private void putextra(String path, String name, boolean nightLayer, int[] pos) {
		bottom.put(pos, doit(path, name, nightLayer));
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
		if (extraBackground == null) {
//			if (textures == null) {
//				textures = g.get(bg[0]);
//			}
//			g.drawTexture2(textures, (int) pos[Values.X], (int) pos[Values.Y], imageWidth, imageHeight, size[Values.Y]);
			
			drawBottomLayer(g);
		} else {
			g.drawImage(extraBackground, pos[Values.X], pos[Values.Y], 1);
		}
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
	public void drawTop(graphics.Graphics g, boolean removeAlpha, HashMap<Integer, Sprite> sprites) {
		if (extraBackground == null) {
			if (removeAlpha) {
				g.setAlphaFunc(.9f);
			}
			
			Iterator<int[]> it = top.keySet().iterator();
			while (it.hasNext()) {
				int[] p = it.next();
				String s = top.get(p);
				GameTexture gt = ImageHandler.getTexture(s);
				int h = gt.getHeight();
				int w = gt.getWidth();

				if (sprites != null) {
					Iterator<Sprite> sit = sprites.values().iterator();
					while (sit.hasNext()) {
						Sprite sprite = sit.next();
						if (sprite.isVisible()) {
							float[] sPos;
							if (sprite instanceof PartyMember) {
								sPos = ((PartyMember) sprite).getMemberPos();
							} else {
								sPos = sprite.getPos();
							}
							int temp = (int) (sPos[Values.X] - p[Values.X]);
							if ((temp + 36) > 0 && temp < w) {
								int tempy = (int) (sPos[Values.Y] - p[Values.Y]);
								if ((tempy + 55) > 0 && tempy < h) {
									g.drawImage(s, pos[Values.X] + p[Values.X], pos[Values.Y] + p[Values.Y], 1);
									break;
								}
							}		
						}
					}
				} else {
					g.drawImage(s, pos[Values.X] + p[Values.X], pos[Values.Y] + p[Values.Y], 1);
				}
			}
			g.setAlphaFunc(0);
			if (nightTop != null) {
				if (nightTop.contains("standard")) {
					g.drawImage(nightTop, 0, 0, 2);
				} else {
					g.drawImage(nightTop, pos[Values.X], pos[Values.Y], 2);
				}
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
	
	private void drawBottomLayer(graphics.Graphics g) {
		drawSystem(g, systems.get(BOTTOM_LAYER));
		if (USE_CUT) {
			int x, y;
			for (int i = 0; i < HORIZONTAL_IMAGES; i++) {
				x = (int) (i * imageWidth + pos[Values.X]) + offsetx;
				if (x > -imageWidth && x < Values.ORIGINAL_RESOLUTION[Values.X]) {
					for (int j = 0; j < VERTICAL_IMAGES; j++) {
						y = (int) (j * imageHeight + pos[Values.Y] + offsety);
						if (y > -imageHeight && y < Values.ORIGINAL_RESOLUTION[Values.Y]) {
							g.drawImage(bg[i][j], x, y);
						}
					}
				}
			}
		} else {
			Iterator<int[]> it = bottom.keySet().iterator();
			while (it.hasNext()) {
				int[] p = it.next();
				String s = bottom.get(p);
				g.drawImage(s, 
						pos[Values.X] + p[Values.X] + offsetx, 
						pos[Values.Y] + p[Values.Y] + offsety, 1);
			}
		}
	}

	public void update(float elapsedTime) {
		for (int i = 0; i < 2; i++) {
			double p = target[i][POS];
			double t = target[i][TARGET];
			double s = target[i][STEP];
			double a = target[i][ACC];

			if (accelerating[i] && Math.abs(s) >= Math.abs(velocityTarget)) {
				target[i][ACC] = 0;
				accelerating[i] = false;
			}
			if (p != t) {
				if (Math.abs(p - t) <= Math.abs((p + s + a) - t)) {
					target[i][POS] = t;
					target[i][ACC] = 0;
				} else {
					target[i][STEP] += target[i][ACC];
					target[i][POS] += target[i][STEP];
				}
				pos[i] = (int) Math.round(target[i][POS]);
			}
		}
		updateSystem(elapsedTime, systems.get(UPPER_LAYER));
		updateSystem(elapsedTime, systems.get(WEATHER_LAYER));
	}

	public void moveTo(int x, int y, int time) {
		double numberOfSteps = time / (double) Values.LOGIC_INTERVAL;
		double distX = x - pos[Values.X];
		double distY = y - pos[Values.Y];
		double stepX = distX / numberOfSteps;
		double stepY = distY / numberOfSteps;
		target[Values.X][TARGET] = x;
		target[Values.Y][TARGET] = y;
		target[Values.X][STEP] = stepX;
		target[Values.Y][STEP] = stepY;
	}
	
	public void move(int distance, int direction, double duration) {
		int index = direction % 2;
		target[index][TARGET] = pos[index] + (distance * Values.DIRECTIONS[direction]);
		index = Math.abs(index - 1);
		target[index][TARGET] = pos[index];
		duration /= Values.LOGIC_INTERVAL;
		for (int i = 0; i < pos.length; i++) {
			target[i][STEP] = Math.abs(target[i][TARGET] - pos[i]) / duration;
			target[i][STEP] *= Values.DIRECTIONS[direction];
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
				target[i][ACC] = (target[i][STEP] * target[i][STEP]) / (2*s);
				target[i][ACC] *= target[i][STEP] < 0 ? 1 : -1;
			}
		}
	}
	
	public void moveScreen(double a, int s, double t, int direction) {
		for (int i = 0; i < 2; i++) {
			target[i][ACC] = 0;
			target[i][STEP] = 0;
			target[i][TARGET] = 0;
		}
		
		t /= Values.LOGIC_INTERVAL;
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
	
	public void setExtraBack(String back) {
		extraBackground = back;	
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
		offsetx = x;
		offsety = y;
	}

	public ParticleSystem getParticleSystem(String name) {
		Iterator<ArrayList<ParticleSystem>> it = systems.values().iterator();
		while (it.hasNext()) {
			ArrayList<ParticleSystem> ps = it.next();
			for (ParticleSystem p : ps) {
				if (p.getName().equals(name)) {
					return p;
				}
			}
		}
		return null;
	}
}
