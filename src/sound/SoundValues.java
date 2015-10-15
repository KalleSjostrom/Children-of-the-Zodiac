/*
 * Classname: SoundValues.java
 * 
 * Version information: 0.7.0
 * 
 * Date: 24/09/2008
 */
package sound;

import info.Values;

/**
 * This class contains some values that is used to manages the music
 * in the game. These values can be used to manages the music player.
 * This can be done by the method setMusicMode() in GameMode class.
 * 
 * @author		Kalle Sjšstršm
 * @version 	0.7.0  - 24 Sep 2008
 */
public class SoundValues {

    public static final int FAST = 1500;
    public static final int SLOW = 2500;
    
    public static final int FADE_OUT = -1;
    public static final int FADE_IN = 1;
    public static final float ALL_THE_WAY = Values.MAX_VOLUME;
    public static final float HALF = .6f * Values.MAX_VOLUME;
    
    public static final int NORMAL = -1;
    public static final int RESUME_PLAY = 0;
    public static final int PAUSE = 1;
	public static final int KILL_MUSIC_ON_FADE_DOWN = 2;
	
	public static float allTheWay(int fade) {
		float fadelength = ALL_THE_WAY;
		if (fade == FADE_OUT) {
			fadelength = ALL_THE_WAY - fadelength;
		}
		return fadelength;
	}
}
