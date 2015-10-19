/*
 * Classname: GraphicHelp.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/01/2008
 */
package graphics;

import info.Values;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;

/**
 * This class contains some static methods for drawing and handling
 * images and graphics.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 27 Jan 2008
 */
public class GraphicHelp {
	
	static final float BRIGHTNESS = .8f;

	/**
	 * Converts the given image to gray scale. It actually returns a new 
	 * image object, so the source image will not be affected.
	 * 
	 * @param colorImage the image to convert.
	 * @return a gray scale version of the given image.
	 */
	public static BufferedImage toGrayScale(BufferedImage im) {
		int cols = im.getWidth();
		int rows = im.getHeight();
		int[] pixels = new int[rows * cols * 4];

		WritableRaster raster = im.getRaster();
		raster.getPixels(0, 0, cols, rows, pixels);
		int r;
		int b;
		int g;
		for (int i = 0; i < pixels.length; i+=4) {
			r = pixels[i];
			b = pixels[i + 1];
			g = pixels[i + 2];
			float n = BRIGHTNESS * (.3f*r + .59f*b + .11f*g);
			pixels[i] = (int) n;
			pixels[i + 1] = (int) n;
			pixels[i + 2] = (int) n;
			//30% of the red value, 59% of the green value, and 11%
		}
		
		/*
		ImageFilter filter = new GrayFilter(true, 0);
		ImageProducer producer = new FilteredImageSource(
				colorImage.getSource(), filter);
		Image mage = new JPanel().createImage(producer);
		*/
		
		BufferedImage image = new BufferedImage(
				cols, rows, BufferedImage.TYPE_INT_ARGB);  
		image.getRaster().setPixels(0, 0, cols, rows, pixels);
		return image;
	}

	/**
	 * This method creates a new buffered image with the given width 
	 * and height. The returned image is of type ARGB.
	 * 
	 * @param width the width of the returned image.
	 * @param height the height of the returned image.
	 * @param c the color to fill the image with.
	 * @return an image with the given proportions.
	 */
	public static BufferedImage getImage(float xpercent, float ypercent, Color c) {
		int width = Math.round(Values.ORIGINAL_RESOLUTION[Values.X] * xpercent);
		int height = Math.round(Values.ORIGINAL_RESOLUTION[Values.Y] * ypercent);
		BufferedImage im = new BufferedImage(
				width, height, BufferedImage.TYPE_INT_ARGB);
		java.awt.Graphics g = im.getGraphics();
		g.setColor(c);
		g.fillRect(0, 0, width, height);
		return im;
	}
	
	/**
	 * This method draws the given text on the given graphics. It draws
	 * the text with the given color with a black frame around the text.
	 * The frame is like a black drop shadow around all the letters.
	 * 
	 * @param g the graphics to draw the text on.
	 * @param text the text to be drawn.
	 * @param x the x position of the text.
	 * @param y the y position of the text.
	 * @param size the size of the text.
	 * @param c the color to draw the text with.
	 */
	// TODO(kalle): Move this to a shader!
	public static void drawStringWithBlackFrame(
			Graphics2D g, String text, int x, int y, int size, Color c, int offset, int font) {
		g.setFont(Values.getFont(font, size));
		g.setColor(Color.BLACK);
		g.drawString(text, x + offset, y);
		g.drawString(text, x - offset, y);
		g.drawString(text, x, y + offset);
		g.drawString(text, x, y - offset);
		g.setColor(c);
		g.drawString(text, x, y);
	}
	
	/*
	public static void drawStringWithBlackFrame(
			Graphics g, String text, int x, int y, int size, Color c, int offset, int font) {
//		g.setFont(Values.BOLD);
		g.setFontSize(size);
		Graphics.setTextColor(Color.black);
//		g.drawString(text, x + offset, y, .8f);
//		g.drawString(text, x - offset, y, .8f);
//		g.drawString(text, x, y + offset, .8f);
//		g.drawString(text, x, y - offset, .8f);
		Graphics.setTextColor(c);
		g.drawString(text, x, y, .8f);
		
//		g.setFont(Values.PLAIN);
	}*/

	/**
	 * This method scales the given image to fit the given width and height.
	 * 
	 * @param im the image to scale.
	 * @param newW the new width of the image.
	 * @param newH the new height of the image.
	 * @return a scaled version of the given image.
	 */
	public static BufferedImage scaleImage(Image im, int newW, int newH) {
		BufferedImage image = new BufferedImage(newW, newH, BufferedImage.TYPE_4BYTE_ABGR);
		Graphics2D g = (Graphics2D) image.getGraphics();
		g.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
				RenderingHints.VALUE_INTERPOLATION_BICUBIC);
		g.drawImage(im, 0, 0, newW, newH, null);
		return image;
	}

	/**
	 * This method scales the given image with the given scale.
	 * 
	 * @param image the image to scale.
	 * @param scale the value to scale with.
	 * @return a scaled version of the given image.
	 */
	public static BufferedImage scaleImage(Image image, float scale) {
		return scaleImage(image, 
				Math.round(image.getWidth(null) * scale), 
				Math.round(image.getHeight(null) * scale)); 
	}
}
