package organizer;

import graphics.Graphics;
import info.Values;

import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GLAutoDrawable;
import com.jogamp.opengl.GLEventListener;
import com.jogamp.opengl.glu.GLU;

public class GameEventListener implements GLEventListener {

	private GameCore gameCore;
	private static GLU glu = new GLU();
	private static Graphics g = new Graphics();
	private enum renderMode {RENDER_2D, RENDER_3D}
	private static renderMode mode;

	public GameEventListener(GameCore core) {
		gameCore = core;
	}

	public void init(GLAutoDrawable drawable) {
		drawable.setAutoSwapBufferMode(false);
		GL2 gl = drawable.getGL().getGL2();
		gl.setSwapInterval(1);
		g.setGL(gl);
		
		int[] res = Values.RESOLUTIONS;
		gl.glViewport(0, 0, res[Values.X], res[Values.Y]);
		gl.glCullFace(GL2.GL_BACK);
		gl.glEnable(GL2.GL_CULL_FACE);
		gl.glEnable(GL2.GL_BLEND);
		gl.glEnable(GL2.GL_ALPHA_TEST);
		gl.glBlendFunc(GL2.GL_SRC_ALPHA, GL2.GL_ONE_MINUS_SRC_ALPHA);
		gl.glAlphaFunc(GL2.GL_LEQUAL, 1);
		gl.glShadeModel(GL2.GL_SMOOTH);
		gl.glHint(GL2.GL_PERSPECTIVE_CORRECTION_HINT, GL2.GL_NICEST);
	}

	public void display(GLAutoDrawable drawable) {
		drawable.swapBuffers();
		
		gameCore.update();
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
		gameCore.testDraw(g, drawable);
	}
	
	private static void set3D(GL2 gl) {
		int[] res = Values.ORIGINAL_RESOLUTION;
		glu.gluPerspective(45.0, res[Values.X] / (float) res[Values.Y], 1, 75);
		
		gl.glDepthMask(true);
		gl.glEnable(GL2.GL_DEPTH_TEST);
		gl.glClearDepth(1.0f);
		gl.glDepthFunc(GL2.GL_LEQUAL);
	}
	
	private static void set2D(GL2 gl) {
		int[] res = Values.ORIGINAL_RESOLUTION;
		float x = 0; //204;
		float y = 0; //144;
		glu.gluOrtho2D(x, res[Values.X] - x, res[Values.Y] - y, y);
		
		gl.glDepthMask(false);
		gl.glDisable(GL2.GL_DEPTH_TEST);
		gl.glDisable(GL2.GL_LIGHTING);
	}
	
	public static void set3DNow(Graphics g) {
		setRenderModeNow(g.getGL(), false);
	}

	public static void set2DNow(Graphics g) {
		setRenderModeNow(g.getGL(), true);
	}
	
	private static void setRenderModeNow(GL2 gl, boolean to2d) {
		gl.glMatrixMode(GL2.GL_PROJECTION);
		gl.glLoadIdentity();
		if (to2d) {
			set2D(gl);
		} else {
			set3D(gl);
		}
		gl.glMatrixMode(GL2.GL_MODELVIEW);
		gl.glLoadIdentity();
	}

	
	public static void set3D() {
		mode = renderMode.RENDER_3D;
	}
	
	public static void set2D() {
		mode = renderMode.RENDER_2D;
	}

	public void displayChanged(
			GLAutoDrawable drawable, 
			boolean modeChanaged, 
			boolean deviceChanged) {
	}

	public void reshape(
			GLAutoDrawable drawable, 
			int x, 
			int y, 
			int width, 
			int height) {
	}
	

	public void dispose(GLAutoDrawable arg0) {
	}

	public static Graphics getG() {
		return g;
	}
}
