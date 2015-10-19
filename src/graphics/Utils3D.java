/*
 * Classname: Utils3D.java
 * 
 * Version information: 0.7.0
 *
 * Date: 23/09/2008
 */
package graphics;

import com.jogamp.opengl.GL2;

import com.jogamp.opengl.util.texture.Texture;
import com.jogamp.opengl.util.texture.TextureCoords;

/**
 * The class consists of some static drawing methods, for drawing
 * textures in 3D. It also has some methods for setting color and
 * calculating distance in 3D space. 
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 23 Sep 2088
 */
public class Utils3D {

	/**
	 * This method maps the given texture coordinates to vertices created
	 * from the given x, y and z arguments. These are arrays containing the 
	 * coordinates of the vertices in 3D space. This method assumes that a 
	 * texture has been bound and that glBegin(GL2.GL_QUADS) has been called.
	 * This method sets up the vertices by mapping the texture coordinates
	 * in a counter-clockwise order, starting with bottom left. This is the
	 * order one must do this to create a "front" drawn texture.
	 * 
	 * @param g the GL object to use when mapping.
	 * @param texture the texture coordinates to map.
	 * @param x the x-axis coordinates.
	 * @param y the y-axis coordinates.
	 * @param z the z-axis coordinates.
	 */
	private static void draw3D(
			Graphics g, TextureCoords tc, float[] x, float[] y, float[] z) {
		GL2 gl = Graphics.gl2;
		gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x[0], y[0], z[0]);
		gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x[1], y[0], z[0]);
		gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x[1], y[1], z[1]);
		gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x[0], y[1], z[1]); 
	}
	
	/**
	 * This method maps the given texture coordinates to vertices created
	 * from the given x, y and z arguments. These are arrays containing the 
	 * coordinates of the vertices in 3D space. This method assumes that a 
	 * texture has been bound and that glBegin(GL2.GL_QUADS) has been called.
	 * It sets up the vertices by mapping the texture coordinates in a 
	 * counter-clockwise order, starting with bottom left. This is the
	 * order one must do this to create a "front" drawn texture.
	 * 
	 * This method draws only part of the bound texture. It will draw from
	 * the left side (on the x-axis), length * percent length units to the
	 * right. If length is the width of the whole texture, this method
	 * will show the given percent of the whole texture. 
	 * 
	 * @param g the GL object to use when mapping.
	 * @param tc the texture coordinates to map.
	 * @param percent the percent of the texture to draw.
	 * @param x the x-axis coordinates.
	 * @param y the y-axis coordinates.
	 * @param z the z-axis coordinates.
	 * @param length the width of the texture (length on x-axis).
	 */
	private static void draw3D(Graphics g, TextureCoords tc, float percent, 
			float[] x, float[] y, float[] z, float length) {
		GL2 gl = Graphics.gl2;
		gl.glTexCoord2f(tc.left(), tc.bottom());
		gl.glVertex3f(x[0], y[0], z[0]);
		gl.glTexCoord2f(tc.right() * percent, tc.bottom());
		float xs = x[0] + length * percent;
		gl.glVertex3f(xs, y[0], z[0]);
		gl.glTexCoord2f(tc.right() * percent, tc.top()); 
		gl.glVertex3f(xs, y[1], z[1]);
		gl.glTexCoord2f(tc.left(), tc.top()); 
		gl.glVertex3f(x[0], y[1], z[1]);
	}
	
	/**
	 * This method maps the given texture coordinates to vertices created
	 * from the given x, y and z arguments. These are arrays containing the 
	 * coordinates of the vertices in 3D space. This method assumes that a 
	 * texture has been bound and that glBegin(GL2.GL_QUADS) has been called.
	 * It sets up the vertices by mapping the texture coordinates in a 
	 * counter-clockwise order, starting with bottom left. This is the
	 * order one must do this to create a "front" drawn texture.
	 * 
	 * This method draws only part of the bound texture. It will draw from
	 * the top side (on the y-axis), length * percent length units towards 
	 * the bottom. If the given length represents the height of the whole 
	 * texture, this method will show the given percent of the whole texture.
	 * 
	 * @param gl the GL object to use when mapping.
	 * @param tc the texture coordinates to map.
	 * @param percent the percent of the texture to draw.
	 * @param x the x-axis coordinates.
	 * @param y the y-axis coordinates.
	 * @param z the z-axis coordinates.
	 * @param length the width of the texture (length on x-axis).
	 */
	private static void draw3DY(Graphics g, TextureCoords tc, float percent, 
			float[] x, float[] y, float[] z, float length) {
		GL2 gl = Graphics.gl2;
		float ys = y[1] - length * percent;
		gl.glTexCoord2f(tc.left(), tc.bottom() * percent); 
		gl.glVertex3f(x[0], ys, z[0]);
		gl.glTexCoord2f(tc.right(), tc.bottom() * percent); 
		gl.glVertex3f(x[1], ys, z[0]);
		gl.glTexCoord2f(tc.right(), tc.top()); 
		gl.glVertex3f(x[1], y[1], z[1]);
		gl.glTexCoord2f(tc.left(), tc.top()); 
		gl.glVertex3f(x[0], y[1], z[1]);
	}
	
	/**
	 * This method maps the given texture coordinates to vertices created
	 * from the given x, y and z arguments. These are arrays containing the 
	 * coordinates of the vertices in 3D space. This method assumes that a 
	 * texture has been bound and that glBegin(GL2.GL_QUADS) has been called.
	 * This method sets up the vertices by mapping the texture coordinates
	 * in a clockwise order, starting with top right. This is the order one 
	 * must do this to create a "back side" drawn texture.
	 * 
	 * @param g the GL object to use when mapping.
	 * @param tc the texture coordinates to map.
	 * @param x the x-axis coordinates.
	 * @param y the y-axis coordinates.
	 * @param z the z-axis coordinates.
	 */
	private static void draw3DBackside(
			Graphics g, TextureCoords tc, float[] x, float[] y, float[] z) {
		GL2 gl = Graphics.gl2;
		gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x[0], y[1], z[1]);
		gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x[1], y[1], z[1]);
		gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x[1], y[0], z[0]);
		gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x[0], y[0], z[0]);
	}

	/**
	 * This method maps the given texture coordinates to vertices created
	 * from the given coordList. This coordList contains three arrays that 
	 * represents the x, y and z -axis coordinates of the vertices in 3D space.
	 * This method assumes that a texture has been bound and that 
	 * glBegin(GL2.GL_QUADS) has been called.
	 * 
	 * @param g the GL object to use when mapping.
	 * @param texture the texture coordinates to map.
	 * @param coordList the list containing all the coordinates.
	 */
	public static void draw3D(Graphics g, TextureCoords tc, float[][] coordList) {
		draw3D(g, tc, coordList[0], coordList[1], coordList[2]);
	}

	/**
	 * This method draws the given texture at the position represented by the
	 * given list of coordinates. This coordList contains three arrays that 
	 * represents the x, y and z -axis coordinates of the vertices in 3D space.
	 * This method binds the given texture and sets up QUAD drawing by calling
	 * glBegin(GL2.GL_QUADS).
	 * 
	 * @param gl the GL object to use when drawing.
	 * @param textureCoords the texture to draw
	 * @param coordList the list containing all the coordinates.
	 */
	public static void draw3D(Graphics g, Texture texture, float[][] coordList) {
		texture.bind(Graphics.gl);
		g.beginQuads();
		draw3D(g, texture.getImageTexCoords(), coordList);
		g.end();
	}
	
	public static void draw3D(Graphics g, Texture tex, float x, float y, float z, float size) {
		TextureCoords tc = tex.getImageTexCoords();
		float hs = size / 2f;
//		g.draw3f(tc, false, x - hs, y - hs, z, x + hs, y + hs, z);
		GL2 gl = Graphics.gl2;
		tex.bind(gl);
		gl.glBegin(GL2.GL_QUADS);
		gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x - hs, y - hs, z);
		gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x + hs, y - hs, z);
		gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x + hs, y + hs, z);
		gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x - hs, y + hs, z); 
		gl.glEnd();
	}
	
	public static void draw3D(GL2 gl, Texture tex, float x, float y, float z, float size) {
		tex.bind(gl);
		gl.glBegin(GL2.GL_QUADS);
		TextureCoords tc = tex.getImageTexCoords();
		float hs = size / 2f;
		gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x - hs, y - hs, z);
		gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x + hs, y - hs, z);
		gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x + hs, y + hs, z);
		gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x - hs, y + hs, z); 
		gl.glEnd();
	}

	
	public static void draw3DwithHW(Graphics g, Texture tex, float x, float y, float z, float size) {
		TextureCoords tc = tex.getImageTexCoords();
		float h = tex.getHeight() * size * tc.bottom();
		float w = tex.getWidth() * size;
		GL2 gl = Graphics.gl2;
		tex.bind(gl);
		gl.glBegin(GL2.GL_QUADS);
		gl.glTexCoord2f(tc.left(), tc.bottom()); gl.glVertex3f(x - w, y - h, z);
		gl.glTexCoord2f(tc.right(), tc.bottom()); gl.glVertex3f(x + w, y - h, z);
		gl.glTexCoord2f(tc.right(), tc.top()); gl.glVertex3f(x + w, y + h, z);
		gl.glTexCoord2f(tc.left(), tc.top()); gl.glVertex3f(x - w, y + h, z); 
		gl.glEnd();
	}
		
	/**
	 * This method draws the given texture at the position represented by the
	 * given list of coordinates. This coordList contains three arrays that 
	 * represents the x, y and z -axis coordinates of the vertices in 3D space.
	 * This method binds the given texture and sets up quad drawing by calling
	 * glBegin(GL2.GL_QUADS). This method is used to draw a texture on the back
	 * of a quad, (e.g. back side of card). This results in mirroring of 
	 * the texture.
	 * 
	 * @param g the GL object to use when drawing.
	 * @param tex the texture to draw
	 * @param coordList the list containing all the coordinates.
	 */
	public static void draw3DBackside(Graphics g, Texture tex, float[][] coordList) {
		tex.bind(Graphics.gl);
		g.beginQuads();
		draw3DBackside(g, tex.getImageTexCoords(), 
				coordList[0], coordList[1], coordList[2]);
		g.end();
	}

	/**
	 * This method draws the given texture at the position represented by the
	 * given list of coordinates. This coordList contains three arrays that 
	 * represents the x, y and z -axis coordinates of the vertices in 3D space.
	 * This method binds the given texture and sets up quad drawing by calling
	 * glBegin(GL2.GL_QUADS). This method will the given percent value of the
	 * whole texture assuming that length is the width of the texture.
	 * 
	 * @param g the GL object to use when drawing.
	 * @param tex the texture to draw.
	 * @param coordList the list containing all the coordinates.
	 * @param percent the percentage of the width of the texture to draw.
	 * @param width the width of the texture (length on x-axis).
	 */
	public static void draw3DPart(
			Graphics g, Texture tex, float[][] coordList, float percent, float width) {
		tex.bind(Graphics.gl);
		g.beginQuads();
		draw3D(g, tex.getImageTexCoords(), percent,
				coordList[0], coordList[1], coordList[2], width);
		g.end();
	}
	
	public static void draw2DPart(
			GL2 gl, Texture tex, int x, int y, int height, int width, float percent) {
		tex.bind(gl);
		gl.glBegin(GL2.GL_QUADS);
		TextureCoords tc = tex.getImageTexCoords();
		
		int xs = Math.round(x + width * percent);
		int ys = Math.round(y + height);
		
		gl.glTexCoord2f(tc.left(), tc.top());
		gl.glVertex2i(x, y);
		
		gl.glTexCoord2f(tc.right() * percent, tc.top());
		gl.glVertex2i(xs, y);
		
		gl.glTexCoord2f(tc.right() * percent, tc.bottom()); 
		gl.glVertex2i(xs, ys);
		
		gl.glTexCoord2f(tc.left(), tc.bottom()); 
		gl.glVertex2i(x, ys);
		
		gl.glEnd();
	}
	
	/**
	 * This method draws the given texture at the position represented by the
	 * given list of coordinates. This coordList contains three arrays that 
	 * represents the x, y and z -axis coordinates of the vertices in 3D space.
	 * This method binds the given texture and sets up quad drawing by calling
	 * glBegin(GL2.GL_QUADS). This method will draw the given percent of the 
	 * whole texture assuming that length is the height of the texture.
	 * 
	 * @param gl the GL object to use when drawing.
	 * @param tex the texture to draw.
	 * @param coordList the list containing all the coordinates.
	 * @param percent the percentage of the width of the texture to draw.
	 * @param height the height of the texture (length on y-axis).
	 */
	public static void draw3DPartY(
			Graphics g, Texture tex, float[][] coordList, float percent, float height) {
		tex.bind(Graphics.gl);
		g.beginQuads();
		draw3DY(g, tex.getImageTexCoords(), percent,
				coordList[0], coordList[1], coordList[2], height);
		g.end();
	}

	/**
	 * This method calculates the distance between the given coordinates.
	 * The given arrays should be of equal length, but it does not matter
	 * if the points represented by the arrays are in 2D space or 3D space
	 * or any other dimension. Because the distance is the same from the
	 * firstPoint to the secondPoint as from the secondPoint to the firstPoint
	 * it does not matter which array is which when to call this method.
	 * 
	 * @param firstPoint the base point or first point.
	 * @param secondPoint the target point or second point.
	 * @param size 
	 * @return the distance between the points.
	 */
	public static float calcDistance(float[] firstPoint, float[] secondPoint, int size) {
		double sum = 0;
		for (int i = 0; i < size; i++) {
			sum += Math.pow(firstPoint[i] - secondPoint[i], 2);
		}
		return (float) Math.sqrt(sum);
	}

	/**
	 * This method returns the vector between the given points.
	 * It does not matter in which dimension the given point lay but
	 * it should be the same. (basePoint.length == headPoint.length)
	 * 
	 * @param basePoint the base point.
	 * @param headPoint the head point.
	 * @return the vector between the base point and the head point.
	 */
	public static float[] createVector(float[] basePoint, float[] headPoint) {
		float[] vector = new float[basePoint.length];
		for (int i = 0; i < basePoint.length; i++) {
			vector[i] = headPoint[i] - basePoint[i];
		}
		return vector;
	}
}
