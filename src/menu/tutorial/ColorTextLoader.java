package menu.tutorial;

import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;
import organizer.GameMode;

import villages.villageStory.Parser;

import menu.AbstractPage;
import bodies.Vector3f;

public class ColorTextLoader extends AbstractMapLoader {
	
	private Chapter currentChapter;
	private String title;
	private HashMap<Integer, Vector3f> currentMap;
	private HashMap<String, Vector3f> vectorVariables = new HashMap<String, Vector3f>();
	private HashMap<Integer, Chapter> book = new HashMap<Integer, Chapter>();
	private int x;
	private int y;
	
	public ColorTextLoader(int x, int y) {
		this.x = x;
		this.y = y;
	}
	
	@Override
	protected void parseFile(String filename) {
		super.parseFile(Values.Tutorials, filename);
	}
	
	@Override
	protected void executeCommand(String command, StringTokenizer t) {
		if (command.equals("title")) {
			String[] args = Parser.getArgument(t.nextToken());
			title = Parser.getText(t, args[1])[0];
		} else if (command.equals("newtext")) {
			currentChapter = new Chapter(x, y);
		} else if (command.equals("addRow")) {
			String[] args;
			boolean newpage = false;
			boolean usemap = false;
			int button = -1;
			int xoffset = 0;
			int yoffset = 0;
			int iconxoffset = 0;
			int iconyoffset = 0;
			float iconscale = 1;
			String[] temp = null;
			String iconName = null;
			Icon icon = null;
			
			while (t.hasMoreTokens()) {
				args = Parser.getArgument(t.nextToken());
				if (args[0].equals("newpage")) {
					newpage = Boolean.parseBoolean(args[1]);
				} else if (args[0].equals("text")) {
					temp = Parser.getText(t, args[1]);
				} else if (args[0].equals("usemap")) {
					usemap = Boolean.parseBoolean(args[1]);
				} else if (args[0].equals("button")) {
					button = getButton(args[1]);
					iconName = AbstractPage.BUTTON_ICONS[button];
				} else if (args[0].equals("xoffset")) {
					xoffset = Integer.parseInt(args[1]);
				} else if (args[0].equals("yoffset")) {
					yoffset = Integer.parseInt(args[1]);
				} else if (args[0].equals("icon")) {
					iconName = Values.res + args[1].replace("_", " ");
				} else if (args[0].equals("iconxoffset")) {
					iconxoffset = Integer.parseInt(args[1]);
				} else if (args[0].equals("iconyoffset")) {
					iconyoffset = Integer.parseInt(args[1]);
				} else if (args[0].equals("iconscale")) {
					iconscale = Float.parseFloat(args[1]);
				} 
			}
			if (iconName != null) {
				icon = new Icon(iconName, iconxoffset, iconyoffset, iconscale);
			}
			HashMap<Integer, Vector3f> map = usemap ? currentMap : null; 
			currentChapter.addRow(newpage, xoffset, yoffset, temp[0], map, icon);
		} else if (command.equals("putMap")) {
			if (currentMap == null) {
				currentMap = new HashMap<Integer, Vector3f>();
			}
			int index = 0;
			Vector3f vec = null;
			while (t.hasMoreTokens()) {
				String[] args = Parser.getArgument(t.nextToken());
				if (args[0].equals("vector")) {
					vec = vectorVariables.get(args[1]);
					if (vec == null) {
						String[] v = args[1].split(",");
						vec = new Vector3f(
								Float.parseFloat(v[0]), 
								Float.parseFloat(v[1]), 
								Float.parseFloat(v[2]));
					}
				} else if (args[0].equals("index")) {
					index = Integer.parseInt(args[1]);
				}
			}
			currentMap.put(index, vec);
		} else if (command.equals("newMap")) {
			currentMap = new HashMap<Integer, Vector3f>();
		} else if (command.equals("var")) {
			String name = null;
			String type = null;
			while (t.hasMoreTokens()) {
				String[] args = Parser.getArgument(t.nextToken());
				if (args[0].equals("type")) {
					type = args[1];
				} else if (args[0].equals("name")) {
					name = args[1];
				} else if (args[0].equals("value")) {
					if (type.equals("vector")) {
						String[] v = args[1].split(",");
						Vector3f vec = new Vector3f(
								Float.parseFloat(v[0]), 
								Float.parseFloat(v[1]), 
								Float.parseFloat(v[2]));
						vectorVariables.put(name, vec);
					}
//				} else if (args[0].equals("index")) {
//					index = Integer.parseInt(args[1]);
//				}
				}
			}
		} else if (command.equals("put")) {
			int turn = 0;
			while (t.hasMoreTokens()) {
				String[] args = Parser.getArgument(t.nextToken());
				if (args[0].equals("turn")) {
					turn = Integer.parseInt(args[1]);
				}
			}
			book.put(turn, currentChapter);
		}
	}
	
	private int getButton(String button) {
		int b = -1;
		if (button.equals("leftright")) {
			b = GameMode.LEFT_RIGHT;
		} else if (button.equals("cross")) {
			b = GameMode.CROSS;
		} else if (button.equals("circle")) {
			b = GameMode.CIRCLE;
		} else if (button.equals("triangle")) {
			b = GameMode.TRIANGLE;
		} else if (button.equals("square")) {
			b = GameMode.SQUARE;
		} else if (button.equals("l1r1")) {
			b = GameMode.L1R1;
		} else if (button.equals("l2r2")) {
			b = GameMode.L2R2;
		} else if (button.equals("r1")) {
			b = GameMode.R1;
		} else if (button.equals("r2")) {
			b = GameMode.R2;
		} else if (button.equals("updown")) {
			b = GameMode.UP_DOWN;
		}
		return b;
	}
	
	public Chapter getCurrentChapter() {
		return currentChapter;
	}
	
	public HashMap<Integer, Chapter> getBook() {
		return book;
	}

	public String getTitle() {
		return title;
	}

	public ArrayList<Row> getFirstPage() {
		return book.get(0).getPage(0);
	}
}
