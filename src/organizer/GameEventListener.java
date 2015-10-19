package organizer;

import graphics.Graphics;
import graphics.StringRenderer;
import info.Values;

import com.jogamp.opengl.GL;
import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GL4;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLEventListener;

public class GameEventListener implements GLEventListener {
	
	private enum renderMode {
		RENDER_2D, RENDER_3D
	}

	private GameCore gameCore;
	private static Graphics g = new Graphics();
	private static renderMode mode;
	
	private StringRenderer text_renderer;

	public GameEventListener(GameCore core) {
		gameCore = core;
		text_renderer = new StringRenderer();
	}

	public void init(GLAutoDrawable drawable) {
		drawable.setAutoSwapBufferMode(false);
		
		GL4 gl = drawable.getGL().getGL4();
		// g.setGL(gl);
		gl.glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		gl.setSwapInterval(1);
		int[] res = Values.RESOLUTIONS;
		gl.glViewport(0, 0, res[Values.X], res[Values.Y]);

		// gl.glCullFace(GL.GL_BACK);
		// gl.glEnable(GL.GL_CULL_FACE);

		gl.glEnable(GL.GL_BLEND);
		gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
		
		g.init(gl);
		
		text_renderer.init(gl);
		
		System.out.println("Version: " + gl.glGetString(GL.GL_VERSION));
	}
	
	public void display(GLAutoDrawable drawable) {
		gameCore.update();

		GL4 gl = drawable.getGL().getGL4();
		gl.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
		Graphics.gl = gl;

		gameCore.render(g, drawable);
		
		/*
		GL2 gl = drawable.getGL().getGL2();
		gl.glMatrixMode(GL2.GL_PROJECTION); 
		gl.glLoadIdentity();
		if (mode == renderMode.RENDER_3D) { 
			set3D(gl);
			gl.glClear(GL2.GL_COLOR_BUFFER_BIT | GL2.GL_DEPTH_BUFFER_BIT);
		} else {
			set2D(gl);
			gl.glClear(GL2.GL_COLOR_BUFFER_BIT);
		}

		gl.glMatrixMode(GL2.GL_MODELVIEW);
		gl.glLoadIdentity();
		gl.glEnable(GL2.GL_TEXTURE_2D);
		g.setGL(gl);
		*/

		drawable.swapBuffers();
	}

	private static void set3D(GL2 gl) {
		/*
		 gl.glDepthMask(true); gl.glEnable(GL2.GL_DEPTH_TEST);
		 gl.glClearDepth(1.0f); gl.glDepthFunc(GL2.GL_LEQUAL);
		 */
	}

	private static void set2D(GL2 gl) {
	}

	public static void set3DNow(Graphics g) {
		// setRenderModeNow(Graphics.gl, false);
	}

	public static void set2DNow(Graphics g) {
		// setRenderModeNow(Graphics.gl, true);
	}

	private static void setRenderModeNow(GL2 gl, boolean to2d) {
		 gl.glMatrixMode(GL2.GL_PROJECTION); gl.glLoadIdentity(); if (to2d) {
		 set2D(gl); } else { set3D(gl); } gl.glMatrixMode(GL2.GL_MODELVIEW);
		 gl.glLoadIdentity();
	}

	public static void set3D() {
		mode = renderMode.RENDER_3D;
	}

	public static void set2D() {
		mode = renderMode.RENDER_2D;
	}

	public void displayChanged(GLAutoDrawable drawable, boolean modeChanaged, boolean deviceChanged) { }
	public void reshape(GLAutoDrawable drawable, int x, int y, int width, int height) { }
	public void dispose(GLAutoDrawable arg0) { }

	public static Graphics getG() {
		return g;
	}
}
