package menu.tutorial;

import java.util.ArrayList;
import java.util.HashMap;

import sound.SoundPlayer;

import bodies.Vector3f;

public class Chapter {
	
	public static final int LAST_PAGE = -10;
	
	private ArrayList<ArrayList<Row>> chapter;
	private int index = -1;
	private int yPos;
	private int xPos;
	private int soundPage = -2;
	private String sound;
	
	public Chapter(int x, int y) {
		chapter = new ArrayList<ArrayList<Row>>();
		xPos = x;
		yPos = y;
	}

	public boolean next() {
		index++;
		if (index == soundPage) {
			SoundPlayer.playSound(sound);
		}
		return index >= chapter.size();
	}
	
	public void setSound(int page, String sound) {
		if (page == LAST_PAGE) {
			soundPage = chapter.size() - 1;
		} else {
			soundPage = page;
		}
		this.sound = sound;
	}
	
	public ArrayList<Row> getCurrentPage() {
		return chapter.get(index);
	}
	
	public ArrayList<Row> getPage(int index) {
		return chapter.get(index);
	}

	public void addRow(
			boolean newPage, int xoffset, int yoffset, String string, 
			HashMap<Integer, Vector3f> c, Icon icon) {
		ArrayList<Row> page;
		int index = 0;
		if (newPage) {
			page = new ArrayList<Row>();
			chapter.add(page);
		} else {
			index = chapter.size() - 1;
			page = chapter.get(index);
		}
		int x = (int) (xPos) + xoffset;
		int y = yPos + yoffset;
		page.add(new Row(string, x, y + 40 * page.size(), c, icon));
	}
}