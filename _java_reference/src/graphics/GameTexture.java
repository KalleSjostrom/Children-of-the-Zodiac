package graphics;

import info.Values;

import java.awt.image.BufferedImage;

import organizer.ResourceLoader;

import com.jogamp.opengl.GLProfile;
import com.jogamp.opengl.util.texture.Texture;
import com.jogamp.opengl.util.texture.TextureCoords;
import com.jogamp.opengl.util.texture.TextureData;
import com.jogamp.opengl.util.texture.awt.AWTTextureIO;

public class GameTexture {

	private BufferedImage data;
	private Texture texture;
	private String name;
	private int height;
	private int width;
	private float x;
	private float y;
	private boolean destroyed;
	private boolean loaded;

	/**
	 * Wraps the given texture and stores the given information about it.
	 * 
	 * @param tex the texture to wrap.
	 * @param name the name of the texture.
	 * @param height the height of the texture.
	 * @param width the width of the texture.
	 */
	public GameTexture(Texture tex, String name, BufferedImage data) {
		texture = tex;
		this.data = data;
		height = data.getHeight();
		width = data.getWidth();
		this.name = name;
		destroyed = false;
		loaded = true;
	}

	public GameTexture(String name, BufferedImage image) {
		this.name = name;
		data = image;
		loaded = false;
	}
	
	public void load() {
		if (data == null) {
			data = ResourceLoader.getResourceLoader().getBufferedImage(name);
			height = data.getHeight();
			width = data.getWidth();
		}
		texture = newTexture();
	}

	/**
	 * Gets the name of the texture.
	 * 
	 * @return the name of the texture.
	 */
	public String getName() {
		return name;
	}

	/**
	 * Gets the height of the texture.
	 * 
	 * @return the height of the texture.
	 */
	public int getHeight() {
		return height;
	}

	/**
	 * Gets the width of the texture.
	 * 
	 * @return the width of the texture.
	 */
	public int getWidth() {
		return width;
	}

	/**
	 * Gets the wrapped texture.
	 * 
	 * @return the texture.
	 */
	public Texture getTexture() {
		if (destroyed) {
			texture = newTexture();
			destroyed = false;
		}
		return texture;
	}
	
	private Texture newTexture() {
		return AWTTextureIO.newTexture(GLProfile.get(GLProfile.GL2), data, false);
	}
	public static Texture newTexture(BufferedImage image) {
		return  AWTTextureIO.newTexture(GLProfile.get(GLProfile.GL2), image, false);
	}
	public static TextureData newTextureData(BufferedImage textImage) {
		return AWTTextureIO.newTextureData(GLProfile.get(GLProfile.GL2), textImage, false);
	}
	
	public void drawMany(Graphics g, float x, float y, float scale) {
		float halfHeight = (height * scale) / 2;
		float halfWidth = (width * scale) / 2;
		y -= halfHeight;
		x -= halfWidth;
		int nyh = (int) (y + 2 * halfHeight);
		int xw = (int) (x + 2 * halfWidth);
		TextureCoords tc = texture.getImageTexCoords();
		g.drawi(tc, (int) x, nyh, xw, (int) y, false);
	}
	
	public void draw(Graphics g, float x, float y, float scale) {
		draw(g, x, y, width, height, scale, 1);
	}
	
	public void draw(Graphics g, float x, float y, float width, float height, float scale, float percent) {
		texture.bind(g.getGL());
		TextureCoords tc = texture.getImageTexCoords();
		int ny = (int) (y);
		int nyh = (int) (y + height * scale);
		int xw = (int) (x + width * scale * percent);
		g.drawip(tc, (int) x, nyh, xw, ny, percent);
	}
	
	public void draw(Graphics g, int x, int y, int width, int height,
			float size, float percentLow, float percentHigh) {
		texture.bind(g.getGL());
		TextureCoords tc = texture.getImageTexCoords();
		int ny = (int) (y);
		int nyh = (int) (y + height * size);
		int xw = (int) (x + width * size * percentHigh);
		int nx = (int) (x + width * size * percentLow);
		g.drawipp(tc, nx, nyh, xw, ny, percentLow, percentHigh);
	}
	
	public void draw(Graphics g, float x, float y) {
		draw(g, x, y, 1);
	}

	public void draw(Graphics g) {
		draw(g, x, y);
	}
	
	public void drawCentered(Graphics g, float y) {
		int w = Math.round(width / 2f);
		int x = Math.round(Values.ORIGINAL_RESOLUTION[Values.X] / 2f) - w;
		draw(g, x, y);
	}

	public void destroy(Graphics g) {
		texture.destroy(g.getGL());
		destroyed = true;
	}

	public boolean isLoaded() {
		return loaded;
	}

	public void setPosition(int x, int y) {
		this.x = x;
		this.y = y;
	}
	
	/**
	 * Sets the x position of the menu hand.
	 * 
	 * @param xpos the xpos to set
	 */
	public void setXpos(int xpos) {
		x = xpos;
	}

	/**
	 * Sets the y position of the menu hand.
	 * 
	 * @param ypos the ypos to set
	 */
	public void setYpos(int ypos) {
		y = ypos;
	}

	/**
	 * Gets the y position of the menu hand.
	 * 
	 * @return the y position of the menu hand.
	 */
	public float getYpos() {
		return y;
	}

	public void setName(String name) {
		this.name = name;
	}

	public void bind(Graphics g) {
		texture.bind(g.getGL());	
	}

	public BufferedImage getData() {
		return data;
	}
}
