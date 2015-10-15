package labyrinth.inventory;

import factories.Load;
import graphics.Graphics;
import info.BattleValues;
import info.LabyrinthMap;
import info.SoundMap;
import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;
import particleSystem.SaveSystem;
import sound.SoundPlayer;

public class Save extends Inventory {
	
	private SaveSystem save;
	
	public Save(Node n, int dir) {
		super(n, dir, 0, "", 0);
	}
	
	@Override
	public void initDraw(Graphics g) {
		save = new SaveSystem(node.getPos().getX(), node.getPos().getZ());
	}

	@Override
	public void activate(Labyrinth labyrinth) {}
	
	@Override
	public void arrive(Labyrinth labyrinth) {
		labyrinth.drawDialog("Your hp is restored and your deck is shuffled!", "Enter the menu to save the game.");
		SoundPlayer.playSound(SoundMap.LABYRINTH_SAVE_PLACE);
		Load.cureParty(1);
		Load.shuffleAllDecks();
	}
	
	public void draw(Graphics g, int dir) {
		g.setLightEnabled(false);
		save.update();
		save.draw(g, dir);
		g.setLightEnabled(true);
	}
	
	@Override
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		zOff = 1.99f;
	}

	@Override
	public String getMapImage() {
		return LabyrinthMap.save[0];
	}

	@Override
	public boolean isPassable(int dir) {
		return true;
	}
	
	@Override
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	@Override
	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return false;
	}
	
	@Override
	public boolean useMaterial() {
		return true;
	}
}
