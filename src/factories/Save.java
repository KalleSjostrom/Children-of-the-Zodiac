/*
 * Classname: Save.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/01/2008
 */
package factories;

import info.Database;
import info.LabyrinthInfo;
import info.LabyrinthMap;
import info.Values;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import labyrinth.Node;
import landscape.Visited;
import sound.OggDecoder;
import cards.Card;
import character.Bestiary;
import character.Character;
import character.Bestiary.Stats;
import equipment.AbstractEquipment;
import equipment.Deck;
import equipment.Items.Item;

/**
 * This class saves the game by writing the necessary information to 
 * a text file which the load class can load when the game starts 
 * up again. It is designed as a singelton which means there will only 
 * be one object of this class.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 22 Jan 2008
 */
public class Save {
	
	private static Save save = new Save();

	private String place;
	private Visited visited;

	/**
	 * The empty private constructor which is a vital part in the singleton
	 * design. It makes sure that no class, except this, can construct an
	 * object of this class.
	 */
	private Save() {
		// Empty constructor.
	}

	/**
	 * Gets the only save object available.
	 * 
	 * @return the save object.
	 */
	public static Save getSave() {
		return save;
	}

	/**
	 * This method saves the game to the file with the specified name.
	 * The additional parameters has extra information needed to load the 
	 * game without loss of important information.
	 * 
	 * @param saveSlot the name of the file to save to.
	 * @param place the name of the place where the player saved.
	 * This is normally the name of the village, containing the church.
	 */
	public void saveGame(String saveSlot, String place) {
		this.place = place;
		visited = Visited.getVisited();
		saveGame(saveSlot);
	}

	/**
	 * This method writes the information to a save file.
	 * 
	 * @param filename the name of the save file
	 */
	private void saveGame(String filename) {
		try {
//			File file = new File("./Children of the Zodiac/lib/data/" + filename + ".sav");
			File file = new File(Values.lib + filename + ".sav");
			if (!file.exists()) {
				file.createNewFile();
			}
			PrintWriter writer = new PrintWriter(
					new BufferedWriter(
							new FileWriter(file)),true);
			writeHeader(writer);
			writeCharacters(writer, Load.getCharacters(), "character");
			writeCharacters(writer, Load.getExCharacters(), "exCharacter");
			writeBackPack(writer);
			writeMainDeck(writer);
			writeStatus(writer);
			writeVisited(writer);
			writeLabyrinthMap(writer);
			writeBestiary(writer);
			writer.println();
			writer.println("end");
			writer.close();

//			crypt(file, filename);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void crypt(File file, String filename) {
		try {
		BufferedReader br = new BufferedReader(new FileReader(file));
//		file = new File("./Children of the Zodiac/lib/data/" + filename + ".sav1");
		file = new File(Values.lib + filename + ".sav1");
		PrintWriter writer;
			writer = new PrintWriter(
					new BufferedWriter(
							new FileWriter(file)),true);
		int cnt = 0;
		int bytesRead = 0;
		while (true) {
			char[] buffer = new char[1024];
			cnt = br.read(buffer, 0, 1024);
			OggDecoder.swapChars(buffer, 0, cnt);
			for (int i = 0; i < buffer.length; i++) {
				buffer[i] += 1;
			}
			StringBuffer sb = new StringBuffer();
			sb.append(buffer);
			writer.println(sb.toString());
			if (cnt <= 0) {
				cnt = 0;
				break;
			}
			bytesRead += cnt;
		}
		writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Writes the first piece of information consisting of the time and the
	 * start location.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeHeader(PrintWriter writer) {
		//writer.println("time " + (Values.DAY ? "day" : "night"));
		writer.println("start " + place.replace(" ", "_"));
	}
	
	/**
	 * Writes all the information about all the characters in the list.
	 * 
	 * @param writer the writer to print the information to.
	 * @param list the list of characters to print the information about.
	 * @param type the type of character to print, either "character" or 
	 * "exCharacter".
	 */
	private void writeCharacters(
			PrintWriter writer, ArrayList<Character> list, String type) {
		for (int i = 0; i < list.size(); i++) {
			Character c = list.get(i);
			String name = c.getName();
			writer.print(type + " " + name + " ");
			for (int j = 0; j < c.getAttribute().length; j++) {
				writer.print(c.getAttribute(j) + " ");
			}
			writer.println();

			if (c.getWeapon() != null) {
				writer.println("rightHand " + 
						c.getRightHandName().replace(" ", "_") + " " + c.getWeapon().getNumber());
			}
			if (c.getLeftHand() != null) {
				writer.println("leftHand " + 
						c.getLeftHandName().replace(" ", "_") + " " + c.getLeftHand().getNumber());
			}
			if (c.getArmor() != null) {
				writer.println("armor "+c.getArmorName().replace(" ", "_") + " " + c.getArmor().getNumber());
			}
			writer.println();
			writer.println("characterdeck");
			Deck d = c.getDeck();
			writeDeck(writer, d);
			writer.println();
		}
	}
	
	/**
	 * Writes down all the cards in the given deck.
	 * 
	 * @param writer the writer to print the information to.
	 * @param d the deck containing the cards to print.
	 */
	private void writeDeck(PrintWriter writer, Deck d) {
		for (int j = 0; j < d.getCurrentDeckSize(); j++) {
			Card card = d.getCard(j);
			writer.println("card " + card.getClass().getName() + 
						" " + card.getLevel() + 
						" " + card.isAll());
		}
	}

	/**
	 * Writes all the information about the items and equipments in 
	 * the backpack.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeBackPack(PrintWriter writer) {
		ArrayList<AbstractEquipment> list = Load.convertWeaponListToAbstractRemoveEquipped();
		for (int i = 0; i < list.size(); i++) {
			writer.println("partyweapons " + 
					list.get(i).getName().replace(" ", "_") + " " + list.get(i).getNumber());
		}
		list = Load.convertShieldListToAbstractRemoveEquipped(); 
		for (int i = 0; i < list.size(); i++) {
			writer.println("partyshields " + 
					list.get(i).getName().replace(" ", "_") + " " + list.get(i).getNumber());
		}
		list = Load.convertArmorListToAbstractRemoveEquipped(); 
		for (int i = 0; i < list.size(); i++) {
			writer.println("partyarmors " + 
					list.get(i).getName().replace(" ", "_") + " " + list.get(i).getNumber());
		}
		int gold = Load.getPartyItems().getGold();
		String hours = Load.getTime().getHours();
		String min = Load.getTime().getMin();
		int steps = Load.getPartyItems().getSteps();
		int battles = Load.getPartyItems().getBattles();
		writer.println("info " + gold + " " + hours + " " + min + " " + steps + " " + battles);
		
		for (int i = 0; i < Load.getPartyItems().itemSize(); i++) {
			Item item = Load.getPartyItems().getItem(i);
			writer.println("item " + item.getName().replace(" ", "_") + " " + item.getNr());
		}
	}

	/**
	 * Writes all the cards in the main deck.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeMainDeck(PrintWriter writer) {
		Deck d = Load.getPartyItems().getMainDeck();
		writer.println("maindeck");
		writeDeck(writer, d);
	}

	/**
	 * Writes the status of all the characters, villagers, roads and so on.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeStatus(PrintWriter writer) {
		Database.saveData(writer);
	}
	
	/**
	 * Writes down all the visited nodes, roads and so on.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeVisited(PrintWriter writer) {
		for (int i = 0; i < 3; i++) {
			String zone = "world" + i + ".map";
			for (String node : visited.getVnodes(zone)) {
				writer.println("visitedNodes " + zone + " " + node.replace(" ", "_"));
			}
			for (Integer road : visited.getVroads(zone)) {
				writer.println("visitedRoads " + zone + " " + road);
			}
		}
	}
	
	private void writeLabyrinthMap(PrintWriter writer) {
		HashMap<String, LabyrinthInfo> info = Database.getVisitedLabyrinths();
		ArrayList<String> keys = Database.getVisitedLabyrinthsList();
		String labName;
		Iterator<String> it = keys.iterator();
		while (it.hasNext()) {
			LabyrinthInfo labInfo = info.get(it.next());
			ArrayList<LabyrinthMap> floors = labInfo.getFloors();
			for (int j = 0; j < floors.size(); j++) {
				LabyrinthMap map = floors.get(j);
				labName = labInfo.getLabyrinthName().replace(" ", "_");
				labName = labName + "--" + map.getName().replace(" ", "_") + ".map";
				writer.println("labmap " + labName);
				HashMap<Integer, Node> nodes = map.getNodes(); 
				Iterator<Integer> nit = nodes.keySet().iterator();
				while (nit.hasNext()) {
					Node n = nodes.get(nit.next());
					writer.println("node " + n.getAddress() + " " + n.isVisited() + " " + n.isSeen());
				}
			}
		}
		String[] l = Database.getLastVisitedLabyrinth();
		if (l != null) {
			writer.println("lastlab " + 
					LabyrinthMap.convertForSave(l));
		}
	}
	
	/**
	 * Writes all the information concerning the bestiary.
	 * 
	 * @param writer the writer to print the information to.
	 */
	private void writeBestiary(PrintWriter writer) {
		HashMap<Integer, Stats> bestiary = Bestiary.getBestiary().getStats();
		
		Iterator<Integer> it = bestiary.keySet().iterator();
		while (it.hasNext()) {
			int key = it.next();
			Stats val = bestiary.get(key);
			int counter = val.getBattleCounter();
			int offset = val.getCounterOffset();
			String name = val.getEnemy().getDbName();
			writer.println("counter " + name + " " + counter + " " + offset);
		}
	}
}
