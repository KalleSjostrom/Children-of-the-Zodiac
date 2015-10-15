/*
 * Classname: VorbisInputStream.java
 * 
 * Version information: 0.7.0
 *
 * Date: 22/06/2008
 */
package sound;

import java.io.IOException;
import java.io.InputStream;

import de.jarnbjo.ogg.EndOfOggStreamException;
import de.jarnbjo.vorbis.VorbisStream;

/**
 * This class wraps a VorbisStream in an InputStream.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 22 June 2008
 */
public class VorbisInputStream extends InputStream {

	private VorbisStream source;

	/**
	 * Constructs a new input stream from the given stream. 
	 * 
	 * @param vSource the source to wrap.
	 */
	public VorbisInputStream(VorbisStream vSource) {
		source = vSource;
	}

	/**
	 * This method just implements read() from InputStream but
	 * it does not do anything but return 0.
	 * 
	 * @return 0
	 */
	public int read() {return 0;}

	/**
	 * Reads length amount of bytes from the stream and puts them 
	 * in the buffer.
	 * 
	 * @param buffer the byte buffer to write the data in.
	 * @param offset the offset, in buffer, at which the data will be written.
	 * @param length the maximum number of bytes to read.
	 * @throws IOException if an input/output error occurs.
	 * @return the amount of bytes read or -1 if the end of the 
	 * stream is reached.
	 */
	public int read(byte[] buffer, int offset, int length) throws IOException {
		try {
			return source.readPcm(buffer, offset, length);
		} catch(EndOfOggStreamException e) {
			return -1;
		}
	}
}