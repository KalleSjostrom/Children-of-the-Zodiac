/*
 * Classname: OggStreamer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/06/2008
 */
package sound;

import info.Values;

import java.net.URL;
import java.util.HashMap;

import java.util.logging.*;

import organizer.ResourceLoader;

/**
 * This class streams ogg-files. It is the main sound player in the game
 * and plays all the background music.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 22 June 2008
 */
public class OggStreamer {

	private static final ALWrapper al = ALWrapper.getALWrapper();
	private static final int NUM_BUFFERS = 2;
	private static final int BUFFER_SIZE = 65536;
	private static HashMap<String, FadeThread> fadeThreads = new HashMap<String, FadeThread>();
	
	private URL[] url;
	private OggDecoder oggDecoder;
	private int rate;
	private int sleepTime;
	private int[] buffers = new int[NUM_BUFFERS];
	private float incTime;
	private float volume = Values.MAX_VOLUME;
	private boolean fadeOut = false;
	private boolean fadeIn = false;
	private boolean updating = true;
	private boolean mute = false;
	private int source;
	private String name;
	private static Logger logger = Logger.getLogger("OggStreamer");

	/**
	 * Creates a new streamer which streams the files with the given name.
	 * 
	 * @param name the name of the files to stream.
	 */
	public OggStreamer(String name) {
		this.name = name;
		url = getURL(name);
		source = ALWrapper.getNextFreeSource();
		logger.log(Level.FINE, "Creating ogg streamer " + name + " " + source);
	}

	/**
	 * This method opens, play back and sets the volume of the music.
	 * If the given value is true it fades in the music, if not, the
	 * volume is set to max.
	 * 
	 * @param fadeIn true if the music should fade in.
	 */
	public void play(boolean fadeIn, boolean play) {
		open();
		playback(play && !mute);
		if (fadeIn && !mute) {
			fade(SoundValues.FADE_IN, 2500, SoundValues.ALL_THE_WAY, SoundValues.NORMAL);
		} else {
			setVolume(volume);
		}
		loopUpdate();
	}
	
	/**
	 * Opens and initializes the decoder, generates buffers and sources and
	 * sets the default volume.
	 */
	private void open() {
		oggDecoder = new OggDecoder(url);
		rate = oggDecoder.getSampleRate();
		
		sleepTime = 25 * BUFFER_SIZE / rate;
		
		al.generateBuffers(NUM_BUFFERS, buffers);
		al.initiateVolume(source);
	}

	/**
	 * Starts streaming all the buffers and plays the source. This method fills
	 * all the buffers with data from the ogg decoder. It then queues all these
	 * buffers on the current source and starts playing the source.
	 */
	public void playback(boolean begin) {
		for (int i = 0; i < NUM_BUFFERS; i++) {
			stream(buffers[i]);
		}
		al.queueBuffers(source, NUM_BUFFERS, buffers);
		if (begin) {
			al.play(source);
		} else {
			al.play(source);
			al.pause(source);
		}
	}

	/**
	 * Loops while updating is true and updates the stream.
	 * (calls update()).
	 */
	private void loopUpdate() {
		while (updating) {
			if (!al.isPaused(source)) {
				update();
				if (!al.isPlaying(source) && !al.isPaused(source)) {
					System.out.println("Source no longer playing... " + name + " " + al.isPaused(source));
					break;
				}
				// System.out.println("Sleep " + sleepTime);
				Values.sleep(sleepTime);// * 8); //(*9)??
			} else {
				Values.sleep(100);
			}
		}
		if (updating && !al.isPlaying(source) && !al.isPaused(source)) {
			System.out.println("Trying to play... " + name);
			al.play(source);
			loopUpdate();
		}
	}

	/**
	 * Updates the stream. Dequeues finished AL buffers, fills these played 
	 * buffers with new data and queues them again. 
	 */
	private void update() {
		int processed = al.getNumberOfProcessedBuffers(source);
		if (processed == -1) {
			logger.log(Level.FINE, 
					"Updating: " + updating + " this: " + 
					this.hashCode() + " url " + url[0].getFile());
		}
		while (processed > 0 && updating) {
			int[] buffer = al.dequeueBuffers(source);
			stream(buffer[0]);
			al.queueBuffers(source, buffer);
			processed--;
		}
	}

	/**
	 * This method reads a buffer from the decoder, wraps the data
	 * in a byte buffer and stores it via .alBufferData().
	 * 
	 * @param buffer the integer used to access the buffer in AL.
	 */
	private void stream(int buffer) {
		byte[] pcm = new byte[BUFFER_SIZE];
		int size = oggDecoder.read(pcm);
		al.bufferData(source, buffer, pcm, size, rate);
	}

	/**
	 * Sets the volume of the music streamed from this player.
	 * The volume is a floating point value ranging from 0 to 1.
	 * The value times 100 can be seen as percent of the volume.
	 * Everything below zero will be used as zero and everything
	 * above one will be used as one.
	 * 
	 * @param newVolume the value of the new volume.
	 */
	public void setVolume(float newVolume) {
		volume = newVolume;
		al.setVolume(source, volume);
	}
	
	/**
	 * Sets the initial volume of this stream.
	 * 
	 * @param volume the volume to set.
	 */
	public void setInitVolume(float volume) {
		if (volume == 0) {
			mute = true;
			fadeIn = fadeOut = false;
		} else {
			this.volume = volume;
		}
	}
	
	public void mute() {
		mute = true;
		fadeIn = fadeOut = false;
		volume = 0;
		if (al.isPlaying(source)) {
			setVolume(volume);
		}
	}
	
	/**
	 * This method fades the music up or down depending on the given values.
	 * 
	 * @param mode either Hints.FADE_IN or Hints.FADE_OUT.
	 * @param time the time, in milliseconds, in which to fade in or out. 
	 * @param volumeTarget representing the target volume. When 
	 * reached, stop fading.
	 * @param playMode which mode to play the music. This could be either to
	 * resume the music before fading 
	 */
	// 232875139
//	
//	1 to load the image res/Village/No Place/No Place.png
//	Initiate music: Previous game mode: battle.BossBattleArea@7a74db2c
//	Initiate music: New music: Menthu's Theme
//	Initiate music: Previous game mode music: Menthu's Theme
//	This game mode 963998519 villages.Village
//	Previous game mode 2054478636 battle.BossBattleArea
//	Previous ogg 232875139
//	This ogg 232875139
//	Initiate music: Previous game mode: villages.Village@39757337
//	Initiate music: New music: continue
//	Initiate music: Previous game mode music: Menthu's Theme
//	This game mode 1961425093 villages.villageStory.VillageStory
//	Previous game mode 963998519 villages.Village
//	Previous ogg 232875139
//	This ogg 232875139
	
	public void fade(final int mode, int time, 
			final float volumeTarget, final int playMode) {
		logger.log(Level.FINE, "\nFading for " + name + " " + volumeTarget + " " + volume);
		if (volumeTarget != volume) {
			final String name = url[0] == null ? "No Music" : url[0].getFile();
			FadeThread t = fadeThreads.get(name);	
			if (t != null && t.isAlive()) {
				t.abortFade();
				while (t.isAlive()) {Values.sleep(100);}
			}
			FadeThread ft = new FadeThread(name, volumeTarget, playMode, this);
			fadeThreads.put(name, ft);
			fadeOut = !(fadeIn = mode == SoundValues.FADE_IN);
			setTime(time);
			al.print();
			ft.start();
		} else {
			checkResume(playMode);
			checkPause(playMode);
			checkExit(playMode);
		}
	}
	
	/**
	 * Sets the fade time. The time it should take to fade in or out.
	 * 
	 * @param time the time in milliseconds it should take to fade in or out.
	 */
	private void setTime(int time) {
		incTime = time == 0 ? 0 : 50f / (time * 0.9f);
	}
	
	private void incrementVolume(float fadeTarget) {
		if (incTime == 0) {
			volume = fadeIn ? fadeTarget : 0;
		} else {
			int value = fadeIn ? 1 : -1;
			volume += value * (incTime * (1 + (volume * 2)));
		}
	}

	/**
	 * Checks if the given mode is resume and if so, resumes the music.
	 * It checks against Hints.RESUME.
	 * 
	 * @param mode the mode to check.
	 */
	private void checkResume(int mode) {
		if (!al.isPlaying(source) && mode == SoundValues.RESUME_PLAY) {
			logger.log(Level.FINE, "Play " + System.currentTimeMillis());
			al.setVolume(source, volume);
			al.play(source);
		}
	}

	/**
	 * Checks if the given mode is pause and if so, pauses the music.
	 * It checks against Hints.PAUSE.
	 * 
	 * @param mode the mode to check.
	 */
	private void checkPause(int mode) {
		if (!al.isPaused(source) && mode == SoundValues.PAUSE) {
			al.setVolume(source, volume);
			al.pause(source);
		}
	}
	
	private void checkExit(int mode) {
		if (mode == SoundValues.KILL_MUSIC_ON_FADE_DOWN) {
			exit();
		}
	}

	/**
	 * Checks if the given mode is fade in or fade out and in either case
	 * checks if the fade should be ended, if it has reached the full
	 * fade length as given by fadeLength. The fadeLength is a value 
	 * between zero and one which represents the percent of the volume
	 * to uses as maximum when fading in and minimum when fading out.
	 * If the OggStreamer is fading in it will stop fading when the volume
	 * of the music is higher or equal to this value. 
	 * 
	 * @param fadeLength the value to fade before stopping.
	 * @return true if it is done fading.
	 */
	private boolean checkFadeMode(float fadeLength) {
		boolean doneFading = false;
		if (fadeIn) {			
			doneFading = volume >= fadeLength;
		} else if (fadeOut) {
			doneFading = volume <= fadeLength;
		}
		return doneFading;
	}
	

	/**
	 * This method stops playing the source, and stops updating
	 * the buffers. This method must be called when exiting a game
	 * mode otherwise the thread will run forever.
	 */
	public void exit() {
		al.exit(source, buffers);
		updating = false;
	}

	/**
	 * Checks if this stream is fading in or out.
	 * 
	 * @return true if this stream is fading.
	 */
	public boolean isFading() {
		return fadeOut || fadeIn;
	}
	
	/**
	 * Checks if the stream is fading out.
	 * 
	 * @return true if the stream is fading out.
	 */
	public boolean isFadingDown() {
		return fadeOut;
	}

	/**
	 * Gets the URLs to the music with the given name. The returned array
	 * contains two URLs where the first is the "intro" part of the music while
	 * the second is the "loop" part. If the second music file is not found, 
	 * the same URL is used as the "intro" part as well as the "loop" part.
	 * 
	 * @param songName the name of the song to load.
	 * @return the URLs containing the locations of the songs.
	 */
	public URL[] getURL(String songName) {
		ResourceLoader r = ResourceLoader.getResourceLoader(); 
		final URL[] url = new URL[2];
		if (exists(songName + "1.ogg")) {
			url[0] = r.getURL(Values.Music + songName + "1.ogg");
		} else {
			logger.info("The song " + 
					(songName + "1.ogg") + " does not exist");
		}
		if (exists(songName + "2.ogg")) {
			url[1] = r.getURL(Values.Music + songName + "2.ogg");
		} else {
			url[1] = url[0];
		}
		return url;
	}
	
	/**
	 * Checks if the file with the given name exists.
	 * 
	 * @param fileName the name of the file to check.
	 * @return true if the file exists.
	 */
	private static boolean exists(String fileName) {
		return ResourceLoader.getResourceLoader().exists(Values.Music + fileName);
	}

	/**
	 * Checks if the URLs to the files that his stream should play is valid.
	 * That they do, in fact, exist.
	 * 
	 * @return true if the songs to be played exists.
	 */
	public boolean isURLValid() {
		return url[0] != null;
	}
	
	private class FadeThread extends Thread {
		
		private float volumeTarget;
		private int playMode;
		private boolean abortFade = false;
		private String n;
		private OggStreamer oggTemp;
		
		public FadeThread(String name, float volumeTarget, int mode, OggStreamer oggStreamer) {
			super.setName(name);
			n = name;
			oggTemp = oggStreamer;
			this.volumeTarget = volumeTarget;
			playMode = mode;
		}
		
		public void abortFade() {
			abortFade = true;	
		}
		
		public void run() {
			checkResume(playMode);
			while (!checkFadeMode(volumeTarget) && !abortFade && isFading()) {
				incrementVolume(volumeTarget);
				al.setVolume(source, volume);
				logger.log(Level.FINE, "Fading " + name + " " + n + " " + " " + oggTemp.hashCode() + " " + volume + " is fading: " + isFading() + " abort " + abortFade);
				Values.sleep(100);
			}
			checkPause(playMode);
			checkExit(playMode);
			fadeOut = fadeIn = false;
		}
	}

	public String getName() {
		return name;
	}
}