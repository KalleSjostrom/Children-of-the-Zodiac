/*
 * Classname: Load.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/01/2008
 */
package factories;

import info.Database;
import info.LabyrinthMap;
import info.Values;
import info.Values.characters;
import input.FakeInputManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import java.util.logging.*;

import labyrinth.MapLoader;
import landscape.Visited;
import menu.AbstractPage;

import organizer.AbstractMapLoader;
import organizer.GameCore;
import organizer.Organizer;

import particleSystem.ParticleSystem;
import particleSystem.emitter.Flame2Emitter;
import villages.utils.Loot;
import battle.equipment.GLDeck;
import cards.Card;
import character.Bestiary;
import character.Character;
import character.Creature;
import character.Bestiary.Stats;
import equipment.AbstractEquipment;
import equipment.Armor;
import equipment.PartyItems;
import equipment.Shield;
import equipment.Time;
import equipment.Weapon;
import equipment.Items.Item;
import graphics.ImageHandler;

/**
 * This class loads the game. It reads information about the characters from
 * the save file and creates the characters and their equipment. It is designed
 * as a singleton which means there will only be one object of this class. It 
 * has methods for getting the party's equipment like weapons, armors, shields,
 * items and so on. 
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 22 Jan 2008
 */
public class Load extends AbstractMapLoader {
	
	private static ArrayList<Character> characters;
	private static HashMap<String, AbstractEquipment> equipments;
	private static Time time;
	private static PartyItems partyItems;
	private static String startl;
	
	private static ArrayList<Character> exCharacter;

	private static String saveSlotName = "Start";
	private static boolean charDeck;
	private static boolean hasLoaded = false;
	private static Logger logger = Logger.getLogger("Load");

	/**
	 * The empty private constructor which is a vital part in the singleton
	 * design. It makes sure that no class, except this, can construct an
	 * object of this class.
	 */
	private Load() {
		// Empty contructor.
	}
	
	private static void reset() {
		characters = new ArrayList<Character>();
		equipments = new HashMap<String, AbstractEquipment>();
		exCharacter = new ArrayList<Character>();

		time = null;
		partyItems = null;
		String name = Values.BattleImages + "stroke.png";
		ImageHandler.addPermanentlyLoadNow(name);
		startl = null;
		Visited.getVisited().clearVisited();
		saveSlotName = "Start";
		charDeck = false;
	}

	/**
	 * Loads the game from the save file with the specified name.
	 * 
	 * @param save the name of the save file.
	 */
	public static void loadGame(String save) {
		reset();
		Organizer.reset();
		EnemyFactory.getEnemyFactory();
		AbstractPage.getImages();
		new Load().parseFile(save + ".sav");
		ParticleSystem.load();
		Flame2Emitter.getImage();
		hasLoaded = true;
	}

	@Override
	protected void parseFile(String filename) {
		String path = Values.lib;
		if (filename.compareToIgnoreCase("Start.sav") == 0) {
			path = Values.Banks;
		}
		super.parseFile(path, filename);
	}

	/**
	 * Loads the game from the save file which was set by setSlot().
	 */
	public static void loadGame() {
		loadGame(saveSlotName);
	}

	/**
	 * This method checks whether or not a new game, or a saved game, 
	 * has been loaded.
	 *  
	 * @return true if a game has been loaded.
	 */
	public static boolean hasLoaded() {
		return hasLoaded;
	}

	/**
	 * Gets the list of character as a list of Creature objects.
	 * 
	 * @return the list of characters as creatures.
	 */
	public static ArrayList<Creature> getCharactersAsCreatures() {
		ArrayList<Creature> list = new ArrayList<Creature>();
		for (int i = 0; i < characters.size(); i++) {
			list.add(characters.get(i));
		}
		return list;
	}
	
	/**
	 * Gets the list of characters in the party.
	 * 
	 * @return the list of characters in the party.
	 */
	public static ArrayList<Character> getCharacters() {
		return characters;
	}
	
	/**
	 * Gets the list of extra characters that can be added to the party.
	 * In the beginning of the game, these characters are Borealis and Zalzi.
	 * 
	 * The sum of this list and the getCharacters() list should always be 4
	 * characters: Kin, Celis, Borealis and Zalzi.
	 * 
	 * @return the list of characters that can be added to the party.
	 */
	public static ArrayList<Character> getExCharacters() {
		return exCharacter;
	}
	
	/**
	 * Gets the party items. The items that the party is carrying.
	 * 
	 * @return the party items.
	 */
	public static PartyItems getPartyItems() {
		return partyItems;
	}
	
	/**
	 * Gets the starting location. This is where the party will start if 
	 * the game is loaded.
	 * 
	 * @return the starting location.
	 */
	public static String getStartLocation() {
		return startl;
	}
	
	/**
	 * Gets the equipment map. The returned map contains all the 
	 * equipments in the partys backpack.
	 * 
	 * @return a list of all equipments in the game.
	 */
	public static HashMap<String, AbstractEquipment> getEquipments() {
		return equipments;
	}
	
	/**
	 * Gets the current time.
	 * 
	 * @return the time.
	 */
	public static Time getTime() {
		return time;
	}

	/**
	 * Gets the character with the given name.
	 * 
	 * @param name the name of the character to get.
	 * @return the character with the given name.
	 */
	public static Character getCharacterByName(String name) {
		int index = getCharacterIndex(name);
		return index == -1 ? null : characters.get(index);
	}

	public static Character getCharacterWithForWhom(int forWhom) {
		for (int i = 0; i < characters.size(); i++) {
			Character c = characters.get(i);
			if (c.getIndex() == forWhom) {
				return c;
			}
		}
		return null;
	}
	
	public static boolean isCharacterActive(int forWhom) {
		characters c = Values.characters.getCharacter(forWhom);
		return getCharacterByName(c.getName()) != null;
	}
	
	/**
	 * Gets the character with the given name.
	 * 
	 * @param name the name of the character to get.
	 * @return the character with the given name.
	 */
	public static int getCharacterIndex(String name) {
		for (int i = 0; i < characters.size(); i++) {
			if (characters.get(i).getName().equals(name)) {
				return i;
			}
		}
		return -1;
	}


	/**
	 * Adds the given equipment to the party's "backpack".
	 * 
	 * @param equipment the equipment to add.
	 * @param number 
	 */
	public static void addEquipment(AbstractEquipment equipment) {
		String name = equipment.getName();
		AbstractEquipment he = equipments.get(name);
		if (he != null) {
			he.addNumber();
		} else {
			equipments.put(equipment.getName(), equipment);
		}
	}
	
	public static void setEquipment(AbstractEquipment equipment, int number) {
		equipment.setNumber(number);
		equipments.put(equipment.getName(), equipment);
	}
	
	/**
	 * Removes the equipment with the given name.
	 * 
	 * @param name the name of the equipment to remove.
	 */
	public static void removeEquipment(String name) {
		AbstractEquipment he = equipments.get(name);
		if (he != null) {
			he.subtractNumber();
			if (he.getNumber() == 0) {
				equipments.remove(name);
			}
		}
	}

	/**
	 * Converts the list of armors to a list of the more general type,
	 * AbstractEquipment.
	 * 
	 * @return a list of the armors as abstract equipments.
	 */
	public static ArrayList<AbstractEquipment> convertArmorListToAbstractRemoveEquipped() {
		return convertListToAbstractRemoveEquipped(Armor.class);
	}

	/**
	 * Converts the list of weapons to a list of the more general type,
	 * AbstractEquipment.
	 * 
	 * @return a list of the weapons as abstract equipments.
	 */
	public static ArrayList<AbstractEquipment> convertWeaponListToAbstractRemoveEquipped() {
		return convertListToAbstractRemoveEquipped(Weapon.class);
	}

	/**
	 * Converts the list of shields to a list of the more general type,
	 * AbstractEquipment.
	 * 
	 * @return a list of the shields as abstract equipments.
	 */
	public static ArrayList<AbstractEquipment> convertShieldListToAbstractRemoveEquipped() {
		return convertListToAbstractRemoveEquipped(Shield.class);
	}

	/**
	 * Converts the list containing objects of the given class to a list of 
	 * the type, AbstractEquipment. This means that, to convert a list of 
	 * shields, for example, just call this method with the class Shield.
	 * The given class must extend the class AbstractEquipment.
	 * 
	 * @param equipClass the class of the objects in the list to convert.
	 * @return a list of the shields as abstract equipments.
	 */
	public static ArrayList<AbstractEquipment> convertListToAbstractRemoveEquipped(
			Class<? extends AbstractEquipment> equipClass) {
		ArrayList<AbstractEquipment> ae = 
			new ArrayList<AbstractEquipment>();
		Iterator<String> names = equipments.keySet().iterator();
		while (names.hasNext()) {
			AbstractEquipment eq = equipments.get(names.next());
			if (!eq.isEquiped() && equipClass.isInstance(eq)) {
				ae.add(eq);
			}
		}
		return ae;
	}

	/**
	 * Gets the list of armors for the character with the specified number.
	 * To get the armors for a certain character, use the static values from 
	 * the StaticValues class. They are: StaticValues.ARGATH .CELIS .ZALZI
	 * and .BOREALIS.
	 * 
	 * @param nr the number of the character.
	 * @return the list of armors this character can choose from.
	 */
	public static ArrayList<AbstractEquipment> getArmorFor(Values.characters character) {
		return getEquipmentFor(character, Armor.class); 
	}

	/**
	 * Gets the weapon suited for the character represented by the 
	 * given number. This could be Values.ARGATH, Values.CELIS, Values.ZALZI
	 * or Values.BOREALIS.
	 * 
	 * @param nr the number representing the character to get the weapons for.
	 * @return the weapons that the character represented by the number
	 * can equip.
	 */
	public static ArrayList<AbstractEquipment> getWeaponFor(Values.characters character) {
		return getEquipmentFor(character, Weapon.class);
	}
	
	/**
	 * Gets all the equipment that can be carried in the left hand by
	 * the character represented by the given number. This could be 
	 * Values.ARGATH, Values.CELIS, Values.ZALZI or Values.BOREALIS.
	 * 
	 * @param nr the number of the character.
	 * @return the list of equipment that the character can equip.
	 */
	public static ArrayList<AbstractEquipment> getLeftHandFor(Values.characters character) {
		return getEquipmentFor(character, Shield.class);
	}

	/**
	 * Gets the equipment suited for the character represented by the 
	 * given number. This could be Values.ARGATH, Values.CELIS, Values.ZALZI
	 * or Values.BOREALIS. The equipClass parameter is the type of equipment
	 * to get.
	 * 
	 * @param character the number representing the character to get the weapons for.
	 * @param equipClass a subclass of abstract equipment.
	 * @return the weapons that the character represented by the number
	 * can equip.
	 */
	private static ArrayList<AbstractEquipment> getEquipmentFor(
			characters character, Class<? extends AbstractEquipment> equipClass) {
		ArrayList<AbstractEquipment> ae = 
			new ArrayList<AbstractEquipment>();
		Iterator<String> it = equipments.keySet().iterator();
		while (it.hasNext()) {
			AbstractEquipment equip = equipments.get(it.next());
			if (equip.getClass() == equipClass && equip.isFor(character)) {
				if (!equip.isEquiped()) {
					ae.add(equip);
				}
			}
		}
		return ae;
	}

	/**
	 * Sets the name of the slot to the given string.
	 * 
	 * @param saveSlot the name of the slot.
	 */
	public static void setSlot(String saveSlot) {
		saveSlotName = saveSlot;
	}

	/**
	 * This method implements the executeCommand from the 
	 * AbstractFactory class. It creates the characters and their equipment
	 * according to the files instructions.
	 * 
	 * @param command the command to execute.
	 * @param tokenizer the information concerning the rest of the information.
	 */
	protected void executeCommand(String command, StringTokenizer tokenizer) {
		if (command.equals("start")) {
			startl = Organizer.convertKeepCase(tokenizer.nextToken());
		} else if (command.equals("visitedNodes")) {
			String zone = tokenizer.nextToken();
			Visited.getVisited().getVnodes(zone).add(
					Organizer.convertKeepCase(tokenizer.nextToken()));
		} else if (command.equals("visitedRoads")) {
			String zone = tokenizer.nextToken();
			Visited.getVisited().getVroads(zone).add(Integer.parseInt(tokenizer.nextToken()));
		} else if (command.equals("character")) {
			currentCharacter = createCharacter(tokenizer);
			int index = Values.characters.getCharacter(currentCharacter.getName()).getIndex();
			if (index <= characters.size()) {
				characters.add(index, currentCharacter);
			} else {
				characters.add(currentCharacter);
			}
		} else if (command.equals("exCharacter")) {
			currentCharacter = createCharacter(tokenizer);
			exCharacter.add(currentCharacter);
		} else if (command.equals("rightHand")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			AbstractEquipment ae = 
				EquipmentFactory.getEquipment(name);
			currentCharacter.equip(ae, false);
			int number = 1;
			if (tokenizer.hasMoreTokens()) {
				number = Integer.parseInt(tokenizer.nextToken());
			}
			setEquipment(ae, number);
		} else if (command.equals("leftHand")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			AbstractEquipment ae = 
				EquipmentFactory.getEquipment(name); 
			currentCharacter.equip(ae, false);
			int number = 1;
			if (tokenizer.hasMoreTokens()) {
				number = Integer.parseInt(tokenizer.nextToken());
			}
			setEquipment(ae, number);
		} else if (command.equals("armor")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			AbstractEquipment ae = 
				EquipmentFactory.getEquipment(name);
			currentCharacter.equip(ae, false);
			int number = 1;
			if (tokenizer.hasMoreTokens()) {
				number = Integer.parseInt(tokenizer.nextToken());
			}
			setEquipment(ae, number);
		} else if (command.equals("partyweapons") || 
				command.equals("partyshields") || command.equals("partyarmors")) {
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			int number = 1;
			if (tokenizer.hasMoreTokens()) {
				number = Integer.parseInt(tokenizer.nextToken());
			}
			setEquipment(EquipmentFactory.getEquipment(name), number);
		} else if (command.equals("characterdeck")) {
			charDeck = true;
		} else if (command.equals("maindeck")) {
			charDeck = false;
		} else if (command.equals("card")) {
			Card newCard = Card.createCard(tokenizer);
			if (charDeck) {
				currentCharacter.getDeck().insert(newCard);
			} else {
				partyItems.addCard(newCard);
			}
		} else if (command.equals("item")) {
			String name = tokenizer.nextToken();
			int Nr = Integer.parseInt(tokenizer.nextToken());
			name = Organizer.convertKeepCase(name);
			partyItems.addItem(name, Nr);
		} else if (command.equals("info")) {
			int gold = Integer.parseInt(tokenizer.nextToken());
			int hours = Integer.parseInt(tokenizer.nextToken());
			int min = Integer.parseInt(tokenizer.nextToken());
			time = new Time(hours, min);
			partyItems = new PartyItems(gold);
			partyItems.setSteps(Integer.parseInt(tokenizer.nextToken()));
			partyItems.setBattles(Integer.parseInt(tokenizer.nextToken()));
		} else if (command.equals("status")) {
			String name = tokenizer.nextToken();
			String next = tokenizer.nextToken();
			if (next.equals("->")) {
				name += tokenizer.nextToken();	
				next = tokenizer.nextToken();
			}
			int value = Integer.parseInt(next);
			name = Organizer.convert(name);
			Database.addStatus(name, value);
		} else if (command.equals("storedTrigger")) {
			String type = Organizer.convertKeepCase(tokenizer.nextToken());
			String name = Organizer.convertKeepCase(tokenizer.nextToken());
			Database.storeTriggers(type, name);
		} else if (command.equals("counter")) {
			String name = Organizer.convert(tokenizer.nextToken()); 
			int counter = Integer.parseInt(tokenizer.nextToken());
			int offset = Integer.parseInt(tokenizer.nextToken());
			Stats s = Bestiary.getBestiary().getStats(name);
			System.out.println("Name " + name);
			s.setCounter(counter);
			s.setCounterOffset(offset);
		} else if (command.equals("labmap")) {
			String labName = prepare(tokenizer.nextToken());
			currentMap = new MapLoader(labName).getMap();
			System.out.println("Lab name " + labName);
			Database.visitLabyrinth(labName.replace(".map", ""), currentMap);
		} else if (command.equals("node")) {
			int address = Integer.parseInt(tokenizer.nextToken());
			boolean isVisited = Boolean.parseBoolean(tokenizer.nextToken());
			boolean isSeen = Boolean.parseBoolean(tokenizer.nextToken());
			if (currentMap.getNode(address) == null) {
				System.out.println("Address " + address);
				System.exit(0);
			}
			currentMap.getNode(address).setVisitedAndSeen(isVisited, isSeen);
			
		} else if (command.equals("lastlab")) {
			Database.setLastVisitedLabyrinth(LabyrinthMap.convert(tokenizer.nextToken()));
		}
	}
	
	public static String prepare(String string) {
		string = Organizer.convert(string);
		StringBuffer sb = new StringBuffer();
		String[] split = string.split("\\s");
		for (int i = 0; i < split.length; i++) {
			if (split[i].length() > 0 && (check(split[i]) || i == 0)) {
				String s = split[i].substring(1);
				sb.append(String.valueOf(split[i].charAt(0)).toUpperCase() + s + " ");
			} else {
				sb.append(split[i] + " ");
			}
		}
		string = sb.toString();
		if (string.contains("--")) {
			split = string.split("--");
			sb = new StringBuffer();
			if (split.length == 2) {
				sb.append(split[0] + "--");
				String s = split[1].substring(1);
				sb.append(
						String.valueOf(split[1].charAt(0)).toUpperCase());
				sb.append(s);
			}
		}
		return sb.toString().trim();
	}

	private static boolean check(String s) {
		return !(s.equals("the") || s.equals("of"));
	}

	LabyrinthMap currentMap;
	Character currentCharacter;

	/**
	 * Creates a new character from the information in the given tokenizer.
	 * 
	 * @param tokenizer the StringTokenizer containing the information about
	 * the character.
	 * @return the newly created character.
	 */
	private Character createCharacter(StringTokenizer tokenizer) {
		String name = tokenizer.nextToken();
		float[] attributes = new float[15];
		for (int i = 0; i < attributes.length; i++) {
			String a = tokenizer.nextToken();
			if (a.equals("--")) {
				attributes[i] = LevelFactory.NO_INCREASE;
			} else {
				attributes[i] = Integer.parseInt(a);
			}
		}
		return new Character(name, attributes, name + ".jpg");
	}

	/**
	 * This method sets up the game for a test run.
	 * It will be removed in the final version.
	 */
	public static void setupForTest() {
		ImageHandler.setGameMode(0);
		loadGame("Start");
		GameCore.inputManager.addInputManager(new FakeInputManager());
		Values.loadFont();
	}
	
	public static void unloadNewCharacter(String name) {
		for (int i = 0; i < characters.size(); i++) {
			Character c = characters.get(i);
			if (c.getName().equals(name)) {
				characters.remove(i);
				exCharacter.add(c);
				return;
			}
		}
		logger.log(Level.WARNING, "There are no extra characters left.");
	}

	/**
	 * Adds the character with the given name to the party.
	 * 
	 * @param name the name of the character to add. 
	 */
	public static void loadNewCharacter(String name) {
		characters charEnum = Values.characters.getCharacter(name);
		if (charEnum != Values.characters.NO_CHARACTER) {
			for (int i = 0; i < exCharacter.size(); i++) {
				Character c = exCharacter.get(i);
				if (c.getName().equals(name)) {
					exCharacter.remove(i);
					if (charEnum.getIndex() > characters.size()) {
						characters.add(c);
					} else {
						characters.add(charEnum.getIndex(), c);
					}
					return;
				}
			}
			logger.log(Level.FINE, "There are no extra characters left.");
		}
	}

	/**
	 * Collects the given loot. It will store the content of the loot in the
	 * correct place.
	 * 
	 * @param l the loot to collect.
	 */
	public static void collectLoot(Loot l) {
		Object o = l.getContent();
		switch (l.getType()) {
		case Loot.GOLD :
			partyItems.addGold((Integer) o);
			break;
		case Loot.ITEM :
			partyItems.addItem((Item) o);
			break;
		case Loot.CARD :
			partyItems.addCard((Card) o);
			break;
		case Loot.EQUIPMENT :
			addEquipment((AbstractEquipment) o);
			break;
		case Loot.LIFE :
			Load.cureParty((Float) o);
			break;
		}
		if (l.getType() != Loot.LIFE) {
			l.takeLoot();
		}
	}

	public static void cureParty() {
		cureParty(.005f);
	}
	
	public static void cureParty(float percent) {
		for (int i = 0; i < characters.size(); i++) {
			Character c = characters.get(i);
			if (!c.isAlive()) {
				c.cureFromDead();
			}
			characters.get(i).curePercent(percent);
		}
	}
	
	public static void shuffleAllDecks() {
		for (int i = 0; i < characters.size(); i++) {
			GLDeck d = characters.get(i).get2DDeck();
			if (d != null) {
				d.shuffleAndDeal();
			}
		}
	}
}