package graphics;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import com.jogamp.opengl.GL4;
import info.Values;

public class ShaderLibrary {

	public enum Shader {
		TEXT,
		SPRITE,
	}
	private enum ShaderType {
		VERTEX,
		FRAGMENT,
	}

	private static HashMap<String, Integer> hash = new HashMap<String, Integer>();
	private static ByteBuffer DEBUGBuffer = ByteBuffer.allocate(2048);
	private static void DEBUGPrintShaderLog(GL4 gl, String path, int shader) {
		gl.glGetShaderInfoLog(shader, DEBUGBuffer.remaining(), null, DEBUGBuffer);
		System.out.println("Shader log: " + path + " " + new String(DEBUGBuffer.array()));
		DEBUGBuffer.clear();
	}

	public static int getVertexShader(GL4 gl, Shader shader) {
		return getShader(gl, shader, ShaderType.VERTEX);
	}
	public static int getFragmentShader(GL4 gl, Shader shader) {
		return getShader(gl, shader, ShaderType.FRAGMENT);
	}
	private static int getShader(GL4 gl, Shader shader, ShaderType type) {
		int result = -1;
		String path = null;
		switch (shader) {
		case TEXT:
			path = type == ShaderType.VERTEX ? "text.vert" : "text.frag";
			break;
		case SPRITE:
			path = type == ShaderType.VERTEX ? "sprite.vert" : "sprite.frag";
			break;
		default:
			break;
		}

		if (path == null)
			return result;
		
		if (hash.containsKey(path))
			return hash.get(path);

		try {
			result = gl.glCreateShader(type == ShaderType.VERTEX ? GL4.GL_VERTEX_SHADER : GL4.GL_FRAGMENT_SHADER);
			byte[] content = Files.readAllBytes(Paths.get(Values.Shaders, path));
			String source = new String(content);
			gl.glShaderSource(result, 1, new String[]{ source }, null);
			gl.glCompileShader(result);
			DEBUGPrintShaderLog(gl, path, result);
			hash.put(path, result);
		} catch (IOException e) {
			e.printStackTrace();
		}

		return result;
	}
}
