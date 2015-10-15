package labyrinth.inventory;

import graphics.Object2D;
import info.BattleValues;
import info.Database;
import info.LabyrinthMap;
import info.SoundMap;

import java.util.ArrayList;
import java.util.StringTokenizer;

import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.mission.Mission;
import sound.SoundPlayer;
import villages.villageStory.Parser;

public class MissionBomb extends Inventory {
	
	private ArrayList<String[]> dialogs = new ArrayList<String[]>();
	private int current = 0;
	private String currentSpeaker;
	private boolean first = true;
	private boolean missionDone = false;

	public MissionBomb(Node n, int dir, int nrOfTexs, String image, int status, StringTokenizer t) {
		super(n, dir, nrOfTexs, image, status);
		if (status == 1) {
			currentTex = Object2D.INVISIBLE;
			current = Integer.MAX_VALUE;
		} else {
			current = 0;
			currentTex = 0;
			while (t.hasMoreTokens()) {
				String[] dial = new String[3];
				String[] s = Parser.getArgument(t.nextToken());
				dial[0] = s[0];
				s = Parser.getText(t, s[1]);
				dial[1] = s[0];
				dial[2] = (s.length > 1) ? s[1] : "";
				dialogs.add(dial);
			}
			if (dialogs.size() > 0) {
				currentSpeaker = dialogs.get(0)[0];
			}
		}
	}
	
	@Override
	protected void setSettings() {
		scale = BattleValues.CARD_SCALE;
		info = getSettings();
		heightOffset = info.getHeightOffset();
		zOff = info.getZOffset();
		scale2 = info.getScale();
	}
	
	@Override
	public void activate(Labyrinth labyrinth) {
		if (current < dialogs.size()) {
			String[] d = dialogs.get(current);
			String cs = d[0];
			String[] css = cs.split("-");
			if (css.length > 1) {
				int i = Integer.parseInt(css[0]);
				Mission mission = labyrinth.getMission();
				int ms = mission.getStatus();
				if (i != ms) {
					current++;
					activate(labyrinth);
					return;
				}
				d[0] = css[1];
			}
			if (currentSpeaker.compareTo(cs) != 0) {
				currentSpeaker = cs;
				first = !first;
			}
//			if (d.length > 3) {
//				
//			}
			labyrinth.drawDialog(first, d[0].replace("()", ""), d[1], d[2], d[0].contains("()"));
			current++;
		} else if (!missionDone) {
			Mission mission = labyrinth.getMission();
			mission.incrementStatus();
			missionDone  = true;
			SoundPlayer.playSound(SoundMap.LABYRINTH_DOOR_SLIDING_STONE);
			if (mission.checkIfFinished()) {
				ArrayList<String[]> missionDialogs = mission.getFinishedDialogs();
				if (missionDialogs != null) {
					dialogs = missionDialogs;
					current = 0;
				}
			}
			activate(labyrinth);
		} else {
			doneForGood();
		}
	}

	private void doneForGood() {
		currentTex = Object2D.INVISIBLE;
		status = 1;
		Database.addStatus(dataBaseName, status);
	}

	@Override
	public String getMapImage() {
		return LabyrinthMap.bomb[status];
	}

	public boolean isPassable(int dir) {
		return status != 0;
	}
	
	public boolean isPassableOnThis(int dir) {return isPassable(dir);}

	public boolean isDirectedTowards(int dir) {
		return true;
	}

	@Override
	public boolean shouldDrawWhenOnlySeen() {
		return true;
	}
}
