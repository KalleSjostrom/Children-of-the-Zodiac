package graphics;

import java.util.HashMap;

import com.jogamp.opengl.GL4;
import graphics.Material.Buffer;

public class SpriteRenderer {
	
	public static class SpriteInfo {
		public int horizontal_parts; 
		public int vertical_parts; 
		public int width;
		public int height;
		public int hashCode() {
			return (horizontal_parts << 24) | (vertical_parts << 16) | (width << 8) | height;
		}
	}
	
	Material material;
	float width, height;
	Buffer buffer;

	HashMap<SpriteInfo, Buffer> sprite_cache = new HashMap<SpriteInfo, Buffer>();
		
	public SpriteRenderer() {
		material = new Material();
	}
	
	public void init(GL4 gl) {
		material.createProgram(gl, ShaderLibrary.Shader.SPRITE);
	}

	private Buffer buildSprite(GL4 gl, SpriteInfo sprite) {
		float width = sprite.width;
		float height = sprite.height;
		int horizontal_parts = sprite.horizontal_parts;
		int vertical_parts = sprite.vertical_parts;

		float part_width = width / horizontal_parts;
		float part_height = height / vertical_parts;
		
		int number_of_parts = horizontal_parts * vertical_parts;
		
		float[] position = new float[8 * number_of_parts];
		float[] uv = new float[8 * number_of_parts];

		int index = 0;
		for (int y = 0; y < vertical_parts; y++) {
			for (int x = 0; x < horizontal_parts; x++) {
				position[index*8+0] = 0;
				position[index*8+1] = 0;
				position[index*8+2] = 0;
				position[index*8+3] = 1;
				position[index*8+4] = 1;
				position[index*8+5] = 0;
				position[index*8+6] = 1;
				position[index*8+7] = 1;
				
				float left = (x*part_width) / width;
				float right = ((x+1)*part_width) / width;
				float bottom = (y*part_height) / height;
				float top = ((y+1)*part_height) / height;
				
				uv[index*8+0] = left;
				uv[index*8+1] = bottom;
				uv[index*8+2] = left;
				uv[index*8+3] = top;
				uv[index*8+4] = right;
				uv[index*8+5] = bottom;
				uv[index*8+6] = right;
				uv[index*8+7] = top;
				
				index++;
			}
		}

		Buffer buffer = material.createBuffer(gl, position, uv);
		
		gl.glUseProgram(material.program);
		gl.glUniformMatrix4fv(material.model_view_location, 1, true, material.model_view, 0);
		
		return buffer;
	}
	
	public void drawSprite(GL4 gl, SpriteInfo sprite, int frame, int x, int y) {
		gl.glUseProgram(material.program);
		
		Buffer buffer;
		if (!sprite_cache.containsKey(sprite)) {
			buffer = buildSprite(gl, sprite);
			sprite_cache.put(sprite, buffer);
		} else {
			buffer = sprite_cache.get(sprite);
		}
		
		material.model_view[3] = x;
		material.model_view[7] = y;
		material.model_view[0] = sprite.width;
		material.model_view[5] = sprite.height;

		gl.glUniformMatrix4fv(material.model_view_location, 1, true, material.model_view, 0);

		gl.glBindVertexArray(buffer.vao[0]);
		// gl.glBindTexture(GL4.GL_TEXTURE_2D, texture[0]);
		gl.glDrawArrays(GL4.GL_TRIANGLE_STRIP, frame*4, 4);
		gl.glBindVertexArray(0);
	}
}
