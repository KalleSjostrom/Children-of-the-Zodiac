package menu.tutorial;

import graphics.Graphics;
import info.Database;
import info.SoundMap;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import menu.AbstractPage;

import organizer.ResourceLoader;

public class Tutorial {

	private static final int IMAGE_HEIGHT = 260;
	private static final float IMAGE_X = 240;
	private boolean active;
	private int index = -1;
	
	private Chapter chapter;
	private ColorTextLoader loader;
	private HashMap<Integer, Chapter> book;
	private String title;
	
	public Tutorial(String name, boolean alwaysShow) {
		book = new HashMap<Integer, Chapter>();
		name = name.toLowerCase();
		String filename = name + ".tut";
		int status = Database.getStatusFor(filename);
		
		boolean exist = status == 1;
		if (!exist && alwaysShow) {
			exist = status == 2;
		}
		if (exist) {
			exist = ResourceLoader.getResourceLoader().exists(Values.Tutorials + filename);
			if (exist) {
				loader = new ColorTextLoader(
						(int) IMAGE_X + AbstractPage.xoffset, IMAGE_HEIGHT + 100);
				loader.parseFile(filename);
				book = loader.getBook();
				title = loader.getTitle();
				Database.addStatus(filename, 2);
				if (status == 1) {
					Chapter cc = loader.getCurrentChapter();
					cc.addRow(
							true, 0, 0, 
							"This information is now available in the menu.", 
							null, null);
					cc.setSound(Chapter.LAST_PAGE, SoundMap.MENU_QUEST_LOG_ENTRY);
				}
			}
		}
		setActive(exist);
	}
	
	public boolean increment() {
		index++;
		chapter = book.get(index);
		return chapter != null;
	}

	public void setActive(boolean active) {
		this.active = active;
		if (active) {
			crossedPressed();
		}
	}
	
	public boolean crossedPressed() {
		chapter = book.get(index);
		boolean done = chapter == null;
		if (!done) {
			done = chapter.next();
		}
		if (done) {
			chapter = null;
		}
		return done;
	}

	public void drawTopLayer(Graphics g) {
		if (active && chapter != null) {
			g.fadeOldSchoolColor(1, 1, 1, .5f);
			int x = (int) (IMAGE_X) + AbstractPage.xoffset;
			int y = IMAGE_HEIGHT;

			g.push();
			g.drawImage(AbstractPage.images[15], x-35, IMAGE_HEIGHT);
			g.pop();
			g.setFontSize(34);
			Graphics.setTextColor(0);
			ArrayList<Row> l = chapter.getCurrentPage();
			g.drawSingleCenteredText(title, y + 50, 1, 0);
			
			g.setFontSize(26);
			Row.drawRows(g, l);
			
		}
	}
}
