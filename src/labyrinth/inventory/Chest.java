/*
 * Classname: Chest.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import equipment.AbstractEquipment;
import factories.EquipmentFactory;
import factories.Load;
import info.BattleValues;
import info.Database;
import info.LabyrinthMap;
import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;
import sound.SoundPlayer;
import villages.utils.DialogSequence;
import villages.utils.Loot;
import cards.Card;

/**
 * This class is the inventory chest. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the Database class is called to find out 
 * whether the chest has been opened or not.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 13 Sep 2008
 */
public class Chest extends Inventory {
	
	private static final int GOLD = 0;
	private static final int EQUIPMENT = 1;
	private static final int CARD = 2;
	private static final int ITEM = 3;
	
	private String name;
	private String[] itemInfo; 
	private int type;

	/**
	 * Creates a new chest from the given information.
	 * 
	 * @param node the node where the chest should be.
	 * @param dir the direction the texture should face. 
	 * (Values.UP, .RIGHT, .DOWN, .LEFT).
	 * @param nrOfTexs the number of textures to use.
	 * @param image the name of the first image in the series.
	 * @param contentType the type of content. Can be either of Chest.GOLD, 
	 * .WEAPON, .ARMOR, .CARD.
	 * @param contentName the name of the content. Amount of gold if 
	 * contentType is Chest.GOLD.
	 * @param info a string array containing the information about the content.
	 * @param status the status for this button according to the Database.
	 */
	public Chest(Node node, int dir, int nrOfTexs, String image, int contentType, 
			String contentName, String[] info, int status) {
		super(node, dir, nrOfTexs, image, status);
		
		type = contentType;
		name = contentName;
		itemInfo = info;
		if (images.length > 1) {
			currentTex = status;
			if (status == -1) {
				currentTex = 0;
			}
		} else {
			currentTex = 0;
		}
	}

	/**
	 * @inheritDoc
	 */
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		info = getSettings();
		heightOffset = info.getHeightOffset();
		zOff = info.getZOffset();
		scale2 = info.getScale();
	}

	/**
	 * Opens the chest. This method starts the animation for this
	 * chest and updates the database, if the chest has not already
	 * been opened.
	 * 
	 * @param labyrinth the labyrinth where this chest is. 
	 */
	public void activate(Labyrinth labyrinth) {
		int status = Database.getStatusFor(dataBaseName);
		if (status == 0) {
			if (images.length > 1) {
				currentTex = 1;
			}
			execute(labyrinth);
			Database.addStatus(dataBaseName, 1);
		}
	}
	
	@Override
	public String getMapImage() {
		int status = Database.getStatusFor(dataBaseName);
		if (status == -1) {
			status = 0;
			Database.addStatus(dataBaseName, 0);
		}
		return LabyrinthMap.chest[status];
	}


	/**
	 * This method actually gives the player the content of the chest.
	 * It also calls the labyrinths method drawDialog() to explain
	 * to the player what has been received.
	 *  
	 * @param labyrinth the labyrinth where this chest resides in.
	 */
	private void execute(Labyrinth labyrinth) {
		String one;
		String two;
		SoundPlayer.playSound(info.getSoundEffect());
		switch(type) {
		case GOLD : 
			int amount = Integer.parseInt(name);
			Load.getPartyItems().addGold(amount);
			one = "You found " + amount + " gold coins!";
			two = "";
			labyrinth.drawDialog(one, two);
			break;
		case EQUIPMENT : 
			name = name.replace("_", " ");
			AbstractEquipment ae = 
				EquipmentFactory.getEquipment(name);
			Load.addEquipment(ae);
			one = "You found " + name + "!";
			two = "";
			labyrinth.drawDialog(one, two);
			break;
		case CARD : 
			int level = Integer.parseInt(itemInfo[0]);
			boolean all = false;
			if (itemInfo.length > 1) {
				all = Boolean.parseBoolean(itemInfo[1]);
			}
			Card c = Card.createCard(name, level, all);
			Load.getPartyItems().addCard(c);
			one = "You received the card " + c.getName() + "!";
			DialogSequence ds = new DialogSequence(one, "");
			Loot l = new Loot("", null, null, Loot.CARD, c, null);
			ds.setGift(l);
			labyrinth.drawDialog(ds);
			break;
		case ITEM : 
			name = name.replace("_", " ");
			Load.getPartyItems().addItem(name, 1);
			one = "You received the item " + name + "!";
			two = "";
			labyrinth.drawDialog(one, two);
			break;
		}
	}

	@Override
	public boolean isPassable(int dir) {
		return false;
	}
	
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	@Override
	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return true;
	}
	
	public boolean useMaterial() {
		return true;
	}
}
