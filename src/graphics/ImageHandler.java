/*
 * Classname: ImageHandler.java
 * 
 * Version information: 0.7.0
 *
 * Date: 30/12/2008
 */
package graphics;

import info.Values;

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Stack;
import java.util.concurrent.Semaphore;

import java.util.logging.*;
import organizer.GameEventListener;
import organizer.ResourceLoader;

/**
 * This class manages (almost) all the images and textures in the game.
 * It keeps the textures sorted in a map where the game mode code (see class 
 * Values) acts as the key to this map. Both a current list for the current
 * game mode and a secondary list for the previous game mode is kept in 
 * memory to be able to quickly return to the previous game mode. The list with
 * textures from the game mode before the previous game mode is always thrown 
 * out, to free memory. However, there are certain textures that should be 
 * loaded just once, and never discarded. These textures are stored in a 
 * permanent list. Methods for adding textures and data to theses maps are
 * found in this class.  
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 30 Dec 2008
 */
public class ImageHandler {

	private static HashMap<Integer, TextureList> texList = 
		new HashMap<Integer, TextureList>();
	private static HashMap<String, BufferedImage> images = 
		new HashMap<String, BufferedImage>();
	private static TextureList permanentList = new TextureList();
	private static Stack<Integer> clearModes = new Stack<Integer>();
	private static Semaphore resourceAccess = new Semaphore(1);
	private static int secondaryGameMode = 0;
	private static int currentGameMode = 0;
	
	private static Logger logger = Logger.getLogger("ImageHandler");
	
	/**
	 * Sets which game mode the images should be saved under. This could
	 * be Values.Village for example. This means that the images loaded after
	 * this call will be saved in the village list. The current game mode
	 * will be set to the given game mode and the previous game mode is stored.
	 * The stored game mode before this method is called is discarded along 
	 * with all textures and images belonging to it.
	 * 
	 * @param gameMode the game mode to save textures in.
	 */
	public static void setGameMode(int gameMode) {
		logger.log(Level.FINE, "Game Mode " + gameMode);
		logger.log(Level.FINE, "Secondary Game Mode " + secondaryGameMode);
		logger.log(Level.FINE, "Current Game Mode " + currentGameMode);
		if (secondaryGameMode != gameMode) {
			if (secondaryGameMode != currentGameMode) {
				if (gameMode != Values.MENU) {
					ImageHandler.clearList(secondaryGameMode);
//					Graphics.clearDrawLists();
				}
			}
			secondaryGameMode = currentGameMode;
			currentGameMode = gameMode;
		}
		logger.log(Level.FINE, "a Game Mode " + gameMode);
		logger.log(Level.FINE, "a Secondary Game Mode " + secondaryGameMode);
		logger.log(Level.FINE, "a Current Game Mode " + currentGameMode);
	}
	
	/**
	 * Swaps the game mode with the stored one. This means if the <code>
	 * Values.Village</code> game mode is the current one, and the landscape is
	 * entered. The current game mode will then be <code>Values.Landscape
	 * </code> and the stored game mode will be <code>Values.Village</code>.
	 * If this method is then called these values will be swapped so that the
	 * <code>Values.Village</code> will be used as the key for the current 
	 * textures in the map and <code>Values.Landscape</code> will be used as 
	 * the secondary or stored game mode. 
	 */
	public static void swapGameMode() {
		int temp = secondaryGameMode;
		secondaryGameMode = currentGameMode;
		currentGameMode = temp;
	}
	
	/**
	 * This method adds the texture with the given name (path) to the current
	 * game modes list. The texture will be loaded when it is first used.
	 * 
	 * @param name the name of the texture.
	 * @return the name of the texture.
	 */
	public static String addToCurrentLoadOnUse(String name) {
		return addLoadOnUse(getList(currentGameMode), name);
	}
	
	/**
	 * This method adds the texture with the given name (path) to the current
	 * game modes list. The texture will be loaded as soon as the GL thread 
	 * gains the context.
	 * 
	 * @param name the name of the texture.
	 * @return the name of the texture.
	 */
	public static String addToCurrentLoadNow(String name) {
		return addLoadNow(getList(currentGameMode), name, null);
	}
	
	/**
	 * This method converts the given image and stores it in the current
	 * game modes list as the given name as key. It will covert the image
	 * as soon as the GL thread gains the context.
	 * 
	 * @param name the name used to store the converted image.
	 * @param image the image to convert.
	 * @return the name of the texture.
	 */
	public static String addToCurrentConvertNow(
			String name, BufferedImage image) {
		return addLoadNow(getList(currentGameMode), name, image);
	}
	
	/**
	 * This method adds the texture with the given name (path) to the permanent
	 * texture list. The texture will be loaded when it is first used.
	 * 
	 * @param name the name of the texture.
	 * @return the name of the texture.
	 */
	public static String addPermanentlyLoadOnUse(String name) {
		return addLoadOnUse(permanentList, name);
	}
	
	/**
	 * This method adds the texture with the given name (path) to the permanent
	 * texture list. The texture will be loaded as soon as the GL thread gains 
	 * the context.
	 * 
	 * @param name the name of the texture.
	 * @return the name of the texture.
	 */
	public static String addPermanentlyLoadNow(String name) {
		return addLoadNow(permanentList, name, null);
	}
	
	/**
	 * This method converts the given image and stores it in the permanent
	 * texture list as the given name as key. It will covert the image as soon
	 * as the GL thread gains the context.
	 * 
	 * @param name the name used to store the converted image.
	 * @param image the image to convert.
	 * @return the name of the texture.
	 */
	public static String addPermanentlyConvertNow(
			String name, BufferedImage image) {
		return addLoadNow(permanentList, name, image);
	}
	
	/**
	 * Adds the given name as key in the given texture list with a null value.
	 * This will cause the texture to be loaded when it is used. This method 
	 * will only add the given name if the list does not already contain the
	 * name.
	 *   
	 * @param list the list to put the name in.
	 * @param name the name of the texture to add.
	 * @return the given name.
	 */
	private static String addLoadOnUse(TextureList list, String name) {
		if (!permanentList.containsKey(name) && !list.containsKey(name)) {
			acquireAccess();
			list.put(name, null);
			releaseAccess();
		}
		return name;
	}
	
	/**
	 * Adds the given name as key in the given texture lists temporary hash map
	 * with the given image as value. This will cause the given image to be 
	 * converted as soon as the OpenGL thread gains context, and stored as a
	 * texture in the given texture lists. This method will only add the given
	 * name if the list does not already contain the name.
	 *   
	 * @param list the list to put the name in.
	 * @param name the name of the texture to add.
	 * @param image the image to convert.
	 * @return the given name.
	 */
	private static String addLoadNow(
			TextureList list, String name, BufferedImage image) {
		if (!permanentList.containsKey(name) && !list.containsKey(name)) {
			acquireAccess();
			list.temp.put(name, image);
			releaseAccess();
		}
		return name;
	}
	
	/**
	 * Puts in the requests that the draw lists should be deleted from the
	 * graphic card. These draw lists are the ones created by the OpenGL API.
	 */
	public static void clearDrawList() {
		clearModes.push(currentGameMode);
	}
	
	/**
	 * This method generates a new draw list using the given GL instance.
	 * It then stores this new draw list in the current game mode's list.
	 * 
	 * @param g the GL to use when creating the draw list.
	 * @return the integer to use when drawing the draw list in OpenGL.
	 */
	public static int generateDrawList(Graphics g) {
		int list = g.generateList();
		getList(currentGameMode).drawLists.add(list);
		return list;
	}
	
	/**
	 * This method actually loads all the texture added with the add methods
	 * in this class. It also converts all the images if there are any. This is
	 * also where the actual removal of the draw lists are taking place. This
	 * method should be called each time the OpenGL gains context to make sure
	 * the needed textures are loaded when they should be drawn.
	 * 
	 * @param g the GL instance to use when deleting draw lists.
	 */
	public static void load(Graphics g) {
		acquireAccess();
		TextureList tl = getList(currentGameMode);
		addList(tl.temp, tl.list);
		tl = getList(secondaryGameMode);
		addList(tl.temp, tl.list);
		addList(permanentList.temp, permanentList.list);
		while (clearModes.size() > 0) {
			TextureList drawTL = getList(clearModes.pop());
			for (int i = 0; i < drawTL.drawLists.size(); i++) {
				int number = drawTL.drawLists.get(i);
				g.deleteList(number);
				
			}
			Iterator<String> it = drawTL.list.keySet().iterator();
			while (it.hasNext()) { 
				String s = it.next();
				GameTexture t = drawTL.list.get(s);
				if (t != null) t.destroy(g);
			}
			drawTL.drawLists.clear();
			drawTL.temp.clear();
			drawTL.list.clear();
		}
		releaseAccess();
	}

	/**
	 * Gets the list mapped together with the given game mode. If the given
	 * game mode does not have a texture list already, a new one is created
	 * added and returned. This method can therefore never return null.
	 * 
	 * @param gameMode the game mode whose texture list to get.
	 * @return the texture list that belongs to the given game mode.
	 */
	private static TextureList getList(int gameMode) {
		TextureList l = texList.get(gameMode);
		if (l == null) {
			l = new TextureList();
			texList.put(gameMode, l);
		}
		return l;
	}
	
	/**
	 * Gets the buffered image with the given path and name. 
	 * 
	 * @param path the path to the image.
	 * @param name the name of the image.
	 * @return the buffered image with the given path and name.
	 */
	public static BufferedImage getImage(String path, String name) {
		return getImage(path + name);
	}
	
	/**
	 * Gets the buffered image with the given name. The image is loaded
	 * from the hard drive if the image has not been loaded. 
	 * 
	 * 
	 * @param name the name of the image to load.
	 * @return the buffered image with the given name.
	 */
	public static BufferedImage getImage(String name) {
		BufferedImage im = images.get(name);
		if (im == null) {
			ResourceLoader rl = ResourceLoader.getResourceLoader();
			im = rl.getBufferedImage(name);
			images.put(name, im);
		}
		return im;
	}

	/**
	 * Converts all the images in the imageList to textures and stores them
	 * in the given list with the same name as key. This method assumes that
	 * there are no textures in the given list that has the same name as the
	 * images in the imageList. If this would occur, the texture in the given
	 * list would be overwritten.
	 * 
	 * @param imageList the list of images to convert.
	 * @param list the list to add the converted images to.
	 */
	private static void addList(
			HashMap<String, BufferedImage> imageList, 
			HashMap<String, GameTexture> list) {
		if (imageList.size() > 0) {
			Iterator<String> it = imageList.keySet().iterator();
			while(it.hasNext()) {
				String name = it.next();
				BufferedImage im = imageList.get(name);
				GameTexture t;
				if (im == null) {
					long zeroTime = System.currentTimeMillis();
					t = ImageLoader.loadTexture(name);
					long time = System.currentTimeMillis() - zeroTime;
//					if (time > 10) {
//						logger.log(Level.WARNING, "Warning! It took " + time + 
//								" to load image " + name);
//					}
				} else {
					t = ImageLoader.getTexture(im, name);
				}
				list.put(name, t);
			}
			imageList.clear();
		}
	}

	/**
	 * Gets the texture with the given name. This method searches in the 
	 * current game mode's list for the texture, if it is not found the 
	 * permanent list is searched, if the texture is still not found the
	 * secondary game mode's list is checked. If all these three lists
	 * does not contain a texture with the given name, the texture is
	 * loaded and stored in the current game mode's list and returned.
	 * This method will therefore never return null (if the image does 
	 * exists), but always the texture with the given name.
	 * 
	 * @param name the name of the texture.
	 * @return the texture with the given name.
	 */
	public static GameTexture getTexture(String name) {
		GameTexture t = getList(currentGameMode).get(name);
		if (t == null) {
			t = permanentList.get(name);
			if (t == null && permanentList.temp.get(name) != null) {
				load(GameEventListener.getG());
				t = permanentList.get(name);
			}
			if (t == null) {
				t = getList(secondaryGameMode).get(name);
				if (t == null) {
					t = ImageLoader.loadTexture(name);
					getList(currentGameMode).put(name, t);
				}
			}
		}
		return t;
	}
		
	public static GameTexture getGameTexture(BufferedImage image) {
		GameTexture t = getIt(getList(currentGameMode).list, image);
		if (t == null) {
			t = getIt(permanentList.list, image);
			if (t == null) {
				Iterator<BufferedImage> it = permanentList.temp.values().iterator();
				while (it.hasNext()) {
					BufferedImage bi = it.next();
					if (bi == null) {
						logger.log(Level.WARNING, "\tBuffered image is null in permanent temp list");
					} else if (bi.equals(image)) {
						logger.log(Level.WARNING, "\tBuffered image in temp list");
					}
				}
//				load(GameEventListener.getGraphics());
//				t = permanentList.get(name);
			}
			if (t == null) {
				t = getIt(getList(secondaryGameMode).list, image);
				if (t == null) {
					String name = "name" + image.hashCode();
					t = ImageLoader.getTexture(image, name);
					getList(currentGameMode).put(name, t);
				}
			}
		}
		return t;
	}

	private static GameTexture getIt(HashMap<String, GameTexture> list,
			BufferedImage image) {
		Iterator<String> it = list.keySet().iterator();
		while (it.hasNext()) {
			String s = it.next();
			GameTexture gt = list.get(s);
			if (gt == null) {
			} else if (gt.getData().equals(image)) {
				return gt;
			}
		}
		return null;
	}

	/**
	 * This method clears all the temporary textures used by the 
	 * game mode with the given mode. These modes can be the modes
	 * in the Values class. 
	 * 
	 * @param gameMode the mode in the Values class.
	 */
	public static void clearList(int gameMode) {
		TextureList list = getList(gameMode);
		if (list != null) {
			list.clear(gameMode);
		}
	}
	
	/**
	 * Acquires the access to the resources. 
	 */
	private static void acquireAccess() {
		try {
			resourceAccess.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
	
	/**
	 * Releases the access to the resources.
	 */
	private static void releaseAccess() {
		resourceAccess.release();
	}
	
	/**
	 * Checks if the current game mode's draw list is empty.
	 * 
	 * @return true if the current draw list is empty.
	 */
	public static boolean isCurrentGameModeCleared() {
		return getList(currentGameMode).list.size() == 0;
	}
	
	public static int getLoadQueueSize() {
		int size = 0;
		acquireAccess();
		TextureList currentTextureList = getList(currentGameMode);
		TextureList secondaryTextureList = getList(secondaryGameMode);
		size = currentTextureList.temp.size() + secondaryTextureList.temp.size() + permanentList.temp.size();
		releaseAccess();
		return size;
	}

	/**
	 * This class stores textures, images and draw lists in different hash 
	 * maps.
	 * 
	 * @author 		Kalle Sj�str�m
	 * @version 	0.7.0 - 30 Dec 2008
	 */
	private static class TextureList {
		
		private HashMap<String, GameTexture> list =
			new HashMap<String, GameTexture>();
		private HashMap<String, BufferedImage> temp = 
			new HashMap<String, BufferedImage>();
		private ArrayList<Integer> drawLists = 
			new ArrayList<Integer>();
		
		/**
		 * This method clears all the images, textures and draw lists from this
		 * texture list.
		 * 
		 * @param gameMode the game mode to clear the image resources for.
		 */
		private void clear(int gameMode) {
			// list.clear();
			temp.clear();
			clearModes.push(gameMode);
		}

		/**
		 * Checks if this texture list contain the given name as key.
		 * 
		 * @param name the name to check.
		 * @return true if this list contains the given name as key.
		 */
		private boolean containsKey(String name) {
			return list.containsKey(name);
		}

		/**
		 * Puts the given texture as value in this hash map with the given name
		 * as key.
		 * 
		 * @param name the key to use when storing the texture.
		 * @param t the texture to store.
		 */
		private void put(String name, GameTexture t) {
			list.put(name, t);
		}
		
		/**
		 * Gets the texture from this TextureList with the given name.
		 * 
		 * @param name the name of the texture to get.
		 * @return the texture with the given name.
		 */
		private GameTexture get(String name) {
			return list.get(name);
		}
	}
}
