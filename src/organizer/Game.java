/*
 * Classname: Game.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/01/2008
 */
package organizer;

import info.Values;

/**
 * The main class of the game
 * 
 * This class calls the Organizer which creates and runs the game. 
 * The game consists of 38 packages with 260 classes (private classes excluded).
 * 
 * This project has currently 1 129 017 characters in 42 975 lines of code.
 * 
 * java -Xmx512m -Dsun.java2d.opengl=true -Djava.library.path=./lib 
 * -classpath ./lib/j-ogg-all.jar:./lib/jinput.jar:./:bin/:./lib/jogl.jar
 * :./lib/gluegen-rt.jar:./lib/joal.jar organizer.Game
 * 
 * -Dsun.java2d.d3d=false
 * If problems persist, try setting the ddoffscreen property to false. 
 * -Dsun.java2d.ddoffscreen=false
 * If that doesn't solve the problems, try setting noddraw to true.
 * -Dsun.java2d.noddraw=true 
 * -Xmx512m -Dsun.java2d.opengl=true -Dsun.java2d.d3d=false -Dsun.java2d.ddoffscreen=false -Dsun.java2d.noddraw=true 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Jan 2008
 */
public class Game {
// -Xmx512m -Dsun.java2d.opengl=true -Dsun.java2d.d3d=false -Dsun.java2d.ddoffscreen=false -Dsun.java2d.noddraw=true 

	/**
	 * The main method, call this to start the game.
	 * "args" should just contain the empty string.
	 * 
	 * @param args an array of strings containing the arguments to this game.
	 * Should be empty.
	 */
	public static void main(String[] args) {
		Object[] obs = null;
//			new Object[1];
//		obs[0] = new InputWiiManager();
		run(args, obs);
	}
	
	public static void run(String[] args, Object[] obs) {
		Organizer o = new Organizer();
		for (String s : args) {
			Values.parseLine(s.replace("_", " "));
		}
		o.init(obs);
	}
}
