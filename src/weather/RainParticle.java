package weather;

/**
 * This class represents a particle used in the magic particle system.
 * A magic particle system is used in the game when a character uses
 * a magic, like fire, ice and so on.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class RainParticle extends WeatherParticle {
	
	private static final float[] color = new float[]{1, 1, 1, 1};
	private static final float[] size = new float[]{.01f, .045f};
	
	protected float[] getSize() {
		return size;
	}

	protected float[] getColor() {
		return color;
	}

	protected boolean shouldResurrect() {
		return pos[1] < -2f;
	}

	protected float getInitialHeight() {
		return (float) (Math.random() * 6 - 2f);
	}
}
