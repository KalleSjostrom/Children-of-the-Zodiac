package menu.tutorial;

import graphics.Graphics;

import java.util.ArrayList;

public class HelpText {
	
	private ColorTextLoader loader;
	private ArrayList<Row> rows;
	
	public HelpText(String name, int x, int y) {
		name = name.toLowerCase();
		String filename = name + ".help";
		loader = new ColorTextLoader(x, y);
		loader.parseFile(filename);
		rows = loader.getFirstPage();
	}

	public void drawTopLayer(Graphics g) {
		g.setFontSize(34);
		Graphics.setTextColor(0);
		g.setFontSize(26);
		Row.drawRows(g, rows);
	}
}
