/*
 * Classname: ParticleValues.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package particleSystem;


/**
 * This class contains some values used by particles and the systems.
 * 
 * @author		Kalle Sjšstršm
 * @version 	0.7.0 - 01 Oct 2008
 */
public class ParticleValues {
	
	public static final int DESTROY_ONCE = 0;
	public static final int DESTROY_MULTIPLE_TIMES = 1;
	public static final int PLAIN_DESTROY = 2;
	
	/**
	 * The plain gray color used for neutral elements.
	 */
	public static final float[] PLAIN_GRAY = new float[]{.2f, .2f, .2f};
	
	/**
	 * The red fire color used when attacking with fire elements.
	 */
    public static final float[] FIRE_RED = new float[]{1, .2f, 0};
    public static final float[] DARK_RED = new float[]{.5f, .02f, 0};
    
	/**
	 * The blue ice color used when attacking with ice elements.
	 */
    public static final float[] ICE_BLUE = new float[]{.3f, .3f, .9f};
    
	/**
	 * The green wind color used when attacking with wind elements.
	 */
    public static final float[] WIND_GREEN = new float[]{.1f, .3f, .1f};
    
	/**
	 * The brown earth color used when attacking with earth elements.
	 */
//    public static final float[] EARTH_BROWN = new float[]{.15f, .09f, 0};
    public static final float[] EARTH_BROWN = new float[]{.3f, .18f, .1f};
    public static final float[] WHITE = new float[]{1, 1, 1, 1};
    public static final float[] BLACK = new float[]{.3f, 0, .3f, 0};
//    public static final float[] BLACK = new float[]{.1f, .1f, .1f, 0};
    public static final float[] PURPLE = new float[]{.15f, 0, .15f, 0};
    public static final float[] YELLOW = new float[]{1, 1, 0};
    
    private static final float[][] COLORS = new float[][]{
    	PLAIN_GRAY, FIRE_RED, ICE_BLUE, WIND_GREEN, EARTH_BROWN, WHITE, BLACK, DARK_RED, PURPLE, YELLOW};
    
    public static final int COLOR_GRAY = 0;
    public static final int COLOR_RED = 1;
    public static final int COLOR_BLUE = 2;
    public static final int COLOR_GREEN = 3;
    public static final int COLOR_BROWN = 4;
    public static final int COLOR_WHITE = 5;
    public static final int COLOR_BLACK = 6;
    public static final int COLOR_DARK_RED = 7;
    public static final int COLOR_PURPLE = 8;
    public static final int COLOR_YELLOW = 9;
    public static final int COLOR_RANDOM = 10;

    /**
     * Gets a copy of the color of the given type. Use the elements of
     * a card as argument for this method. If a card is fire, then a red 
     * color is gotten.
     * 
     * @param color the color to get.
     * @return a copy of the chosen color.
     */
    protected static float[] getColor(int color) {
    	float[] copy;
    	if (color == COLOR_RANDOM) {
    		copy = new float[]{(float) Math.random(), (float) Math.random(), (float) Math.random()};
    	} else {
    		float[] original = COLORS[color];
    		copy = new float[original.length];
    		for (int i = 0; i < original.length; i++) {
    			copy[i] = original[i];
    		}
    	}
    	return copy;
    }
}
