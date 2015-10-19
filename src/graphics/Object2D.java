/*
 * Classname: Object2D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 23/09/2008
 */
package graphics;

/**
 * This method is an abstraction for a 2D object drawn in 3D space.
 * This is used mostly by the Battle mode when drawing cards, enemies
 * slots, time bars and so on. It is also used to draw chests and other 
 * 2D images in the labyrinth. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 23 Sep 2088
 */
public abstract class Object2D extends TimeHideable {
	
	public static final int X = 0;
	public static final int Y = 1;
	public static final int Z = 2;
	public static final int INVISIBLE = -1;

	protected GameTexture[] texture;
	protected int currentList = 0;
	protected float[][][] coordList;
	protected float width = 3;//3.5f;
	protected float height = 3f;
	
	/**
	 * Creates a new 2D object and allocates memory to store size
	 * amount of textures and coordinates.
	 *  
	 * @param size the number of textures to use.
	 */
	public Object2D(int size) {
		texture = new GameTexture[size];
	}
	
	/**
	 * This method creates standard coordinates where the textures will
	 * be drawn with the origin as center. The given size value can be 1 or 2
	 * but for more coordinates this method must be overwritten by a more
	 * specific createCoords() method. 
	 * 
	 * @param size the number of coordinates to use (one or two).
	 */
	protected void createCoords(int size) {
		createCoordList(size);

		createCoordFor(-width / 2, width / 2, 0, X);
		createCoordFor(-height / 2, height / 2, 0, Y);
		createCoordFor(0, 0, 0, Z);

		if (size >= 2) {
			copyCoords(1, 0, X);
			copyCoords(1, 0, Y);
			createCoordFor(-.001f, -.001f, 1, Z);
		}
	}

	/**
	 * This method creates the list of coordinates. The given value
	 * is the number of different position or coordinates that the texture
	 * will be drawn at.
	 * 
	 * @param size the number of coordinates to allocate memory for.
	 */
	protected void createCoordList(int size) {
		coordList = new float[size][3][2];
	}

	/**
	 * This method copies the coordinates stored in the source position
	 * of the coordinate list. The given axle value represents if the 
	 * coordinate to copy is on the X-axis, Y-axis or the Z-axis.
	 * 
	 * @param destination the destination coordinate.
	 * @param source the source coordinate.
	 * @param axle the axle of the coordinate to copy.
	 */
	public void copyCoords(int destination, int source, int axle) {
		coordList[destination][axle][0] = coordList[source][axle][0];
		coordList[destination][axle][1] = coordList[source][axle][1];
	}

	/**
	 * Creates the coordinate for a texture.
	 * 
	 * @param bottomLeft the bottom coordinate if axle = Y or the 
	 * left if axle = X.
	 * @param topRight the top coordinate if axle = Y or the 
	 * right if axle = X.
	 * @param index the index of the coordinate in the list.
	 * @param axle the axle for the coordinate. X, Y or Z
	 */
	protected void createCoordFor(float bottomLeft, float topRight, int index, int axle) {
		coordList[index][axle][0] = bottomLeft;
		coordList[index][axle][1] = topRight;
	}

	/**
	 * Makes a draw list and draws the texture with the given index, with
	 * the given list of coordinates.
	 * 
	 * @param gl the GL to create the list on.
	 * @param texIndex the index of the texture to use.
	 * @param coordIndex the index of the coordinates to use.
	 * @param drawFront true if the Utils3D.draw3D() method should be used,
	 * if false the method used to draw is Utils3D.draw3DBackside().
	 */
	protected void draw(Graphics g, int texIndex, int coordIndex, boolean drawFront) {
		if (texture[texIndex] != null) {
			if (drawFront) {
				Utils3D.draw3D(g, texture[texIndex].getTexture(), coordList[coordIndex]);
			} else {
				Utils3D.draw3DBackside(g, texture[texIndex].getTexture(), coordList[coordIndex]);
			}
		}
	}

	/**
	 * Makes a draw list where the texture with the given index is drawn
	 * on the given GL using the coordinates with the given index.
	 * The drawList is stored in the array at the position of the 
	 * given texIndex.
	 *  
	 * @param gl the GL to draw on.
	 * @param texIndex the index of the texture to draw.
	 * @param coordIndex the index of the coordinates to draw.
	 */
	protected void draw(Graphics g, int texIndex, int coordIndex) {
		if (texture[texIndex] != null) {
			Utils3D.draw3D(g, texture[texIndex].getTexture(), coordList[coordIndex]);
		}
	}

	/**
	 * Loads the texture with the given name iff the texture has not
	 * already been loaded. The texture is then stored in the texture
	 * list with the given index.
	 * 
	 * @param image the name of the image to load (path + name).
	 * @param index the index in the list to store the texture.
	 */
	protected void loadTexture(String image, int index) {
		if (image != null) {
			texture[index] = ImageHandler.getTexture(image);
		}
	}
	
	/**
	 * This method loads the texture with the given path and name.
	 * 
	 * @param path the path to the file containing the texture to load.
	 * @param name the name of the file to load.
	 * @param index the index where to store the texture.
	 */
	public void loadTexture(String path, String name, int index) {
		loadTexture(path + name, index);
	}

	/**
	 * This method sets the size of this object2D based on the given scale.
	 * It takes the texture with the given index and gets it height and width.
	 * It then multiplies the height and width with the given scale value and
	 * stores the values in this class variables height and width.
	 * 
	 * @param index the index of the texture to get the height and width from.
	 * @param scale the scale of the texture height and width.
	 */
	public void setSize(int index, float scale) {
		height = texture[index].getHeight() * scale;
		width = texture[index].getWidth() * scale;
	}
	
	/**
	 * This method must be implemented by subclasses to initiated the drawings
	 * on the given GL object.
	 * 
	 * @param gl the GL object to use when initializing.
	 */
	public abstract void initDraw(Graphics g);
	public abstract void draw(Graphics g);
	public void drawTopLayer(Graphics g) {}
}
