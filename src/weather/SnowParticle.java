package weather;

/**
 * This class represents a particle used in the magic particle system.
 * A magic particle system is used in the game when a character uses
 * a magic, like fire, ice and so on.
 * 
 * @author		Kalle Sjšstršm
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SnowParticle extends WeatherParticle {
	
	private static final float[] color = new float[]{1, 1, 1, 1};
	private static final float[] size = new float[]{.075f, .075f};

	protected float[] getSize() {
		return size;
	}

	protected float[] getColor() {
		return color;
	}
	
//	protected int[] getWorldSize() {
//		return new int[]{11 * 4, 8, 13 * 4, 0};
//	}

	protected boolean shouldResurrect() {
		return pos[1] < -2.2f;
	}

	protected float getInitialHeight() {
		return rand.nextFloat() * 6 - 2f;
	}
}
