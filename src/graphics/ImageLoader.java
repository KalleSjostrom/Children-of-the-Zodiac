/*
 * Classname: Image3D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 23/09/2008
 */
package graphics;

import java.awt.image.BufferedImage;

import java.util.logging.*;

import organizer.ResourceLoader;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class loads and creates texture from files or images.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 23 Sep 2088
 */
public class ImageLoader {

	private static Logger logger = Logger.getLogger("ImageLoader");

	/**
	 * Loads a texture from the file with the given name.
	 * 
	 * @param name the name of the file to load.
	 * @return the loaded texture.
	 */
	public static GameTexture loadTexture(String name) {
		BufferedImage im = ResourceLoader.getResourceLoader().getBufferedImage(name);
		Texture tex = GameTexture.newTexture(im);
		return new GameTexture(tex, name, im);
	}

	/**
	 * Creates a texture from the given image.
	 * 
	 * @param im the image to create the texture from.
	 * @return the created texture. 
	 */
	protected static GameTexture getTexture(BufferedImage im, String name) {
		GameTexture gt = null;
		if (im == null) {
			logger.log(Level.WARNING, "\tThe buffered image to base a game texture on is null: Image3D");
		} else {
			Texture tex = GameTexture.newTexture(im);
			gt = new GameTexture(tex, name, im);
		}
		return gt;
	}
}
