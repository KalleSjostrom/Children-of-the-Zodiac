package battleBacks;

/**
 * This class represents a particle used in the magic particle system.
 * A magic particle system is used in the game when a character uses
 * a magic, like fire, ice and so on.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SnowParticle extends BattleParticle {
	
	private static final float[] color = new float[]{1, 1, 1, 1};
	private static final float[] size = new float[]{.1f, .1f};

	protected float[] getSize() {
		return size;
	}

	protected float[] getColor() {
		return color;
	}
	
	protected boolean shouldResurrect() {
		return pos.y < -4.2f;
	}

	protected float getInitialHeight() {
		return rand.nextFloat() * 14 - 7;
	}
}
