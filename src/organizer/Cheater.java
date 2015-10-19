/*
 * Classname: Cheater.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/01/08
 */
package organizer;

import factories.Load;
import graphics.Graphics;
import info.Database;
import info.Values;
import java.util.HashMap;
import java.util.logging.*;
import landscape.Landscape;
import menu.Node;
import store.CardStore;
import store.Church;
import store.Inn;
import store.WeaponStore;
import villages.Village;

/**
 * This class show a window displaying different places the player can visit.
 * It is used to test, and will not be in the final product.
 * Not all places can be visited from here but a lot of new places
 * will soon be available.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 27 Jan 2008
 */
public class Cheater extends GameMode {

	private Node activeNode;
	private boolean shouldGetInfoFromMain = true;
	private static Logger logger = Logger.getLogger("Cheater");

	/**
	 * Creates a new cheater and a new window. It gets the current window
	 * as a JFrame and changes some of its settings so that buttons and
	 * such can be added and displayed.
	 * 
	 * @param info the information used when initiating the cheater.
	 */
	public void init(HashMap<String, String> info) {
		info = new HashMap<String, String>();
		info.put("music", null);
		super.init(info, Values.DETECT_INIT);
		activeNode  = new Node(null, "");
		fadeValue = 1;
		fillRoot();
		logicLoading = false;
		/*
		new Thread() {
			public void run() {
				while (true) {
				SoundPlayer.playSound(SoundMap.ACCEPT);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_ACCEPT);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_BACK);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_SWITCH_PAGE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_CURE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_EQUIP_SWORD);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_ARMOR);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_ENTER_MENU);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_ITEM_USE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.MENU_NAVIAGATE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.ERROR);

				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_NAVIAGATE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_FINISH_ROUND);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_CHARACTER_NAVIGATE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_FLIP_MODE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_SAVE_CARD);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_DISCARD_CARD);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_CHOOSE_CARD);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_NEXT);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_WRONG);

				Values.sleep(1000);
				
				SoundPlayer.playSound(SoundMap.BATTLE_ATTACK + "1.ogg");
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_ATTACK_KIN);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_FIRE);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_MISS);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_MISS_MONSTER);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_WEREWOLF_ATTACK);
				Values.sleep(1000);
				SoundPlayer.playSound(SoundMap.BATTLE_WEREWOLF_DAMAGE);
				Values.sleep(1000);

				}
			}
		}.start();
		*/
	}

	private void setNormalMenuValues(Node n) {
		n.setPositions(40, 40);
		n.setDistance(30);
	}
	
	private void fillRoot() {
		activeNode.insertChild("Villages");
		activeNode.insertChild("Labyrinths - West Continent");
		activeNode.insertChild("Labyrinths - East Continent");
		activeNode.insertChild("Labyrinths - Ice Continent");
		activeNode.insertChild("Stories");
		activeNode.insertChild("Landscape");
		activeNode.insertChild("Landscape From the Air");
		activeNode.insertChild("Buildings");
//		activeNode.insertChild("Battle Test");
		setNormalMenuValues(activeNode);
		fillStory();
		fillVillages();
		fillLabyrinths();
		fillLandscape(activeNode.getChild("Landscape"));
		fillLandscape(activeNode.getChild("Landscape From the Air"));
		fillStore();
	}

	private void fillStory() {
		Node n = activeNode.getChild("Stories");
		fillChapter1(n.insertChild("Prolog"));
		fillChapter2(n.insertChild("Chapter one - Running Away From Home"));
		fillChapter3(n.insertChild("Chapter two - Zazo, the Home of the Miners"));
		fillChapter4(n.insertChild("Chapter three - The Son Returs"));
		fillChapter5(n.insertChild("Chapter four - A Wind of Change"));
		fillChapter6(n.insertChild("Chapter five - Soaring Through the Sky"));
		fillChapter7(n.insertChild("Chapter six - The End Draws Near"));
		fillChapter8(n.insertChild("Epilog"));
		setNormalMenuValues(n);
	}
	
	private void fillChapter1(Node n) {		
		n.insertChild("Prolog");
		setNormalMenuValues(n);
	}
	
	private void fillChapter2(Node n) {
		n.insertChild("Celis Memory - Having Fun");
		n.insertChild("Celis Memory - Ana's Reaction");
		n.insertChild("Celis Memory - Someone's Comming");
		n.insertChild("Celis Memory - Arrival at the New Home");
		
		n.insertChild("Running Away From Home - Part 1");
		n.insertChild("Home of Celisnode1");
		n.insertChild("Alaresnode1");
		n.insertChild("Talking to Farmer John");
		n.insertChild("Meeting a Crazy Man");
		n.insertChild("Someone's Calling");
		n.insertChild("The Senate of Pensara");
		n.insertChild("The Revelation of Elmer");
		n.insertChild("A Permission From Uri");
		n.insertChild("Encounter With an Ally");
		setNormalMenuValues(n);
	}
	
	private void fillChapter3(Node n) {
		n.insertChild("Meanwhile in Zazo");
		n.insertChild("Zazonode1");
		n.insertChild("Zazonode2");
		n.insertChild("After a Hard Days Work");
		n.insertChild("Menthu is Disappointed");
		n.insertChild("Meeting with Farl of Zazo");
		n.insertChild("The Farl Story");
		n.insertChild("Meeting with Farl of Zazo2");
		setNormalMenuValues(n);
	}
	
	private void fillChapter4(Node n) {
		n.insertChild("On the Boat to Pensara");
		n.insertChild("A Call From the Gods");
		n.insertChild("Arrival at the Port Town of Parasne");
		n.insertChild("The Mentor of Menthu");
		n.insertChild("Crossroadnode1");
		n.insertChild("Fire Cavern--Hall of Fire-mark0node1");
		n.insertChild("Meanwhile - Teo is Plotting With Vincent");
		n.insertChild("Crossroadnode2");
		n.insertChild("Meeting Vincent af Kinstone");
		n.insertChild("Menthu is Pleased");
		n.insertChild("Berca Desert--South West-mark0node1");
		n.insertChild("The Prison Cell - Celis Speaks Up");
		setNormalMenuValues(n);
	}
	
	private void fillChapter5(Node n) {
		n.insertChild("Bercanode1");
		n.insertChild("Meeting With the Rebels");
		n.insertChild("Zalzi Speaks of Her Concerns");
		n.insertChild("Emerge From The Sewers");
		n.insertChild("Kin is Meeting With Vincent");
		n.insertChild("Kin Gets Freed");
		setNormalMenuValues(n);
	}
	
	private void fillChapter6(Node n) {
		n.insertChild("Bercanode2");
		n.insertChild("Seeing the Elder of Berca");
		n.insertChild("Meanwhile - Menthu Kills Teo");
		n.insertChild("Vincent Tries to Cool Down the War");
		n.insertChild("Serphia Awakens-Part 1");
		n.insertChild("Serphia Awakens-Part 2");
		n.insertChild("Getting the Crystal of Levitation");
		n.insertChild("Dellnanode1");
		n.insertChild("Dellnanode2");
		n.insertChild("The Entering of Zazo");
		n.insertChild("Asking Farl of Zazo");
		n.insertChild("Reencounter With an Ally");
		setNormalMenuValues(n);
	}
	
	private void fillChapter7(Node n) {
		n.insertChild("Elder of Dellna Saves the Day");
		n.insertChild("Celis Wakes Up");
		n.insertChild("A Visit to the Childhood Home - Part 1");
		n.insertChild("Celis Memory - The Killing");
		n.insertChild("Showing the Path to the Gods");
		n.insertChild("Talking to Menthu");
		setNormalMenuValues(n);
	}
	
	private void fillChapter8(Node n) {
		n.insertChild("Ending - Part 1.1");
		n.insertChild("Ending - Part 1.2");
		n.insertChild("Ending - Part 1.3");
		n.insertChild("Ending - Part 2.1");
		n.insertChild("Ending - Part 2.2");
		n.insertChild("Ending - Part 2.3");
		n.insertChild("Ending - Part 2.4");
		n.insertChild("Ending - Part 2.5");
		n.insertChild("Ending - Part 2.6");
		n.insertChild("Ending - Part 2.7");
		n.insertChild("Ending - Part 2.8");
		n.insertChild("Ending - Part 2.9");
		n.insertChild("Ending - Part 3");
		setNormalMenuValues(n);
	}

	private void fillVillages() {
		Node n = activeNode.getChild("Villages");
		n.insertChild("Home of Celis");
		n.insertChild("Alares");
		n.insertChild("Port of Alares");
		n.insertChild("Pass to Zazo");
		n.insertChild("Zazo - The Home of the Miners");
		n.insertChild("Zazo - The House of Teo");
		n.insertChild("Port of Zazo");
		n.insertChild("The Ship Cabin");
		n.insertChild("Pensara - The Trade District");
		n.insertChild("Pensara - The School District");
		n.insertChild("Pensara - The North District");
		n.insertChild("Parasne");
		n.insertChild("Crossroad");
		n.insertChild("Vincent's Office");
		n.insertChild("The Prison Cell");
		n.insertChild("Berca - Village of the Sun");
		n.insertChild("Serphia Hall");
		n.insertChild("Dellna - The Artic Village");
		n.insertChild("Dellna - The Elder House");
		n.insertChild("Home of the Gods");
		setNormalMenuValues(n);
	}
	
	private void fillLabyrinths() {
		Node n = activeNode.getChild("Labyrinths - West Continent");
		fillReil(n.insertChild("Forest of Reil"));
		fillGrivera(n.insertChild("Grivera"));
		fillPass(n.insertChild("Central Pass"));
		fillZazoMine(n.insertChild("The Great Mine of Zazo"));
		fillEastPass(n.insertChild("East Passage"));
		fillEastForest(n.insertChild("Forest of Bri"));
		fillMtCesadur(n.insertChild("Mt. Cesadur"));
		setNormalMenuValues(n);
		
		n = activeNode.getChild("Labyrinths - East Continent");
		fillPensaraForest(n.insertChild("Pensara Forest"));
		fillForestOfDorma(n.insertChild("Dorma's Forest"));
		fillFireCavern(n.insertChild("Fire Cavern"));
		fillSilentRuin(n.insertChild("Silent Ruin"));
		fillPrison(n.insertChild("Prison"));
		fillDesert(n.insertChild("Berca Desert"));
		fillSewers(n.insertChild("Sewers"));
		fillTempleOfAegis(n.insertChild("Temple of Aegis"));
		setNormalMenuValues(n);
		
		n = activeNode.getChild("Labyrinths - Ice Continent");
		fillSnowPass(n.insertChild("Frozen Forest"));
		fillIceCavern(n.insertChild("Ice Cavern"));
		fillAirTemple(n.insertChild("Empyrian Temple"));
		fillMenthusLair(n.insertChild("Menthu's Lair"));
		setNormalMenuValues(n);
	}

	private void fillForestOfDorma(Node n) {
		n.insertChild("Forest of Hate");
		setNormalMenuValues(n);
	}

	private void fillReil(Node n) {
		n.insertChild("North Entrance");
		n.insertChild("South Entrance");
		n.insertChild("The Path");
		setNormalMenuValues(n);
	}
	
	private void fillGrivera(Node n) {
		n.insertChild("First Floor - Entrance");
		n.insertChild("First Floor - To Second Floor - North Stairs");
		n.insertChild("First Floor - To Second Floor - East Stairs");
		n.insertChild("Second Floor - To First Floor - North Stairs");
		n.insertChild("Second Floor - To First Floor - East Stairs");
		n.insertChild("Second Floor - To Third Floor");
		n.insertChild("Third Floor - To Second Floor");
		n.insertChild("Third Floor - To Fourth Floor");
		n.insertChild("Fourth Floor - To Third Floor");
		n.insertChild("Fourth Floor - To Fifth Floor");
		n.insertChild("Fifth Floor - To Fourth Floor");
		n.insertChild("Boss Door - Entrance");
		n.insertChild("Boss Door - Inside");
		setNormalMenuValues(n);
	}
	
	private void fillPass(Node n) {
		n.insertChild("West - Entrance");
		n.insertChild("West - Central");
		n.insertChild("Central - West");
		n.insertChild("Central - North");
		n.insertChild("North - Central");
		n.insertChild("North - North East");
		n.insertChild("North East - North");
		n.insertChild("North East - Exit");
		setNormalMenuValues(n);
	}
	
	private void fillZazoMine(Node n) {
		n.insertChild("The Hall - Entrance");
		n.insertChild("The Hall - To West Wing");
		n.insertChild("The Hall - To Mine Core");
		n.insertChild("The Hall - To Tunnel");
		n.insertChild("West Wing - To The Hall");
		n.insertChild("West Wing - To The Great Deep");
		n.insertChild("Great Deep - To West Wing");
		n.insertChild("Great Deep - To The Mine Core");
		n.insertChild("The Mine Core - To The Great Deep");
		n.insertChild("The Mine Core - To The Hall");
		n.insertChild("The Mine Core - To Mine Shaft");
		n.insertChild("Mine Shaft - To The Mine Core");
		n.insertChild("Mine Shaft - To Tunnel");
		n.insertChild("Tunnel - To Mine Shaft");
		n.insertChild("Tunnel - To The Hall");
		setNormalMenuValues(n);
	}
	
	private void fillEastPass(Node n) {
		n.insertChild("Entrance");
		n.insertChild("West Mountain - To East Mountain");
		n.insertChild("East Mountain - To West Mountain");
		n.insertChild("East Mountain - To Forest of Bri");
		setNormalMenuValues(n);
	}
	
	private void fillEastForest(Node n) {
		n.insertChild("West Forest - To West Mountain");
		n.insertChild("West Forest - To East Forest - North Way");
		n.insertChild("West Forest - To East Forest - South Way");
		n.insertChild("East Forest - To West Forest - North Way");
		n.insertChild("East Forest - To West Forest - South Way");
		n.insertChild("East Forest - Towards Mt. Cesadur");
		setNormalMenuValues(n);
	}
	
	private void fillMtCesadur(Node n) {
		n.insertChild("Basement");
		n.insertChild("Basement - 1");
		n.insertChild("Basement - 2");
		n.insertChild("Entrance");
		n.insertChild("Entrance - To Second Floor - North");
		n.insertChild("Entrance - To Second Floor - North West");
		n.insertChild("Entrance - To Second Floor - East");
		n.insertChild("Entrance - To Second Floor - South East");
		n.insertChild("Entrance - To Second Floor - South West");
		
		n.insertChild("Second Floor - To Entrance - North");
		n.insertChild("Second Floor - To Entrance - North West");
		n.insertChild("Second Floor - To Entrance - East");
		n.insertChild("Second Floor - To Entrance - South East");
		n.insertChild("Second Floor - To Entrance - South West");
		n.insertChild("Second Floor - To Third Floor - North");
		n.insertChild("Second Floor - To Third Floor - North West");
		n.insertChild("Second Floor - To Third Floor - South");
		
		n.insertChild("Third Floor - To Second Floor - North");
		n.insertChild("Third Floor - To Second Floor - North West");
		n.insertChild("Third Floor - To Second Floor - South");
		n.insertChild("Third Floor - To Fourth Floor - South West");
		n.insertChild("Third Floor - To Fourth Floor - South East");
		n.insertChild("Third Floor - To Fourth Floor - North West");
		n.insertChild("Third Floor - To Fourth Floor - North East");
		
		n.insertChild("Fourth Floor - To Third Floor - South West");
		n.insertChild("Fourth Floor - To Third Floor - South East");
		n.insertChild("Fourth Floor - To Third Floor - North West");
		n.insertChild("Fourth Floor - To Third Floor - North East");
		n.insertChild("Fourth Floor - To Top Floor");
		
		n.insertChild("Top Floor - To Fourth Floor");
		n.insertChild("Top Floor - To Boss");
		setNormalMenuValues(n);
	}
	
	private void fillPensaraForest(Node n) {
		n.insertChild("South Entrance");
		n.insertChild("North Entrance");
		setNormalMenuValues(n);
	}
	
	private void fillFireCavern(Node n) {
		n.insertChild("Hall of Fire - Entrance");
		n.insertChild("Hall of Fire - Blazing Maze");
		n.insertChild("Hall of Fire - Furnace");
		n.insertChild("Blazing Maze - Hall of Fire");
		n.insertChild("Blazing Maze - Passage of Ifrit");
		n.insertChild("Passage of Ifrit - Blazing Maze");
		n.insertChild("Passage of Ifrit - Hall of the Damned");
		n.insertChild("Furnace - Hall of Fire");
		n.insertChild("Furnace - Inferno");
		n.insertChild("Inferno - Furnace");
		n.insertChild("Hall of the Damned - Passage of Ifrit");
		setNormalMenuValues(n);
	}

	private void fillSilentRuin(Node n) {
		n.insertChild("Silent Ruin");
		setNormalMenuValues(n);
	}
	
	private void fillPrison(Node n) {
		n.insertChild("Floor 5 - From Prison Cell");
		n.insertChild("Floor 5 - Floor 6");
		n.insertChild("Floor 5 - Floor 4");
		n.insertChild("Floor 6 - Floor 5");
		n.insertChild("Floor 4 - Floor 5");
		n.insertChild("Floor 4 - Floor 3");
		n.insertChild("Floor 3 - Floor 4");
		n.insertChild("Floor 3 - Floor 2");
		n.insertChild("Floor 2 - Floor 3");
		n.insertChild("Floor 2 - Floor 1");
		n.insertChild("Floor 1 - Floor 2");
		n.insertChild("Floor 1 - Exit");
		setNormalMenuValues(n);
	}
	
	private void fillDesert(Node n) {
		n.insertChild("South West - Entrance");
		n.insertChild("South West - To South - South Way");
		n.insertChild("South West - To South - North Way");
		n.insertChild("South West - To North");

		n.insertChild("South - To North");
		n.insertChild("South - To South West - South Way");
		n.insertChild("South - To South West - North Way");
        n.insertChild("South - To South East - South Way");
		n.insertChild("South - To South East - North Way");

		n.insertChild("South East - To North - West Way");
		n.insertChild("South East - To North - East Way");
		n.insertChild("South East - To South - North Way");
		n.insertChild("South East - To South - South Way");

		n.insertChild("North West - To South West");
		n.insertChild("North West - To North");

		n.insertChild("North - To South");
		n.insertChild("North - To North West");
		n.insertChild("North - To North East");

		n.insertChild("North East - Exit");
		n.insertChild("North East - To South East - West Way");
		n.insertChild("North East - To South East - East Way");
        n.insertChild("North East - To North");

		setNormalMenuValues(n);
	}
	
	private void fillSewers(Node n) {
		n.insertChild("South East - Entrance");
		n.insertChild("South East - To South");
		n.insertChild("South - To South East");
		n.insertChild("South - To North");
		n.insertChild("South - To South West");
		n.insertChild("South West - To South");
		n.insertChild("South West - To North West");
		n.insertChild("North West - To South West");
		n.insertChild("North - To South");
		n.insertChild("North - To North East");
		n.insertChild("North - To Pensara");
		n.insertChild("North East - To North");
		setNormalMenuValues(n);
	}
	
	private void fillTempleOfAegis(Node n) {
		n.insertChild("First Floor - Entrance");
		n.insertChild("First Floor - To Second Floor");
		n.insertChild("First Floor - To Base Level - North West");
		n.insertChild("First Floor - To Base Level - North East");
		n.insertChild("First Floor - To Base Level - South West");
		n.insertChild("First Floor - To Base Level - South East");
		
		n.insertChild("Base Level - To First Floor - North West");
		n.insertChild("Base Level - To First Floor - North East");
		n.insertChild("Base Level - To First Floor - South West");
		n.insertChild("Base Level - To First Floor - South East");
		
		n.insertChild("Second Floor - To First Floor");
		n.insertChild("Second Floor - To Third Floor");
		
		n.insertChild("Third Floor - To Second Floor");
		n.insertChild("Third Floor - To Fourth Floor - North East");
		n.insertChild("Third Floor - To Fourth Floor - Center");
		n.insertChild("Third Floor - To Fourth Floor - South West");
		
		n.insertChild("Fourth Floor - To Third Floor - North East");
		n.insertChild("Fourth Floor - To Third Floor - Center");
		n.insertChild("Fourth Floor - To Third Floor - South West");
		n.insertChild("Fourth Floor - To Fifth Floor");
		
		n.insertChild("Top Floor - To Fourth Floor");
		n.insertChild("Top Floor - To Crystal Room");
		n.insertChild("Boss");
		
		setNormalMenuValues(n);
	}
	
	private void fillAirTemple(Node n) {
		n.insertChild("Hall of Wind - Entrance");
		n.insertChild("Tower of Magic - Bottom");
		n.insertChild("Tower of Magic - Top");
		n.insertChild("Tower of Strength - Bottom");
		n.insertChild("Tower of Strength - Top");
		n.insertChild("Light");
		n.insertChild("Dark");
		n.insertChild("Demon Floor");
		setNormalMenuValues(n);
	}

	private void fillMenthusLair(Node n) {
		n.insertChild("Menthu's Lair - Room of Confusion");
		n.insertChild("Menthu's Lair - Hall of Memories");
		n.insertChild("Menthu's Lair - Throne of Serpents");
		n.insertChild("Talking to Menthu");
		n.insertChild("Boss pt.1");
		n.insertChild("Boss pt.2");
		setNormalMenuValues(n);
	}
	
	private void fillIceCavern(Node n) {
		n.insertChild("Pillar Room - Entrance");
		n.insertChild("Pillar Room - Frozen Field");
		n.insertChild("Pillar Room - Mysterious Forest");
		n.insertChild("Frozen Field - Pillar Room");
		n.insertChild("Frozen Field - Hall of Confusion");
		n.insertChild("Mysterious Forest - Pillar Room");
		n.insertChild("Mysterious Forest - Hall of Anguish");
		n.insertChild("Hall of Confusion - Frozen Field");
		n.insertChild("Hall of Confusion - Throne Room - North");
		n.insertChild("Hall of Confusion - Throne Room - Center");
		n.insertChild("Hall of Confusion - Throne Room - South");
		n.insertChild("Hall of Anguish - Mysterious Forest");
		n.insertChild("Hall of Anguish - Throne Room - North");
		n.insertChild("Hall of Anguish - Throne Room - Center");
		n.insertChild("Hall of Anguish - Throne Room - South");
		n.insertChild("Throne Room - Hall of Confusion - North");
		n.insertChild("Throne Room - Hall of Confusion - Center");
		n.insertChild("Throne Room - Hall of Confusion - South");
		n.insertChild("Throne Room - Hall of Anguish - North");
		n.insertChild("Throne Room - Hall of Anguish - Center");
		n.insertChild("Throne Room - Hall of Anguish - South");
		n.insertChild("Throne Room - Boss");
		n.insertChild("Boss2");
		setNormalMenuValues(n);		
	}
	
	private void fillSnowPass(Node n) {
		n.insertChild("Entrance");
		n.insertChild("To Ice Cavern");
		setNormalMenuValues(n);
	}
	
	private void fillLandscape(Node n) {
		fillWestContinent(n.insertChild("West Continent"));
		fillEastContinent(n.insertChild("East Continent"));
		fillNorthContinent(n.insertChild("North Continent"));
		
		setNormalMenuValues(n);
	}
	
	private void fillWestContinent(Node n) {
		n.insertChild("Home of Celis");
		n.insertChild("Forest of Reil - North Entrance");
		n.insertChild("Forest of Reil - South Entrance");
		n.insertChild("Alares");
		n.insertChild("Grivera");
		n.insertChild("Port of Alares");
		n.insertChild("Pass to Zazo");
		n.insertChild("Central Pass - North Entrance");
		n.insertChild("Zazo");
		n.insertChild("Port of Zazo");
		n.insertChild("The Great Mine");
		n.insertChild("East Passage");
		n.insertChild("Forest of Bri");
		n.insertChild("Mt. Cesadur");
		setNormalMenuValues(n);
	}
	
	private void fillEastContinent(Node n) {
		n.insertChild("Parasne");
		n.insertChild("Pensara Forest - South Entrance");
		n.insertChild("Pensara Forest - North Entrance");
		n.insertChild("Pensara");
		n.insertChild("Crossroad");
		n.insertChild("Fire Cavern");
		n.insertChild("Prison");
		n.insertChild("Desert - West Entrance");
		n.insertChild("Desert - North Entrance");
		n.insertChild("Berca");
		n.insertChild("Temple of Aegis");
		
		setNormalMenuValues(n);
	}
	
	private void fillNorthContinent(Node n) {
		n.insertChild("Dellna");
		n.insertChild("Frozen Forest");
		n.insertChild("Ice Cavern");
		
		setNormalMenuValues(n);
	}
	
	private void fillStore() {
		Node n = activeNode.getChild("Buildings");
		fillWeaponStore(n.insertChild("Weapon Store"));
		fillCardStore(n.insertChild("Card Store"));
		fillChurchStore(n.insertChild("Church"));
		fillInnStore(n.insertChild("Inn"));
		setNormalMenuValues(n);
	}
	
	private void fillWeaponStore(Node n) {
		n.insertChild("Alares");
		n.insertChild("Zazo");
		n.insertChild("Pensara - The Trade District");
		n.insertChild("Berca");
		n.insertChild("Dellna");
		setNormalMenuValues(n);
	}

	private void fillCardStore(Node n) {
		n.insertChild("Alares--0");
		n.insertChild("Alares--1");
		n.insertChild("Alares--2");
		n.insertChild("Zazo--0");
		n.insertChild("Zazo--1");
		n.insertChild("Zazo--2");
		n.insertChild("Zazo--3");
		n.insertChild("Parasne--0");
		n.insertChild("Parasne--1");
		n.insertChild("Pensara - The Trade District--0");
		n.insertChild("Pensara - The Trade District--1");
		n.insertChild("Pensara - The Trade District--2");
		n.insertChild("Pensara - The Trade District--3");
		n.insertChild("Berca--0");
		n.insertChild("Berca--1");
		n.insertChild("Berca--2");
		n.insertChild("Dellna--0");
		n.insertChild("Dellna--1");
		setNormalMenuValues(n);
	}
	
	private void fillChurchStore(Node n) {
		n.insertChild("Alares");
		n.insertChild("Zazo");
		n.insertChild("Pensara - The School District");
		n.insertChild("Berca");
		n.insertChild("Dellna");
		setNormalMenuValues(n);
	}
	
	private void fillInnStore(Node n) {
		n.insertChild("Alares");
		n.insertChild("Zazo");
		n.insertChild("Pensara - The Trade District");
		n.insertChild("Berca");
		n.insertChild("Dellna");
		setNormalMenuValues(n);
	}

	/**
	 * This method draws the cheat mode. It will display all the places
	 * that the player can go to.
	 * 
	 * @param g3D the graphics to draw on.
	 */
	public void draw(Graphics g) {
		g.setColor(1);
		g.loadIdentity();
		g.setColor(Graphics.RED);
		g.setFontSize(26);
		activeNode.drawChildren(g);
	}

	/**
	 * This method checks which mode the cheater wants to exit with.
	 * It will return the mode chosen by the player.
	 * 
	 * @return the mode that the player chose.
	 */
	public int checkExit() {
		return mode;
	}

	/**
	 * This method force exits the cheater. It overwrites the finishOff()
	 * in GameMode and this method is called when the organizer switches 
	 * from the Cheater to the mode chosen by the player.
	 */
	public void finishOff() {
		//killOggPlayer();
	}

	/**
	 * Updates the cheater. It checks for whether or not the player has
	 * pressed a button.
	 * 
	 * @param elapsedTime the amount of time that has elapsed since the 
	 * last update.
	 */
	public void update(float elapsedTime) {
		if (gameActions[UP].isPressed()) {
			activeNode.previousChild();
		} else if (gameActions[DOWN].isPressed()) {
			activeNode.nextChild();
		} else if (gameActions[CROSS].isPressed()) {
			if (activeNode.getCurrentChild().hasChildren()) {
				activeNode = activeNode.getCurrentChild();
			} else {
				if (!Load.hasLoaded()) {
					Load.loadGame("Start");
				}
				switchToNext();
			}
		} else if (gameActions[CIRCLE].isPressed()) {
			Node n = activeNode.getParent();
			if (n != null) {
				activeNode = n;
			} else {
				exitWithoutFading(Values.SWITCH_BACK);
			}
		}
		super.update(elapsedTime);
	}

	/**
	 * Gets the information concerning the next place in the game.
	 * It is used to tell the organizer which place to load.
	 * 
	 * @return the next place.
	 */
	public String getNextPlace() {
		return nextPlace;
	}
	
	/**
	 * This method is called when the player has pressed the cross button
	 * indicating that the player wants to be teleported to the chosen place. 
	 * It checks which place was chosen and sets up the correct values to
	 * send the player there.
	 */
	private void switchToNext() {
		String next = activeNode.getCurrentChild().getName();
		String current = activeNode.getName();
		Node n = activeNode.getParent();
		String parent = n == null ? "" : n.getName();
		if (next.equals("Battle Test")) {
			mode = Values.BATTLE_TEST;
			nextPlace = "";
			//Values.DAY = true;
			shouldGetInfoFromMain = false;
			Organizer.getOrganizer().setNext(false);
		} else if (current.equals("Villages")) {
			if (next.equals("Home of Celis")) {
				setWestVillage("Home of Celis");
			} else if (next.equals("Kin's Place")) {
				setWestVillage("Kin's Place");
			} else if (next.equals("Alares")) {
				setWestVillage("Alares");
			} else if (next.equals("Port of Alares")) {
				setWestVillage("Port of Alares");
			} else if (next.equals("Pass to Zazo")) {
				setWestVillage("Pass to Zazo");
			} else if (next.equals("Zazo - The Home of the Miners")) {
				setWestVillage("Zazo");
			} else if (next.equals("Zazo - The House of Teo")) {
				setWestVillage("Zazo - Teo's House");
			} else if (next.equals("Port of Zazo")) {
				setWestVillage("Port of Zazo");
			} else if (next.equals("The Ship Cabin")) {
				setWestVillage("The Ship Cabin");
			} else if (next.equals("Pensara - The Trade District")) {
				setEastVillage("Pensara - The Trade District");
			} else if (next.equals("Pensara - The School District")) {
				setEastVillage("Pensara - The School District");
			} else if (next.equals("Pensara - The North District")) {
				setEastVillage("Pensara - The North District");
			} else if (next.equals("Parasne")) {
				setEastVillage("Parasne");
			} else if (next.equals("Crossroad")) {
				setEastVillage("Crossroad");
			} else if (next.equals("Vincent's Office")) {
				setEastVillage("Vincent's Office");
			} else if (next.equals("The Prison Cell")) {
				setEastVillage("The Prison Cell");
			} else if (next.equals("Berca - Village of the Sun")) {
				setEastVillage("Berca");
			} else if (next.equals("Serphia Hall")) {
				setEastVillage("Serphia Hall");
			} else if (next.equals("Dellna - The Artic Village")) {
				setNorthVillage("Dellna");
			} else if (next.equals("Dellna - The Elder House")) {
				setNorthVillage("Dellna - Elder House - Floor 1");
			} else if (next.equals("Home of the Gods")) {
				setNorthVillage("Home of the Gods");
			}
		} 
		
		else if (current.equals("Forest of Reil")) {
			if (next.equals("North Entrance")) {
				setLabyrinth("Forest of Reil--Deep_Forest-mark0");
			} else if (next.equals("South Entrance")) {
				setLabyrinth("Forest of Reil--Deep_Forest-mark1");
			} else if (next.equals("The Path")) {
				setLabyrinth("Forest of Reil--Forest Path-mark0");
			}
		}
		
		else if (current.equals("Grivera")) {
			if (next.equals("First Floor - Entrance")) {
				setLabyrinth("Grivera--First Floor-mark0");
			} else if (next.equals("First Floor - To Second Floor - North Stairs")) {
				setLabyrinth("Grivera--First Floor-mark1");
			} else if (next.equals("First Floor - To Second Floor - East Stairs")) {
				setLabyrinth("Grivera--First Floor-mark2");
			} else if (next.equals("Second Floor - To First Floor - North Stairs")) {
				setLabyrinth("Grivera--Second Floor-mark0");
			} else if (next.equals("Second Floor - To First Floor - East Stairs")) {
				setLabyrinth("Grivera--Second Floor-mark1");
			}else if (next.equals("Second Floor - To Third Floor")) {
				setLabyrinth("Grivera--Second Floor-mark2");
			} else if (next.equals("Third Floor - To Second Floor")) {
				setLabyrinth("Grivera--Third Floor-mark0");
			} else if (next.equals("Third Floor - To Fourth Floor")) {
				setLabyrinth("Grivera--Third Floor-mark1");
			} else if (next.equals("Fourth Floor - To Third Floor")) {
				setLabyrinth("Grivera--Omnious Hall-mark0");
			} else if (next.equals("Fourth Floor - To Fifth Floor")) {
				setLabyrinth("Grivera--Omnious Hall-mark1");
			} else if (next.equals("Fifth Floor - To Fourth Floor")) {
				setLabyrinth("Grivera--Corridor of Agony-mark0");
			} else if (next.equals("Boss Door - Entrance")) {
				setLabyrinth("Grivera--Corridor of Agony-mark1");
			} else if (next.equals("Boss Door - Inside")) {
				setLabyrinth("Grivera--Corridor of Agony-mark2");
			}
		}
		
		else if (current.equals("Central Pass")) {

			if (next.equals("West - Entrance")) {
				setLabyrinth("Central Pass--West Part-mark0");
			} else if (next.equals("West - Central")) {
				setLabyrinth("Central Pass--West Part-mark1");
			}
			
			else if (next.equals("Central - West")) {
				setLabyrinth("Central Pass--Central Part-mark0");
			} else if (next.equals("Cenral - North")) {
				setLabyrinth("Central Pass--Central Part-mark1");
			}
				
			else if (next.equals("North - Central")) {
				setLabyrinth("Central Pass--North Part-mark0");
			} else if (next.equals("North - North East")) {
				setLabyrinth("Central Pass--North Part-mark1");
			}
			
			else if (next.equals("North East - North")) {
				setLabyrinth("Central Pass--North East Part-mark1");
			} else if (next.equals("North East - Exit")) {
				setLabyrinth("Central Pass--North East Part-mark0");
			}
	
		}
		
		else if (current.equals("The Great Mine of Zazo")) {
			if (next.equals("The Hall - Entrance")) {
				setLabyrinth("The Great Mine--The Hall-mark0");
			} else if (next.equals("The Hall - To West Wing")) {
				setLabyrinth("The Great Mine--The Hall-mark1");
			} else if (next.equals("The Hall - To Mine Core")) {
				setLabyrinth("The Great Mine--The Hall-mark2");
			} else if (next.equals("The Hall - To Tunnel")) {
				setLabyrinth("The Great Mine--The Hall-mark3");
			} 
		
			else if (next.equals("West Wing - To The Hall")) {
				setLabyrinth("The Great Mine--West Wing-mark0");
			} else if (next.equals("West Wing - To The Great Deep")) {
				setLabyrinth("The Great Mine--West Wing-mark1");
			} 
			
			else if (next.equals("Great Deep - To West Wing")) {
				setLabyrinth("The Great Mine--Great Deep-mark0");
			} else if (next.equals("Great Deep - To The Mine Core")) {
				setLabyrinth("The Great Mine--Great Deep-mark1");
			}
			
			else if (next.equals("The Mine Core - To The Great Deep")) {
				setLabyrinth("The Great Mine--The Mine Core-mark1");
			} else if (next.equals("The Mine Core - To The Hall")) {
				setLabyrinth("The Great Mine--The Mine Core-mark0");
			} else if (next.equals("The Mine Core - To Mine Shaft")) {
				setLabyrinth("The Great Mine--The Mine Core-mark2");
			}
			
			else if (next.equals("Mine Shaft - To The Mine Core")) {
				setLabyrinth("The Great Mine--Mine Shaft-mark1");
			} else if (next.equals("Mine Shaft - To Tunnel")) {
				setLabyrinth("The Great Mine--Mine Shaft-mark0");
			}
			
			else if (next.equals("Tunnel - To Mine Shaft")) {
				setLabyrinth("The Great Mine--Tunnel-mark1");
			} else if (next.equals("Tunnel - To The Hall")) {
				setLabyrinth("The Great Mine--Tunnel-mark0");
			}
		}
	
		else if (current.equals("East Passage")) {
			if (next.equals("Entrance")) {
				setLabyrinth("East Passage--West Mountain-mark0");
			} else if (next.equals("West Mountain - To East Mountain")) {
				setLabyrinth("East Passage--West Mountain-mark1");
			} else if (next.equals("East Mountain - To West Mountain")) {
				setLabyrinth("East Passage--East Mountain-mark1");
			} else if (next.equals("East Mountain - To Forest of Bri")) {
				setLabyrinth("East Passage--East Mountain-mark0");
			} 
		}

		else if (current.equals("Forest of Bri")) {
			if (next.equals("West Forest - To West Mountain")) {
				setLabyrinth("Forest of Bri--West Forest-mark0");
			} else if (next.equals("West Forest - To East Forest - North Way")) {
				setLabyrinth("Forest of Bri--West Forest-mark1");
			} else if (next.equals("West Forest - To East Forest - South Way")) {
				setLabyrinth("Forest of Bri--West Forest-mark2");
			} else if (next.equals("East Forest - To West Forest - North Way")) {
				setLabyrinth("Forest of Bri--East Forest-mark1");
			} else if (next.equals("East Forest - To West Forest - South Way")) {
				setLabyrinth("Forest of Bri--East Forest-mark2");
			} else if (next.equals("East Forest - Towards Mt. Cesadur")) {
				setLabyrinth("Forest of Bri--East Forest-mark0");
			} 
		}
		
		else if (current.equals("Mt. Cesadur")) {
			if (next.equals("Basement")) {
				setLabyrinth("Mt. Cesadur--Basement-mark0");
			} else if (next.equals("Basement - 1")) {
				setLabyrinth("Mt. Cesadur--Basement-mark1");
			} else if (next.equals("Basement - 2")) {
				setLabyrinth("Mt. Cesadur--Basement-mark2");
			} else if (next.equals("Entrance")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark0");
			} else if (next.equals("Entrance - To Second Floor - North")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark1");
			} else if (next.equals("Entrance - To Second Floor - North West")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark2");
			} else if (next.equals("Entrance - To Second Floor - East")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark3");
			} else if (next.equals("Entrance - To Second Floor - South East")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark4");
			} else if (next.equals("Entrance - To Second Floor - South West")) {
				setLabyrinth("Mt. Cesadur--Entrance-mark5");
			}
		
			else if (next.equals("Second Floor - To Entrance - North")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark0");
			} else if (next.equals("Second Floor - To Entrance - North West")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark2");
			} else if (next.equals("Second Floor - To Entrance - East")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark1");
			} else if (next.equals("Second Floor - To Entrance - South East")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark3");
			} else if (next.equals("Second Floor - To Entrance - South West")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark4");
			} else if (next.equals("Second Floor - To Third Floor - North")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark5");
			} else if (next.equals("Second Floor - To Third Floor - North West")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark6");
			} else if (next.equals("Second Floor - To Third Floor - South")) {
				setLabyrinth("Mt. Cesadur--Second_Floor-mark7");
			}
				
			else if (next.equals("Third Floor - To Second Floor - North")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark0");
			} else if (next.equals("Third Floor - To Second Floor - North West")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark1");
			} else if (next.equals("Third Floor - To Second Floor - South")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark2");
			} else if (next.equals("Third Floor - To Fourth Floor - South West")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark3");
			} else if (next.equals("Third Floor - To Fourth Floor - South East")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark4");
			} else if (next.equals("Third Floor - To Fourth Floor - North West")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark5");
			} else if (next.equals("Third Floor - To Fourth Floor - North East")) {
				setLabyrinth("Mt. Cesadur--Third_Floor-mark6");
			}
	
			else if (next.equals("Fourth Floor - To Third Floor - South West")) {
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark0");
			} else if (next.equals("Fourth Floor - To Third Floor - South East")) {
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark1");
			} else if (next.equals("Fourth Floor - To Third Floor - North West")) {
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark3");
			} else if (next.equals("Fourth Floor - To Third Floor - North East")) {
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark2");
			} else if (next.equals("Fourth Floor - To Top Floor")) {
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark4");
			}
			
			else if (next.equals("Top Floor - To Fourth Floor")) {
				setLabyrinth("Mt. Cesadur--Mountain Top-mark0");
			} else if (next.equals("Top Floor - To Boss")) {
				setLabyrinth("Mt. Cesadur--Mountain Top-mark2");
			}
		}
		else if (current.equals("Pensara Forest")) {
			if (next.equals("South Entrance")) {
				setLabyrinth("Pensara Forest--Forest-mark0");
			} else if (next.equals("North Entrance")) {
				setLabyrinth("Pensara Forest--Forest-mark1");
			}
		}
		else if (current.equals("Dorma's Forest")) {
			if (next.equals("Forest of Hate")) {
				setLabyrinth("Dorma's Forest--Forest of Hate-mark0");
			}
		}
	
		else if (current.equals("Fire Cavern")) {
			if (next.equals("Hall of Fire - Entrance")) {
				setLabyrinth("Fire Cavern--Hall of Fire-mark0");
			} else if (next.equals("Hall of Fire - Blazing Maze")) {
				setLabyrinth("Fire Cavern--Hall of Fire-mark1");
			} else if (next.equals("Hall of Fire - Furnace")) {
				setLabyrinth("Fire Cavern--Hall of Fire-mark2");
			} else if (next.equals("Blazing Maze - Hall of Fire")) {
				setLabyrinth("Fire Cavern--Blazing Maze-mark0");
			} else if (next.equals("Blazing Maze - Passage of Ifrit")) {
				setLabyrinth("Fire Cavern--Blazing Maze-mark1");
			} else if (next.equals("Passage of Ifrit - Blazing Maze")) {
				setLabyrinth("Fire Cavern--Passage of Ifrit-mark0");
			} else if (next.equals("Passage of Ifrit - Hall of the Damned")) {
				setLabyrinth("Fire Cavern--Passage of Ifrit-mark1");
			} else if (next.equals("Furnace - Hall of Fire")) {
				setLabyrinth("Fire Cavern--Furnace-mark0");
			} else if (next.equals("Furnace - Inferno")) {
				setLabyrinth("Fire Cavern--Furnace-mark1");
			} else if (next.equals("Inferno - Furnace")) {
				setLabyrinth("Fire Cavern--Inferno-mark0");
			} else if (next.equals("Hall of the Damned - Passage of Ifrit")) {
				setLabyrinth("Fire Cavern--Hall of the Damned-mark0");
			}
		}
		
		else if (current.equals("Silent Ruin")) {
			setLabyrinth("Silent Ruin--The Great Ruins-mark0");
		}
		else if (current.equals("Prison")) {
			if (next.equals("Floor 5 - From Prison Cell")) {
				setLabyrinth("Pensara Prison--Floor 5-mark0");
			} else if (next.equals("Floor 5 - Floor 6")) {
				setLabyrinth("Pensara Prison--Floor 5-mark1");
			} else if (next.equals("Floor 5 - Floor 4")) {
				setLabyrinth("Pensara Prison--Floor 5-mark2");
			} else if (next.equals("Floor 6 - Floor 5")) {
				setLabyrinth("Pensara Prison--Floor 6-mark0");
			} else if (next.equals("Floor 4 - Floor 5")) {
				setLabyrinth("Pensara Prison--Floor 4-mark1");
			} else if (next.equals("Floor 4 - Floor 3")) {
				setLabyrinth("Pensara Prison--Floor 4-mark0");
			} else if (next.equals("Floor 3 - Floor 4")) {
				setLabyrinth("Pensara Prison--Floor 3-mark0");
			} else if (next.equals("Floor 3 - Floor 2")) {
				setLabyrinth("Pensara Prison--Floor 3-mark1");
			} else if (next.equals("Floor 2 - Floor 3")) {
				setLabyrinth("Pensara Prison--Floor 2-mark1");
			} else if (next.equals("Floor 2 - Floor 1")) {
				setLabyrinth("Pensara Prison--Floor 2-mark0");
			} else if (next.equals("Floor 1 - Floor 2")) {
				setLabyrinth("Pensara Prison--Floor 1-mark0");
			} else if (next.equals("Floor 1 - Exit")) {
				setLabyrinth("Pensara Prison--Floor 1-mark1");
			}
		}
		
		else if (current.equals("Berca Desert")) {
            if (next.equals("South West - Entrance")) {
				setLabyrinth("Berca Desert--South West-mark0");
			} else if (next.equals("South West - To South - South Way")) {
				setLabyrinth("Berca Desert--South West-mark1");
			} else if (next.equals("South West - To South - North Way")) {
				setLabyrinth("Berca Desert--South West-mark2");
			} else if (next.equals("South West - To North")) {
				setLabyrinth("Berca Desert--South West-mark3");
			} 
            
            else if (next.equals("South - To North")) {
				setLabyrinth("Berca Desert--South-mark0");
			} else if (next.equals("South - To South West - South Way")) {
				setLabyrinth("Berca Desert--South-mark1");
			} else if (next.equals("South - To South West - North Way")) {
				setLabyrinth("Berca Desert--South-mark2");
			} else if (next.equals("South - To South East - South Way")) {
				setLabyrinth("Berca Desert--South-mark3");
			} else if (next.equals("South - To South East - North Way")) {
				setLabyrinth("Berca Desert--South-mark4");
			} 

            else if (next.equals("South East - To North - West Way")) {
				setLabyrinth("Berca Desert--South East-mark0");
			} else if (next.equals("South East - To North - East Way")) {
				setLabyrinth("Berca Desert--South East-mark1");
			} else if (next.equals("South East - To South - North Way")) {
				setLabyrinth("Berca Desert--South East-mark2");
			} else if (next.equals("South East - To South - South Way")) {
				setLabyrinth("Berca Desert--South East-mark3");
			} 

            else if (next.equals("North West - To South")) {
				setLabyrinth("Berca Desert--North West-mark0");
			} else if (next.equals("North West - To North")) {
				setLabyrinth("Berca Desert--North West-mark1");
			}

            else if (next.equals("North - To South")) {
				setLabyrinth("Berca Desert--North-mark0");
            } else if (next.equals("North - To North West")) {
                setLabyrinth("Berca Desert--North-mark1");
            } else if (next.equals("North - To North East")) {
                setLabyrinth("Berca Desert--North-mark2");
            }

            else if (next.equals("North East - Exit")) {
                setLabyrinth("Berca Desert--North East-mark0");
            } else if (next.equals("North East - To South East - West Way")) {
                setLabyrinth("Berca Desert--North East-mark1");
            } else if (next.equals("North East - To South East - East Way")) {
                setLabyrinth("Berca Desert--North East-mark3");
            } else if (next.equals("North East - To North")) {
                setLabyrinth("Berca Desert--North East-mark2");
            }
		}
		
		else if (current.equals("Sewers")) {
			if (next.equals("South East - Entrance")) {
				setLabyrinth("The Sewers--South East-mark0");
			} else if (next.equals("South East - To South")) {
				setLabyrinth("The Sewers--South East-mark1");
			} 
			
			else if (next.equals("South - To South East")) {
				setLabyrinth("The Sewers--South-mark0");
			} else if (next.equals("South - To North")) {
				setLabyrinth("The Sewers--South-mark1");
			} else if (next.equals("South - To South West")) {
				setLabyrinth("The Sewers--South-mark2");
			}

			else if (next.equals("South West - To South")) {
				setLabyrinth("The Sewers--South_West-mark0");
			} else if (next.equals("South West - To North West")) {
				setLabyrinth("The Sewers--South_West-mark1");
			}
			
			else if (next.equals("North West - To South West")) {
				setLabyrinth("The Sewers--North_West-mark0");
			}
			
			else if (next.equals("North - To South")) {
				setLabyrinth("The Sewers--North-mark0");
			} else if (next.equals("North - To North East")) {
				setLabyrinth("The Sewers--North-mark1");
			} else if (next.equals("North - To Pensara")) {
				setLabyrinth("The Sewers--North-mark6");
			}
			
			else if (next.equals("North East - To North")) {
				setLabyrinth("The Sewers--North_East-mark0");
			}
		}
		
		else if (current.equals("Temple of Aegis")) {
			if (next.equals("First Floor - Entrance")) {
				setLabyrinth("Temple of Aegis--First Floor-mark0");
			} else if (next.equals("First Floor - To Second Floor")) {
				setLabyrinth("Temple of Aegis--First Floor-mark1");
			} else if (next.equals("First Floor - To Base Level - North West")) {
				setLabyrinth("Temple of Aegis--First Floor-mark2");
			} else if (next.equals("First Floor - To Base Level - North East")) {
				setLabyrinth("Temple of Aegis--First Floor-mark3");
			} else if (next.equals("First Floor - To Base Level - South West")) {
				setLabyrinth("Temple of Aegis--First Floor-mark4");
			} else if (next.equals("First Floor - To Base Level - South East")) {
				setLabyrinth("Temple of Aegis--First Floor-mark5");
			}
			
			else if (next.equals("Base Level - To First Floor - North West")) {
				setLabyrinth("Temple of Aegis--Base Level-mark0");
			} else if (next.equals("Base Level - To First Floor - North East")) {
				setLabyrinth("Temple of Aegis--Base Level-mark1");
			} else if (next.equals("Base Level - To First Floor - South West")) {
				setLabyrinth("Temple of Aegis--Base Level-mark2");
			} else if (next.equals("Base Level - To First Floor - South East")) {
				setLabyrinth("Temple of Aegis--Base Level-mark3");
			}
			
			else if (next.equals("Second Floor - To First Floor")) {
				setLabyrinth("Temple of Aegis--Second Floor-mark0");
			} else if (next.equals("Second Floor - To Third Floor")) {
				setLabyrinth("Temple of Aegis--Second Floor-mark1");
			}
			
			else if (next.equals("Third Floor - To Second Floor")) {
				setLabyrinth("Temple of Aegis--Third Floor-mark0");
			} else if (next.equals("Third Floor - To Fourth Floor - North East")) {
				setLabyrinth("Temple of Aegis--Third Floor-mark1");
			} else if (next.equals("Third Floor - To Fourth Floor - Center")) {
				setLabyrinth("Temple of Aegis--Third Floor-mark2");
			} else if (next.equals("Third Floor - To Fourth Floor - South West")) {
				setLabyrinth("Temple of Aegis--Third Floor-mark3");
			}
			
			else if (next.equals("Fourth Floor - To Third Floor - North East")) {
				setLabyrinth("Temple of Aegis--Fourth Floor-mark0");
			} else if (next.equals("Fourth Floor - To Third Floor - Center")) {
				setLabyrinth("Temple of Aegis--Fourth Floor-mark1");
			} else if (next.equals("Fourth Floor - To Third Floor - South West")) {
				setLabyrinth("Temple of Aegis--Fourth Floor-mark2");
			} else if (next.equals("Fourth Floor - To Fifth Floor")) {
				setLabyrinth("Temple of Aegis--Fourth Floor-mark3");
			}
			
			else if (next.equals("Top Floor - To Fourth Floor")) {
				setLabyrinth("Temple of Aegis--Top Floor-mark0");
			} else if (next.equals("Top Floor - To Crystal Room")) {
				setLabyrinth("Temple of Aegis--Top Floor-mark1");
			} else if (next.equals("Boss")) {
				setBossBattleArea("Serphia");
			}
		}
		
		else if (current.equals("Frozen Forest")) {
			if (next.equals("Entrance")) {
				setLabyrinth("Frozen Forest--Forest Passage-mark0");
			} else if (next.equals("To Ice Cavern")) {
				setLabyrinth("Frozen Forest--Forest Passage-mark1");
			}
		}

		else if (current.equals("Ice Cavern")) {
			if (next.equals("Pillar Room - Entrance")) {
				setLabyrinth("Ice Cavern--Pillar Room-mark0");
			} else if (next.equals("Pillar Room - Frozen Field")) {
				setLabyrinth("Ice Cavern--Pillar Room-mark2");
			} else if (next.equals("Pillar Room - Mysterious Forest")) {
				setLabyrinth("Ice Cavern--Pillar Room-mark1");
			} else if (next.equals("Frozen Field - Pillar Room")) {
				setLabyrinth("Ice Cavern--Frozen Field-mark0");
			} else if (next.equals("Frozen Field - Hall of Confusion")) {
				setLabyrinth("Ice Cavern--Frozen Field-mark1");
			} else if (next.equals("Mysterious Forest - Pillar Room")) {
				setLabyrinth("Ice Cavern--Mysterious Forest-mark0");
			} else if (next.equals("Mysterious Forest - Hall of Anguish")) {
				setLabyrinth("Ice Cavern--Mysterious Forest-mark14");
			} else if (next.equals("Hall of Confusion - Frozen Field")) {
				setLabyrinth("Ice Cavern--Hall of Confusion-mark1");
			} else if (next.equals("Hall of Confusion - Throne Room - North")) {
				setLabyrinth("Ice Cavern--Hall of Confusion-mark3");
			} else if (next.equals("Hall of Confusion - Throne Room - Center")) {
				setLabyrinth("Ice Cavern--Hall of Confusion-mark2");
			} else if (next.equals("Hall of Confusion - Throne Room - South")) {
				setLabyrinth("Ice Cavern--Hall of Confusion-mark0");
			} else if (next.equals("Hall of Anguish - Mysterious Forest")) {
				setLabyrinth("Ice Cavern--Hall of Anguish-mark0");
			} else if (next.equals("Hall of Anguish - Throne Room - North")) {
				setLabyrinth("Ice Cavern--Hall of Anguish-mark3");
			} else if (next.equals("Hall of Anguish - Throne Room - Center")) {
				setLabyrinth("Ice Cavern--Hall of Anguish-mark2");
			} else if (next.equals("Hall of Anguish - Throne Room - South")) {
				setLabyrinth("Ice Cavern--Hall of Anguish-mark0");
			} else if (next.equals("Hall of Anguish - Mysterious Forest")) {
				setLabyrinth("Ice Cavern--Hall of Anguish-mark1");
			} else if (next.equals("Throne Room - Hall of Confusion - North")) {
				setLabyrinth("Ice Cavern--Throne Room-mark4");
			} else if (next.equals("Throne Room - Hall of Confusion - Center")) {
				setLabyrinth("Ice Cavern--Throne Room-mark5");
			} else if (next.equals("Throne Room - Hall of Confusion - South")) {
				setLabyrinth("Ice Cavern--Throne Room-mark0");
			} else if (next.equals("Throne Room - Hall of Anguish - North")) {
				setLabyrinth("Ice Cavern--Throne Room-mark3");
			} else if (next.equals("Throne Room - Hall of Anguish - Center")) {
				setLabyrinth("Ice Cavern--Throne Room-mark2");
			} else if (next.equals("Throne Room - Hall of Anguish - South")) {
				setLabyrinth("Ice Cavern--Throne Room-mark1");
			} else if (next.equals("Throne Room - Boss")) {
				setLabyrinth("Ice Cavern--Throne Room-mark7");
			} else if (next.equals("Boss2")) {
				setBossBattleArea("Menthuattack");
			}
		}
		
		else if (current.equals("Empyrian Temple")) {
			if (next.equals("Hall of Wind - Entrance")) {
				setLabyrinth("Empyrian Temple--Hall of Wind-mark0");
			} else if (next.equals("Tower of Magic - Bottom")) {
				setLabyrinth("Empyrian Temple--Tower of Magic-mark0");
			} else if (next.equals("Tower of Magic - Top")) {
				setLabyrinth("Empyrian Temple--Tower of Magic-mark7");
			} else if (next.equals("Tower of Strength - Bottom")) {
				setLabyrinth("Empyrian Temple--Tower of Strength-mark0");
			} else if (next.equals("Tower of Strength - Top")) {
				setLabyrinth("Empyrian Temple--Tower of Strength-mark7");
			} else if (next.equals("Light")) {
				setLabyrinth("Empyrian Temple--Light-mark0");
			} else if (next.equals("Dark")) {
				setLabyrinth("Empyrian Temple--Dark-mark0");
			} else if (next.equals("Demon Floor")) {
				setLabyrinth("Empyrian Temple--Hall of Memories-mark0");
			}
		}

		else if (current.equals("Menthu's Lair")) {
			if (next.equals("Menthu's Lair - Room of Confusion")) {
				setLabyrinth("Menthu's Lair--Room of Confusion-mark0");
			} else if (next.equals("Menthu's Lair - Hall of Memories")) {
				setLabyrinth("Menthu's Lair--Hall of Memories-mark0");
			} else if (next.equals("Menthu's Lair - Throne of Serpents")) {
				setLabyrinth("Menthu's Lair--Throne of Serpents-mark0");
			} else if (next.equals("Talking to Menthu")) {
				setStory("Talking to Menthu");
			} else if (next.equals("Boss pt.1")) {
				setBossBattleArea("Menthu2");
			} else if (next.equals("Boss pt.2")) {
				setBossBattleArea("Menthuattack2");
			}
		}

		else if (current.equals("Prolog")) {
			setProlog(next);
		} else if (current.equals("Chapter one - Running Away From Home")) {
			setStory(next);
		} else if (current.equals("Chapter two - Zazo, the Home of the Miners")) {
			setStory(next);
		}  else if (current.equals("Chapter three - The Son Returs")) {
			setStory(next);
		}  else if (current.equals("Chapter four - A Wind of Change")) {
			setStory(next);
		}  else if (current.equals("Chapter five - Soaring Through the Sky")) {
			setStory(next);
		} else if (current.equals("Chapter six - The End Draws Near")) {
			setStory(next);
		} else if (current.equals("Epilog")) {
			setStory(next);
		}
		else if (parent.equals("Landscape")) {
			if (current.equals("West Continent")) {
				if (next.equals("Home of Celis")) {
					setWestLandscape("Home of Celis");
				} else if (next.equals("Forest of Reil - North Entrance")) {
					setWestLandscape("Forest of Reil--Deep_Forest-mark0");
				} else if (next.equals("Forest of Reil - South Entrance")) {
					setWestLandscape("Forest of Reil--Deep_Forest-mark1");
				} else if (next.equals("Alares")) {
					setWestLandscape("Alares");
				} else if (next.equals("Grivera")) {
					setWestLandscape("Grivera--First Floor-mark0");
				} else if (next.equals("Port of Alares")) {
					setWestLandscape("Port of Alares");
				} else if (next.equals("Pass to Zazo")) {
					setWestLandscape("Pass to Zazo");
				} else if (next.equals("Central Pass - North Entrance")) {
					setWestLandscape("Central Pass--North East Part-mark0");
				} else if (next.equals("Zazo")) {
					setWestLandscape("Zazo");
				} else if (next.equals("Port of Zazo")) {
					setWestLandscape("Port of Zazo");
				} else if (next.equals("The Great Mine")) {
					setWestLandscape("The Great Mine--The Hall-mark0");
				} else if (next.equals("East Passage")) {
					setWestLandscape("East Passage--West_Mountain-mark0");
				} else if (next.equals("Forest of Bri")) {
					setWestLandscape("Forest of Bri--East_Forest-mark0");
				} else if (next.equals("Mt. Cesadur")) {
					setWestLandscape("Mt. Cesadur--Entrance-mark0");
				} 
			}

			else if (current.equals("East Continent")) {
				if (next.equals("Parasne")) {
					setEastLandscape("Parasne");
				} else if (next.equals("Pensara Forest - Souht Entrance")) {
					setEastLandscape("Pensara Forest--Forest-mark0");
				} else if (next.equals("Pensara Forest - North Entrance")) {
					setEastLandscape("Pensara Forest--Forest-mark1");
				} else if (next.equals("Pensara")) {
					setEastLandscape("Pensara - The Trade District");
				} else if (next.equals("Crossroad")) {
					setEastLandscape("Crossroad");
				} else if (next.equals("Fire Cavern")) {
					setEastLandscape("Fire Cavern--Hall of Fire-mark0");
				} else if (next.equals("Prison")) {
					setEastLandscape("Pensara Prison--Floor 1-mark0");
				} else if (next.equals("Desert - West Entrance")) {
					setEastLandscape("Berca Desert--South West-mark0");
				} else if (next.equals("Desert - North Entrance")) {
					setEastLandscape("Berca Desert--North West-mark0");
				} else if (next.equals("Berca")) {
					setEastLandscape("Berca");
				} else if (next.equals("Temple of Aegis")) {
					setEastLandscape("Temple of Aegis--First Floor-mark0");
				}
			}

			else if (current.equals("North Continent")) {
				if (next.equals("Dellna")) {
					setNorthLandscape("Dellna");
				} else if (next.equals("Frozen Forest")) {
					setNorthLandscape("Frozen Forest--Forest Passage-mark0");
				} else if (next.equals("Ice Cavern")) {
					setNorthLandscape("Demon Cave4-mark0");
				}
			}
		}

		else if (parent.equals("Landscape From the Air")) {
			if (current.equals("West Continent")) {
				if (next.equals("Home of Celis")) {
					setAirLandscape("Home of Celis");
				} else if (next.equals("Forest of Reil - North Entrance")) {
					setAirLandscape("Forest of Reil--Deep_Forest-mark0");
				} else if (next.equals("Forest of Reil - South Entrance")) {
					setAirLandscape("Forest of Reil--Deep_Forest-mark1");
				} else if (next.equals("Alares")) {
					setAirLandscape("Alares");
				} else if (next.equals("Grivera")) {
					setAirLandscape("Grivera--First Floor-mark0");
				} else if (next.equals("Port of Alares")) {
					setAirLandscape("Port of Alares");
				} else if (next.equals("Pass to Zazo")) {
					setAirLandscape("Pass to Zazo");
				} else if (next.equals("Central Pass - North Entrance")) {
					setAirLandscape("Central Pass--North East Part-mark0");
				} else if (next.equals("Zazo")) {
					setAirLandscape("Zazo");
				} else if (next.equals("Port of Zazo")) {
					setAirLandscape("Port of Zazo");
				} else if (next.equals("The Great Mine")) {
					setAirLandscape("The Great Mine--The Hall-mark0");
				} else if (next.equals("East Passage")) {
					setAirLandscape("East Passage--West_Mountain-mark0");
				} else if (next.equals("Forest of Bri")) {
					setAirLandscape("Forest of Bri--East_Forest-mark0");
				} else if (next.equals("Mt. Cesadur")) {
					setAirLandscape("Mt. Cesadur--Entrance-mark0");
				} 
			}

			else if (current.equals("East Continent")) {
				if (next.equals("Parasne")) {
					setAirLandscape("Parasne");
				} else if (next.equals("Pensara Forest - Souht Entrance")) {
					setAirLandscape("Pensara Forest--Forest-mark0");
				} else if (next.equals("Pensara Forest - North Entrance")) {
					setAirLandscape("Pensara Forest--Forest-mark1");
				} else if (next.equals("Pensara")) {
					setAirLandscape("Pensara - The Trade District");
				} else if (next.equals("Crossroad")) {
					setAirLandscape("Crossroad");
				} else if (next.equals("Fire Cavern")) {
					setAirLandscape("Fire Cavern--Hall of Fire-mark0");
				} else if (next.equals("Prison")) {
					setAirLandscape("Pensara Prison--Floor 1-mark0");
				} else if (next.equals("Desert - West Entrance")) {
					setAirLandscape("Berca Desert--South West-mark0");
				} else if (next.equals("Desert - North Entrance")) {
					setAirLandscape("Berca Desert--North West-mark0");
				} else if (next.equals("Berca")) {
					setAirLandscape("Berca");
				} else if (next.equals("Temple of Aegis")) {
					setAirLandscape("Temple of Aegis--First Floor-mark0");
				}
			}

			else if (current.equals("North Continent")) {
				if (next.equals("Dellna")) {
					setAirLandscape("Dellna");
				} else if (next.equals("Frozen Forest")) {
					setAirLandscape("Frozen Forest--Forest Passage-mark0");
				} else if (next.equals("Ice Cavern")) {
					setAirLandscape("Demon Cave4-mark0");
				}
			}
		}
		else if (current.equals("Weapon Store")) {
			WeaponStore.setTestMap(getStoreInfo(next, "Weapon"));
			setStore(Values.WEAPONSTORE);
		} else if (current.equals("Card Store")) {
			CardStore.setTestMap(createStoreInfo(next, "Card"));
			setStore(Values.CARDSTORE);
		} else if (current.equals("Church")) {
			Church.setTestMap(getStoreInfo(next, "Church"));
			setStore(Values.CHURCH);
		} else if (current.equals("Inn")) {
			Inn.setTestMap(getStoreInfo(next, "Inn"));
			setStore(Values.INN);
		}
		
		else if (next.equals("Landscape Test")) {
			setLandTest("west");
		}
		
		// No matching case... //
		else {
			logger.log(Level.WARNING, "No matching case... Current: " + current + " - Next: " + next);
			System.exit(0);
		}
	}

	private void setBossBattleArea(String name) {
		mode = Values.BOSS_BATTLE_AREA;
		nextPlace = name;
		exit(Values.BOSS_BATTLE_AREA);
		Organizer.getOrganizer().setNext(true);
	}

	private void setWestVillage(String name) {
		Database.addStatus("Landscape", Landscape.WEST_CONTINENT);
		setVillage2(name);
	}
	
	private void setEastVillage(String name) {
		Database.addStatus("Landscape", Landscape.EAST_CONTINENT);
		setVillage2(name);
	}
	
	private void setNorthVillage(String name) {
		Database.addStatus("Landscape", Landscape.NORTH_CONTINENT);
		setVillage2(name);
	}
	
	private void setVillage2(String name) {
		mode = Values.VILLAGE;
		nextPlace = name;
		exit(Values.VILLAGE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setLandTest(String name) {
		mode = Values.LANDSCAPE_TEST;
		nextPlace = name;
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setLabyrinth(String name) {
		nextPlace = name;
		exit(Values.LABYRINTH);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setStory(String name) {
		nextPlace = name;
		exit(Values.STORY_SEQUENSE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setProlog(String name) {
		nextPlace = name;
		exit(Values.STORY_SEQUENSE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setWestLandscape(String name) {
		Database.addStatus("Landscape", Landscape.WEST_CONTINENT);
		nextPlace = "land" + name;
		exit(Values.LANDSCAPE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setEastLandscape(String name) {
		Database.addStatus("Landscape", Landscape.EAST_CONTINENT);
		nextPlace = "land" + name;
		exit(Values.LANDSCAPE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setNorthLandscape(String name) {
		Database.addStatus("Landscape", Landscape.NORTH_CONTINENT);
		nextPlace = "land" + name;
		exit(Values.LANDSCAPE);
		Organizer.getOrganizer().setNext(true);
	}
	
	private void setAirLandscape(String name) {
		nextPlace = "air" + name;
		exit(Values.AIR_SHIP);
		Organizer.getOrganizer().setNext(true);
	}
	
	private HashMap<String, String> getStoreInfo(String next, String type) {
		Village vl = new Village();
		vl.init(Organizer.getOrganizer().getInformationFor(next));
		return vl.getTestInfoForType(type);
	}
	
	private HashMap<String, String> createStoreInfo(String next, String type) {
		String[] temp = next.split("--");
		next = temp[0];
		int status = Integer.parseInt(temp[1]);
		HashMap<String, String> info = getStoreInfo(next, type);
		String storeName = info.get("storeName");
		Database.addStatus(storeName, status);
		return info;
	}
	
	private void setStore(int mode) {
		exit(mode);
		Organizer.getOrganizer().setNext(true);
	}

	/**
	 * Gets the info for next place if the next place is a
	 * weapon store.
	 * 
	 * @return the information about the next place, if the next
	 * place is a weapon store.
	 */
	public HashMap<String, String> getInfoForNextPlace() {
		return null;//mode == Values.CARDSTORE ? null : null;
	}
	
	/**
	 * Checks if the organizer should get the information about next place 
	 * from the main information source or just to initiated the next mode.
	 * 
	 * @return true if the organizer should get the next information from the
	 * main file.
	 */
	public boolean shouldGetInfoFromMain() {
		return (mode != Values.CARDSTORE && mode != Values.WEAPONSTORE 
		&& mode != Values.CHURCH && mode != Values.INN)
		&& shouldGetInfoFromMain;
	}

	public static void doCheat(String cheat) {
		String[] commands = cheat.split(" ");
		if (commands != null && commands.length > 0) {
			if (commands[0].equals("trigger")) {
				Database.addStatus(commands[1], Integer.parseInt(commands[2]));
			} else if (cheat.equals("open")) {
				Database.openAllRoads();
				GameMode gm = Organizer.getOrganizer().getCurrentMode();
				if (gm instanceof Landscape) {
					Landscape l = (Landscape) gm;
//					l.openRoads();
				}
			}
		}
		/*
		if (cheat.startsWith("open")) {
			
		} else if (cheat.startsWith("kinset")) {
			int[] att = Load.getCharacterByName("Kin").getAttribute();
			set(att, cheat, value);
		} else if (cheat.startsWith("celisset")) {
			int[] att = Load.getCharacterByName("Celis").getAttribute();
			set(att, cheat, value);
		} else if (cheat.startsWith("borealisset")) {
			int[] att = Load.getCharacterByName("Borealis").getAttribute();
			set(att, cheat, value);
		} else if (cheat.startsWith("zalziset")) {
			int[] att = Load.getCharacterByName("Zalzi").getAttribute();
			set(att, cheat, value);
		}
		*/
	}
/*
	private static void set(int[] att, String cheat, int value) {
		if (cheat.contains("setmaxhp")) {
			att[Creature.MAX_HP] = value;
		} else if (cheat.contains("setdef")) {
			att[Creature.DEFENSE] = value;
		} else if (cheat.contains("setmdef")) {
			att[Creature.MAGIC_DEFENSE] = value;
		} else if (cheat.contains("setagi")) {
			att[Creature.AGILITY] = value;
		} else if (cheat.contains("seteva")) {
			att[Creature.EVADE] = value;
		} else if (cheat.contains("sethit")) {
			att[Creature.HIT] = value;
		} else if (cheat.contains("setatt")) {
			att[Creature.ATTACK] = value;
		} else if (cheat.contains("setmatt")) {
			att[Creature.MAGIC_ATTACK] = value;
		} else if (cheat.contains("setsup")) {
			att[Creature.SUPPORT_ATTACK] = value;
		} else if (cheat.contains("sethp")) {
			att[Creature.HP] = value;
		} else if (cheat.contains("setnextlv")) {
			att[Creature.EXP_LEFT_TO_NEXT_LEVEL] = value;
		} else if (cheat.contains("setdecksize")) {
			att[Creature.DECK_SIZE] = value;
		} else if (cheat.contains("sethandsize")) {
			att[Creature.HAND_SIZE] = value;
		} else if (cheat.contains("setexp")) {
			att[Creature.EXPERIANCE] = value;
		}
	}
	*/
}
