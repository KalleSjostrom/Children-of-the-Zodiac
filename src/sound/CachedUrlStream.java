package sound;

import info.Values;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;

import de.jarnbjo.ogg.EndOfOggStreamException;
import de.jarnbjo.ogg.LogicalOggStream;
import de.jarnbjo.ogg.LogicalOggStreamImpl;
import de.jarnbjo.ogg.OggFormatException;
import de.jarnbjo.ogg.OggPage;
import de.jarnbjo.ogg.PhysicalOggStream;

/**
 *  Implementation of the <code>PhysicalOggStream</code> interface for reading
 *  and caching an Ogg stream from a URL. This class reads the data as fast as
 *  possible from the URL, caches it locally either in memory or on disk, and
 *  supports seeking within the available data.
 */

public class CachedUrlStream implements PhysicalOggStream {

	private URLConnection source;
	private InputStream sourceStream;
	private Object drainLock = new Object();
	private byte[] memoryCache;
	private ArrayList<Long> pageOffsets = new ArrayList<Long>();
	private ArrayList<Long> pageLengths = new ArrayList<Long>();

	private boolean closed = false;
	private long cacheLength;
	private HashMap<Integer, LogicalOggStream> logicalStreams = 
		new HashMap<Integer, LogicalOggStream>();
	private LoaderThread loaderThread;

	/**
	 * Creates an instance of this class, using the specified file as cache. The
	 * file is not automatically deleted when this class is disposed.
	 * 
	 * @param url the URL to the stream to play.
	 * @throws OggFormatException the exception thrown when the format of the
	 * audio file is not in ogg format.
	 * @throws IOException is thrown if an Input / Output exception occurred 
	 * when reading the audio file.
	 */ 
	public CachedUrlStream(URL url) throws OggFormatException, IOException {
		source = url.openConnection();
		
		int contentLength = source.getContentLength();
		if (contentLength == -1) {
			throw new IOException(
					"The URLConncetion's content length " +
					"must be set when operating with a in-memory cache.");
		}
		memoryCache = new byte[contentLength];
		sourceStream = source.getInputStream();
		loaderThread = new LoaderThread(sourceStream, memoryCache);
		new Thread(loaderThread).start();
		while (!loaderThread.isBosDone()) {
			Values.sleep(20);
		}
	}

	public Collection<LogicalOggStream> getLogicalStreams() {
		return logicalStreams.values();
	}

	public boolean isOpen() {
		return !closed;
	}

	public void close() throws IOException {
		closed=true;
		sourceStream.close();
	}

	public long getCacheLength() {
		return cacheLength;
	}

	public OggPage getOggPage(int index) throws IOException {
		synchronized(drainLock) {
			Long offset = pageOffsets.get(index);
			Long length = pageLengths.get(index);
			if (offset != null) {
				byte[] tmpArray = new byte[length.intValue()];
				System.arraycopy(memoryCache, offset.intValue(), tmpArray, 0, length.intValue());
				return OggPage.create(tmpArray);
			}
			return null;
		}
	}

	private LogicalOggStream getLogicalStream(int serialNumber) {
		return logicalStreams.get(new Integer(serialNumber));
	}

	public void setTime(long granulePosition) throws IOException {
		Iterator<LogicalOggStream> it = logicalStreams.values().iterator();
		while (it.hasNext()) {
			LogicalOggStream los = it.next();
			los.setTime(granulePosition);
		}
	}
	
	public boolean isSeekable() {
		return true;
	}

	public class LoaderThread implements Runnable {

		private InputStream source;
		private byte[] memoryCache;
		private boolean bosDone=false;
		private int pageNumber;

		public LoaderThread(InputStream source, byte[] memoryCache) {
			this.source = source;
			this.memoryCache = memoryCache;
		}

		public void run() {
			try {
				boolean eos = false;
				while (!eos) {
					OggPage op = OggPage.create(source);
					synchronized (drainLock) {
						int listSize = pageOffsets.size();

						long pos = listSize > 0 ? 
								pageOffsets.get(listSize-1).longValue() + 
								pageLengths.get(listSize-1).longValue() : 0;

						byte[] arr1 = op.getHeader();
						byte[] arr2 = op.getSegmentTable();
						byte[] arr3 = op.getData();

						System.arraycopy(
								arr1, 0, memoryCache, (int)pos, arr1.length);
						System.arraycopy(
								arr2, 0, memoryCache, (int)pos + arr1.length, arr2.length);
						System.arraycopy(
								arr3, 0, memoryCache, (int)pos + arr1.length + arr2.length, arr3.length);

						pageOffsets.add(new Long(pos));
						pageLengths.add(new Long(arr1.length + arr2.length + arr3.length));
					}

					bosDone = !op.isBos();
					eos = op.isEos();

					LogicalOggStreamImpl los = 
						(LogicalOggStreamImpl) getLogicalStream(op.getStreamSerialNumber());
					if (los == null) {
						los = new LogicalOggStreamImpl(
								CachedUrlStream.this, op.getStreamSerialNumber());
						logicalStreams.put(new Integer(op.getStreamSerialNumber()), los);
						los.checkFormat(op);
					}

					los.addPageNumberMapping(pageNumber);
					los.addGranulePosition(op.getAbsoluteGranulePosition());

					pageNumber++;
					cacheLength = op.getAbsoluteGranulePosition();
				}
			} catch (EndOfOggStreamException e) {
				// Ignore
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		public boolean isBosDone() {
			return bosDone;
		}
	}
}