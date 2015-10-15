/*
 * Classname: Graphics.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/09/2008
 */
package graphics;

import info.BattleValues;
import info.Values;

import java.awt.Color;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.nio.ByteBuffer;

import com.jogamp.opengl.GL2;
import com.jogamp.opengl.glu.GLU;

import java.util.logging.*;
import organizer.Organizer;

import bodies.Vector3f;

import com.jogamp.opengl.util.awt.TextRenderer;
import com.jogamp.opengl.util.texture.TextureCoords;

/**
 * This class is wraps the java open GL library JOGL in a class similar to
 * to Graphics2D class. With this, one can draw images and strings with 
 * the same coordinate system as the Graphics2D. These images are converted
 * to textures to be drawn in openGL and they are stored in a map with the
 * images as keys. 
 * 
 * @author 		Kalle Sj�str�m 
 * @version 	0.7.0 - 01 Sep 2088
 */
public class Graphics {

	public static final BufferedImage fadeImage = 
		GraphicHelp.getImage(.125f, .125f, Color.BLACK);
	public static final BufferedImage whiteFadeImage = 
		GraphicHelp.getImage(.125f, .125f, Color.WHITE);
	public static final BufferedImage textBack = 
		GraphicHelp.getImage(1, .25f, Color.BLACK);
	
	public static final int FADE_TO_BLACK = 0;
	public static final int FADE_TO_WHITE = 1;
	public static final int FADE_TO_IMAGE = 2;
	private static int fadeMode = FADE_TO_BLACK;

	private static float[] textColor = new float[3];
	public static GL2 gl;
	private static String fadeImageName;
	private float color;
	private static TextManager textManager;
	
	private static Logger logger = Logger.getLogger("Graphics");
	
	/**
	 * Constructs a new graphics object for drawing images in JOGL.
	 */
	public Graphics() {
		Values.loadFont();
		textManager = new TextManager();
		textManager.setFont(24, Values.PLAIN);
	}
	
	////////// IMAGE DRAWING METHODS //////////
	
	public void drawi(TextureCoords tc, int x, int yh, int xw, int y) {
		drawi(tc, x, yh, xw, y, true);
	}
	public void drawi(TextureCoords tc, int x, int yh, int xw, int y, boolean begin) {
		if (begin) {beginQuads();}
		gl.glTexCoord2f(tc.left(), tc.bottom());
		gl.glVertex2i(x, yh);
		
		gl.glTexCoord2f(tc.right(), tc.bottom());
		gl.glVertex2i(xw, yh);
		
		gl.glTexCoord2f(tc.right(), tc.top());
		gl.glVertex2i(xw, y);
		
		gl.glTexCoord2f(tc.left(), tc.top());
		gl.glVertex2i(x, y);
		if (begin) {end();}
	}
	
	public void drawip(TextureCoords tc, int x, int yh, int xw, int y, float percent) {
		drawip(tc, x, yh, xw, y, true, percent);
	}
	public void drawip(TextureCoords tc, int x, int yh, int xw, int y, boolean begin, float percent) {
		if (begin) {beginQuads();}
		gl.glTexCoord2f(tc.left(), tc.bottom());
		gl.glVertex2i(x, yh);
		gl.glTexCoord2f(tc.right() * percent, tc.bottom());
		gl.glVertex2i(xw, yh);
		
		gl.glTexCoord2f(tc.right() * percent, tc.top());
		gl.glVertex2i(xw, y);
		
		gl.glTexCoord2f(tc.left(), tc.top());
		gl.glVertex2i(x, y);
		if (begin) {end();}
	}
	
	public void drawipp(TextureCoords tc, int x, int yh, int xw, int y, 
			float percentLow, float percentHigh) {
		drawipp(tc, x, yh, xw, y, true, percentLow, percentHigh);
	}
	public void drawipp(TextureCoords tc, int x, int yh, int xw, int y, boolean begin,
			float percentLow, float percentHigh) {
		if (begin) {beginQuads();}
		gl.glTexCoord2f(tc.left() + percentLow, tc.bottom());
		gl.glVertex2i(x, yh);
		gl.glTexCoord2f(tc.right() * percentHigh, tc.bottom());
		gl.glVertex2i(xw, yh);
		
		gl.glTexCoord2f(tc.right() * percentHigh, tc.top());
		gl.glVertex2i(xw, y);
		
		gl.glTexCoord2f(tc.left() + percentLow, tc.top());
		gl.glVertex2i(x, y);
		if (begin) {end();}
	}
	
	// TODO: Is drawf necessary?
	public void drawf(TextureCoords tc, float x, float yh, float xw, float y) {
		drawf(tc, x, yh, xw, y, true);
	}
	public void drawf(TextureCoords tc, float x, float yh, float xw, float y, boolean begin) {
		if (begin) {beginQuads();}
		gl.glTexCoord2f(tc.left(), tc.bottom());
		gl.glVertex2f(x, yh);
		
		gl.glTexCoord2f(tc.right(), tc.bottom());
		gl.glVertex2f(xw, yh);
		
		gl.glTexCoord2f(tc.right(), tc.top());
		gl.glVertex2f(xw, y);
		
		gl.glTexCoord2f(tc.left(), tc.top());
		gl.glVertex2f(x, y);
		if (begin) {end();}
	}
	
	public void draw3f(TextureCoords tc, boolean flip, float x, float y,
			float z, float x2, float y2, float z2) {
		draw3f(tc, flip, x, y, z, x2, y2, z2, true);
	}
	
	public void draw3f(TextureCoords tc, boolean flip, float x, float y,
			float z, float x2, float y2, float z2, boolean begin) {
		if (begin) {beginQuads();}
		gl.glTexCoord2f(flip ? tc.left() : tc.right(), flip ? tc.top() : tc.bottom()); 
		gl.glVertex3f(x, y, z);
		
		gl.glTexCoord2f(flip ? tc.left() : tc.right(), flip ? tc.bottom() : tc.top());
		gl.glVertex3f(x, y2, z);
		
		gl.glTexCoord2f(flip ? tc.right() : tc.left(), flip ? tc.bottom() : tc.top());
		gl.glVertex3f(x2, y2, z);
		
		gl.glTexCoord2f(flip ? tc.right() : tc.left(), flip ? tc.top() : tc.bottom());
		gl.glVertex3f(x2, y, z);
		if (begin) {end();}
	}

	//// Buffered Image drawing /////
	
	public void drawImage(BufferedImage image, int x, int y) {
		drawImage(image, x, y, 1);
	}
	
	public void drawImage(BufferedImage image, int x, int y, float scale) {
		GameTexture t = ImageHandler.getGameTexture(image);
		drawTexture(t, x, y, scale);
	}
	
	//// Draw texture with given name /////

	public void drawImage(String name, int x, int y) {
		drawImage(name, x, y, 1);
	}
	
	public void drawImage(String name, float x, float y, float scale) {
		drawImage(name, Math.round(x), Math.round(y), scale);
	}
	
	public void drawImage(String name, int x, int y, float scale) {
		if (name != null) {
			long time = System.currentTimeMillis();
			drawTexture(ImageHandler.getTexture(name), x, y, scale);
			time = System.currentTimeMillis() - time; 
			if (time > 500) {
				logger.log(Level.WARNING, 
						"Warning! The image " + name + " took " + time + " ms to load");
			}
		}
	}
	
	public void drawImage(String name, int x, int y, int w, int h, float scale, float percent) {
		if (name != null) {
			long time = System.currentTimeMillis();
			drawTexture(ImageHandler.getTexture(name), x, y, w, h, scale, percent);
			time = System.currentTimeMillis() - time; 
			if (time > 500) {
				logger.log(Level.WARNING, 
						"Warning! The image " + name + " took " + time + " ms to load");
			}
		}
	}
	
	public void drawImage(String name, int x, int y, int w, int h, float scale, float percentLow, float percentHigh) {
		if (name != null) {
			long time = System.currentTimeMillis();
			drawTexture(ImageHandler.getTexture(name), x, y, w, h, scale, percentLow, percentHigh);
			time = System.currentTimeMillis() - time; 
			if (time > 500) {
				logger.log(Level.WARNING, 
						"Warning! The image " + name + " took " + time + " ms to load");
			}
		}
	}

	//// Game texture drawing ////
	
	public void drawTexture(GameTexture t, int x, int y) {
		drawTexture(t, x, y, 1);
	}
	
	public void drawTexture(GameTexture t, int x, int y, float size) {
		t.draw(this, x, y, size);
	}
	
	public void drawTexture(GameTexture t, int x, int y, int w, int h, float size, float percent) {
		t.draw(this, x, y, w, h, size, percent);
	}
	
	private void drawTexture(GameTexture t, int x, int y, int w, int h,
			float size, float percentLow, float percentHigh) {
		t.draw(this, x, y, w, h, size, percentLow, percentHigh);
	}
	
	//// Draw centered image with given name ////

	public void drawCenteredImage(String name, int y) {
		GameTexture t = ImageHandler.getTexture(name);
		int width = Math.round(t.getWidth() / 2f);
		int hx = Values.ORIGINAL_RESOLUTION[Values.X] / 2;
		int x = hx - width;
		drawImage(name, x, y);
	}
	
	public void drawCenteredImage(String name, int x, int y) {
		GameTexture t = ImageHandler.getTexture(name);
		int width = Math.round(t.getWidth() / 2f);
		int newx = x - width;
		drawImage(name, newx, y);
	}
	
	public GameTexture[][] get(String[][] names) {
		GameTexture[][] gts = new GameTexture[names.length][names[0].length];
		for (int i = 0; i < names.length; i++) {
			for (int j = 0; j < names[0].length; j++) {
				gts[i][j] = ImageHandler.getTexture(names[i][j]);
			}
		}
		return gts;
	}

	/**
	 * Compiles a draw list where the given texture is drawn with the
	 * given scale. This texture is drawn with x = 0 and y = 0 
	 * so one must translate the current matrix before calling the drawList
	 * to draw the texture at a different position. 
	 * 
	 * @param t the texture to render.
	 * @param scale the scale to draw the texture.
	 * @return the integer representing the list. Use this integer as
	 * parameter when calling glCallList();
	 */
	
	////////// TEXT DRAWING METHODS //////////

	private void beginRendering() {
		textManager.getCurrentFont().beginRendering(
				Values.ORIGINAL_RESOLUTION[Values.X], 
				Values.ORIGINAL_RESOLUTION[Values.Y]);
	}
	
	private void endRendering() {
		textManager.getCurrentFont().endRendering();
	}
	
	public void drawString(String string, int x, int y, float alpha) {
		beginRendering();
		textManager.getCurrentFont().setColor(textColor[0], textColor[1], textColor[2], alpha);
		drawSingleString(string, x, y, textManager.getCurrentFont());
		endRendering();
		setColor(this.color);
	}
	
	/**
	 * Draws the given string at the given position.
	 * 
	 * @param string the string to draw.
	 * @param x the x coordinate of the string position.
	 * @param y the y coordinate of the string position.
	 */
	public void drawString(String string, int x, int y) {
		drawString(string, x, y, 1);
	}
	
	public void drawStringSetSize(String string, int x, int y, int size) {
		setFontSize(size);
		drawString(string, x, y, 1);
	}
	
	private void drawSingleString(String string, int x, int y, TextRenderer text) {
		if (string != null) {
			text.draw(string, x, Values.ORIGINAL_RESOLUTION[Values.Y] - y);
		}
	}

	/**
	 * Draws the given string at the given position. This method
	 * assumes that the startText() method has been called to set up
	 * drawings of strings.
	 * 
	 * @param string the string to draw.
	 * @param x the x coordinate of the string position.
	 * @param y the y coordinate of the string position.
	 */
	public void drawMultiString(String string, int x, int y) {
		drawSingleString(string, x, y, textManager.getCurrentFont());
	}
	
	boolean textStarted = false;
	private float[] fadeColor = new float[]{1, 1, 1, 1};

	/**
	 * This method sets up drawing of string.
	 * 
	 * @param alpha the alpha value to use when drawing texts.
	 */
	public void startText() {
		startText(Organizer.getOrganizer().getCurrentMode().fadeValue, -1);
	}
	
	public void startText(float alpha, float color) {
		startText(alpha, color, -1);
	}
	
	public void startText(float alpha, float color, int fontSize) {
		if (!textStarted) {
			setFontSize(fontSize);
			setTextColor(color);
			textStarted = true;
			beginRendering();
			if (alpha <= -1) {
				alpha = Organizer.getOrganizer().getCurrentMode().fadeValue;
			}
			textManager.getCurrentFont().setColor(textColor[0], textColor[1], textColor[2], alpha);
		}
	}

	/**
	 * This method is called to finish the drawings of text.
	 */
	public void finishText() {
		textManager.getCurrentFont().endRendering();
		textStarted = false;
		setColor(this.color);
	}
	
	public void drawSingleCenteredText(String string, int y) {
		drawSingleCenteredText(string, y, 1, 1);
	}
	
	public void drawSingleCenteredText(String string, int y, int x) {
		drawSingleCenteredText(string, y, 1, 1, -1, x);
	}
	
	public void drawSingleCenteredText(String string, int y, float alpha, float c) {
		int hx = Values.ORIGINAL_RESOLUTION[Values.X] / 2;
		drawSingleCenteredText(string, y, alpha, c, -1, hx);
	}
	
	public void drawSingleCenteredText(String string, int y, float alpha, float c, int center) {
		drawSingleCenteredText(string, y, alpha, c, -1, center);
	}
	
	public void drawSingleCenteredText(String string, int y, float alpha, float c, int fontSize, int center) {
		setFontSize(fontSize);
		startText(alpha, c);
		drawMultiCenteredText(string, y, center);
		finishText();
	}

	/**
	 * Draws the given string at the given height with the given size.
	 * The text is rendered in black. This method should be used when
	 * drawing rather small texts.
	 * 
	 * @param string the string to draw.
	 * @param y the height of the text.
	 * @param size the size of the text.
	 * @param alpha the alpha value of the text. The transparency value.
	 * @param color the color of the text.
	 */
	public void drawMultiCenteredText(String string, int y, int x) {
		x = calcAlignCenter(string, x);
		drawSingleString(string, x, y, textManager.getCurrentFont());
	}
	
	public void drawMultiCenteredText(String string, int y) {
		drawMultiCenteredText(string, y, Values.ORIGINAL_RESOLUTION[Values.X] / 2);
	}

	/**
	 * This method calculates the position where to draw the given string
	 * so that the right most limit of the string is positioned at the
	 * given rightMostLimit x position.
	 * 
	 * @param string the string to be drawn.
	 * @param rightMostLimit the position of the right limit of the text.
	 * @return the x position where to draw the given string.
	 */
	public static int calcAlignRight(String string, int rightMostLimit) {
		Rectangle2D r = textManager.getCurrentFont().getBounds(string);
		int width = (int) Math.round(r.getWidth());
		return rightMostLimit - width;
	}
	
	public static int calcAlignCenter(String string, int center) {
		return calcAlignCenter(string, center, textManager.getCurrentFont());
	}
	
	public static int calcAlignCenter(String string, int center, TextRenderer rend) {
		Rectangle2D r = rend.getBounds(string);
		int halfWidth = (int) Math.round(r.getWidth() / 2.0f);
		return center - halfWidth;
	}
	
	public static int calcAlignCenterTest(String string, int center, TextRenderer rend, float scale) {
		Rectangle2D r = rend.getBounds(string);
		int halfWidth = (int) Math.round((r.getWidth() * scale) / 2.0f);
		return center - halfWidth;
	}
	
	public static int getStringWidth(String string) {
		Rectangle2D r = textManager.getCurrentFont().getBounds(string);
		return (int) Math.round(r.getWidth());
	}
	
	/**
	 * Draw the given text, right aligned, at the given height.
	 * The right most limit is set to 980. 
	 * 
	 * @param text the text to draw.
	 * @param y the height of the text.
	 */
	public void drawStringRightWithReg(String text, int y) {
		int x = calcAlignRight(text, 985);
		drawString(text, x, y);
	}
	
	public void drawStringRightAligned(String text, int y, int rightLimit) {
		int x = calcAlignRight(text, rightLimit);
		drawString(text, x, y);
	}

	/**
	 * Sets the given GL as the GL to use when rendering in 3D.
	 * 
	 * @param gl the GL to set.
	 */
	public void setGL(GL2 gl) {
		Graphics.gl = gl;
	}

	/**
	 * Gets the current GL object used. This GL object might
	 * not be current, so do not use the returned object without
	 * making sure that the GL context is current.
	 * 
	 * @return the current GL object used.
	 */
	public GL2 getGL() {
		return gl;
	}

	/**
	 * This method draws a black texture with the given fade index as 
	 * alpha value. If this method is called with rising fade index from
	 * 0 to 1 this method will fade the current screen from completely
	 * transparent to completely black.
	 * 
	 * @param fadeindex the alpha value of the black overlay texture.
	 */
	public void fade(float fv) {
		if (fadeMode == FADE_TO_WHITE) {
			fv = 1 - fv;
		}
		if (fv < 1) {
			gl.glColor3f(fv, fv, fv);
		}
	}
	
	public void dim(float alpha) {
		gl.glColor4f(1, 1, 1, alpha);
	}
	
	public void fadeOldSchool(float fadeindex) {
		fadeindex = fadeindex <= 0 ? 0 : fadeindex;
		if (fadeindex < 1) {
			gl.glColor4f(fadeColor[0], fadeColor[1], fadeColor[2], 1 - fadeindex);
			switch (fadeMode) {
			case FADE_TO_WHITE : 
				drawImage(whiteFadeImage, 0, 0, 8);
				break;
			case FADE_TO_BLACK : 
				drawImage(fadeImage, 0, 0, 8);
				break;
			case FADE_TO_IMAGE : 
				drawImage(fadeImageName, 0, 0, 1);
				break;
			}
		}
	}
	
	public void fadeOldSchoolColor(float r, float g, float b, float a) {
		gl.glColor4f(r, g, b, a);
		drawImage(fadeImage, 0, 0, 8);
		gl.glColor4f(1, 1, 1, 1);
	}
	
	public void fadeOldSchoolColorWhite(float r, float g, float b, float a) {
		gl.glColor4f(r, g, b, a);
		drawImage(whiteFadeImage, 0, 0, 8);
		gl.glColor4f(1, 1, 1, 1);
	}
	
	public static void setFadeImage(int image) {
		fadeMode = image;
	}
	
	public static void setFadeImage(String image) {
		fadeMode = FADE_TO_IMAGE;
		fadeImageName = image;
	}

	/**
	 * Sets the given color as the currently used text color.
	 * 
	 * @param c the color to set.
	 */
	public static void setTextColor(Color c) {
		textColor[0] = c.getRed() / 255f;
		textColor[1] = c.getGreen() / 255f;
		textColor[2] = c.getBlue() / 255f;
	}

	/**
	 * Sets the given RGB values as the currently used text color.
	 * 
	 * @param r the value of red.
	 * @param g the value of green.
	 * @param b the value of blue.
	 */
	public static void setTextColor(float r, float g, float b) {
		textColor[0] = r;
		textColor[1] = g;
		textColor[2] = b;
	}
	
	public static void setTextColor(Vector3f color) {
		textColor[0] = color.x;
		textColor[1] = color.y;
		textColor[2] = color.z;
	}
	public void setTextColorAndApply(Vector3f color) {
		textColor[0] = color.x;
		textColor[1] = color.y;
		textColor[2] = color.z;
		applyColor(1);
	}
	
	public static void setTextColor(float i) {
		if (i >= 0 && i <= 1) {
			textColor[0] = i;
			textColor[1] = i;
			textColor[2] = i;
		}
	}
	
	public void setTextColorAndApply(float i, float alpha) {
		setTextColor(i);
		applyColor(alpha);
	}
	
	private void applyColor(float alpha) {
		textManager.getCurrentFont().setColor(
				textColor[0], textColor[1], textColor[2], alpha);
	}

	/**
	 * Sets the color to use when drawing images.
	 * 
	 * @param r the red intensity.
	 * @param g the greed intensity.
	 * @param b the blue intensity.
	 * @param a the alpha value to use when drawing images.
	 */
	public void setImageColor(float r, float g, float b, float a) {
		gl.glColor4f(r, g, b, a);
	}
	
	public void setFadeColor(float r, float g, float b, float a) {
		gl.glColor4f(r, g, b, a);
		fadeColor = new float[]{r, g, b, a};
	}

	/**
	 * Sets the color by giving one value to be used as all the 
	 * three values of the RGB color. So calling this method with
	 * argument 0 will result in black color.
	 * 
	 * @param i the value to use as red, green and blue.
	 */
	public void setColor(float i) {
		gl.glColor4f(i, i, i, i);
		color = i;
	}
	
	public void setColor(float r, float g, float b) {
		gl.glColor3f(r, g, b);
	}
	public void setColor(float r, float g, float b, float a) {
		gl.glColor4f(r, g, b, a);
	}
	public void setColor(Vector3f color, float a) {
		gl.glColor4f(color.x, color.y, color.z, a);
	}
	public void setColor(Vector3f color) {
		gl.glColor4f(color.x, color.y, color.z, 1);
	}
	public void setColor3(float[] color) {
		gl.glColor3f(color[0], color[1], color[2]);
	}
	public void setColor4(float[] color, float alpha) {
		gl.glColor4f(color[0], color[1], color[2], alpha);
	}
	public void setColorv(float[] colors, int index) {
		gl.glColor4fv(colors, index);
	}
	public void clearColor(int color) {
		gl.glClearColor(color, color, color, 1);
	}

	/**
	 * Sets the size as the size used when drawing texts.
	 * 
	 * @param size the size of the text to be drawn.
	 */
	public void setFontSize(int size) {
		if (size > 0) {
			textManager.setFont(size);
		} 
	}
	
	public void setFontSize(int size, boolean bold) {
		if (size > 0) {
			if (bold) {
				textManager.setFont(size, Values.BOLD);
			} else {
				textManager.setFont(size, Values.PLAIN);
			}
		} 
	}
	
	public int getFontSize() {
		return textManager.getFontSize();
	}

	/**
	 * This method scales both the x and y values by the given value.
	 * This is used to zoom in and out of images.
	 * 
	 * @param zoom the value to use when scaling.
	 */
	public void scale(float zoom) {
		gl.glScalef(zoom, zoom, 1);
	}

	public void translate(float x, float y, float z) {
		gl.glTranslatef(x, y, z);
	}

	/**
	 * Gets the width of the texture with the given name. The texture
	 * is gotten from the map in ImageHandler.
	 * 
	 * @param name the name of the texture to get the width from.
	 * @return the width of the texture with the given name.
	 */
	public float getWidth(String name) {
		GameTexture t = ImageHandler.getTexture(name);
		return t.getWidth();
	}

	/**
	 * Gets the height of the texture with the given name. The texture
	 * is gotten from the map in ImageHandler.
	 * 
	 * @param name the name of the texture to get the height from.
	 * @return the height of the texture with the given name.
	 */
	public float getHeight(String name) {
		GameTexture t = ImageHandler.getTexture(name);
		return t.getHeight();
	}

	/**
	 * This method calls the glCallList() with the given list
	 * if and only if the given argument is not -1.
	 * 
	 * @param list the list to draw.
	 */
	public void drawList(int list) {
		if (list != -1) {
			gl.glCallList(list);
		}
	}

	/**
	 * This method loads the identity matrix for the current gl.
	 * This is equivalent to Values.loadIdentity(Graphics3D.getGL()).
	 */
	public void loadIdentity() {
		gl.glLoadIdentity();
	}

	public void setBlendFunc(int glMode) {
		gl.glBlendFunc(GL2.GL_SRC_ALPHA, glMode);
	}

	/**
	 * Draws the given value at the given location with a black drop shadow.
	 * The value is drawn in the given color.
	 * 
	 * @param value the value to draw.
	 * @param x the x position of the value.
	 * @param y the y position of the value.
	 * @param color the color to draw the value in.
	 */
	public void drawValueWithShadow(int value, int x, int y, Color color) {
		setTextColor(Color.black);
		drawString(value + "", x + 1, y + 1);
		if (value > 0) {
			setTextColor(color);
		} else {
			setTextColor(Color.white);
		}
		drawString(value + "", x, y);
	}

	/**
	 * Draws the given string at the given location with a black drop shadow.
	 * The string will be rendered in white.
	 * 
	 * @param string the string to draw.
	 * @param x the x position of the value.
	 * @param y the y position of the value.
	 */
	public void drawWithShadow(String string, int x, int y) {
		drawWithShadow(string, x, y, Color.white);
	}

	/**
	 * Draws the given string at the given location with a black drop shadow.
	 * It will draw the string with the given color.
	 * 
	 * @param string the string to draw.
	 * @param x the x position of the value.
	 * @param y the y position of the value.
	 * @param color the color to use when rendering the string.
	 */
	public void drawWithShadow(String string, int x, int y, Color color) {
		setTextColor(Color.black);
		drawString(string, x + 1, y + 1);
		setTextColor(color);
		drawString(string, x, y);
	}

	/**
	 * Draws the given value at the given location with a black drop shadow.
	 * 
	 * @param info the integer to draw.
	 * @param x the x position of the value.
	 * @param y the y position of the value.
	 */
	public void drawWithShadow(int info, int x, int y) {
		drawWithShadow(String.valueOf(info), x, y);
	}
	
	public void drawWithShadow(int val, int x, int y, Color color) {
		drawWithShadow(String.valueOf(val), x, y, color);
	}

	private int frameWidth;
	private int frameHeight;

	public BufferedImage copyFrame(GL2 gl) {  
		frameHeight = Values.RESOLUTIONS[Values.Y];
		frameWidth = Values.RESOLUTIONS[Values.X];
		// Create a ByteBuffer to hold the frame data.
		java.nio.ByteBuffer pixelsRGB = 
			//BufferUtils.newByteBuffer
			ByteBuffer.allocateDirect
			( frameWidth * frameHeight * 3 ); 

		// Get date from frame as ByteBuffer.
		getFrameData(gl, pixelsRGB);

		return transformPixels(pixelsRGB);
	}

	private ByteBuffer getFrameData(GL2 gl, 
			ByteBuffer pixelsRGB) {
		// Read Frame back into our ByteBuffer.
		gl.glReadBuffer(GL2.GL_FRONT);
		gl.glPixelStorei(GL2.GL_PACK_ALIGNMENT, 1);
		gl.glReadPixels(0, 0, frameWidth, frameHeight, 
				GL2.GL_RGB, GL2.GL_UNSIGNED_BYTE, 
				pixelsRGB);
		return pixelsRGB;
	}

	// Copies the Frame to an integer array.
	// Do the necessary conversion by hand.
	//
	private BufferedImage transformPixels(ByteBuffer pixelsRGB) {
		// Transform the ByteBuffer and get it as pixeldata.

		int[] pixelInts = new int[ frameWidth * frameHeight ];

		// Convert RGB bytes to ARGB ints with no transparency. 
		// Flip image vertically by reading the
		// rows of pixels in the byte buffer in reverse 
		// - (0,0) is at bottom left in OpenGL.
		//
		// Points to first byte (red) in each row.
		int p = frameWidth * frameHeight * 3; 
		int q; // Index into ByteBuffer
		int i = 0; // Index into target int[]
		int w3 = frameWidth * 3; // Number of bytes in each row
		for (int row = 0; row < frameHeight; row++) {
			p -= w3;
			q = p;
			for (int col = 0; col < frameWidth; col++) {
				int iR = pixelsRGB.get(q++);
				int iG = pixelsRGB.get(q++);
				int iB = pixelsRGB.get(q++);
				pixelInts[i++] = 
					0xFF000000 | ((iR & 0x000000FF) << 16) | 
					((iG & 0x000000FF) << 8) | (iB & 0x000000FF);
			}
		}

		// Create a new BufferedImage from the pixeldata.
		BufferedImage bufferedImage = 
			new BufferedImage( frameWidth, frameHeight, 
					BufferedImage.TYPE_INT_RGB);
		bufferedImage.setRGB( 0, 0, frameWidth, frameHeight, 
				pixelInts, 0, frameWidth );

		return bufferedImage;
	}

	public void beginBlend(boolean disableDepth) {
		gl.glEnable(GL2.GL_BLEND);
		gl.glAlphaFunc(GL2.GL_LEQUAL, 1);
		if (disableDepth) {
			gl.glDisable(GL2.GL_DEPTH_TEST);
			gl.glDepthMask(false);
		}
	}

	public void endBlend() {		
		gl.glEnable(GL2.GL_DEPTH_TEST);
		gl.glBlendFunc(GL2.GL_SRC_ALPHA, GL2.GL_ONE_MINUS_SRC_ALPHA);
		gl.glAlphaFunc(GL2.GL_GEQUAL, .01f);
	}

	public void beginQuads() {
		gl.glBegin(GL2.GL_QUADS);
	}
	public void end() {
		gl.glEnd();
	}
	
	public void push() {
		gl.glPushMatrix();
	}
	
	public void pop() {
		gl.glPopMatrix();
	}

	public void drawCenteredCurrent2D(Vector3f pos, float size) {
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(pos.x - size, pos.y - size, pos.z);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(pos.x + size, pos.y - size, pos.z);
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(pos.x + size, pos.y + size, pos.z);
		gl.glTexCoord2i(0, 0);
		gl.glVertex3f(pos.x - size, pos.y + size, pos.z);
	}
	
	public void drawCenteredCurrent2D(Vector3f pos, float width, float height) {
		width *= .5f;
		height *= .5f;
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(pos.x - width, pos.y - height, pos.z);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(pos.x + width, pos.y - height, pos.z);
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(pos.x + width, pos.y + height, pos.z);
		gl.glTexCoord2i(0, 0);
		gl.glVertex3f(pos.x - width, pos.y + height, pos.z);
	}

	public void rotate(float angle, float x, float y, float z) {
		gl.glRotatef(angle, x, y, z);
	}

	public void setTextureEnabled(boolean enable) {
		if (enable) {
			gl.glEnable(GL2.GL_TEXTURE_2D);
		} else {
			gl.glDisable(GL2.GL_TEXTURE_2D);
		}
	}

	public void setAlphaTestEnabled(boolean enable) {
		if (enable) {
			gl.glEnable(GL2.GL_ALPHA_TEST);
		} else {
			gl.glDisable(GL2.GL_ALPHA_TEST);
		}
	}

	public void setLightEnabled(boolean enable) {
		if (enable) {
			gl.glEnable(GL2.GL_LIGHTING);	
		} else {
			gl.glDisable(GL2.GL_LIGHTING);	
		}
	}
	
	public void setDepthTestEnabled(boolean enable) {
		if (enable) {
			gl.glEnable(GL2.GL_DEPTH_TEST);	
		} else {
			gl.glDisable(GL2.GL_DEPTH_TEST);	
		}
	}
	
	public void setAlphaFunc(float f) {
		 gl.glAlphaFunc(GL2.GL_GREATER, f);
	}
	
	public void drawGradient(Vector3f color, float topAlpha, float bottomAlpha, float xRight, 
			float xLeft, float yBottom, float yTop, boolean popPush, boolean beginQuads) {
		if (popPush) {
			push();
			loadIdentity();
			translate(0, 0, BattleValues.STANDARD_Z_DEPTH);
		}
		if (beginQuads) {
			setTextureEnabled(false);
			beginQuads();
		}
		
		setColor(color, topAlpha);
		gl.glVertex3f(xRight, yTop, 0);
		gl.glVertex3f(xLeft, yTop, 0);
		setColor(color, bottomAlpha);
		gl.glVertex3f(xLeft, yBottom, 0);
		gl.glVertex3f(xRight, yBottom, 0);
		
		if (beginQuads) {
			end();
			setTextureEnabled(true);
		}
		
		if (popPush) {
			setColor(1, 1, 1);
			pop();
		}
	}

	public void setNormal(float x, float y, float z) {
		gl.glNormal3f(x, y, z);	
	}

	public void pushTranslateRotatez(float x, float y, float z, float angle) {
		push();
		translate(x, y, z);
		rotate(-angle, 0, 0, 1);
	}
	
	// Draw list methods.
	
	public int generateList() {
		return gl.glGenLists(1);
	}

	public void compileDrawList(int drawList) {
		gl.glNewList(drawList, GL2.GL_COMPILE);
	}

	public void endList() {
		gl.glEndList();
	}

	public void callList(int drawList) {
		gl.glCallList(drawList);
	}
	
	public void deleteList(int list) {
		gl.glDeleteLists(list, 1);
	}

	public void checkError() {
		int err = gl.glGetError();
		
		if (err != GL2.GL_NO_ERROR) {
			String s = new GLU().gluErrorString(err);
			logger.log(Level.WARNING, "OpenGL Error: " + s);
		}
	}

	public void translate(Vector3f pos) {
		gl.glTranslatef(pos.x, pos.y, pos.z);	
	}
	public void translateBack(Vector3f pos) {
		gl.glTranslatef(-pos.x, -pos.y, -pos.z);	
	}
}
