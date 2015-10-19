/*
 * Classname: OggStreamer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/06/2008
 */
package sound;

import java.io.InputStream;
import java.net.URL;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.util.concurrent.Semaphore;

import java.util.logging.*;

import com.jogamp.openal.AL;
import com.jogamp.openal.ALConstants;
import com.jogamp.openal.ALException;
import com.jogamp.openal.ALFactory;
import com.jogamp.openal.util.ALut;

import organizer.ResourceLoader;

/**
 * This class streams ogg-files. It is the main sound player in the game
 * and plays all the background music.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 22 June 2008
 */
public class Sound {

	private static AL al = ALFactory.getAL(); //Values.al;
	private int[] buffer = new int[1];
	private int[] source = new int[1];
	private float volume = SoundPlayer.MAX_VOLUME;
	private String filename;
	private float[] sourcePos = {0.0f, 0.0f, 0.0f};
	private float[] sourceVel = {0.0f, 0.0f, 0.0f};
	private float[] listenerPos = {0.0f, 0.0f, 0.1f};
	private float[] listenerVel = {0.0f, 0.0f, 0.0f};
	private float[] listenerOri = {0.0f, 0.0f, -1.0f, 0.0f, 1.0f, 0.0f};
	private boolean initiated = false;
	private Semaphore audioAccess = new Semaphore(1);
	private static Logger logger = Logger.getLogger("Sound");

	/**
	 * Creates a new streamer which streams the files with the given name.
	 * 
	 * @param name the name of the files to stream.
	 */
	public Sound(String name) {
		filename = name;
	}
	
	public void init() {
		loadALData();
		setListenerValues();
	}
	
	public void play() {
		try {
			audioAccess.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		if (!initiated) {
			init();
			initiated = true;
		}
		al.alSourcePlay(source[0]);
		setVolume(volume);
		audioAccess.release();
	}
	
	private int loadALData() {
		int[] format = new int[1];
		int[] size = new int[1];
		ByteBuffer[] data = new ByteBuffer[1];
		int[] freq = new int[1];
		int[] loop = new int[1];

		check();
		al.alGenBuffers(1, IntBuffer.wrap(buffer));
		if (al.alGetError() != AL.AL_NO_ERROR) {
			return AL.AL_FALSE;
		}
	
    	InputStream is = ResourceLoader.getResourceLoader().getFileInputStream(filename);

		try {
			ALut.alutLoadWAVFile(is,
							format, data, size, freq, loop);
		} catch (ALException e) {
			e.printStackTrace();
		}
		al.alBufferData(buffer[0], format[0], data[0], size[0], freq[0]);
		al.alGenSources(1, source, 0);

		if (al.alGetError() != AL.AL_NO_ERROR)
			return AL.AL_FALSE;

		al.alSourcei (source[0], AL.AL_BUFFER,   buffer[0]   );
		al.alSourcef (source[0], AL.AL_PITCH,    1.0f     );
		al.alSourcef (source[0], AL.AL_GAIN,     1.0f     );
		al.alSourcefv(source[0], AL.AL_POSITION, FloatBuffer.wrap(sourcePos));
		al.alSourcefv(source[0], AL.AL_VELOCITY, FloatBuffer.wrap(sourceVel));
		al.alSourcei (source[0], AL.AL_LOOPING,  loop[0]     );
		// Do another error check and return.
		if(al.alGetError() == AL.AL_NO_ERROR)
			return AL.AL_TRUE;

		return AL.AL_FALSE;
	}
	private void setListenerValues() {
		al.alListenerfv(AL.AL_POSITION,	FloatBuffer.wrap(listenerPos));
		al.alListenerfv(AL.AL_VELOCITY,    FloatBuffer.wrap(listenerVel));
		al.alListenerfv(AL.AL_ORIENTATION, FloatBuffer.wrap(listenerOri));
	}
	
	protected void killALData() {
		try {
			audioAccess.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		al.alDeleteSources(1, source, 0);
		al.alDeleteBuffers(1, buffer, 0);
		audioAccess.release();
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
		al.alSourcef(source[0], ALConstants.AL_GAIN, volume);
		check();
	}
	
	public void setVolumeValue(float newVolume) {
		volume = newVolume;
	}
	
	/**
	 * This method checks if and error has occurred in openAL.
	 * If so it just prints "OpenAL error".
	 */
	private void check() {
		int e = al.alGetError();
		if (e != ALConstants.AL_NO_ERROR) {
			new IndexOutOfBoundsException("Sound " + this.hashCode()).printStackTrace();
			logger.log(Level.SEVERE, "Sound: OpenAL error: " + ALWrapper.getALErrorString(e));
		}
	}

	/**
	 * This method stops playing the source, and stops updating
	 * the buffers. This method must be called when exiting a game
	 * mode otherwise the thread will run forever.
	 */
	public void stop() {
		al.alSourceStop(source[0]);
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
	public URL getURL(String songName) {
		ResourceLoader r = ResourceLoader.getResourceLoader();
		return r.getURL(songName);
	}

	public boolean isPlaying() {
		if (initiated) {
			return checkState(ALConstants.AL_PLAYING);
		} else {
			return false;
		}
	}
	
	private boolean checkState(int state) {
		int[] stat = new int[1];
		al.alGetSourcei(source[0], ALConstants.AL_SOURCE_STATE, stat, 0);
		return stat[0] == state;
	}
}