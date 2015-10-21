package graphics;

import java.nio.ByteBuffer;
import java.util.HashMap;

import com.jogamp.opengl.GL4;

import graphics.Material.Buffer;

public class StringRenderer {
	
	private class Text {
		Buffer buffer;
		int string_length;
	}

	int texture[];
	TextLoader text_loader;
	Material material;
	
	float width, height;
	
	HashMap<String, Text> string_cache = new HashMap<String, Text>();
		
	public StringRenderer() {
		text_loader = new TextLoader();
		width = text_loader.width;
		height = text_loader.height;
		material = new Material();
	}
	
	public void init(GL4 gl) {
		texture = new int[1];
		gl.glGenTextures(1, texture, 0);
		gl.glBindTexture(GL4.GL_TEXTURE_2D, texture[0]);
		gl.glTexParameteri(GL4.GL_TEXTURE_2D, GL4.GL_TEXTURE_MAG_FILTER, GL4.GL_NEAREST);
		gl.glTexParameteri(GL4.GL_TEXTURE_2D, GL4.GL_TEXTURE_MIN_FILTER, GL4.GL_NEAREST);
		gl.glTexImage2D(GL4.GL_TEXTURE_2D, 0, GL4.GL_RED, (int)width, (int)height, 0, GL4.GL_RED, GL4.GL_UNSIGNED_BYTE, ByteBuffer.wrap(text_loader.pixels));

		material.createProgram(gl, ShaderLibrary.Shader.TEXT);
	}
	
	private void fillBufferData(char[] glyphs, float[] position, float[] uv) {
		float x = 0;
		float y = 0;
		
		for (int i = 0; i < glyphs.length; i++) {
			TextLoader.Character c = text_loader.characters[glyphs[i] - ' '];
			float left = c.x0 / width;
			float right = c.x1 / width;
			float top = c.y1 / height;
			float bottom = c.y0 / height;
			
			float cwidth = c.x1 - c.x0;
			float cheight = c.y1 - c.y0;
			
			float xoff = c.xoff;
			float yoff = c.yoff;
			
			// Front facing is counter clockwise, but we want to scale with negative y in order to use the top left scheme that's already in place
			float basex = x+xoff;
			float basey = y+yoff;
			
			position[i*8+0] = basex;
			position[i*8+1] = basey;
			position[i*8+2] = basex;
			position[i*8+3] = basey + cheight;
			position[i*8+4] = basex + cwidth;
			position[i*8+5] = basey;
			position[i*8+6] = basex + cwidth;
			position[i*8+7] = basey + cheight;
			
			uv[i*8+0] = left;
			uv[i*8+1] = bottom;
			uv[i*8+2] = left;
			uv[i*8+3] = top;
			uv[i*8+4] = right;
			uv[i*8+5] = bottom;
			uv[i*8+6] = right;
			uv[i*8+7] = top;
			
			x += c.xadvance;
			if (i < glyphs.length-1) {
				float kern = text_loader.kerning_table[glyphs[i] - ' '][glyphs[i+1] - ' '];
				x += kern;
			}
		}
	}
		
	private Text buildString(GL4 gl, String input) {
		char[] glyphs = input.toCharArray();
		int string_length = glyphs.length;
		
		float[] quad_buffer = new float[8 * glyphs.length];
		float[] quad_buffer_uv = new float[8 * glyphs.length];
		
		fillBufferData(glyphs, quad_buffer, quad_buffer_uv);
		
		Buffer buffer = material.createBuffer(gl, quad_buffer, quad_buffer_uv);
		Text text = new Text();
		text.buffer = buffer;
		text.string_length = string_length;
		return text;
	}
	
	private void rebuildString(GL4 gl, Text text, String input) {
		char[] glyphs = input.toCharArray();
		int string_length = glyphs.length;
		
		float[] quad_buffer = new float[8 * glyphs.length];
		float[] quad_buffer_uv = new float[8 * glyphs.length];
		
		fillBufferData(glyphs, quad_buffer, quad_buffer_uv);
		
		material.refillBuffer(gl, text.buffer, quad_buffer, quad_buffer_uv);
		text.string_length = string_length;
	}
	
	public void setTextColor(GL4 gl, float[] color) {
		gl.glUseProgram(material.program);
		gl.glUniform4fv(material.color_location, 1, color, 0);
	}
	
	public void drawString(GL4 gl, String string, int x, int y, float scale, float alpha) {
		gl.glUseProgram(material.program);
		Text text;
		if (string_cache.size() > 256) { // NOTE(kalle): is 256 max number of strings a reasonable value?
			String key = string_cache.keySet().iterator().next();
			text = string_cache.get(key);
			rebuildString(gl, text, string);
		} else {
			if (!string_cache.containsKey(string)) {
				text = buildString(gl, string);
				string_cache.put(string, text);
			} else {
				text = string_cache.get(string);
			}
		}
		
		material.model_view[3] = x;
		material.model_view[7] = y;
		material.model_view[0] = scale;
		material.model_view[5] = scale;

		gl.glUniformMatrix4fv(material.model_view_location, 1, true, material.model_view, 0);
		gl.glUniform1f(material.alpha_location, alpha);

		gl.glBindVertexArray(text.buffer.vao[0]);
		gl.glBindTexture(GL4.GL_TEXTURE_2D, texture[0]);
		for (int j = 0; j < text.string_length; j++) {
			gl.glDrawArrays(GL4.GL_TRIANGLE_STRIP, j*4, 4);
		}
		gl.glBindVertexArray(0);
	}

	public int getWidth(String string) {
		return 0;
	}

	public int getSize() {
		return string_cache.size();
	}
}
