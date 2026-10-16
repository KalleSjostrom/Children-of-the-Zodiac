package battle.bosses;

import java.util.ArrayList;

import villages.utils.DialogSequence;

public class Dialog {
	
	private int counter;
	private ArrayList<DialogSequence> dialog;
	
	public Dialog() {
		dialog = new ArrayList<DialogSequence>();
	}

	public DialogSequence getNext() {
		if (counter < dialog.size()) {
			return dialog.get(counter++);
		}
		return null;
	}

	public void add(DialogSequence seq) {
		dialog.add(seq);
	}
}
