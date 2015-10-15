package labyrinth.inventory;

import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Utils3D;
import info.Database;
import info.LabyrinthMap;
import info.SoundMap;
import labyrinth.Labyrinth;
import labyrinth.Node;

import organizer.Organizer;

import sound.SoundPlayer;

import com.jogamp.opengl.util.texture.Texture;

public abstract class AbstractDoor extends Inventory {

	private static final int STRAIGHT = 0;
	private static final int DOWN = 1;
	private static final int UP = 2;
	protected int direction = STRAIGHT;
	private String nameInMain;
	protected int index;

	public AbstractDoor(Node n, int dir, int nrOfTexs, String image, int status) {
		super(n, dir, nrOfTexs, image, status);
	}
	
	public void setGoingUp(boolean goingUp) {
		direction = goingUp ? UP : DOWN;
	}
	
	public void checkHaveBeen() {
		super.checkHaveBeen();
		String[] temp = dataBaseName.split("\\.");
		nameInMain = Organizer.convert(temp[0]) + "-mark" + index;
		haveBeenIn = Database.getStatusFor(dataBaseName + "havebeenin") == 1;
	}
	
	public abstract boolean checkIfOpen();
		
	@Override
	public String getMapImage() {
		if (checkIfOpen()) {
			return getMapImageWhenOpen();
		}
		return getMapImageWhenClosed();
	}
		
	protected String getMapImageWhenOpen() {
		String image = null;
		switch (direction) {
		case STRAIGHT :
			image = LabyrinthMap.doorOpen[(dir + 2) % 4];
			break;
		case UP :
			image = LabyrinthMap.stairs[1];
			break;
		case DOWN :
			image = LabyrinthMap.stairs[0];
			break;
		}
		return image;
	}
	
	protected void enter(Labyrinth lab, InventoryInfo info) {
		if (info == null) {
			switch (direction) {
			case UP :
				SoundPlayer.playSound(SoundMap.LABYRINTH_STONE_STAIRS);
				break;
			case DOWN :
				SoundPlayer.playSound(SoundMap.LABYRINTH_STONE_STAIRS);
				break;
			}
		} else if (info.hasSoundEffect()) {
			SoundPlayer.playSound(info.getSoundEffect());
		}
	}
	
	protected String getMapImageWhenClosed() {
		return LabyrinthMap.doorClosed[(dir + 2) % 4];
	}

	public void drawInMap(Graphics g, float x, float y, int angle) {
		if (mapImageMoveWithMap()) {
			String s = getMapImage();
			if (s != null) {
				Texture tex = ImageHandler.getTexture(s).getTexture();
				if (tex != null) {
					Utils3D.draw3D(g, tex, x, y, 0, .1f);
				}
			}
		} else {
			super.drawInMap(g, x, y, angle);
		}
	}
	
	protected boolean mapImageMoveWithMap() {
		if (checkIfOpen()) {
			return direction == STRAIGHT;
		}
		return true;
	}
	
	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return false;
	}
	
	@Override
	public boolean isPassable(int dir) {
		return (this.dir + 2) % 4 != dir;
	}
	
	@Override
	public boolean isPassableOnThis(int dir) {
		return (this.dir) % 4 != dir;
	}

	@Override
	public boolean isDirectedTowards(int dir) {
		return this.dir == dir;
	}
		
	public void setStatus(int value) {
		Database.addStatus(dataBaseName, value);
		status = value;
	}
	
	public int getStatus() {
		return status;
	}

	public String getNameInMain() {
		return nameInMain;
	}
}
