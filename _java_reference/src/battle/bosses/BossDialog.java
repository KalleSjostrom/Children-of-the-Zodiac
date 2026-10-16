package battle.bosses;

import java.util.HashMap;

import villages.utils.DialogSequence;

public class BossDialog {
	
	public static final int BEGINNING = 0;
	public static final int ENEMY_DEAD = -1;
	public static final int PARTY_DEAD = -2;
	
	private HashMap<Integer, Dialog> dialogs = new HashMap<Integer, Dialog>();
	private String nextPlace;

	public boolean wantsToTalk(int i) {
		return dialogs.get(i) != null;
	}

	public DialogSequence get(int i) {
		Dialog dialog = dialogs.get(i);
		if (dialog != null) {
			return dialog.getNext();
		}
		return null;
	}

	public void set(int i, Dialog d) {
		dialogs.put(i, d);
	}

	public String getNextPlace() {
		return nextPlace;
	}
	
	public void setNesxtPlace(String n) {
		nextPlace = n;
	}
}
