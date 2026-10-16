/*
 * Classname: Inn.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package store;

import static menu.MenuValues.DISTANCE;
import static menu.MenuValues.MENU_TEXT_X;
import static menu.MenuValues.MENU_TEXT_Y;
import static menu.MenuValues.MENU_TITLE_Y;
import equipment.Slot;
import factories.Load;
import graphics.Graphics;
import info.Database;
import info.LabyrinthInfo;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import menu.Node;
import menu.StartPage;

import java.util.logging.*;

import sound.SoundPlayer;
import sound.SoundValues;
import villages.utils.Dialog;
import villages.utils.Loot;
import cards.Card;
import cards.magic.Death;
import cards.magic.Earth;
import cards.magic.Fire;
import cards.magic.Flare;
import cards.magic.SacredBeam;
import cards.magic.Ultima;
import cards.magic.Wind;
import cards.neutral.TheElementOfIce;
import cards.offense.BattleCard;
import cards.offense.ChameleonStrike;
import cards.offense.CriticalBlow;
import cards.offense.CrushingSaber;
import cards.offense.SpiritAssault;
import cards.support.Focus;
import cards.support.Fungi;
import cards.support.HerbOfVitality;
import cards.support.Resurrect;

/**
 * This class represents an Inn in a village. In the inn, the player can 
 * sleep until morning or just take a nap which will cause the player
 * to wake up in the middle of the night.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 13 May 2008
 */
public class Inn extends AbstractStore {
	
	private static HashMap<String, String> testInfo;
	private boolean delay;
	private int menuMode = MENU;
	private Loot currentLoot;
	private static Logger logger = Logger.getLogger("Inn");
	private static final int SELL_MAP = BASE;
	private static final int SHOW_PRIZE = BASE + 1;
	
	private static final String SELL_MAP_NAME = "Trade map info";
	private static final HashMap<String, Loot> prizes = createPrices();
	private static final int LAB_PRIZE_REDEEMED = 1;

	/**
	 * Creates the inn from the hash map containing the information about
	 * the inn. See the loadFromInfo() in Building.
	 * 
	 * @param info the information about the inn.
	 */
	public void init(HashMap<String, String> info) {
		if (info == null) {
			info = testInfo;
		}
		super.init(info);
		initStore();
		activeNode = new Node(null, "Inn");
		nextPlace = info.get("villageName");
		fillDay();
		loadFromInfo(info);
		if (hasStoredTriggers()) {
			makeNewDialog("The first night is free!", "");
		}
		setStoreImages(INN);
		setMenuImagesUsed(0x00000fff);
		
		logicLoading = false;
	}

	/**
	 * Updates the menu and checks the game input.
	 * 
	 * @param elapsedTime the time between updates.
	 */
	public void update(long elapsedTime) {
		super.update(elapsedTime);
	}

	protected void dirPressed(int dir) {
		switch(menuMode) {
		case SELL_MAP : 
			dirMenuPressed(activeNode, dir);
			break;
		case MENU : 
			dirMenuPressed(activeNode, dir);
			break;
		case CONFIRM_BUY :
			dirMenuPressed(confirmNode, dir);
			break;
		}
	}
	
	/**
	 * This method is called if the circle button has been pressed.
	 * It exits the inn.
	 */
	protected void circlePressed() {
		switch (menuMode) {
		case SELL_MAP :
			Node n = activeNode.getParent();
			if (n != null) {
				setDialogCopyAsACurrent();
				activeNode = n;
				menuMode = MENU;
			}
			break;
		case SHOW_PRIZE :
			menuMode = SELL_MAP;
			currentLoot = null;
			break;
		default:
			exit(Values.SWITCH_BACK);
		}
	}
	
	/**
	 * This method is called when the cross button is pressed.
	 * It executes the current node.
	 */
	protected void crossPressed() {
		Node n = activeNode.getCurrentChild();
		String playerChoice = n.getName();
		if (playerChoice.equals("Exit")) {
			exit(Values.SWITCH_BACK);
			return;
		} else if (playerChoice.equals("Back")) {
			circlePressed();
			return;
		} else if (playerChoice.equals(SELL_MAP_NAME)) {
			ArrayList<String> list = getSellMapList();
			if (list.size() > 0) {
				copyDialog();
				makeNewDialog("Trade the maps you've fully explored for nice prizes!", "");
				menuMode = SELL_MAP;
				activeNode = n;
				activeNode.setActive(true);
				fillSellMap(list);
			} else {
				SoundPlayer.playSound(SoundMap.MENU_ERROR);
			}
			return;
		}
		String choice;
		switch (menuMode) {
		case MENU :
			checkBuy(activeNode.getCurrentChild().getPrice());
			menuMode = CONFIRM_BUY;
			break;
		case SHOW_PRIZE :
			menuMode = SELL_MAP;
			currentLoot = null;
			break;
		case SELL_MAP :
			String labName = activeNode.getCurrentChild().getName();
			currentLoot = prizes.get(labName);
			Database.addStatus(labName, LAB_PRIZE_REDEEMED);
			activeNode.getCurrentChild().setEnabled(false);
			Load.collectLoot(currentLoot);
			menuMode = SHOW_PRIZE;
			break;
		case CONFIRM_BUY :
			n = confirmNode.getCurrentChild();
			choice = n.getName();
			if (choice.equals("Call it a night")) {
				int price = activeNode.getCurrentChild().getPrice();
				Load.getPartyItems().addGold(-price);
				this.setMusicFadeOutSpeed(SoundValues.FAST);
				goToDay();
				final Inn inn = this;
				new Thread() {
					public void run() {
						Values.sleep(100);
						while (inn.isMusicFadingDown()) {
							Values.sleep(100);
						}
						SoundPlayer.playSound(SoundMap.VILLAGE_SLEEP);
					}
				}.start();
			}
			confirmNode.setMenuCursor(0);
			menuMode = MENU;
			break;
		}
	}

	private ArrayList<String> getSellMapList() {
		ArrayList<String> exploredLabs = new ArrayList<String>();
		
		HashMap<String, LabyrinthInfo> labs = Database.getVisitedLabyrinths();
		ArrayList<String> list = Database.getVisitedLabyrinthsList();
		for (String s : list) {
			LabyrinthInfo info = labs.get(s);
			boolean b = info.isFullyExplored();
			if (b) {
				String name = info.getLabyrinthName();
				int status = Database.getStatusFor(name);
				if (status != LAB_PRIZE_REDEEMED) {
					exploredLabs.add(name);
				}
			}
		}
		return exploredLabs;
	}

	private void fillSellMap(ArrayList<String> list) {
		Node n = activeNode;
		n.removeChildren(true);
		if (!n.hasChildren()) {
			for (String s : list) {
				n.insertChild(s);
			}
			n.insertChild("Back");
			n.setDistance(DISTANCE);
			n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
		}
	}

	/**
	 * This method loads the day.
	 */
	private void goToDay() {
		for (int i = 0; i < Load.getCharacters().size(); i++) {
			Load.getCharacters().get(i).fullCure();
		}
		if (nextPlace.contains("night")) {
			logger.log(Level.WARNING, "The next place in Inn should not contain the word night");
		}
		if (delay = checkStoredTriggers()) {
			return;
		}
		nextPlace = nextPlace.toLowerCase().replace(" ", "_");
		delay = true;
		exit(Values.SWITCH_BACK);
	}
	
	public int checkExit() {
		if (isDone()) {
			if (delay) {
				Values.sleep(7000);
			}
			return mode;
		}
		return Values.NO_MODE_IS_SELECTED;
	}
	
	/**
	 * Checks the stored triggers. If any is found with the name "inn"
	 * it will load the stored trigger instead of going to night or day.
	 * 
	 * @return true if a stored trigger was found.
	 */
	private boolean checkStoredTriggers() {
		String name = infoMap.get("villageName") + "inn";
		String s = Database.getStoredTriggers(name);
		if (s != null) {
			nextPlace = s;
			Database.clearStoredTriggers(name);
			exit(Values.VILLAGE_STORY);
		}
		return s != null;
	}
	
	private boolean hasStoredTriggers() {
		String name = infoMap.get("villageName") + "inn";
		String s = Database.getStoredTriggers(name);
		return s != null;
	}

	
	/**
	 * This method draws the inn. It can draw the inn on the given 
	 * graphics3D or choose to draw it on the protected graphics
	 * from the Building class. 
	 * 
	 * @param g the graphics to draw on.
	 */
	protected void draw3D(Graphics g) {
//		g.drawImage(keeper, 300, 205);
		String title = activeNode.getName();
		g.drawString(title, MENU_TEXT_X, MENU_TITLE_Y);
		StartPage.drawInfo(g);
		activeNode.drawChildrenFreely(g, true, false, false, false, false);
		switch (menuMode) {
		case CONFIRM_BUY : 
			drawConfirmDialog(g, "Rent a room", activeNode.getCurrentChild().getPrice());
			break;
		case SHOW_PRIZE :
			Dialog.drawGift(g, "You got the a prize: " + currentLoot.getContentName(), "", currentLoot);
			break;
		}
	}
	
	/**
	 * Fills the menu to display when day time.
	 */
	private void fillDay() {
		int price = hasStoredTriggers() ? 0 : 50;
		Node n = activeNode;
		n.insertChild("Rest").setPrice(price);
		ArrayList<String> list = getSellMapList();
		Node smn = n.insertChild(SELL_MAP_NAME);
		smn.setEnabled(list.size() > 0);
		
		int maxY = MENU_TEXT_Y + 3 * DISTANCE;
		smn.setBoundingBox(MENU_TEXT_Y, maxY, 978);
		
		n.insertChild("Exit");
		n.setDistance(DISTANCE);
		n.setPositions(MENU_TEXT_X, MENU_TEXT_Y);
	}

	public static void setTestMap(HashMap<String, String> info) {
		testInfo = info;
	}

	@Override
	protected void fillPositiveConfirm(Node n) {
		n.insertChild("Call it a night");
	}
	
	private static HashMap<String, Loot> createPrices() {
		HashMap<String, Loot> prices = new HashMap<String, Loot>();
		
		Card reilCard = Card.createCard(Wind.class.getName(), 2, false, Slot.MAGIC, 200);
		Loot reilLoot = new Loot("Earth", Loot.CARD, reilCard);
		reilLoot.setContentName("Earth");
		prices.put("Forest of Reil", reilLoot);
		
		Card griveraCard = Card.createCard(CriticalBlow.class.getName(), 2, true, Slot.ATTACK, 2000);
		Loot griveraLoot = new Loot("Critical Blow", Loot.CARD, griveraCard);
		griveraLoot.setContentName("Critical Blow");
		prices.put("Grivera", griveraLoot);
		
		Card centralCard = Card.createCard(Fire.class.getName(), 2, false, Slot.MAGIC, 2000);
		Loot centralLoot = new Loot("Fire", Loot.CARD, centralCard);
		centralLoot.setContentName("Fire");
		prices.put("Central Pass", centralLoot);
		
		// TODO: Which slot type? Doesn't matter.
		Card greatCard = Card.createCard(TheElementOfIce.class.getName(), 1, true, 1, 2000);
		Loot greatLoot = new Loot("Ice Element", Loot.CARD, greatCard);
		greatLoot.setContentName("Ice Element");
		prices.put("The Great Mine", greatLoot);
		
		Card eastCard = Card.createCard(BattleCard.class.getName(), 2, false, Slot.ATTACK, 2000);
		Loot eastLoot = new Loot("Battle Card", Loot.CARD, eastCard);
		eastLoot.setContentName("Battle Card");
		prices.put("East Passage", eastLoot);
		
		Card briCard = Card.createCard(Focus.class.getName(), 1, true, Slot.SUPPORT, 2000);
		Loot briLoot = new Loot("Focus", Loot.CARD, briCard);
		briLoot.setContentName("Focus");
		prices.put("Forest of Bri", briLoot);
		
		Card cesadurCard = Card.createCard(ChameleonStrike.class.getName(), 1, false, Slot.ATTACK, 0);
		Loot cesadurLoot = new Loot("Chameleon Strike", Loot.CARD, cesadurCard);
		cesadurLoot.setContentName("Chameleon Strike");
		prices.put("Mt. Cesadur", cesadurLoot);
		
		Card pensaraCard = Card.createCard(Fungi.class.getName(), 1, true, Slot.SUPPORT, 0);
		Loot pensaraLoot = new Loot("Fungi", Loot.CARD, pensaraCard);
		pensaraLoot.setContentName("Fungi");
		prices.put("Pensara Forest", pensaraLoot);
		
		Card fireCard = Card.createCard(Earth.class.getName(), 3, false, Slot.MAGIC, 0);
		Loot fireLoot = new Loot("Earth", Loot.CARD, fireCard);
		fireLoot.setContentName("Earth");
		prices.put("Fire Cavern", fireLoot);
		
		Card prisonCard = Card.createCard(SpiritAssault.class.getName(), 1, false, Slot.ATTACK, 0);
		Loot prisonLoot = new Loot("Spirit Assault", Loot.CARD, prisonCard);
		prisonLoot.setContentName("Spirit Assault");
		prices.put("Pensara Prison", prisonLoot);
		
		Card dormaCard = Card.createCard(HerbOfVitality.class.getName(), 1, true, Slot.SUPPORT, 0);
		Loot dormaLoot = new Loot("Herb of Vitality", Loot.CARD, dormaCard);
		dormaLoot.setContentName("Herb of Vitality");
		prices.put("Dorma's Forest", dormaLoot);
		
		Card desertCard = Card.createCard(CrushingSaber.class.getName(), 3, true, Slot.ATTACK, 0);
		Loot desertLoot = new Loot("Crushing Saber", Loot.CARD, desertCard);
		desertLoot.setContentName("Crushing Saber");
		prices.put("Berca Desert", desertLoot);
		
		Card sewersCard = Card.createCard(Flare.class.getName(), 1, false, Slot.MAGIC, 0);
		Loot sewersLoot = new Loot("Flare", Loot.CARD, sewersCard);
		sewersLoot.setContentName("Flare");
		prices.put("The Sewers", sewersLoot);
		
		Card aegisCard = Card.createCard(Death.class.getName(), 1, true, Slot.MAGIC, 0);
		Loot aegisLoot = new Loot("Death", Loot.CARD, aegisCard);
		aegisLoot.setContentName("Death");
		prices.put("Temple of Aegis", aegisLoot);

		Card frozenCard = Card.createCard(Resurrect.class.getName(), 3, false, Slot.SUPPORT, 0);
		Loot frozenLoot = new Loot("Resurrect", Loot.CARD, frozenCard);
		aegisLoot.setContentName("Resurrect");
		prices.put("Frozen Forest", frozenLoot);
		
		Card iceCard = Card.createCard(SacredBeam.class.getName(), 3, false, Slot.MAGIC, 0);
		Loot iceLoot = new Loot("Sacred Beam", Loot.CARD, iceCard);
		iceLoot.setContentName("Sacred Beam");
		prices.put("Ice Cavern", iceLoot);
		
		Card empyrianCard = Card.createCard(Ultima.class.getName(), 1, true, Slot.MAGIC, 0);
		Loot empyrianLoot = new Loot("Ultima", Loot.CARD, empyrianCard);
		empyrianLoot.setContentName("Ultima");
		prices.put("Empyrian Temple", empyrianLoot);
		
		Card menthuCard = Card.createCard(Resurrect.class.getName(), 3, true, Slot.SUPPORT, 0);
		Loot menthuLoot = new Loot("Resurrect", Loot.CARD, menthuCard);
		menthuLoot.setContentName("Resurrect");
		prices.put("Menthu's Lair", menthuLoot);
		return prices;
	}
}