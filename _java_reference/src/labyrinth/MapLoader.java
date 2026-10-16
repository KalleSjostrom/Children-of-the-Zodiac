package labyrinth;

import info.LabyrinthMap;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import labyrinth.inventory.Door;
import labyrinth.inventory.Inventory;

import organizer.AbstractMapLoader;
import organizer.Organizer;

import villages.villageStory.Parser;
import battle.enemy.BattleEnemy;

public class MapLoader extends AbstractMapLoader {
	
	public static final int FOG = 0;
	public static final int LIGHT_0 = 1;
	public static final int LIGHT_1 = 2;
	public static final int MATERIAL = 3;
	public static final int INV_MATERIAL = 4;
	public static final int SKY = 5;
	public static final int SETTING_VALUE_SIZE = 6;
	public static final int USE_CARPET_FLOOR = 6;
	public static final int USE_PILLAR_WALLS = 7;
	public static final int USE_SNOW = 8;
	public static final int USE_FIRE = 9;
	public static final int USE_RAIN = 10;
	public static final int SETTING_SIZE = 11;
	
	public static final int FLOOR = 0;
	public static final int WALL = 1;
	public static final int ROOF = 2;
	public static final int CARPET_FLOOR = 3;
	public static final int PILLAR_WALLS = 4;
	
	private String labyrinthName;
	private ArrayList<String> mission;
	private LabyrinthMap map;
	private int[] stepsToBattle = new int[]{13, 20};
	private float[][] settingValues = new float[SETTING_VALUE_SIZE][];
	private boolean[] settings;
	
	private ArrayList<LabyrinthTexture> textures;
	private HashMap<String, Integer> fog = getFogMap();
	private HashMap<String, Integer> light = getLightMap();
	private HashMap<String, Integer> material = getMaterialMap();
	private HashMap<String, Integer> sky = getSkyMap();
	private String[] battleMusic = new String[]{"Battle", "Fight the Demons"};
	public static int[][] textureNorm;
	
	public MapLoader(String name) {
		stepsToBattle[1] -= stepsToBattle[0];
		labyrinthName = name;
		Door.reset();
		map = new LabyrinthMap();
		textures = new ArrayList<LabyrinthTexture>();
		settings = new boolean[SETTING_SIZE];
		textureNorm = new int[5][2];
		parseFile(name);
	}
	
	public static final int FOG_RED = 0;
	public static final int FOG_GREEN = 1;
	public static final int FOG_BLUE = 2;
	public static final int FOG_ALPHA = 3;
	public static final int FOG_DENSITY = 4;
	public static final int FOG_START = 5;
	public static final int FOG_END = 6;
	
	private HashMap<String, Integer> getFogMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("red", FOG_RED);
		map.put("green", FOG_GREEN);
		map.put("blue", FOG_BLUE);
		map.put("alpha", FOG_ALPHA);
		map.put("density", FOG_DENSITY);
		map.put("start", FOG_START);
		map.put("end", FOG_END);
		return map;
	}
	
	public static final int LIGHT_AMBIENT = 0;
	public static final int LIGHT_DIFFUSE = 4;
	public static final int LIGHT_SPECULAR = 8;
	public static final int LIGHT_POSITION = 12;
	public static final int LIGHT_ATTENUATION = 16;
	
	private HashMap<String, Integer> getLightMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("ambient", LIGHT_AMBIENT);
		map.put("diffuse", LIGHT_DIFFUSE);
		map.put("specular", LIGHT_SPECULAR);
		map.put("position", LIGHT_POSITION);
		map.put("attenuation", LIGHT_ATTENUATION);
		return map;
	}
	
	public static final int MATERIAL_AMBIENT = 0;
	public static final int MATERIAL_DIFFUSE = 4;
	public static final int MATERIAL_SPECULAR = 8;
	public static final int MATERIAL_EMISSION = 12;
	public static final int MATERIAL_SHININESS = 16;
	
	private HashMap<String, Integer> getMaterialMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("ambient", MATERIAL_AMBIENT);
		map.put("diffuse", MATERIAL_DIFFUSE);
		map.put("specular", MATERIAL_SPECULAR);
		map.put("emission", MATERIAL_EMISSION);
		map.put("shininess", MATERIAL_SHININESS);
		return map;
	}
	
	public static final int SKY_TOP_COLOR = 0;
	public static final int SKY_BOTTOM_COLOR = 4;
	
	private HashMap<String, Integer> getSkyMap() {
		HashMap<String, Integer> map = new HashMap<String, Integer>();
		map.put("top", SKY_TOP_COLOR);
		map.put("bottom", SKY_BOTTOM_COLOR);
		return map;
	}

	protected void parseFile(String filename) {
		super.parseFile(Values.LabyrinthMaps, filename);
	}
	
	public LabyrinthMap getMap() {
		return map;
	}
	
	/**
	 * @inheritDoc
	 */
	protected void executeCommand(String command, StringTokenizer t) {
		if (command.equals("dir")) {
			int source = Integer.parseInt(t.nextToken());
			int dir = Integer.parseInt(t.nextToken());
			int destination = Integer.parseInt(t.nextToken());
			InsertNodes(source, dir, destination);
		} else if (command.equals("mapEnd")) {
			sort();
		} else if (command.equals("size")) {
			map.setSize(Integer.parseInt(t.nextToken()));
		} else if (command.equals("battleMusic")) {
			battleMusic[0] = Organizer.convertKeepCase(t.nextToken());
			if (t.hasMoreTokens()) {
				battleMusic[1] = Organizer.convertKeepCase(t.nextToken());
			}
		} else if (command.equals("mapPos")) {
			int[] mapPos = new int[2];
			mapPos[0] = Integer.parseInt(t.nextToken());
			mapPos[1] = Integer.parseInt(t.nextToken());
			map.setMapPos(mapPos);
		} else if (command.equals("inv")) {
			Inventory i = Inventory.createInventory(t, map, labyrinthName);
			if (i != null) {
				map.putInventory(i.getDatabaseName(), i);
			}
		} else if (command.equals("mission")) {
			mission = new ArrayList<String>();
			mission.add(t.nextToken());
			mission.add(Organizer.convert(t.nextToken()));
			while (t.hasMoreTokens()) {
				String[] args = Parser.getArgument(t.nextToken());
				if (args[0].equals("trigger")) {
					String[] val = Parser.getText(t, args[1]);
					String dbName = val[0];
					int value = Integer.parseInt(val[1]);
					String s = args[0] + "&&" + dbName + "&&" + value;
					mission.add(Organizer.convert(s));
				} else if (args[0].equals("dialog")) {
					String[] val = Parser.getText(t, args[1]);
					mission.add(args[0] + "&&" + val[0] + "&&" + val[1]);
				} else if (args[0].equals("extranext")) {
					String[] val = Parser.getText(t, args[1]);
					mission.add(args[0] + "&&" + val[0] + "&&" + val[1]);
				}
			}
		} else if (command.equals("steps")) {
			stepsToBattle = new int[2];
			stepsToBattle[0] = Integer.parseInt(t.nextToken()); // 7
			stepsToBattle[1] = Integer.parseInt(t.nextToken()) - stepsToBattle[0]; // 16 - 7 = 9
			// 4.5 + 7 = 11.5
		} else if (command.equals("fog")) {
			settings[FOG] = true;
			float[] fogSettings = new float[7];
			while (t.hasMoreTokens()) {
				String[] s = t.nextToken().split("=");
				String key = s[0];
				int index = fog.get(key);
				fogSettings[index] = Float.parseFloat(s[1]);
			}
			settingValues[FOG] = fogSettings;
		} else if (command.equals("light0")) {
			addSettings(LIGHT_0, t, light);
		} else if (command.equals("light1")) {
			addSettings(LIGHT_1, t, light);
		} else if (command.equals("material")) {
			addSettings(MATERIAL, t, material);
		} else if (command.equals("invMaterial")) {
			addSettings(INV_MATERIAL, t, material);
		} else if (command.equals("sky")) {
			addSettings(SKY, t, sky);
		} else if (command.equals("enemyColor")) {
			float[] color = new float[4];
			color[0] = Float.parseFloat(t.nextToken());
			color[1] = Float.parseFloat(t.nextToken());
			color[2] = Float.parseFloat(t.nextToken());
			color[3] = Float.parseFloat(t.nextToken());
			BattleEnemy.setColor(color);
		} else if (command.equals("useSnow")) {
			settings[USE_SNOW] = true;
		} else if (command.equals("useFire")) {
			settings[USE_FIRE] = true;
		} else if (command.equals("useRain")) {
			settings[USE_RAIN] = true;
		} else if (command.equals("floorTex")) {
			addTexture("Floors/" + t.nextToken());
		} else if (command.equals("SfloorTex")) {
			settings[USE_CARPET_FLOOR] = true;
			String s = t.nextToken();
			textureNorm[CARPET_FLOOR][0] = Integer.parseInt(t.nextToken());
			textureNorm[CARPET_FLOOR][1] = textureNorm[CARPET_FLOOR][0] + 5;
			for (int i = 0; i < 5; i++) {
				String tex = s.replace(".jpg", i + ".jpg");
				addTexture("Floors/" + tex);
			}
		} else if (command.equals("roofTex")) {
			addTexture("Roofs/" + t.nextToken());
		} else if (command.equals("wallTex")) {
			addTexture("Walls/" + t.nextToken());
		} else if (command.equals("SwallTex")) {
			settings[USE_PILLAR_WALLS] = true;
			String s = t.nextToken();
			textureNorm[PILLAR_WALLS][0] = Integer.parseInt(t.nextToken());
			textureNorm[PILLAR_WALLS][1] = textureNorm[PILLAR_WALLS][0] + 4;
			for (int i = 0; i < 4; i++) {
				String tex = s.replace(".png", i + ".png");
				addTexture("Walls/" + tex);
			}
		} else if (command.equals("wall")) {
			int nr = Integer.parseInt(t.nextToken());
			int addr = Integer.parseInt(t.nextToken());
			int dir = Integer.parseInt(t.nextToken());
			dir = Values.getCounterAngle(dir);
			map.getNode(addr).setWall(dir, nr);
		} else if (command.equals("roof") || command.equals("floor")) {
			int nr = Integer.parseInt(t.nextToken());
			int addr = Integer.parseInt(t.nextToken());
			if (command.equals("roof")) {
				map.getNode(addr).setRoof(nr);
			} else {
				map.getNode(addr).setFloor(false, nr);
			}
		} else if (command.equals("normal")) {
			String kind = t.nextToken();
			if (kind.equals("floor")) {
				textureNorm[FLOOR][0] = Integer.parseInt(t.nextToken());
				textureNorm[FLOOR][1] = Integer.parseInt(t.nextToken());
			} else if (kind.equals("wall")) {
				textureNorm[WALL][0] = Integer.parseInt(t.nextToken());
				textureNorm[WALL][1] = Integer.parseInt(t.nextToken());
			} else if (kind.equals("roof")) {
				textureNorm[ROOF][0] = Integer.parseInt(t.nextToken());
				textureNorm[ROOF][1] = Integer.parseInt(t.nextToken());
			}
		}
	}
	
	private void addSettings(int settingIndex, StringTokenizer t, HashMap<String, Integer> map) {
		settings[settingIndex] = true;
		float[] light = new float[19];
		while (t.hasMoreTokens()) {
			String[] s = t.nextToken().split("=");
			String key = s[0];
			int index = map.get(key);
			String[] args = s[1].split(";");
			for (int i = 0; i < args.length; i++) {
				light[index + i] = Float.parseFloat(args[i]);
			}
		}
		settingValues[settingIndex] = light;
	}

	/**
	 * Adds the a new labyrinth texture with the given path to the 
	 * hash map of textures.
	 * 
	 * @param path the path of the texture to add.
	 */
	private void addTexture(String path) {
		LabyrinthTexture tex = new LabyrinthTexture(path);
		textures.add(tex);
	}

	/**
	 * This method creates the necessary nodes and binds them together.
	 * It takes two addresses and one direction, it then checks if the nodes
	 * have been created already, if not this method creates the nodes 
	 * and adds it to the node list. It then adds the destination node
	 * to the source nodes list of neighbors, with the given direction and
	 * vice versa with the exception that the opposite direction 
	 * is used instead.
	 * 
	 * @param source the address of the source node to be created and 
	 * bind together with the destination node.
	 * @param direction the direction between the source and the 
	 * destination node.
	 * @param destination the address of the destination node to be created and
	 * bind together with the source node.
	 */
	private void InsertNodes(int source, int direction, int destination) {
		Node sourceNode;
		Node destNode;
		sourceNode = map.getNode(source);
		if (sourceNode == null) {
			sourceNode = new Node(source);
			map.put(source, sourceNode);
		}
		destNode = map.getNode(destination);
		if (destNode == null) {
			destNode = new Node(destination);
			map.put(destination, destNode);
		}
		sourceNode.putNeighbours(Values.getCounterAngle(direction), destNode);
		destNode.putNeighbours(direction, sourceNode);
	}
	
	private void sort() {
		Node n;
		HashMap<Integer, Node> nodes = map.getNodes();
		Iterator<Integer> it = nodes.keySet().iterator();
		while (it.hasNext()) {
			int addr = it.next();
			n = nodes.get(addr);
			int tex = textureNorm[settings[USE_PILLAR_WALLS] ? PILLAR_WALLS : WALL][0];
			n.setWalls(settings[USE_PILLAR_WALLS], tex);
			tex = textureNorm[settings[USE_CARPET_FLOOR] ? CARPET_FLOOR : FLOOR][0];
			n.setFloor(settings[USE_CARPET_FLOOR], tex);
			n.setRoof(textureNorm[ROOF][0]);
		}
	}
	
	/**
	 * Creates, initializes and returns a new LabyrinthRenderer.
	 * 
	 * @return a new LabyrinthRenderer.
	 */
	public LabyrinthRenderer getRenderer() {
		LabyrinthRenderer renderer = new LabyrinthRenderer(textures);
		renderer.setMap(map);
		renderer.setSettings(settings, settingValues);
		return renderer;
	}
	
	public int[] getStepsToBattle() {
		return stepsToBattle;
	}

	public ArrayList<String> getMission() {
		return mission;
	}

	public String[] getBattleMusic() {
		return battleMusic;
	}
}
