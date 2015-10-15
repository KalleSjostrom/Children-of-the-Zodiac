/*
 * Classname: AbstractFactory.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package factories;

import info.Values;

import organizer.AbstractMapLoader;

/**
 * The subclasses of this abstract class is intended to be designed as
 * singleton classes. This means that there should be a private constructor
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 21 Jan 2008
 */
public abstract class AbstractFactory extends AbstractMapLoader {

	/**
	 * This method parses a file. It loads the file and sends each line to
	 * the parseLine() method which creates a StringTokenizer object. From this
	 * object, the command is gotten and the executeCommand() method is called.
	 * (If the line is not a comment).
	 * 
	 * @param filename the name of the file to be read.
	 */
	protected void parseFile(String filename) {
		parseFile(Values.Banks, filename);
	}
}
