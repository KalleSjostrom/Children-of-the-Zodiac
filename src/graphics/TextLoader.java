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
		// int line_gap = getNextInt(data);
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

	   	// int baseline = (int)(ascent*scale);

	   	kerning_table = new float[num_chars][num_chars];
		for (int i = 0; i < num_chars; ++i) {
			for (int j = 0; j < num_chars; ++j) {
				int kern = getNextInt(data);
				kerning_table[i][j] = kern * scale;
			}
		}

		int size = getNextInt(data);
		pixels = new byte[size];
		for (int i = 0; i < size; i++) {
			pixels[i] = data[cursor + i];
		}
	}
}

	/*
	 * text_loader = new TextLoader();

		texture = new int[1];
		gl.glGenTextures(1, texture, 0);
		gl.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);
	    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
	    gl.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
		
		int size = text_loader.pixels.length;
		byte[] data = new byte[size * 4];
		
		for (int i = 0; i < size; i++) {
			byte value = text_loader.pixels[i];
			data[i*4+0] = value;
			data[i*4+1] = 0;
			data[i*4+2] = 0;
			data[i*4+3] = value;
		}
		
		// gl.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_ALPHA, 512, 512, 0, GL.GL_ALPHA, GL.GL_UNSIGNED_BYTE, ByteBuffer.wrap(text_loader.pixels));
		gl.glTexImage2D(GL2.GL_TEXTURE_2D, 0, GL2.GL_RGBA, 512, 512, 0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, ByteBuffer.wrap(data));
	 */
	
	/*
	 * gl.glEnable(GL2.GL_TEXTURE_2D);
		gl.glBindTexture(GL.GL_TEXTURE_2D, texture[0]);

		gl.glBegin(GL2.GL_QUADS);
		
		float width = (1024.0f / 1600.0f) * 512;
		float height = (768.0f / 1200.0f) * 512;

		gl.glTexCoord2f(0, 0);
		gl.glVertex2f(0, 0);

		gl.glTexCoord2f(1, 0);
		gl.glVertex2f(width, 0);

		gl.glTexCoord2f(1, 1);
		gl.glVertex2f(width, height);

		gl.glTexCoord2f(0, 1);
		gl.glVertex2f(0, height);
		
		char[] glyphs = new char[]{ 'T', 'o' };
		
		float inv_scale = (1024.0f / 1600.0f);
		
		float x = inv_scale * 512;
		float y = (768.0f / 1200.0f) * 200;
		
		for (int i = 0; i < glyphs.length; i++) {
			TextLoader.Character c = text_loader.getCharacter(glyphs[i]);
			float left = c.x0 / 512.0f;
			float right = c.x1 / 512.0f;
			float top = c.y1 / 512.0f;
			float bottom = c.y0 / 512.0f;
			
			float cwidth = c.x1 - c.x0;
			float cheight = c.y1 - c.y0;
			
			float xoff = c.xoff;
			float yoff = c.yoff;
			
			gl.glTexCoord2f(left, bottom);
			gl.glVertex2f(x+xoff, y+yoff);

			gl.glTexCoord2f(right, bottom);
			gl.glVertex2f(x+xoff + cwidth, y+yoff);

			gl.glTexCoord2f(right, top);
			gl.glVertex2f(x+xoff + cwidth, y+yoff + cheight);

			gl.glTexCoord2f(left, top);
			gl.glVertex2f(x+xoff, y+yoff + cheight);
			
			x += c.xadvance;
			if (i < glyphs.length-1) {
				float kern = text_loader.kerning_table[glyphs[i] - ' '][glyphs[i+1] - ' '];
				x += kern;
			}
		}
		gl.glEnd();
	 */
	
	/*
	 * #include <stdio.h>

#define STB_RECT_PACK_IMPLEMENTATION
#include "stb_rect_pack.h"
#define STBRP_LARGE_RECTS
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

#define WIDTH 512
#define HEIGHT 512

int main() {
	stbtt_pack_context spc;

	unsigned char pixels[WIDTH*HEIGHT];

	int stride_in_bytes = 0;
	int padding = 1;
	int result = stbtt_PackBegin(&spc, pixels, WIDTH, HEIGHT, stride_in_bytes, padding, NULL);

	unsigned int h_oversample = 1;
	unsigned int v_oversample = 1;
	stbtt_PackSetOversampling(&spc, h_oversample, v_oversample);

	FILE *ttf_file = fopen("./font.ttf", "rb");
	fseek(ttf_file, 0, SEEK_END);
	size_t length = ftell(ttf_file);
	fseek(ttf_file, 0, SEEK_SET);
	unsigned char *fontdata = (unsigned char *)malloc(length*sizeof(unsigned char));
	fread(fontdata, 1, length, ttf_file);
	fclose(ttf_file);

	int font_index = 0;
	int num_chars = ('~' - ' ')+1;
	stbtt_packedchar *chardata_for_range = (stbtt_packedchar*)malloc(num_chars*sizeof(stbtt_packedchar));

	stbtt_pack_range range;
	range.first_unicode_codepoint_in_range = ' ';
	range.array_of_unicode_codepoints = NULL;
	range.num_chars                   = num_chars;
	range.chardata_for_range          = chardata_for_range;
	range.font_size                   = 128;
	result = stbtt_PackFontRanges(&spc, fontdata, font_index, &range, 1);

	stbtt_PackEnd(&spc);


	FILE *file = fopen("font.gamefont", "w");

	stbtt_fontinfo info;
	stbtt_InitFont(&info, fontdata, stbtt_GetFontOffsetForIndex(fontdata, font_index));

	int ascent, descent, line_gap;
	stbtt_GetFontVMetrics(&info, &ascent, &descent, &line_gap);

	int font_size = range.font_size;

	fwrite(&ascent, sizeof(ascent), 1, file);
	fwrite(&descent, sizeof(descent), 1, file);
	fwrite(&line_gap, sizeof(line_gap), 1, file);
	fwrite(&font_size, sizeof(font_size), 1, file);
	fwrite(&num_chars, sizeof(num_chars), 1, file);

	for (int i = 0; i < num_chars; ++i) {
		stbtt_packedchar character = chardata_for_range[i];

		int xoff = character.xoff;
		int yoff = character.yoff;
		int x0 = character.x0;
		int x1 = character.x1;
		int y0 = character.y0;
		int y1 = character.y1;

		fwrite(&xoff, sizeof(xoff), 1, file);
		fwrite(&yoff, sizeof(yoff), 1, file);
		fwrite(&x0, sizeof(x0), 1, file);
		fwrite(&x1, sizeof(x1), 1, file);
		fwrite(&y0, sizeof(y0), 1, file);
		fwrite(&y1, sizeof(y1), 1, file);

		int xadvance = (int)((character.xadvance/scale)+0.5f);
		fwrite(&xadvance, sizeof(xadvance), 1, file);
	}

	for (char i = ' '; i <= '~'; ++i) {
		for (char j = ' '; j <= '~'; ++j) {
			int kern = stbtt_GetCodepointKernAdvance(&info, i, j);
			printf("%d\n", kern);
			fwrite(&kern, sizeof(kern), 1, file);
		}
	}

	int size = WIDTH * HEIGHT;
	fwrite(&size, sizeof(size), 1, file);
	fwrite(pixels, sizeof(pixels[0]), size, file);

	fclose(file);
	return 0;
}*/
