package graphics;

import info.Values;

import java.util.HashMap;

import com.jogamp.opengl.util.awt.TextRenderer;

public class TextManager {

	private static final HashMap<Integer, TextRenderer> boldTexts = createTextRenderer(Values.BOLD);
	private static final HashMap<Integer, TextRenderer> plainTexts = createTextRenderer(Values.PLAIN);
	
	private TextRenderer currentFont;
	private int size;
	private int type;

	private static HashMap<Integer, TextRenderer> createTextRenderer(int type) {
		HashMap<Integer, TextRenderer> texts = new HashMap<Integer, TextRenderer>();
		for (int size = 20; size <= 50; size+=2) {
			TextRenderer tr = createRenderer(type, size);
			texts.put(size, tr);
		}
		return texts;
	}
	
	public static TextRenderer createRenderer(int type, int size) {
		return new TextRenderer(Values.getFont(type, size), true, true);
	}
	
	public static TextRenderer createRenderer(int size) {
		return new TextRenderer(Values.getFont(size), true, true);
	}
	
	public void setFont(int size, int type) {
		if (size >= 20 && size <= 50 && size % 2 == 0) {
			currentFont = type == Values.PLAIN ? plainTexts.get(size) : boldTexts.get(size);
			this.size = size;
			this.type = type;
		} else {
			new IllegalArgumentException("Font size must be an even integer between 20 and 50, not " + size).printStackTrace();
		}
	}
	
	public void setFont(int size) {
		setFont(size, type);
	}
	
	public TextRenderer getCurrentFont() {
		return currentFont;
	}

	public int getFontSize() {
		return size;
	}
}
