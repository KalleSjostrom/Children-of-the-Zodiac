package labyrinth.inventory;

import organizer.Organizer;

import info.Database;
import labyrinth.Labyrinth;
import labyrinth.inventory.Inventory;

public class DummyDoor extends Inventory {
	
	private String dataBaseName;

	public DummyDoor(String name) {
		super(null, 0, 0, null, 0);
		dataBaseName = Organizer.convert(name);
	}

	@Override
	public void activate(Labyrinth labyrinth) {
		// TODO Auto-generated method stub
	}

	@Override
	protected void setSettings() {
		// TODO Auto-generated method stub

	}
	
	public void setStatus(int value) {
		status = value;
		Database.addStatus(dataBaseName, value);
	}
	
	public void addStatus(int value) {
		status = Database.getStatusFor(dataBaseName);
		status += value;
		Database.addStatus(dataBaseName, status);
	}
	
	@Override
	public String getMapImage() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean isPassable(int dir) {
		// TODO Auto-generated method stub
		return false;
	}
	
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	@Override
	public boolean isDirectedTowards(int dir) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return false;
	}
}
