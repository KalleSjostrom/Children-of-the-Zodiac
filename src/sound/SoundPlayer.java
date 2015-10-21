/*
 * Classname: SoundPlayer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 03/10/2008
 */
package sound;

import info.SoundMap;
import info.Values;

import java.util.HashMap;
import java.util.Random;

/**
 * This player plays sound effects in the game. These effects are small
 * *.ogg files containing attack sounds, magic sounds and so on.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 03 Oct 2008
 */
public class SoundPlayer {
	private static HashMap<String, Sound> sounds = new HashMap<String, Sound>();
	private static HashMap<String, Float> volumes;
	private static boolean enabled = false; // Values.soundEnabled();
	public static final float MAX_VOLUME = 1f;
	
	static {
		volumes = new HashMap<String, Float>();
		volumes.put(SoundMap.MAGICS_BLIZZARD, .7f);
//		volumes.put(SoundMap.MAGICS_ICE, .7f);
	}

	/**
	 * This method plays the sound with the given name. The sound is
	 * gotten from a hashMap containing all the sounds that has been
	 * played in the game. If the sound with the given name does not
	 * exist in this map, the sound is loaded and stored in the map.
	 * 
	 * @param name the name of the sound to play.
	 */
	public static synchronized void playSound(final String name) {
		if (name == null || name.equals("")) {
			return;
		}
		if (enabled) {
			new Thread() {
				public void run() {
					Sound sound = getSound(name);
					
					boolean isPlaying = sound.isPlaying();
					if (isPlaying) {
						sound = addSound(name);
					}
					Float volume = volumes.get(name);
					if (volume == null) {
						volume = MAX_VOLUME;
					}
					sound.setVolumeValue(volume);
					sound.play();
					if (isPlaying) {
						while (sound.isPlaying()) {
							Values.sleep(100);
						}
						sound.killALData();
					}
				}
			}.start();
		}
	}

	/**
	 * This method plays the sound with the given name. The sound is
	 * gotten from a hashMap containing all the sounds that has been
	 * played in the game. If the sound with the given name does not
	 * exist in this map, the sound is loaded and stored in the map.
	 * This method plays the sound with the given name, plus a random 
	 * number between one and nr plus .wav.
	 * 
	 * @param name the name of the sound to play.
	 * @param nr the highest number to randomize between.
	 */
	public static void playSoundWithRandom(String name, int nr) {
		int ra = new Random().nextInt(nr) + 1;
		playSound(name + ra + ".wav");
	}
	
	/**
	 * Gets the source sound with the given name. The sound is
	 * gotten from a hashMap containing all the sounds that has been
	 * played in the game. If the sound with the given name does not
	 * exist in this map, the sound is loaded and stored in the map.
	 * 
	 * @param name the name of the sound source to get.
	 * @return the source of the sound with the given name.
	 */
	private static Sound getSound(String name) {
		Sound sound = sounds.get(name);
		if (sound == null) {
			sound = addSound(name);
			sounds.put(name, sound);
		}
		return sound;
	}

	/**
	 * Adds the sound source with the given name to the map.  
	 * 
	 * @param name the name of the sound source to load.
	 * @return the source of the sound file that has been loaded.
	 */
	private static Sound addSound(final String name) {
		return new Sound(Values.SoundEffects + name);
	}
//	
//	public static void main(String[] args) {
//		Values.initAL();
//		SoundPlayer.enabled = true;
//		for (int i = 0; i < 20; i++) {
//			SoundPlayer.playSound(SoundMap.MAGICS_FIRE);
//			Values.sleep(500);
//		}
//		Values.sleep(3000);
//	}
}
