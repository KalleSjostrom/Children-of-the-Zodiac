/*
 * Classname: Graphics.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/09/2008
 */
package graphics;

import info.Values;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.nio.ByteBuffer;

import com.jogamp.opengl.GL2;
import com.jogamp.opengl.GL4;
import com.jogamp.opengl.glu.GLU;

import java.util.logging.*;

import com.jogamp.opengl.util.texture.Texture;

import bodies.Vector3f;

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

	public static final float[] BLACK = new float[]{ 0, 0, 0, 1 };
	public static final float[] WHITE = new float[]{ 1, 1, 1, 1 };

	public static final float[] RED = new float[]{ Color.red.getRed(), Color.red.getGreen(), Color.red.getBlue(), 1.0f };
	public static final float[] GREEN = new float[]{ Color.green.getRed(), Color.green.getGreen(), Color.green.getBlue(), 1.0f };
	public static final float[] DARK_GRAY = new float[]{ Color.darkGray.getRed(), Color.darkGray.getGreen(), Color.darkGray.getBlue(), 1.0f };

	public static GL2 gl2;
	public static GL4 gl;
	private static String fadeImageName;
	private float[] global_color = new float[4];
		
	private Material spriteMaterial;
	private StringRenderer stringRenderer;
	
	private static Logger logger = Logger.getLogger("Graphics");
	
	public Graphics() {
		Values.loadFont();
	}

	public void init(GL4 gl) {
		spriteMaterial = new Material();
		spriteMaterial.init(gl);

		stringRenderer = new StringRenderer();
		stringRenderer.init(gl);
	}
	
	////////// IMAGE DRAWING METHODS //////////
	

	//// Buffered Image drawing /////
	public void drawImage(BufferedImage image, int x, int y) {
		drawImage(image, x, y, 1, 1);
	}
	public void drawImage(BufferedImage image, int x, int y, float scale, float alpha) {
		GameTexture t = ImageHandler.getGameTexture(image);
		drawTexture(t.getTexture(), x, y, scale, alpha);
	}
	
	//// Draw texture with given name /////
	// TODO(kalle): Make sure unused textures are destroyed!
	public void drawImage(String name, float x, float y) {
		drawImage(name, x, y, 1.0f, 1.0f);
	}
	public void drawImage(String name, float x, float y, float scale) {
		drawImage(name, x, y, scale, 1.0f);
	}
	public void drawImage(String name, float x, float y, float scale, float alpha) {
		drawTexture(ImageHandler.getTexture(name).getTexture(), x, y, scale, alpha);
	}
	public void drawImage(String name, int x, int y, int w, int h, float scale, float percent) {
		// drawTexture(ImageHandler.getTexture(name), x, y, w, h, scale, percent);
	}
	public void drawImage(String name, int x, int y, int w, int h, float scale, float percentLow, float percentHigh) {
		// drawTexture(ImageHandler.getTexture(name), x, y, w, h, scale, percentLow, percentHigh);
	}

	//// Texture drawing ////
	public void drawTexture(Texture texture, float x, float y, float scale, float alpha) {
		spriteMaterial.useMaterial(gl);
		spriteMaterial.setSprite(gl, texture, x, y, scale, alpha);
		spriteMaterial.render(gl);
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
	public void drawString(String string, int x, int y) {
		stringRenderer.drawString(gl, string, x, y, 1.0f);
	}
	public void drawString(String string, int x, int y, float alpha) {
		stringRenderer.drawString(gl, string, x, y, alpha);
	}
	public void drawStringCentered(String string, int y) {
		int anchor = Values.ORIGINAL_RESOLUTION[Values.X] / 2;
		drawStringCentered(string, y, anchor);
	}
	public void drawStringCentered(String string, int y, int anchor) {
		int x = calcAlignCenter(string, anchor);
		drawString(string, x, y);
	}
	public void drawStringRightAligned(String text, int y, int rightLimit) {
		int x = calcAlignRight(text, rightLimit);
		drawString(text, x, y);
	}
	
	public void drawWithShadow(String string, int x, int y) {
		drawWithShadow(string, x, y, WHITE);
	}	
	public void drawWithShadow(String string, int x, int y, Color color) {
		setColor(0, 0, 0, 1);
		drawString(string, x + 1, y + 1);
		setColor(color.getColorComponents(null), 1);
		drawString(string, x, y);
	}	
	public void drawWithShadow(String string, int x, int y, float[] color) {
		setColor(0, 0, 0, 1);
		drawString(string, x + 1, y + 1);
		setColor(color);
		drawString(string, x, y);
	}

	// Bounds and alignments
	public int calcAlignRight(String string, int rightMostLimit) {
		int width = stringRenderer.getWidth(string);
		return rightMostLimit - width;
	}
	public int calcAlignCenter(String string, int center) {
		int width = stringRenderer.getWidth(string);
		int halfWidth = (int) Math.round(width / 2.0f);
		return center - halfWidth;
	}
	public int getStringWidth(String string) {
		return stringRenderer.getWidth(string);
	}

	public void fade(float fv) {
		if (fadeMode == FADE_TO_WHITE) {
			fv = 1 - fv;
		}
		if (fv < 1) {
			gl2.glColor3f(fv, fv, fv);
		}
	}
	
	public void dim(float alpha) {
		gl2.glColor4f(1, 1, 1, alpha);
	}
	
	public void fadeOldSchool(float fadeindex) {
		fadeindex = fadeindex <= 0 ? 0 : fadeindex;
		if (fadeindex < 1) {
			switch (fadeMode) {
			case FADE_TO_WHITE : 
				drawImage(whiteFadeImage, 0, 0, 8, 1 - fadeindex);
				break;
			case FADE_TO_BLACK : 
				drawImage(fadeImage, 0, 0, 8, 1 - fadeindex);
				break;
			case FADE_TO_IMAGE : 
				drawImage(fadeImageName, 0, 0, 1, 1 - fadeindex);
				break;
			}
		}
	}
	
	public static void setFadeImage(int image) {
		fadeMode = image;
	}
	
	public static void setFadeImage(String image) {
		fadeMode = FADE_TO_IMAGE;
		fadeImageName = image;
	}

	public void setImageColor(float r, float g, float b, float a) {
		setColor(r, g, b, a);
	}

	/**
	 * Sets the color by giving one value to be used as all the 
	 * three values of the RGB color. So calling this method with
	 * argument 0 will result in black color.
	 * 
	 * @param i the value to use as red, green and blue.
	 */
	public void setColor(float i) {
		global_color[0] = global_color[1] = global_color[2] = global_color[3] = i;
	}
	public void setColor(float r, float g, float b) {
		global_color[0] = r;
		global_color[1] = g;
		global_color[2] = b;
	}
	public void setColor(float r, float g, float b, float a) {
		global_color[0] = r;
		global_color[1] = g;
		global_color[2] = b;
		global_color[3] = a;
	}
	public void setColor(float[] rgb, float a) {
		global_color[0] = rgb[0];
		global_color[1] = rgb[1];
		global_color[2] = rgb[2];
		global_color[3] = a;
	}
	public void setColor(float[] rgba) {
		global_color[0] = rgba[0];
		global_color[1] = rgba[1];
		global_color[2] = rgba[2];
		global_color[3] = rgba[3];
	}

	/**
	 * Sets the size as the size used when drawing texts.
	 * 
	 * @param size the size of the text to be drawn.
	 */
	public void setFontSize(int size) {
		if (size > 0) {
		} 
	}
	
	public void setFontSize(int size, boolean bold) {
		if (size > 0) {
			if (bold) {
			} else {
			}
		} 
	}
	
	public int getFontSize() {
		return 0;
	}

	/**
	 * This method scales both the x and y values by the given value.
	 * This is used to zoom in and out of images.
	 * 
	 * @param zoom the value to use when scaling.
	 */
	public void scale(float zoom) {
		gl2.glScalef(zoom, zoom, 1);
	}

	public void translate(float x, float y, float z) {
		gl2.glTranslatef(x, y, z);
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
			gl2.glCallList(list);
		}
	}
	public void loadIdentity() {
		// gl2.glLoadIdentity();
	}
	public void setBlendFunc(int glMode) {
		gl2.glBlendFunc(GL2.GL_SRC_ALPHA, glMode);
	}

	private int frameWidth;
	private int frameHeight;

	// TODO(kalle): Remove dependency on buffered image. We only need the open gl texture
	public BufferedImage copyFrame(GL2 gl) {  
		frameHeight = Values.RESOLUTIONS[Values.Y];
		frameWidth = Values.RESOLUTIONS[Values.X];
		java.nio.ByteBuffer pixelsRGB = ByteBuffer.allocateDirect(frameWidth * frameHeight * 3);
		
		gl.glReadBuffer(GL2.GL_FRONT);
		gl.glPixelStorei(GL2.GL_PACK_ALIGNMENT, 1);
		gl.glReadPixels(0, 0, frameWidth, frameHeight, 
				GL2.GL_RGB, GL2.GL_UNSIGNED_BYTE, 
				pixelsRGB);
		
		int[] pixelInts = new int[frameWidth * frameHeight];

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
		BufferedImage bufferedImage = new BufferedImage(frameWidth, frameHeight, BufferedImage.TYPE_INT_RGB);
		bufferedImage.setRGB(0, 0, frameWidth, frameHeight, pixelInts, 0, frameWidth);

		return bufferedImage;
	}

	public void beginBlend(boolean disableDepth) {
		gl2.glEnable(GL2.GL_BLEND);
		gl2.glAlphaFunc(GL2.GL_LEQUAL, 1);
		if (disableDepth) {
			gl2.glDisable(GL2.GL_DEPTH_TEST);
			gl2.glDepthMask(false);
		}
	}

	public void endBlend() {		
		gl2.glEnable(GL2.GL_DEPTH_TEST);
		gl2.glBlendFunc(GL2.GL_SRC_ALPHA, GL2.GL_ONE_MINUS_SRC_ALPHA);
		gl2.glAlphaFunc(GL2.GL_GEQUAL, .01f);
	}

	public void beginQuads() {
		gl2.glBegin(GL2.GL_QUADS);
	}
	public void end() {
		gl2.glEnd();
	}
	
	public void push() {
		gl2.glPushMatrix();
	}
	
	public void pop() {
		gl2.glPopMatrix();
	}

	public void drawCenteredCurrent2D(Vector3f pos, float size) {
		gl2.glTexCoord2i(0, 1);
		gl2.glVertex3f(pos.x - size, pos.y - size, pos.z);
		gl2.glTexCoord2i(1, 1);
		gl2.glVertex3f(pos.x + size, pos.y - size, pos.z);
		gl2.glTexCoord2i(1, 0);
		gl2.glVertex3f(pos.x + size, pos.y + size, pos.z);
		gl2.glTexCoord2i(0, 0);
		gl2.glVertex3f(pos.x - size, pos.y + size, pos.z);
	}
	
	public void drawCenteredCurrent2D(Vector3f pos, float width, float height) {
		width *= .5f;
		height *= .5f;
		gl2.glTexCoord2i(0, 1);
		gl2.glVertex3f(pos.x - width, pos.y - height, pos.z);
		gl2.glTexCoord2i(1, 1);
		gl2.glVertex3f(pos.x + width, pos.y - height, pos.z);
		gl2.glTexCoord2i(1, 0);
		gl2.glVertex3f(pos.x + width, pos.y + height, pos.z);
		gl2.glTexCoord2i(0, 0);
		gl2.glVertex3f(pos.x - width, pos.y + height, pos.z);
	}

	public void rotate(float angle, float x, float y, float z) {
		gl2.glRotatef(angle, x, y, z);
	}

	public void setTextureEnabled(boolean enable) {
		if (enable) {
			gl2.glEnable(GL2.GL_TEXTURE_2D);
		} else {
			gl2.glDisable(GL2.GL_TEXTURE_2D);
		}
	}

	public void setAlphaTestEnabled(boolean enable) {
		if (enable) {
			gl2.glEnable(GL2.GL_ALPHA_TEST);
		} else {
			gl2.glDisable(GL2.GL_ALPHA_TEST);
		}
	}

	public void setLightEnabled(boolean enable) {
		if (enable) {
			gl2.glEnable(GL2.GL_LIGHTING);	
		} else {
			gl2.glDisable(GL2.GL_LIGHTING);	
		}
	}
	
	public void setDepthTestEnabled(boolean enable) {
		if (enable) {
			gl2.glEnable(GL2.GL_DEPTH_TEST);	
		} else {
			gl2.glDisable(GL2.GL_DEPTH_TEST);	
		}
	}
	
	public void setAlphaFunc(float f) {
		 // gl2.glAlphaFunc(GL2.GL_GREATER, f);
	}
	
	public void drawGradient(Vector3f color, float topAlpha, float bottomAlpha, float xRight, 
			float xLeft, float yBottom, float yTop, boolean popPush, boolean beginQuads) {
		/*if (popPush) {
			push();
			loadIdentity();
			translate(0, 0, BattleValues.STANDARD_Z_DEPTH);
		}
		if (beginQuads) {
			setTextureEnabled(false);
			beginQuads();
		}
		
		setColor(color, topAlpha);
		gl2.glVertex3f(xRight, yTop, 0);
		gl2.glVertex3f(xLeft, yTop, 0);
		setColor(color, bottomAlpha);
		gl2.glVertex3f(xLeft, yBottom, 0);
		gl2.glVertex3f(xRight, yBottom, 0);
		
		if (beginQuads) {
			end();
			setTextureEnabled(true);
		}
		
		if (popPush) {
			setColor(1, 1, 1);
			pop();
		}*/
	}

	public void setNormal(float x, float y, float z) {
		gl2.glNormal3f(x, y, z);	
	}

	public void pushTranslateRotatez(float x, float y, float z, float angle) {
		push();
		translate(x, y, z);
		rotate(-angle, 0, 0, 1);
	}
	
	// Draw list methods.
	
	public int generateList() {
		return gl2.glGenLists(1);
	}

	public void compileDrawList(int drawList) {
		gl2.glNewList(drawList, GL2.GL_COMPILE);
	}

	public void endList() {
		gl2.glEndList();
	}

	public void callList(int drawList) {
		gl2.glCallList(drawList);
	}
	
	public void deleteList(int list) {
		gl2.glDeleteLists(list, 1);
	}

	public void checkError() {
		int err = gl.glGetError();
		
		if (err != GL2.GL_NO_ERROR) {
			String s = new GLU().gluErrorString(err);
			logger.log(Level.WARNING, "OpenGL Error: " + s);
		}
	}

	public void translate(Vector3f pos) {
		gl2.glTranslatef(pos.x, pos.y, pos.z);	
	}
	public void translateBack(Vector3f pos) {
		gl2.glTranslatef(-pos.x, -pos.y, -pos.z);	
	}

	public void setAlpha(float alpha) {
	}
}
