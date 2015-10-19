/*
 * Classname: OggDecoder.java
 * 
 * Version information: 0.7.0
 *
 * Date: 01/10/2008
 */
package sound;

import java.io.IOException;
import java.net.URL;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;

import de.jarnbjo.ogg.LogicalOggStream;
import de.jarnbjo.ogg.OggFormatException;
import de.jarnbjo.vorbis.IdentificationHeader;
import de.jarnbjo.vorbis.VorbisFormatException;
import de.jarnbjo.vorbis.VorbisStream;

/**
 * This class decodes an ogg stream and reads it.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class OggDecoder {

	private VorbisStream[] vStream;
	private LogicalOggStream[] loStream;
	private AudioInputStream[] ais;
	private IdentificationHeader vStreamHdr;
	private AudioFormat audioFormat;
	private URL[] url;
	private int current = 0;

	/**
	 * Creates a new *.ogg decoder and starts decoding the *.ogg files pointed out
	 * by the URLs in the given array.
	 * 
	 * @param url an array containing the URLs of some *.ogg files.
	 */
	public OggDecoder(URL[] url) {
		this.url = url;
		vStream = new VorbisStream[2];
		loStream = new LogicalOggStream[2];
		ais = new AudioInputStream[2];
		init();
	}

	/**
	 * This method creates the streams from the URLs given in the constructor.
	 */
	private void init() {
		try {
			CachedUrlStream os = new CachedUrlStream(url[current]);
			loStream[current] = os.getLogicalStreams().iterator().next();
			vStream[current] = new VorbisStream(loStream[current]);
			vStreamHdr = vStream[current].getIdentificationHeader();

			audioFormat = new AudioFormat(vStreamHdr.getSampleRate(),
					16, vStreamHdr.getChannels(), true, true);

			ais[current] = new AudioInputStream(
					new VorbisInputStream(vStream[current]), audioFormat, -1);
			initNext();
		} catch (OggFormatException e) {
			e.printStackTrace();
		} catch (VorbisFormatException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * This method initiates the next ogg-file that should be streamed.
	 * It always initiates the second ogg file, because this file is the
	 * one that should loop.
	 */
	private void initNext() {
		int tempCurrent = Math.abs(current - 1);
		try {
			URL ur = url[1];
			CachedUrlStream os = new CachedUrlStream(ur);
			loStream[tempCurrent] = os.getLogicalStreams().iterator().next();
			vStream[tempCurrent] = new VorbisStream(loStream[tempCurrent]);
			ais[tempCurrent] = new AudioInputStream(
					new VorbisInputStream(vStream[tempCurrent]), audioFormat, -1);
		} catch (OggFormatException e) {
			e.printStackTrace();
		} catch (VorbisFormatException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * This method gets the sample rate from the stream header.
	 * 
	 * @return the sample rate of the current stream.
	 */
	public int getSampleRate() {
		return vStreamHdr.getSampleRate();
	}

	/**
	 * This method swaps the bytes in the given array. It puts the
	 * byte with odd index in the array with even indices.
	 * 
	 * @param b the array of bytes to swap.
	 * @param offset the offset in the given array from where to start swapping.
	 * @param length is how much of the array to swap.
	 */
	public static void swapBytes(byte[] b, int offset, int length) {
		byte tempByte;
		for (int i = offset; i < (offset+length); i += 2) {
			tempByte = b[i];
			b[i] = b[i + 1];
			b[i + 1] = tempByte;
		}
	}
	
	public static void swapChars(char[] b, int offset, int length) {
		char tempByte;
		for (int i = offset; i < (offset+length); i += 2) {
			tempByte = b[i];
			b[i] = b[i + 1];
			b[i + 1] = tempByte;
		}
	}

	/**
	 * This method reads the given buffer.
	 * 
	 * @param buffer the buffer to read.
	 * @return the amount of bytes read or -1 if the end of the stream 
	 * was reached.
	 */
	public int read(byte[] buffer) {
		try {
			return read(buffer, 0);
		} catch (IOException e) {
			e.printStackTrace();
			return -1;
		}
	}

	/**
	 * Reads up to a specified maximum number of bytes of data from the 
	 * audio stream, putting them into the given byte array.
	 *  
	 * @param buffer the buffer to store the read bytes in.
	 * @param offset the offset from where in the stream to start reading.
	 * @return the amount of bytes read.
	 * @throws IOException the exception thrown if an input/output error 
	 * occurs. 
	 */
	private int read(byte[] buffer, int offset) throws IOException {
		int cnt = 0;
		int bytesRead = offset;
		while (bytesRead < buffer.length) {
			cnt = ais[current].read(buffer, bytesRead, buffer.length - bytesRead);
			if (cnt <= 0) {
				current = Math.abs(current - 1);
				new Thread() {
					public void run() {
						initNext();
					}
				}.start();
				cnt = 0;
			}
			bytesRead += cnt;
		}
		swapBytes(buffer, 0, bytesRead);
		return bytesRead;
	}
}
