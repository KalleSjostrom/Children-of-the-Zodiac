/*
 * Classname: ResourceLoader.java
 * 
 * Version information: 0.7.0
 *
 * Date: 19/01/2008
 */
package organizer;

import info.Values;

import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.StringTokenizer;

import javax.imageio.ImageIO;

import java.util.logging.*;

import villages.villageStory.Parser;

/**
 * This singleton class loads the resources used in this game. 
 * It tries to load everything from inside the game jar, 
 * if that is unsuccessful try to load it from outside the jar.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 19 Jan 2008
 */
public class ResourceLoader extends AbstractMapLoader {

	private static ResourceLoader resLoader = new ResourceLoader();
	
	private HashMap<String, HashMap<String, String>> mainInfo = 
		new HashMap<String, HashMap<String, String>>();

	private HashMap<String, String> variables = new HashMap<String, String>();

	private static Logger logger = Logger.getLogger("ResourceLoader");

	/**
	 * The private constructor of ResourceLoader. 
	 */
	private ResourceLoader() {
		// The private constructor of ResourceLoader.
	}

	/**
	 * This method parses the file with the given name. The commands in the
	 * file (first word in every line), is sent to the executeCommand() method
	 * together with the rest of the line in the form of a StringTokenizer.
	 * 
	 * @param filename the name of the file to parse.
	 */
	protected void parseFile(String filename) {
		parseFile(Values.MainMap, filename);
	}

	/**
	 * This method executes the given command and uses the information in the 
	 * tokenizer to carry out the command.
	 * 
	 * @param command the command to execute.
	 * @param tok the StringTokenizer containing the needed information. 
	 */
	protected void executeCommand(String command, StringTokenizer tok) {
		String[] argument;
		String key;
		String value;
		if (command.equals("place")) {
			String name = null;
			HashMap<String, String> info = new HashMap<String, String>();
			while (tok.hasMoreTokens()) {
				argument = Parser.getArgument(tok.nextToken());
				key = argument[0];
				if (argument[1].startsWith("\"")) {					
					value = Parser.getText(tok, argument[1])[0];
				} else {
					value = variables.get(argument[1]);
				}
				if (key.equals("name")) {
					name = value;
				}
				info.put(key, value);
			}
			if (name == null) {
				Parser.error(lineCount + " No Name Found!");
			}
			String in = Organizer.convert(name);
			mainInfo.put(in, info);
		} else if (command.equals("var")) { 
			argument = Parser.getArgument(tok.nextToken());
			key = argument[0];
			value = Parser.getText(tok, argument[1])[0];
			variables.put(key, value);
		} else {
			Parser.error(lineCount + " Unknown command " + command);
		}
	}

	/**
	 * This method parses a file. It loads the text file and adds the lines to
	 * a string array. From that array, each string can be read by 
	 * the parseLine method.
	 * 
	 * @param filename the name of the file to be read.
	 * @return the main information.
	 */
	protected HashMap<String, HashMap<String, String>> getMainInfo(String filename) {
		parseFile(filename);
		return mainInfo;
	}

	/**
	 * Gets the only ResourceLoader object.
	 * 
	 * @return the resource loader.
	 */
	public synchronized static ResourceLoader getResourceLoader() {
		return resLoader;
	}

	/**
	 * Gets the URL that represents the given filename.
	 * 
	 * @param name the filename.
	 * @return the URL to the file.
	 */
	public URL getURL(String name) {
		URL url = this.getClass().getResource("/" + name);
		if (url == null) {
			try {
				url = new File(name).toURI().toURL();
			} catch (MalformedURLException e) {
				e.printStackTrace();
				return null;
			}
		}
		return url;
	}
	
	/**
	 * This method gets the file with the given name as an 
	 * input stream. It first tries to load the file from the jar files
	 * resources. If that is unsuccessful, a new file input stream is 
	 * created from the given name.
	 * 
	 * @param name the name of the path to the file.
	 * @return the file as an input stream.
	 */
	public InputStream getFileInputStream(String name) {
		InputStream is = this.getClass().getResourceAsStream("/" + name);
		if (is == null) {
			try {
				is = new FileInputStream(name);
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}
		return is;
	}

	/**
	 * Gets the buffered reader derived from the file with the given path
	 * and filename.
	 * 
	 * @param path the path to the file to open.
	 * @param filename the filename of the file to open.
	 * @return the buffered reader to read from the file.
	 */
	public BufferedReader getBufferedReader(String path, String filename) {
		BufferedReader reader = null;
		URL url = getURL(path + filename);
		try {
			if (url != null) {
				reader = new BufferedReader(
						new InputStreamReader(url.openStream()));
			} else {
				reader = new BufferedReader(
						new FileReader(new File(path, filename)));
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return reader;
	}

	/**
	 * Gets the input stream for the font used in this game.
	 * @param i 
	 * 
	 * @return the input stream for the font.
	 */
	public synchronized InputStream getFontAsStream(int i) {
		return getFileInputStream(Values.MainRes + (i == 1 ? "bold":"") + "font.ttf");
	}

	/**
	 * Loads the images used in the game. 
	 * Tries to load it from a jar file first, if that result in a null url
	 * try to load it as a normal file.
	 * 
	 * @param name the name of the image to load.
	 * @return the loaded image.
	 */
	public BufferedImage getBufferedImage(String name) {
		URL url = getURL(name);
		return getImage(new File(name), url);
	}

	/**
	 * Gets the image represented by either the given file or the given URL.
	 * If the URL is null, the file is used to get the image. If the URL is 
	 * not null, it does not matter if the file are null or not.
	 * 
	 * @param file the file containing the image, 
	 * or null if it should be gotten from the URL.
	 * @param url the URL location of the image
	 * or null if it should be gotten from the file.
	 * @return the buffered image referenced by the given file or URL.
	 */
	private BufferedImage getImage(File file, URL url) {
		BufferedImage returnImage = null;
		try {
			if (url != null) {
				return ImageIO.read(url.openStream());
//				stream = ImageIO.createImageInputStream(url.openStream());
			} else {
				return ImageIO.read(file);
//				stream = ImageIO.createImageInputStream(file);
			}
//
//			ImageReader reader = ImageIO.getImageReaders(stream).next();
//			reader.setInput(stream);
//			ImageReadParam param = reader.getDefaultReadParam();
//
//			ImageTypeSpecifier typeToUse = null;
//
//			for (Iterator<ImageTypeSpecifier> i = reader.getImageTypes(0); i.hasNext();) {
//				ImageTypeSpecifier type = i.next();
//				if (type.getColorModel().getColorSpace().isCS_sRGB()) {
//					typeToUse = type;
//				}
//			}
//
//			if (typeToUse != null) {
//				param.setDestinationType(typeToUse);
//			}
//
//			returnImage = reader.read(0, param);
//			reader.dispose();
//			stream.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return returnImage;
	}
	
	/**
	 * Checks if the file with the given name exists.
	 * 
	 * @param name the name of the file to check.
	 * @return true if the file exists.
	 */
	public boolean exists(String name) {
		URL url = getURL(name);
		Object o = null;
		try {
			if (url != null) {
				logger.log(Level.FINE, "URL: " + url);
				o = url.getContent();
			}
		} catch (IOException e) {
			logger.log(Level.FINE, "URL exception");
			// e.printStackTrace();
			// Ignore
		}
		return o != null;
	}
}
