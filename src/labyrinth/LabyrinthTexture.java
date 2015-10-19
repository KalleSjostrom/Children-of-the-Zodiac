/*
 * Classname: LabyrinthTexture.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/05/2008
 */
package labyrinth;

import graphics.GameTexture;
import graphics.ImageHandler;
import info.Values;

import organizer.ResourceLoader;

/**
 * This class stores information about the textures in the labyrinth.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 May 2008.
 */
public class LabyrinthTexture {

	private String fileName;
	private GameTexture texture;
	private GameTexture textureNormal;
	/*
	public static Texture black = 
		ImageHandler..loadTexture(
				Values.LabyrinthTextures + "black.jpg").getTexture();
				*/

	/**
	 * Constructs a new LabyrinthTexture and stores the given strings.
	 * 
	 * @param filename the name of the file to use as texture.
	 */
	public LabyrinthTexture(String filename) {
		fileName = filename;
	}

	/**
	 * This method loads the textures with the stored filename.
	 */
	public void loadTexture() {
		String n = ImageHandler.addToCurrentLoadNow(Values.LabyrinthTextures + fileName);
		texture = ImageHandler.getTexture(n);
		String normal = Values.LabyrinthTextures + fileName.replace(".png", "normal.png");
		if (ResourceLoader.getResourceLoader().exists(normal)) {
			n = ImageHandler.addToCurrentLoadNow(normal);
			textureNormal = ImageHandler.getTexture(n);
		} else {
			normal = Values.LabyrinthTextures + fileName.replace(".jpg", "normal.jpg");
			if (ResourceLoader.getResourceLoader().exists(normal)) {
				n = ImageHandler.addToCurrentLoadNow(normal);
				textureNormal = ImageHandler.getTexture(n);
			}
		}
	}
	
	/**
	 * Gets the texture.
	 * 
	 * @return the stored texture.
	 */
	public GameTexture getTexture() {
		return texture;
	}
	
	public GameTexture getNormalTexture() {
		return textureNormal;
	}
}
