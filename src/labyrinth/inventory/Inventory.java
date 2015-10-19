/*
 * Classname: Inventory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Object2D;
import graphics.Utils3D;
import info.Database;
import info.LabyrinthMap;
import info.SoundMap;
import info.Values;

import java.util.HashMap;
import java.util.StringTokenizer;

import com.jogamp.opengl.GL2;

import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.Position;

import java.util.logging.*;
import organizer.Organizer;
import organizer.ResourceLoader;

import com.jogamp.opengl.util.texture.Texture;

/**
 * This class is the abstract inventory. An inventory is a thing in the 
 * labyrinth, that the player can find. Examples of these is chest,
 * buttons, doors and so on.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 13 Sep 2008
 */
public abstract class Inventory implements Comparable<Inventory> {
	
	private static Logger logger = Logger.getLogger("Inventory");
	
	protected Node node;
	protected String dataBaseName;
	protected String image;
	protected String[] images;
	protected int dir;
	protected int status;
	protected float scale;
	protected float scale2;
	protected float zOff;
	protected float heightOffset;
	protected GameTexture[] texture;
	protected float height;
	private float width;
	protected int currentTex;
	protected boolean haveBeenIn = false;
	
	protected static final int Y_HEIGHT = 0;
	protected static final int Z_OFF = 1;
	protected static final int SCALE = 2;
	protected InventoryInfo info;
	
	private final static HashMap<String, InventoryInfo> map = createMap();

	/**
	 * Creates a new inventory from the given information.
	 * 
	 * @param n the node where the inventory should be.
	 * @param dir the direction the texture should face. 
	 * (Values.UP, .RIGHT, .DOWN, .LEFT).
	 * @param nrOfTexs the number of textures to use.
	 * @param image the name of the first image in the series.
	 * @param status the status for this inventory according to 
	 * the Database class.
	 */
	public Inventory(Node n, int dir, int nrOfTexs, String image, int status) {
		node = n;
		this.dir = dir;
		this.image = image;
		this.status = status;
		images = new String[nrOfTexs];
		texture = new GameTexture[nrOfTexs];
		setSettings();
	}
	
	/**
	 * Initiates the drawings of the inventory on the given GL object.
	 * 
	 * @param gl the GL object to initiate the drawings to.
	 */
	public void initDraw(Graphics g) {
		if (image == null) {
			return;
		}
		if (images.length > 1) {
			for (int i = 0; i < images.length; i++) {
				String temp = Values.LabyrinthTextures + image + i + ".png";
				
				if (ResourceLoader.getResourceLoader().exists(temp)) {
					images[i] = temp; 
				} else {
					images[i] = Values.LabyrinthTextures + image + i + ".jpg";
				}
				
				ImageHandler.addToCurrentLoadOnUse(images[i]);
				texture[i] = ImageHandler.getTexture(images[i]);
			}
		} else {
			images[0] = Values.LabyrinthTextures + image;
			ImageHandler.addToCurrentLoadOnUse(images[0]);
			texture[0] = ImageHandler.getTexture(images[0]);
		}
		setSize(0, scale);
	}
	
	public void setSize(int index, float scale) {
		height = texture[index].getHeight() * scale;
		width = texture[index].getWidth() * scale;
	}
	
	public void draw(Graphics g) {
		if (currentTex != Object2D.INVISIBLE) {
			GL2 gl = Graphics.gl2;
			if (currentTex < texture.length) {
				texture[currentTex].bind(g);
			}
			gl.glBegin(GL2.GL_QUADS);
			draw(gl, dir);
			gl.glEnd();
		}
	}
	
	protected void draw(GL2 gl, int dir) {
		Position position = node.getPos();
		float x = position.getX();
		float x2;
		float y = Node.FLOOR_HEIGHT + heightOffset;
		float y2 = y + height * scale2;
		float z = position.getZ();
		float z2;
		
		boolean flip = true;
		switch (dir) {
		case 0 : 
		// Back wall // SOUTH
			z = position.getZ() + zOff;
			x = position.getX() - (width / 2) * scale2;
			x2 = position.getX() + (width / 2) * scale2;
			flip = false;
			gl.glNormal3f(0, 0, -1.0f);
			gl.glTexCoord2f(flip ? 0 : 1, 1); gl.glVertex3f(x, y, z);
			gl.glTexCoord2f(flip ? 0 : 1, 0); gl.glVertex3f(x, y2, z);
			gl.glTexCoord2f(flip ? 1 : 0, 0); gl.glVertex3f(x2, y2, z);
			gl.glTexCoord2f(flip ? 1 : 0, 1); gl.glVertex3f(x2, y, z);
		break;
		case 1 :
			// Left Wall // WEST
			x = position.getX() - zOff;
			z = position.getZ() + (width / 2) * scale2;
			z2 = position.getZ() - (width / 2) * scale2;
			gl.glNormal3f(1.0f, 0, 0);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, y2, z);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, y, z);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, y, z2);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, y2, z2);
			break;
		case 2 :
			// Front Wall // NORTH
			z = position.getZ() - zOff;
			x = position.getX() - (width / 2) * scale2;
			x2 = position.getX() + (width / 2) * scale2;
			gl.glNormal3f(0, 0, 1.0f);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, y2, z);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, y, z);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x2, y, z);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x2, y2, z);
			break;
		case 3 :
			// Right Wall // EAST
			x = position.getX() + zOff;
			z = position.getZ() + (width / 2) * scale2;
			z2 = position.getZ() - (width / 2) * scale2;
			gl.glNormal3f(-1.0f, 0, 0);
			gl.glTexCoord2f(0, 0); gl.glVertex3f(x, y2, z2);
			gl.glTexCoord2f(0, 1); gl.glVertex3f(x, y, z2);
			gl.glTexCoord2f(1, 1); gl.glVertex3f(x, y, z);
			gl.glTexCoord2f(1, 0); gl.glVertex3f(x, y2, z);
			break;
		}
	}
	
	/**
	 * Sets the name of this inventory as it is marked in the data base.
	 * This name can later be used when calling the database to find out
	 * the status for this inventory. The status can be if the chest is
	 * opened or not, if a hinder is still blocking the passage in the 
	 * labyrinth and so on.
	 * 
	 * @param name the name of this inventory in the database.
	 */
	private void setDatabaseName(String name) {
		dataBaseName = name;
	}
	
	/**
	 * Gets the name of this inventory as it is marked in the database.
	 * This name can be used when calling the database to find out
	 * the status for this inventory. The status can be if the chest is
	 * opened or not, if a hinder is still blocking the passage in the 
	 * labyrinth and so on.
	 * 
	 * @return the name of this inventory in the database.
	 */
	public String getDatabaseName() {
		return dataBaseName;
	}

	/**
	 * Gets the node where this inventory is located.
	 * 
	 * @return the node where this inventory is.
	 */
	public Node getNode() {
		return node;
	}
	
	public int getDirection() {
		return dir;
	}
	
	private static HashMap<String, InventoryInfo> createMap() {
		HashMap<String, InventoryInfo> map = new HashMap<String, InventoryInfo>();
//		this.soundEffect = soundEffect;
		map.put("Images/chest", new InventoryInfo(0, 0, 3.5f, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST));
		map.put("Images/pot", new InventoryInfo(0, 0, 2, SoundMap.LABYRINTH_OPEN_STONE_BOX));
		map.put("Images/icepot", new InventoryInfo(0, 0, 2, SoundMap.LABYRINTH_OPEN_STONE_BOX));
		map.put("Images/crate", new InventoryInfo(0, 0, 3, SoundMap.LABYRINTH_OPEN_CRATE));
		map.put("Images/snowcrate", new InventoryInfo(0, 0, 3, SoundMap.LABYRINTH_OPEN_CRATE));
		map.put("Images/lever", new InventoryInfo(0, 1.f, 5f, SoundMap.LABYRINTH_LEVER_PRESSED));
		map.put("Images/note1", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_NOTE_1));
		map.put("Images/note2", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_NOTE_2));
		map.put("Images/note3", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_NOTE_3));
		map.put("Images/note4", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_NOTE_4));
		map.put("Images/note5", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_NOTE_5));
		map.put("Images/5x5small.png", new InventoryInfo(1.45f, 1.99f, 3, ""));
		map.put("Images/4x4small.png", new InventoryInfo(1.45f, 1.99f, 3, ""));
		map.put("Images/1-9small.png", new InventoryInfo(1.45f, 1.99f, 3, ""));
		map.put("Images/ladderdown.png", new InventoryInfo(-2.5f, .3f, 2.5f, SoundMap.LABYRINTH_LADDER));
		map.put("Images/ladderup.png", new InventoryInfo(0, .3f, 2.5f, SoundMap.LABYRINTH_LADDER));
		map.put("Images/sandstone.png", new InventoryInfo(0, -1.5f, 3.5f, SoundMap.LABYRINTH_OPEN_STONE_BOX));
		map.put("Images/stub.png", new InventoryInfo(0, 0, 2, SoundMap.LABYRINTH_OPEN_STUB));
		map.put("Images/volcano.png", new InventoryInfo(-.1f, 0, 2.5f, SoundMap.LABYRINTH_DOOR_STONE));
		map.put("Images/woodenbox", new InventoryInfo(0, 0, 3, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST));
		map.put("Images/woodenbox1", new InventoryInfo(0, 0, 3, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST));
		map.put("Images/riddle", new InventoryInfo(0, 0, 1, ""));
		map.put("Images/bomb.png", new InventoryInfo(1.5f, 1.99f, 3, SoundMap.LABYRINTH_SECRET));
		map.put("Images/stonebox", new InventoryInfo(0, 0, 3.5f, SoundMap.LABYRINTH_OPEN_STONE_BOX));
		map.put("Walls/prisondooru", new InventoryInfo(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS));
		map.put("Walls/prisondoord", new InventoryInfo(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS));
		map.put("Walls/airtemplestairdown", new InventoryInfo(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS));
		map.put("Walls/airtemplestairup", new InventoryInfo(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS));
		return map;
	}
	
	protected InventoryInfo getSettings() {
		return map.get(image);
	}
	
	/**
	 * This method activates the inventory. The given labyrinth can
	 * be used to make changes depending on which inventory is activated.
	 * This method is called when the player presses the cross button
	 * in front of this inventory.
	 * 
	 * @param labyrinth the labyrinth object that can be used to make 
	 * something happen when the player presses the cross button in front 
	 * of this inventory.
	 */
	public abstract void activate(Labyrinth labyrinth);
	
	/**
	 * This method sets the settings for the inventory textures. These
	 * settings is scale, y position and z offset.
	 */
	protected abstract void setSettings();
	
	/**
	 * This method parses the given string tokenizer and creates an inventory
	 * accordingly. It places that inventory at the correct place in the given
	 * graph and gets the status for the inventory from the database.
	 * 
	 * @param t the string tokenizer containing information about the inventory.
	 * @param map the labyrinth map where the inventory should be placed.
	 * @param labName the name of the labyrinth where the created inventory 
	 * should be placed.
	 * @return the inventory created.
	 */
	public static Inventory createInventory(
			StringTokenizer t, LabyrinthMap map, String labName) {
		String command = t.nextToken();
		String commandName = command.split("--")[0];
		int address = Integer.parseInt(t.nextToken());
		String dbName = Organizer.convert(labName + commandName + address);
		int status = Database.getStatusFor(dbName);
		logger.info("Setting db name " + dbName + " status " + status);
		Node n = map.getNode(address);
		int dir = Integer.parseInt(t.nextToken());
		dir = Values.getCounterAngle(dir);
		String token = t.nextToken();
		String image = t.nextToken();
		Inventory inv = null;
		if (command.equals("chest")) {
			String con = t.nextToken();
			int contentType = Integer.parseInt(con);
			String contentName = t.nextToken();
			int contentSize = t.countTokens();
			String[] info = new String[contentSize];
			for (int i = 0; i < contentSize; i++) {
				info[i] = t.nextToken();
			}
			inv = new Chest(
					n, dir, Integer.parseInt(token), image, 
					contentType, contentName, info, status);
		} else if (command.equals("riddle")) {
			String name = t.nextToken();
			String riddleClass = t.nextToken();
			Inventory[] hinders = getHinders(t, map);
			inv = new Riddle(n, dir, name, image, status, riddleClass, hinders);
		} else if (command.equals("floorButton")) {
			Inventory[] hinders = getHinders(t, map);
			inv = new FloorButton(n, dir, Integer.parseInt(token), image, status, hinders);
		} else if (command.equals("button")) {
			Inventory[] hinders = getHinders(t, map);
			inv = new Button(n, dir, Integer.parseInt(token), image, status, hinders);
		} else if (command.equals("iceButton")) {
			String sound = t.nextToken().replace("_", " ");
			Inventory[] hinders = getHinders(t, map);
			inv = new IceButton(n, dir, Integer.parseInt(token), image, status, hinders, sound);
		} else if (command.equals("aegisComboButton")) {
			int imageNr = Integer.parseInt(t.nextToken());
			int nr = Integer.parseInt(t.nextToken());
			ComboButton[] buttons = new ComboButton[nr];
			for (int i = 0; i < buttons.length; i++) {
				String name = Organizer.convert(t.nextToken());
				buttons[i] = (ComboButton) map.getInventory(name);
			}
			HinderDoor openDoor = null;
			if (t.hasMoreTokens()) {
				String doorToOpen = Organizer.convert(t.nextToken());
				openDoor = (HinderDoor) map.getInventory(doorToOpen);
			}
			AegisComboButton combo = new AegisComboButton(
					n, dir, Integer.parseInt(token), image, status, buttons, openDoor, imageNr);
			inv = combo;
		} else if (command.equals("iceComboButton")) {
			int imageNr = Integer.parseInt(t.nextToken());
			String sound = t.nextToken().replace("_", " ");
			int nr = Integer.parseInt(t.nextToken());
			ComboButton[] buttons = new ComboButton[nr];
			for (int i = 0; i < buttons.length; i++) {
				String name = Organizer.convert(t.nextToken());
				buttons[i] = (ComboButton) map.getInventory(name);
			}
			HinderDoor openDoor = null;
			if (t.hasMoreTokens()) {
				String doorToOpen = Organizer.convert(t.nextToken());
				openDoor = (HinderDoor) map.getInventory(doorToOpen);
			}
			IceComboButton combo = new IceComboButton(
					n, dir, Integer.parseInt(token), image, status, 
					buttons, openDoor, imageNr, sound);
			inv = combo;
		} else if (command.startsWith("door")) {
			// token is used as openroad
			// image is used as nextPlace
			Door d = new Door(n, dir, token, image, status, t);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("triggerDoor")) {
			// token is used as openroad
			// image is used as nextPlace
			TriggerDoor d = new TriggerDoor(n, dir, token, image, status, t);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("ladderDoor")) {
			LadderDoor.goingUp = Boolean.parseBoolean(t.nextToken());
			String next = t.nextToken();
			inv = new LadderDoor(n, dir, token, image, status, t, next);
		} else if (command.equals("ifDoor")) {
			IfDoor d = new IfDoor(n, dir, token, image, status, t);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("hinderDoor")) {
			String nextPlace = t.nextToken();
			int vStart = -1;
			if (t.hasMoreTokens()) {
				vStart = Integer.parseInt(t.nextToken());
			}
			AbstractDoor d = new HinderDoor(
					n, dir, Integer.parseInt(token), image,
					status, nextPlace, vStart);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("hiddenHinderDoor")) {
			String nextPlace = t.nextToken();
			int vStart = -1;
			if (t.hasMoreTokens()) {
				vStart = Integer.parseInt(t.nextToken());
			}
			AbstractDoor d = new HiddenHinderDoor(
					n, dir, Integer.parseInt(token), image,
					status, nextPlace, vStart);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("riddleDoor")) {
			String nextPlace = t.nextToken();
			int vStart = -1;
			if (t.hasMoreTokens()) {
				vStart = Integer.parseInt(t.nextToken());
			}
			AbstractDoor d = new RiddleDoor(
					n, dir, Integer.parseInt(token), image,
					status, nextPlace, vStart);
			if (command.contains("--")) {
				d.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = d;
		} else if (command.startsWith("addDoor")) {
			String nextPlace = t.nextToken();
			int openStatus = Integer.parseInt(t.nextToken());
			int vStart = -1;
			if (t.hasMoreTokens()) {
				vStart = Integer.parseInt(t.nextToken());
			}
			AdditiveHinderDoor add = new AdditiveHinderDoor(
					n, dir, Integer.parseInt(token), image,
					status, nextPlace, vStart);
			add.setOpenStatus(openStatus);
			if (command.contains("--")) {
				add.setGoingUp(command.split("--")[1].equals("up"));
			}
			inv = add;
		} else if (command.equals("bomb")) {
			inv = new MissionBomb(n, dir, 1, image, status, t);
		} else if (command.equals("villager")) {
			inv = new Villager(n, dir, 1, image, status, t);
		} else if (command.equals("simpleRiddle")) {
			inv = new SimpleRiddle(n, dir, 1, image, status, t);
		} else if (command.equals("missionChest")) {
			inv = new MissionChest(n, dir, 2, image, status, t);
		} else if (command.equals("boss")) {
			dbName = Organizer.convert(image);
			inv = new Boss(n, image);
		} else if (command.equals("save")) {
			inv = new Save(n, dir);
		}
		if (inv != null) {
			inv.setDatabaseName(dbName);
			inv.checkHaveBeen();
		} else {
			logger.log(Level.FINE, "The inventory " + dbName + " is null! exiting...");
			System.exit(-1);
		}
		System.out.println("N " + dbName + " " + n.getAddress());
		n.setInventory(inv);
		return inv;
	}

	private static Inventory[] getHinders(StringTokenizer t, LabyrinthMap map) {
		Inventory[] hinders = new Inventory[t.countTokens()];
		for (int i = 0; t.hasMoreTokens(); i++) {
			String name = Organizer.convert(t.nextToken());
			hinders[i] = map.getInventory(name);
			if (hinders[i] == null) {
				hinders[i] = new DummyDoor(name);
			}
		}
		return hinders;
	}

	public void updateStatus() {
		status = Database.getStatusFor(dataBaseName);
		if (status == -1) {
			status = 0;
			Database.addStatus(dataBaseName, status);
		}
	}
	
	public void arrive(Labyrinth lab) {
		// Override for effect
	}
	
	public void setHaveBeen() {
		Database.addStatus(dataBaseName + "havebeenin", 1);
		haveBeenIn = true;
	}
	
	public void setHaveBeen(String lastNodesName) {
		setHaveBeen();
	}
	
	public void checkHaveBeen() {
		haveBeenIn = Database.getStatusFor(dataBaseName + "havebeenin") == 1;
	}
	
	public boolean hasBeenIn() {
		return haveBeenIn;
	}
	
	public abstract boolean isDirectedTowards(int dir);
	public abstract boolean isPassable(int dir);
	public abstract boolean isPassableOnThis(int dir);
	public abstract String getMapImage();
	public abstract boolean shouldDrawWhenOnlySeen();
	
	public void drawTopLayer(Graphics g) {}
	
	public void drawInMap(Graphics g, float x, float y, int angle) {
		String s = getMapImage();
		if (s != null) {
			Texture tex = ImageHandler.getTexture(s).getTexture();
			if (tex != null) {
				GL2 gl = Graphics.gl2;
				gl.glPushMatrix();
				gl.glTranslatef(x, y, 0);
				gl.glRotatef(-angle, 0, 0, 1);
				Utils3D.draw3D(g, tex, 0, 0, 0, .1f);
				gl.glPopMatrix();
			}
		}
	}
	
	public int compareTo(Inventory i) {
		return ((i.useMaterial() ? 1 : 0) <= (useMaterial() ? 1 : 0)) ? 1 : -1;
	}
	
	public boolean useMaterial() {
		return false;
	}
	
	public static class InventoryInfo {
		private float height;
		private float zOffset;
		private float scale;
		private String soundEffect;
		
		public InventoryInfo(float height, float zOffset, float scale, String soundEffect) {
			this.height = height;
			this.zOffset = zOffset;
			this.scale = scale;
			this.soundEffect = soundEffect;
		}

		public float getHeightOffset() {
			return height;
		}

		public float getZOffset() {
			return zOffset;
		}

		public float getScale() {
			return scale;
		}

		public String getSoundEffect() {
			return soundEffect;
		}

		public boolean hasSoundEffect() {
			return soundEffect != null;
		}
	}
}
