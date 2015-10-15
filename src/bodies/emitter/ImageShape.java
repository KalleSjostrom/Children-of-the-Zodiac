package bodies.emitter;

import graphics.GraphicHelp;
import info.Values;

import java.awt.image.BufferedImage;

import organizer.ResourceLoader;

import settings.ShapeSettings;
import bodies.Vector3f;

public class ImageShape extends EmitterShape {

	private int height;
	private int width;
	private int[][] pixels;
	private boolean flipY;
	private boolean flipX;

	protected ImageShape(ShapeSettings settings) {
		super(settings);
		flipY = settings.getBoolean(ShapeSettings.FLIP_VERTICALLY);
		flipX = settings.getBoolean(ShapeSettings.FLIP_HORIZONTALLY);
		float scalex = settings.getValue(ShapeSettings.SCALE_X);
		float scaley = settings.getValue(ShapeSettings.SCALE_Y);
		scalex = scalex == 0 ? 1 : scalex;
		scaley = scaley == 0 ? 1 : scaley;
		String imageName = settings.getString(ShapeSettings.IMAGE);
		BufferedImage image = ResourceLoader.getResourceLoader().getBufferedImage(
					Values.ParticleSystemsImages + imageName + ".png");
		float w = image.getWidth();
		float h = image.getHeight();

		w *= scalex;
		h *= scaley;
		
		width = Math.round(w);
		height = Math.round(h);
		image = GraphicHelp.scaleImage(image, width, height);
		pixels = new int[height][width];

		for (int i = 0; i < height; i++) {
			image.getAlphaRaster().getPixels(0, i, width, 1, pixels[i]);
		}
	}

	@Override
	protected Vector3f modifyDirection(Vector3f direction) {
		return direction;
	}

	@Override
	public Vector3f getEmittancePos() {
		Vector3f emitPosition = new Vector3f();
		boolean found = false;
		int maxit = 500;
		int i = 0, w = 0, h = 0;
		while (!found || i < maxit) {
			w = (int) Math.round(Math.random() * (width-1));
			h = (int) Math.round(Math.random() * (height-1));
			found = pixels[h][w] >= 100;
			i++;
		}
		if (found) {
			emitPosition.x = (float) (flipX ? width - w : w );
			emitPosition.y = -(float) (flipY ? height - h : h);
			emitPosition.addLocal(getPosition());
		}
		return emitPosition;
	}
}
