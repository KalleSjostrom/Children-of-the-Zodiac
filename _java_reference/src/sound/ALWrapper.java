package sound;

import java.nio.ByteBuffer;
import java.util.concurrent.Semaphore;

import java.util.logging.*;

import com.jogamp.openal.AL;
import com.jogamp.openal.ALConstants;
import info.Values;

public class ALWrapper {

	private static final int FORMAT = ALConstants.AL_FORMAT_STEREO16;
	private static int[] sources = new int[8];
	private static boolean[] usedSources = new boolean[8];
	private static AL al = Values.al;
	private static ALWrapper alWrapper = new ALWrapper();
	private static Logger logger = Logger.getLogger("ALWrapper");
	private Semaphore audioAccess = new Semaphore(1);

	static {
		al.alGenSources(sources.length, sources, 0);
		check("Generating sources");
	}

	private ALWrapper() {
		// 
	}

	protected static ALWrapper getALWrapper() {
		return alWrapper;
	}

	protected static int getNextFreeSource() {
		int[] stat = new int[1];
		for (int i = 0; i < sources.length; i++) {
			al.alGetSourcei(sources[i], ALConstants.AL_SOURCE_STATE, stat, 0);
			check("getNextFreeSource");
			if (!usedSources[i] && (stat[0] == ALConstants.AL_INITIAL || stat[0] == ALConstants.AL_STOPPED)) {
				usedSources[i] = true;
				logger.log(Level.FINE, "Taking " + i + " " + stat[0] + " " + ALConstants.AL_INITIAL + " " + ALConstants.AL_STOPPED);
				return i;
			}
		}
		return -1;
	}

	public boolean isPlaying(int source) {
		return checkState(ALConstants.AL_PLAYING, source);
	}

	public boolean isPaused(int source) {
		return checkState(ALConstants.AL_PAUSED, source);
	}

	public void setVolume(int source, float volume) {
		aquire();
		if (usedSources[source]) {
			al.alSourcef(sources[source], ALConstants.AL_GAIN, volume);
		} else {
			logger.log(Level.FINE,
					"The source " + sources[source] + " (" + source + ") is not used, cannot set volume.");
		}
		audioAccess.release();
	}
	
	private void aquire() {
		try {
			audioAccess.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Gets the state of the source and compares that state
	 * to the given one.
	 * 
	 * @param state the state to check the source state against.
	 * @return true if the state of the source matches the given state. 
	 */
	private boolean checkState(int state, int source) {
		int[] stat = new int[1];
		al.alGetSourcei(sources[source], ALConstants.AL_SOURCE_STATE, stat, 0);
		return stat[0] == state;
	}

	/**
	 * This method checks if and error has occurred in openAL.
	 * If so it just prints "OpenAL error".
	 */
	private static void check(String error) {
		int e = al.alGetError();
		if (e != ALConstants.AL_NO_ERROR) {
			logger.log(Level.SEVERE, "OggStreamer: OpenAL error: " + error);
		}
	}

	protected static String getALErrorString(int err) {
		String error = null;
		switch(err) {
		case ALConstants.AL_NO_ERROR:
			error = "AL_NO_ERROR";
			break;

		case ALConstants.AL_INVALID_NAME:
			error = "AL_INVALID_NAME";
			break;

		case ALConstants.AL_INVALID_ENUM:
			error = "AL_INVALID_ENUM";
			break;

		case ALConstants.AL_INVALID_VALUE:
			error = "AL_INVALID_VALUE";
			break;

		case ALConstants.AL_INVALID_OPERATION:
			error = "AL_INVALID_OPERATION";
			break;

		case ALConstants.AL_OUT_OF_MEMORY:
			error = "AL_OUT_OF_MEMORY";
			break;
		}
		return error;
	}

	public void generateBuffers(int numBuffers, int[] buffers) {
		al.alGenBuffers(numBuffers, buffers, 0);
		check("Generate buffers");		
	}

	public void initiateVolume(int source) {
		aquire();
		if (usedSources[source]) {
			al.alSourcef(sources[source], ALConstants.AL_PITCH, 1.0f);
			check("initiateVolume (PITCH)");
			al.alSourcef(sources[source], ALConstants.AL_GAIN, 0);
			check("initiateVolume (GAIN)");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, cannot initiate volume.");
		}
		audioAccess.release();
	}

	public void queueBuffers(int source, int numBuffers, int[] buffers) {
		aquire();
		if (usedSources[source]) {
			al.alSourceQueueBuffers(sources[source], numBuffers, buffers, 0);
			check("queueBuffers1");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, no buffers queued (1).");
		}
		audioAccess.release();
	}

	public void queueBuffers(int source, int[] buffer) {
		aquire();
		if (usedSources[source]) {
			al.alSourceQueueBuffers(sources[source], 1, buffer, 0);
			check("queueBuffers2");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, no buffers queued (2).");
		}
		audioAccess.release();
	}

	public void play(int source) {
		aquire();
		if (usedSources[source]) {
			al.alSourcePlay(sources[source]);
			check("play");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, cannot play.");
		}
		audioAccess.release();
	}

	public void pause(int source) {
		aquire();
		if (usedSources[source]) {
			al.alSourcePause(sources[source]);
			check("pause");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, cannot pause.");
		}
		audioAccess.release();
	}

	public int getNumberOfProcessedBuffers(int source) {
		aquire();
		int[] processed = new int[1];
		if (usedSources[source]) {
			al.alGetSourcei(sources[source], ALConstants.AL_BUFFERS_PROCESSED, processed, 0); 
			check("getNumberOfProcessedBuffers");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, 0 buffers processed.");
			processed[0] = -1;
		}
		audioAccess.release();
		return processed[0];
	}

	public int[] dequeueBuffers(int source) {
		aquire();
		int[] buffer = new int[1];
		if (usedSources[source]) {
			al.alSourceUnqueueBuffers(sources[source], 1, buffer, 0); 
			check("unqueueBuffers");
		} else {
			logger.log(Level.FINE, "The source " + sources[source] + " is not used, no buffers unqueued.");
		}
		audioAccess.release();
		return buffer;
	}

	public void bufferData(int source, int buffer, byte[] pcm, int size, int rate) {
		aquire();
		if (usedSources[source]) {
			ByteBuffer data = ByteBuffer.wrap(pcm, 0, size);
			if (al.alIsBuffer(buffer)) {
				checkSource(source);
				al.alBufferData(buffer, FORMAT, data, size, rate);
				check("bufferData");
			} else {
				logger.log(Level.FINE, "The buffer: " + buffer + " is no buffer!");
			}
		}
		audioAccess.release();
	}
	
	private void checkSource(int source) {
		if (!al.alIsSource(sources[source])) {
			int[] stat = new int[1];
			al.alGetSourcei(sources[source], ALConstants.AL_SOURCE_STATE, stat, 0);
			logger.log(Level.FINE, "\tThe source: " + sources[source] + " is not a source!");
			logger.log(Level.FINE, "\tThe source: " + sources[source] + " has state: " + stat[0]);
		} else {
			int[] stat = new int[1];
			al.alGetSourcei(sources[source], ALConstants.AL_SOURCE_STATE, stat, 0);
			int[] processed = new int[1];
			al.alGetSourcei(sources[source], ALConstants.AL_BUFFERS_PROCESSED, processed, 0); 
		}
	}

	public void exit(int source, int[] buffers) {
		aquire();
//		new IllegalAccessException(Thread.currentThread().getName() + " - Source " + source + " - " + sources[source]).printStackTrace();
		if (al.alIsSource(sources[source])) {
			logger.log(Level.FINE, "Stop source: " + source);
			al.alSourceStop(sources[source]);
			check("exit: isSource");
		} else {
			logger.log(Level.FINE, "Is not a source1");
		}
		if (al.alIsSource(sources[source])) {
			logger.log(Level.FINE, "Setting none as buffer source: " + source);
			al.alSourcei(sources[source], ALConstants.AL_BUFFER, ALConstants.AL_NONE);
			check("Setting none as buffer source.");
		} else {
			logger.log(Level.FINE, "Is not a source2");
		}
		if (al.alIsBuffer(buffers[0])) {
			logger.log(Level.FINE, "Deleting buffer " + buffers[0]);
			al.alDeleteBuffers(1, buffers, 0);
			check("Deleting buffer 0");
		} else {
			logger.log(Level.FINE, buffers[0] + " is not a buffer");
		}
		if (al.alIsBuffer(buffers[1])) {
			logger.log(Level.FINE, "Deleting buffer " + buffers[1]);
			al.alDeleteBuffers(1, buffers, 1);
			check("Deleting buffer 1");
		} else {
			logger.log(Level.FINE, buffers[1] + " is not a buffer");
		}
		usedSources[source] = false;
		audioAccess.release();
	}

	public void print() {
		logger.log(Level.FINE, "Used sources");
		for (int i = 0; i < sources.length; i++) {
			if (usedSources[i]) {
				logger.log(Level.FINE, sources[i] + "");
			}
		}
	}
}
