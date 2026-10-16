package labyrinth.inventory;

import info.BattleValues;
import info.LabyrinthMap;

import java.util.StringTokenizer;

import labyrinth.Node;

public class LadderDoor extends Door {
	
	public static boolean goingUp;
	public boolean thisGoingUp;
	
	public LadderDoor(Node node, int dir, String openRoad, String image,
			int status, StringTokenizer tok, String next) {
		super(node, dir, openRoad, next, status, tok, 1, image);
	}
	
	@Override
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		thisGoingUp = goingUp;
		info = getSettings();
		heightOffset = info.getHeightOffset();
		zOff = info.getZOffset();
		scale2 = info.getScale();
	}

	@Override
	public String getMapImage() {
		return LabyrinthMap.stairs[thisGoingUp ? 1 : 0];
	}
	
//	@Override
//	public void activate(Labyrinth lab) {
//		int playerDir = ((lab.getPlayerAngle() - 90) / 90 + 4) % 4;
//		if (playerDir == dir) {
//			SoundPlayer.playSound(info.getSoundEffect());
//			super.activate(lab);
//		}
//	}
	
	@Override
	public boolean isPassable(int dir) {
		return false;
	}
	
	@Override
	protected boolean mapImageMoveWithMap() {
		return false;
	}
	
	@Override
	public boolean isPassableOnThis(int dir) {
		return true;
	}
	
	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return true;
	}
}
