package graphics;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import info.Values;

public class TextLoader {
	public class Character {
		public int xoff;
		public int yoff;
		public int x0;
		public int x1;
		public int y0;
		public int y1;
		public float xadvance;
	}	

	public int width;
	public int height;
	public Character[] characters;
	public float[][] kerning_table;
	public byte[] pixels;
	
	int cursor;
	
	private int getNextInt(byte[] data) {
		int c = cursor;
		cursor += 4;
		return ((data[c+0] & 0xFF) << 0) |
				((data[c+1] & 0xFF) << 8) |
				((data[c+2] & 0xFF) << 16) |
				((data[c+3] & 0xFF) << 24);
	}
	
	public TextLoader() {
		File file = new File(Values.MainRes, "font.gamefont");
		byte[] data = new byte[(int) file.length()];
		FileInputStream fis;
		try {
			fis = new FileInputStream(file);
			fis.read(data);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		int ascent = getNextInt(data);
		int descent = getNextInt(data);
		int line_gap = getNextInt(data);
		int font_size = getNextInt(data);
		int num_chars = getNextInt(data);
		
		characters = new Character[num_chars];
		
		float scale = (float)font_size / (float)(ascent - descent);
		for (int i = 0; i < num_chars; ++i) {
			Character c = new Character();
			c.xoff = getNextInt(data);
			c.yoff = getNextInt(data);
			c.x0 = getNextInt(data);
			c.x1 = getNextInt(data);
			c.y0 = getNextInt(data);
			c.y1 = getNextInt(data);
			c.xadvance = getNextInt(data) * scale;
			characters[i] = c;
		}

	   	int baseline = (int)(ascent*scale);

	   	kerning_table = new float[num_chars][num_chars];
		for (int i = 0; i < num_chars; ++i) {
			for (int j = 0; j < num_chars; ++j) {
				int kern = getNextInt(data);
				kerning_table[i][j] = kern * scale;
			}
		}

		width = getNextInt(data);
		height = getNextInt(data);
		int size = width*height;
		pixels = new byte[size];
		for (int i = 0; i < size; i++) {
			pixels[i] = data[cursor + i];
		}
	}
}
