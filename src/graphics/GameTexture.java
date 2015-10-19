package graphics;

import java.awt.image.BufferedImage;
import organizer.ResourceLoader;
import com.jogamp.opengl.GLProfile;
import com.jogamp.opengl.util.texture.Texture;
import com.jogamp.opengl.util.texture.TextureData;
import com.jogamp.opengl.util.texture.awt.AWTTextureIO;

public class GameTexture {

	private BufferedImage data;
	private Texture texture;
	private String name;
	private int height;
	private int width;
	private boolean destroyed;
	private boolean loaded;

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

	public Texture DEBUGGetTexture() {
		return texture;
	}

	public int getHeight() {
		return height;
	}
	public int getWidth() {
		return width;
	}

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

	public void destroy(Graphics g) {
		texture.destroy(Graphics.gl);
		destroyed = true;
	}

	public boolean isLoaded() {
		return loaded;
	}

	public void bind(Graphics g) {
		texture.bind(Graphics.gl);	
	}

	public BufferedImage getData() {
		return data;
	}
}
