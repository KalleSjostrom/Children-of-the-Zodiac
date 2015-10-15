/*
 * Classname: AbstractMapLoader.java
 * 
 * Version information: 0.7.0
 *
 * Date: 12/05/2008
 */
package organizer;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.StringTokenizer;

import villages.villageStory.Parser;

/**
 * This class is an abstraction of a map loader. It consists of methods
 * for handling the loading of a map.
 * 
 * @author 		Kalle Sjšstršm
 * @version 	0.7.0 - 19 Jan 2008
 */
public abstract class AbstractMapLoader {

	protected String lastLine;
	protected int lineCount;
	private boolean comment;

	/**
	 * This method is the entry point and where the programmer can specify
	 * which map is going to be loaded. The programmer should call
	 * super.parseFile(String path, String filename).
	 * 
	 * @param filename the name of the map file.
	 */
	protected abstract void parseFile(String filename);

	/**
	 * This method parses a file. It loads the file and sends each line to
	 * the parseLine() method which creates a StringTokenizer object. From this
	 * object, the command is gotten and the executeCommand() method is called.
	 * (If the line is not a comment).
	 * 
	 * @param path the path to the file to be read.
	 * @param filename the name of the file to be read.
	 */
	protected void parseFile(String path, String filename) {
		try {
			ResourceLoader rl = ResourceLoader.getResourceLoader(); 
			BufferedReader reader = rl.getBufferedReader(path, filename);
			String line = "";
			lineCount = 0;
			Parser.reset();
			while (line != null) {
				line = reader.readLine();
				lineCount++;
				if (line != null) {
					line = line.trim();
					if (!line.equals("") && !line.startsWith("#")) {
						parseLine(line);
					}
				}
			}
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Parses a line in the file and executes the commands in the file.
	 * These commands is executed via the executeCommand() method,
	 * which all the subclasses of the AbstractFatory must implement.
	 * 
	 * @param line the line to read.
	 */
	private void parseLine(String line) {
		lastLine = line;
		StringTokenizer tokenizer = new StringTokenizer(line);

		boolean lineOk = !line.equals("") && !line.equals(" ") && !line.equals("\t");
		if (lineOk && tokenizer.hasMoreTokens()) {
			String command = tokenizer.nextToken();
			if (command.equals("/*")) {
				comment = true;
			}
			if (!comment && !command.equals("#")) {
				executeCommand(command, tokenizer);
			}
			if (command.equals("*/")) {
				comment = false;
			}
		}
	}

	/**
	 * This method executes the command sent. This method also takes a 
	 * StringTokenizer with the rest of the information concerning the 
	 * command. What information and commands are executed
	 * are up to the subclasses.
	 * 
	 * @param command the command to execute.
	 * @param tokenizer the StringTokenizer containing additional information.
	 */
	protected abstract void executeCommand(
			String command, StringTokenizer tokenizer);
}
