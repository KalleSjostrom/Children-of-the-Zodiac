/*
 * Classname: VillageLoader.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/01/2008
 */
package villages;

import graphics.DoubleBackground;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import java.util.logging.*;
import organizer.AbstractMapLoader;
import organizer.MenuStarter;
import organizer.Organizer;

import sprite.Sprite;
import store.Door;
import villages.utils.AnimatedObjects;
import villages.utils.Dialog;
import villages.utils.Loot;
import villages.utils.ObstacleHandler;
import villages.utils.Player;
import villages.utils.Sign;
import bodies.Vector3f;
import bodies.system.ParticleSystem;
import bodies.system.SystemLoader;

/**
 * This class loads all images and creates the animations and input mapping. It
 * has three subclasses: Dialog, Background and MapLoader.
 * 
 * @author Kalle Sjöström
 * @version 0.7.0 - 19 Jan 2008
 */
public abstract class VillageLoader extends MenuStarter {

	public static int staticStartPos = 0;

	protected Player player;
	protected Dialog dialog = Dialog.getDialog();
	protected HashMap<Integer, Sprite> sprites = new HashMap<Integer, Sprite>();
	protected HashMap<String, HashMap<String, String>> buildingInfo = new HashMap<String, HashMap<String, String>>();
	protected ArrayList<Loot> loots = new ArrayList<Loot>();
	protected ArrayList<Door> doors = new ArrayList<Door>();
	protected ArrayList<Door> holeDoors = new ArrayList<Door>();
	protected ArrayList<Sign> signs = new ArrayList<Sign>();
	protected DoubleBackground background;
	protected String folderName;
	protected String storeName;
	protected String villageName;
	protected long startTime;
	protected int backgroundWidth;
	protected int backgroundHeight;
	private int actualHeight;
	private int actualWidth;
	protected ObstacleHandler obstacleHandler;
	protected int[] BACK_POS;
	private int startPos;
	protected boolean inside = false;

	private static Logger logger = Logger.getLogger("VillageLoader");

	/**
	 * This method initializes the village loader and loads the village. It gets
	 * the map name from the given information map and sends it to the map
	 * loader of type MapLoader().
	 * 
	 * @param info
	 *            he information to use when loading the village.
	 */
	public void init(HashMap<String, String> info) {
		logger.log(Level.FINE, "Static start " + staticStartPos);
		startPos = staticStartPos;
		staticStartPos = 0;

		HashMap<String, String> newInfo = new HashMap<String, String>();
		newInfo.putAll(info);
		/*
		 * if (!Values.DAY) { String m = newInfo.get("music"); if (!m.contains(
		 * "at Night")) { m += "at Night"; } newInfo.put("music", m); }
		 */
		newInfo.put("landname", "land" + newInfo.get("name"));
		load(newInfo);
		super.init(newInfo, Values.DETECT_ALL);
	}

	/**
	 * This method loads the information in the given map.
	 * 
	 * @param info
	 *            the information map.
	 */
	public void load(HashMap<String, String> info) {
		String map = info.get("name");
		String folder = map + "/";
		int status = Database.getStatusFor(map);
		status = status < 0 ? 0 : status;
		String time = info.get("time");
		if (time != null && time.equals("night")) {
			map += " at Night - " + status + ".vil";
		} else {
			map += " - " + status + ".vil";
		}
		/*
		 * } else { map += " at Night - " + status + ".vil"; }
		 */
		infoMap = info;
		try {
			new MapLoader().parseFile(folder + map);
		} catch (Exception e) {
			e.printStackTrace();
		}
		startTime = System.currentTimeMillis();
	}

	/**
	 * Gets the villager with the given name. It is used to execute triggers on
	 * a villager with a certain name.
	 * 
	 * @param name
	 *            the name of the villager.
	 * @return the villager with the given name.
	 */
	protected Villager getVillager(String name) {
		Iterator<Integer> it = sprites.keySet().iterator();
		while (it.hasNext()) {
			Sprite as = sprites.get(it.next());
			if (as instanceof Villager) {
				Villager v = (Villager) as;
				if (v.name.equalsIgnoreCase(name)) {
					return v;
				}
			}
		}
		return null;
	}

	/**
	 * This class loads the information about the village from a *.vil file
	 * 
	 * @author Kalle Sjöström
	 * @version 0.7.0 - 13 May 2008
	 */
	private class MapLoader extends AbstractMapLoader {

		private Sign sign;
		private boolean nightLayer;
		private String extraName = null;
		private String backgroundFolder;
		private String villagerFolder;

		/**
		 * This method parses the file with the given filename in the villages
		 * map folder. (Values.VillageMaps)
		 * 
		 * @param filename
		 *            the filename of the map to load
		 */
		protected void parseFile(String filename) {
			parseFile(Values.VillageMaps, filename);
		}

		/**
		 * @inheritDoc
		 */
		public void executeCommand(String command, StringTokenizer tok) {
			if (command.equals("o")) {
				int x = Integer.parseInt(tok.nextToken());
				int y = Integer.parseInt(tok.nextToken());
				int x2 = Integer.parseInt(tok.nextToken());
				int y2 = Integer.parseInt(tok.nextToken());
				obstacleHandler.addObstacle(Values.createNormalPoint(x, y), Values.createNormalPoint(x2, y2),
						player.getHeight(), player.getWidth());
			} else if (command.equals("inside")) {
				inside = true;
			} else if (command.startsWith("start")) {
				String s = command.replace("start", "");
				if (!s.equals("")) {
					int sp = Integer.parseInt(s);
					if (sp == startPos) {
						initPlayerPos(tok);
					}
				} else if (player == null) {
					initPlayerPos(tok);
				}
			} else if (command.contains("landname")) {
				infoMap.put("landname", "land" + tok.nextToken());
			} else if (command.startsWith("lootL")) {
				if (loots.size() > 0) {
					Loot l = loots.get(loots.size() - 1);
					l.addString(lastLine.replace("lootLine ", ""));
				}
			} else if (command.equals("loot")) {
				Loot l = Loot.getLoot(tok, villageName);
				if (l != null) {
					loots.add(l);
				}
			} else if (command.equals("door")) {
				doors.add(Door.getDoor(tok, villageName));
			} else if (command.equals("wind")) {
				String wind = tok.nextToken();
				String[] array = wind.split(";");
				Vector3f windForce = new Vector3f();
				for (int i = 0; i < 3; i++) {
					windForce.set(i, Float.parseFloat(array[i]));
				}
				float turbulence = Float.parseFloat(tok.nextToken());
				ParticleSystem.setWind(windForce, turbulence);
			} else if (command.equals("holeDoor")) {
				holeDoors.add(Door.getDoor(tok, villageName));
			} else if (command.equals("doorSignFl")) {
				Sign s = new Sign();
				s.addText(lastLine.replace("doorSignFl", ""));
				doors.get(doors.size() - 1).setSign(s);
			} else if (command.equals("doorSignSl")) {
				Sign s = doors.get(doors.size() - 1).getSign();
				s.addText(lastLine.replace("doorSignSl", ""));
			} else if (command.equals("holeDoorSignFl")) {
				Sign s = new Sign();
				s.addText(lastLine.replace("holeDoorSignFl", ""));
				holeDoors.get(holeDoors.size() - 1).setSign(s);
			} else if (command.equals("holeDoorSignSl")) {
				Sign s = holeDoors.get(holeDoors.size() - 1).getSign();
				s.addText(lastLine.replace("holeDoorSignSl", ""));
			} else if (command.equals("sign")) {
				int x = Integer.parseInt(tok.nextToken());
				int y = Integer.parseInt(tok.nextToken());
				int w = -1;
				if (tok.hasMoreTokens()) {
					w = Integer.parseInt(tok.nextToken());
				}
				ArrayList<Integer> dirs = new ArrayList<Integer>();
				if (tok.hasMoreTokens()) {
					String[] ds = tok.nextToken().split(";");
					for (String s : ds) {
						dirs.add(Integer.parseInt(s));
					}
				} else {
					dirs.add(0);
				}
				sign = new Sign(x, y, w, dirs);
			} else if (command.equals("signL")) {
				sign.addText(lastLine.replace("signL ", ""));
				signs.add(sign);
			} else if (command.equals("signL2")) {
				sign.addText(lastLine.replace("signL2 ", ""));
			} else if (command.equals("villager")) {
				String name = tok.nextToken().replace("_", " ");
				int status = Database.getStatusFor(name);
				if (status == -1) {
					logger.log(Level.WARNING, "Could not find: " + name + " in the database.");
					logger.info("Using default value!");
					status = 1;
					Database.addStatus(name, status);
				}
				logger.log(Level.FINE, "Status " + name + " " + status);
				boolean found = false;
				boolean hadTokens = tok.hasMoreTokens();
				while (tok.hasMoreTokens() && !found) {
					found = Integer.parseInt(tok.nextToken()) == status;
				}
				if (!hadTokens || found) {
					Villager v = new Villager(name, villagerFolder, status);
					sprites.put(v.hashCode(), v);
				}
			} else if (command.equals("particlesystem")) {
				SystemLoader loader = SystemLoader.getLoader();
				while (tok.hasMoreTokens()) {
					String name = tok.nextToken();

					boolean villagerLayer = false;
					boolean activate = true;
					int layer = DoubleBackground.UPPER_LAYER;
					int activationStatus = -1;
					if (name.contains(":")) {
						String[] temp = name.split(":");
						name = temp[0];
						layer = Integer.parseInt(temp[1]);
						if (temp.length > 2) {
							activate = Boolean.parseBoolean(temp[2]);
						}
						if (temp.length > 3) {
							activationStatus = Integer.parseInt(temp[3]);
						}
						villagerLayer = layer == DoubleBackground.VILLAGER_LAYER;
					}

					ArrayList<ParticleSystem> system = loader.buildSystem(name);
					for (ParticleSystem p : system) {
						p.name = name;
						p.setActive(activate);
						p.setActivateStatus(activationStatus);
					}
					if (villagerLayer) {
						for (ParticleSystem p : system) {
							sprites.put(p.hashCode(), p);
							// background.addSystem(p, layer);
						}
					} else {
						for (ParticleSystem p : system) {
							background.addSystem(p, layer);
						}
					}
					for (ParticleSystem p : system) {
						// p.warmUp(1.0f / 60.0f);
					}
				}
			} else if (command.equals("background")) {
				folderName = tok.nextToken().replace("_", " ");
				logger.log(Level.FINE, "Folder " + folderName);
				if (folderName.contains("--")) {
					villageName = folderName.split("--")[0];
					backgroundFolder = villageName + folderName.split("--")[1];
					logger.log(Level.FINE, "Village name " + villageName);
					logger.log(Level.FINE, "Back " + backgroundFolder);
				} else {
					villageName = folderName;
					backgroundFolder = folderName;
				}
				nightLayer = !Boolean.parseBoolean(tok.nextToken()); // stands for day
				villagerFolder = villageName;
			} else if (command.equals("villagerFolder")) {
				villagerFolder = Organizer.convertKeepCase(tok.nextToken());
			} else if (command.equals("back")) {
				backgroundWidth = Integer.parseInt(tok.nextToken());
				backgroundHeight = Integer.parseInt(tok.nextToken());
				actualWidth = backgroundWidth;
				actualHeight = backgroundHeight;
				if (tok.hasMoreTokens()) {
					String s = tok.nextToken();
					if (s.contains("as=")) {
						s = s.replace("as=", "");
						String[] sa = s.split(":");
						actualWidth = Integer.parseInt(sa[0]);
						actualHeight = Integer.parseInt(sa[1]);
					}
				}
				background = new DoubleBackground(backgroundWidth, backgroundHeight, actualWidth, actualHeight);
				background.init(backgroundFolder, villageName, nightLayer);
			} else if (command.equals("offset")) {
				int width = Integer.parseInt(tok.nextToken());
				int height = Integer.parseInt(tok.nextToken());
				background.setOffset(width, height);
			} else if (command.equals("music")) {
				infoMap.put("music", tok.nextToken());
			} else if (command.equals("building")) {
				HashMap<String, String> info = new HashMap<String, String>();
				String buildingName = tok.nextToken();
				info.put("storeName", buildingName);
				info.put("background", tok.nextToken());
				info.put("keeper", tok.nextToken());
				info.put("name", tok.nextToken().replace("_", " "));
				info.put("firstLine", tok.nextToken().replace("_", " "));
				String secondLine = Organizer.convertKeepCase(tok.nextToken());
				info.put("secondLine", secondLine);

				info.put("music", tok.nextToken().replace("_", " "));
				info.put("villageName", villageName);
				info.put("folderName", folderName);
				buildingInfo.put(buildingName, info);
			} else if (command.equals("animObj")) {
				String name = tok.nextToken();
				int x = Integer.parseInt(tok.nextToken());
				int y = Integer.parseInt(tok.nextToken());
				int[] pos = Values.createNormalPoint(x, y);
				int size = 4;
				if (tok.hasMoreTokens()) {
					size = Integer.parseInt(tok.nextToken());
				}
				AnimatedObjects ao = new AnimatedObjects(folderName, name, pos, size);
				sprites.put(ao.hashCode(), ao);
			}
		}

		/**
		 * Initiates the player and its positions. It also sets the position of
		 * the background.
		 * 
		 * @param tok
		 *            the tokenizer containing information.
		 */
		private void initPlayerPos(StringTokenizer tok) {
			int x = Integer.parseInt(tok.nextToken());
			int y = Integer.parseInt(tok.nextToken());
			int a = Integer.parseInt(tok.nextToken());
			BACK_POS = new int[] { backgroundHeight, backgroundWidth };
			float[] pos = Values.createNormalFloatPoint(x, y);
			if (obstacleHandler == null) {
				obstacleHandler = new ObstacleHandler(BACK_POS);
			}
			player = new Player(pos, a);

			int ox = Values.ORIGINAL_RESOLUTION[Values.X];
			int oy = Values.ORIGINAL_RESOLUTION[Values.Y];

			int hx = ox / 2;
			int hy = oy / 2;

			int backgroundX = x - hx;
			int backgroundY = y - hy;

			if (backgroundX < 0) {
				backgroundX = 0;
			} else if (backgroundX > backgroundWidth - ox) {
				backgroundX = backgroundWidth - ox;
			}

			if (backgroundY < 0) {
				backgroundY = 0;
			} else if (backgroundY > backgroundHeight - oy) {
				backgroundY = backgroundHeight - oy;
			}
			background.setPos(Values.X, -1 * backgroundX);
			background.setPos(Values.Y, -1 * backgroundY);
			backgroundHeight -= player.getHeight();
			backgroundWidth -= player.getWidth();
		}
	}
}
