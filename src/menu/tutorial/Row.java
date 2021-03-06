package menu.tutorial;

import graphics.Graphics;
import java.util.ArrayList;
import java.util.HashMap;
import bodies.Vector3f;

public class Row {
	
	private ArrayList<String> row;
	private HashMap<Integer, Vector3f> colorMap;
	private Icon icon;
	private int x;
	private int y;
	
	public Row(String r, int x, int y) {
		this(r, x, y, null, null);
	}
	
	public Row(String r, int x, int y, HashMap<Integer, Vector3f> colorMap, Icon icon) {
		row = new ArrayList<String>();
		String[] rs = r.split(" ");
		for (String s : rs) {
			row.add(s + " ");
		}
		this.x = x;
		this.y = y;
		this.colorMap = colorMap;
		this.icon = icon;
	}
	
	public void draw(Graphics g) {
		int offset = 0;
		for (int i = 0; i < row.size(); i++) {
			String s = row.get(i);
			if (colorMap != null) {
				Vector3f c = colorMap.get(i);
				if (c != null) {
					g.setColor(0, 0, 0, 1);
					g.drawString(s, x + offset + 1, y + 1);		
					g.setColor(c.x, c.y, c.z, 1);
				} else {
					g.setColor(0, 0, 0, 1);
				}
			} else {
				g.setColor(0, 0, 0, 1);
			}
			g.drawString(s, x + offset, y);
			offset += g.getStringWidth(s) + 7;
		}
	}

	public void drawIcon(Graphics g) {
		if (icon != null) {
			icon.draw(g, x, y);
		}
	}

	public static void drawRows(Graphics g, ArrayList<Row> rows) {
		for (Row r : rows) {
			r.draw(g);
		}
		for (Row r : rows) {
			r.drawIcon(g);
		}
	}
}
