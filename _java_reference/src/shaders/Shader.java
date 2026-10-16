package shaders;

import info.Values;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.util.ArrayList;

import com.jogamp.opengl.GL2;

public class Shader {
	
	private int shaderprogram;
	
	public void init(GL2 gl) {
		int v = gl.glCreateShader(GL2.GL_VERTEX_SHADER);
		int f = gl.glCreateShader(GL2.GL_FRAGMENT_SHADER);

		try {
			readFile("vtest.glsl", v, gl);
			readFile("ftest.glsl", f, gl);
//			readFile("vshade2.glsl", v, gl);
//			readFile("fshade2.glsl", f, gl);
		} catch (IOException e) {
			e.printStackTrace();
		}

		shaderprogram = gl.glCreateProgram();
		gl.glAttachShader(shaderprogram, v);
		gl.glAttachShader(shaderprogram, f);
		gl.glLinkProgram(shaderprogram);
		gl.glValidateProgram(shaderprogram);

		gl.glUseProgram(shaderprogram);
	}

	private void readFile(String string, int kind, GL2 gl) throws IOException {
		BufferedReader brv = 
			new BufferedReader(
					new FileReader(
							Values.Shaders + string));
		ArrayList<String> list = new ArrayList<String>();
		String line;
		while ((line = brv.readLine()) != null) {
			list.add(line + "\n");
		}
		String[] a = new String[list.size()];
		list.toArray(a);
		
		IntBuffer test = null;
		gl.glShaderSource(kind, a.length, a, test);
		gl.glCompileShader(kind);
		IntBuffer ib = IntBuffer.wrap(new int[30]);
		gl.glGetShaderiv(kind, GL2.GL_COMPILE_STATUS, ib);
		checkError(kind, ib.get(0), gl);
	}
	
	private void checkError(int kind, int status, GL2 gl) {
		if (status != GL2.GL_TRUE) {
			ByteBuffer bb = ByteBuffer.allocate(3000);
			IntBuffer ib = IntBuffer.allocate(10);
			gl.glGetShaderInfoLog(kind, 3000, ib, bb);
			byte[] b = bb.array();
			for (int i = 0; i < b.length; i++) {
				System.out.print(new Character((char) b[i]));
			}
			System.exit(0);
		}
	}

	public int getUniformLocation(GL2 gl, String string) {
		return gl.glGetUniformLocation(shaderprogram, string);
	}

	public int getAttributeLocation(GL2 gl, String string) {
		return gl.glGetAttribLocation(shaderprogram, string);
	}

	public void useShader(GL2 gl) {
		gl.glUseProgram(shaderprogram);
	}
	
	public void useDefaultShader(GL2 gl) {
		gl.glUseProgram(0);
	}
}
