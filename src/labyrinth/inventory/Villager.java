package labyrinth.inventory;

import graphics.Object2D;
import info.BattleValues;
import info.Database;
import info.LabyrinthMap;

import java.util.ArrayList;
import java.util.StringTokenizer;

import labyrinth.Labyrinth;
import labyrinth.Node;
import labyrinth.inventory.Inventory;
import labyrinth.mission.Mission;
import villages.villageStory.Parser;

public class Villager extends Inventory {
	
	private ArrayList<String[]> dialogs = new ArrayList<String[]>();
	private int current = 0;
	private String currentSpeaker;
	private boolean first = true;
	private boolean missionDone = false;

	public Villager(Node n, int dir, int nrOfTexs, String image, int status, StringTokenizer t) {
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
		scale2 = 2.4f;
	}
	
//	public void draw(float dt, Graphics g) {
//		GL2 gl = Graphics.gl2;
//		gl.glEnd();
//		texture[0].bind(g);
//		gl.glBegin(GL2.GL_QUADS);
//		draw(gl, dir);
//		gl.glEnd();
//	}
	
	@Override
	public void activate(Labyrinth labyrinth) {
		if (current < dialogs.size()) {
			String[] d = dialogs.get(current);
			String cs = d[0];
			if (currentSpeaker.compareTo(cs) != 0) {
				currentSpeaker = cs;
				first = !first;
			}
			labyrinth.drawDialog(first, d[0], d[1], d[2], false);
			current++;
		} else if (!missionDone) {
			Mission mission = labyrinth.getMission();
			mission.incrementStatus();
			missionDone  = true;
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
		return LabyrinthMap.miner[status];
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
