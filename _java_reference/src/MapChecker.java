

import info.Values;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import organizer.Organizer;

import villages.villageStory.Parser;

public class MapChecker {
	
	private String current;
	private int counter;
	private HashMap<String, Door> map = new HashMap<String, Door>();
	private boolean comment;
	
	public static void main(String[] args) {
		new MapChecker();	
	}
	
	public MapChecker() {
		File[] files = new File(Values.LabyrinthMaps).listFiles();
		for (File f : files) {
			try {
				if (f.isFile() && f.getName().endsWith(".map")) {
					BufferedReader reader = new BufferedReader(new FileReader(f));
					current = f.getName().toLowerCase().replace(" ", "_").replace(".map", "");
					counter = 0;
					String line = "";
					Parser.reset();
					while (line != null) {
						line = reader.readLine();
						if (line != null) {
							line = line.trim();
							if (!line.equals("") && !line.startsWith("#")) {
								parseLine(line);
							}
						}
					}
					reader.close();
				}
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		Iterator<Door> it = map.values().iterator();
		while (it.hasNext()) {
			Door d = it.next();
			if (!map.containsKey(d.leadsTo)) {
				System.out.println(d);
			}
		}
		it = map.values().iterator();
		Object[] os = map.keySet().toArray();
		Arrays.sort(os);
		for (Object o : os) {
			String s = (String) o;
			if (!map.containsKey(s)) {
				System.out.println("S " + s);
			}
		}
	}
	
	private void parseLine(String line) {
		StringTokenizer tokenizer = new StringTokenizer(line);
		boolean lineOk = !line.equals("") && !line.equals(" ") && !line.equals("\t");
		if (lineOk && tokenizer.hasMoreTokens()) {
			String command = tokenizer.nextToken();
			if (command.equals("/*")) {
				comment = true;
			}
			if (!comment && !command.equals("#")) {
				executeCommand(command, tokenizer);
			}
			if (command.equals("*/")) {
				comment = false;
			}
		}
	}

	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("inv")) {
			String s = tokenizer.nextToken();
			if (s.equals("door") || s.equals("hinderDoor") || s.equals("ladderDoor")) {
				while (tokenizer.hasMoreTokens()) {
					command = tokenizer.nextToken();
				}
				command = Organizer.convert(command);
				System.out.println("Command " + command);
				if (!command.startsWith("land") && !command.equals("_")) {
					Door door = new Door(current, command, counter);
					Door d = map.put(door.from, door);
					if (d != null) {
						System.err.println("Door already inserted: " + d);
					}
				}
				counter++;
			} else if (s.equals("addDoor")) {
				for (int i = 0; i < 5; i++) {
					command = tokenizer.nextToken();
				}
				command = Organizer.convert(command);
				System.out.println("Command " + command);
				if (!command.startsWith("land")) {
					Door door = new Door(current, command, counter);
					Door d = map.put(door.from, door);
					if (d != null) {
						System.err.println("Door already inserted: " + d);
					}
					counter++;
				}
			}
		}
	}
	 
	private class Door {
		String from;
		String leadsTo;
		public Door(String from, String to, int counter) {
			this.from = (from + "-mark" + counter).toLowerCase();
			leadsTo = to.toLowerCase();
			
		}
		
		public String toString() {
			return "From " + this.from + " to " + leadsTo;
		}
	}
}
