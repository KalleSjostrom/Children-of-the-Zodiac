/*
 * Classname: VillageStoryLoader.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/2008
 */
package villages.villageStory;

import factories.Load;
import graphics.ImageHandler;
import info.Values;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;
import organizer.Organizer;

import story.ScrollableTexts;
import story.Text;
import story.TimeLineEvent;

/**
 * This class loads and creates the village story sequence.
 * It parses the sequence file and creates the sequence according to 
 * the file.
 * 
 * @author     Kalle Sjöström 
 * @version    0.7.0 - 13 May 2008
 */
public class VillageStoryLoader extends AbstractMapLoader {

	private HashMap<String, int[]> poses = new HashMap<String, int[]>();
	private HashMap<String, String> newVillageInfo = new HashMap<String, String>();
	private ArrayList<DialogPackage> dialogs = new ArrayList<DialogPackage>();
	private ArrayList<TimeLineEvent> info = new ArrayList<TimeLineEvent>();
	private ArrayList<Text> texts = new ArrayList<Text>();
	private ScrollableTexts scrolltext;
	private boolean[] showing;
	private Parser parser = new Parser();
	
	private HashMap<Integer, ArrayList<String>> infoList = 
		new HashMap<Integer, ArrayList<String>>();
	private boolean drawPause = false;
	private boolean fromVillage = false;
	private boolean passVillage = false;

	/**
	 * Parses the file with the given name to load the village story.
	 * 
	 * @param fileName the name of the file to load.
	 */
	public void parseFile(String fileName) {
		parseFile(Values.StorySequences, fileName + ".seq");
	}
	
	/**
	 * This method executes the given command create the 
	 * village story sequence.
	 * 
	 * @param command the command to execute.
	 * @param tok the StringTokenizer containing additional information.
	 */
	protected void executeCommand(String command, StringTokenizer tok) {
		parser.updateLineCounter(lineCount, lastLine);
		if (command.equals("import")) {
			String file = Parser.getArgument(tok.nextToken())[1];
			parseFile(Values.StorySequences, file);
			lineCount -= parser.variableSize();
		} else if (command.equals("info")) {
			String[] arguments;
			while (tok.hasMoreTokens()) {
				arguments = Parser.getArgument(tok.nextToken());
				newVillageInfo.put(arguments[0], Parser.getText(tok, arguments[1])[0]);
			}
		} else if (command.equals("actor")) {
			String name = Parser.getText(tok, Parser.getArgument(tok.nextToken())[1])[0];
			getList(TimeLineEvent.ACTORS).add(name);
//			Load.loadNewCharacter(name);
			int[] pos = null;
			if (tok.hasMoreTokens()) {
				pos = parser.getPos(Parser.getArgument(tok.nextToken())[1]);
			}
			if (pos != null) {
				poses.put(name, pos);
			}
		} else if (command.equals("pos")) {
			String name = Parser.getText(tok, Parser.getArgument(tok.nextToken())[1])[0];
			int[] pos = null;
			if (tok.hasMoreTokens()) {
				pos = parser.getPos(Parser.getArgument(tok.nextToken())[1]);
			}
			if (pos != null) {
				poses.put(name, pos);
			}
		} else if (command.equals("set")) {
			String val = tok.nextToken();
			if (val.equals("fromvillage")) {
				fromVillage = true;
			} else if (val.equals("passvillage")) {
				passVillage = true;
			}
		} else if (command.equals("ins")) {
			TimeLineEvent t = parser.getTimeLineEvent(tok);
			info.add(t);
		} else if (command.equals("show")) {
			if (showing == null) {
				showing = new boolean[getList(TimeLineEvent.ACTORS).size()];
				Arrays.fill(showing, true);
			}
			parser.show(tok, showing);
		} else if (command.equals("dialogpacket")) {
			dialogs.add(parser.getDialogPacket(tok));
		} else if (command.equals("var")) {
			parser.addVariable(tok);
		} else if (command.equals("text")) {
			texts.add(parser.getText(tok));
		} else if (command.equals("newscrolltext")) {
			scrolltext = new ScrollableTexts();
			String[] args = Parser.getArgument(tok.nextToken());
			String cmd = args[0];
			String argument = args[1];
			if (cmd.equals("speed")) {
				scrolltext.setSpeed(Float.parseFloat(argument));
			}
		} else if (command.equals("scrolltext")) {
			scrolltext.add(parser.getScrollText(tok));
		} else if (command.equals("load")) {
			String[] args = Parser.getArgument(tok.nextToken());
			String cmd = args[0];
			String argument = Parser.getText(tok, args[1])[0];
			if (cmd.equals("image")) {
				if (!argument.equals("black")) {
					argument = Values.StoryImages + argument + ".jpg";
					ImageHandler.addToCurrentLoadNow(argument);
				}
				getList(TimeLineEvent.IMAGES).add(argument);
			} else if (cmd.equals("translucent")) {
				if (!argument.equals("black")) {
					ImageHandler.addToCurrentLoadNow(argument);
				}
				getList(TimeLineEvent.IMAGES).add(argument);
			} else if (cmd.equals("music")) {
				getList(TimeLineEvent.MUSICS).add(argument);
			} else if (cmd.equals("trigger")) {
				getList(TimeLineEvent.TRIGGERS).add(Organizer.convert(argument));
			} else if (cmd.equals("character")) {
				Load.loadNewCharacter(argument);
			} else if (cmd.equals("animation")) {
				getList(TimeLineEvent.ANIMATIONS).add(argument);
			} else if (cmd.equals("story")) {
				getList(TimeLineEvent.STORY_SEQUENCES).add(argument);
			} else if (cmd.equals("particleSystem")) {
				getList(TimeLineEvent.PARTICLE_SYSTEMS).add(argument);
			}
		} else if (command.equals("unload")) {
			String[] args = Parser.getArgument(tok.nextToken());
			String cmd = args[0];
			String argument = Parser.getText(tok, args[1])[0];
			if (cmd.equals("character")) {
				Load.unloadNewCharacter(argument);
			} 
		} else if (command.equals("dialog")) {
			parser.addDialog(tok, dialogs, null);
		} else if (command.equals("dialogsingle")) {
			dialogs.add(parser.addSingleDialog(tok));
		} else if (command.equals("set")) {
			String[] args = Parser.getArgument(tok.nextToken());
			String cmd = args[0];
			String argument = Parser.getText(tok, args[1])[0];
			if (cmd.equals("drawpause")) {
				drawPause = argument.equals("true");
			} 
		} else {
			Parser.error("Unknown command: " + lastLine);
		}
	}
	
	/**
	 * Gets the list with the given code. The codes (and lists) available are
	 * TimeLineEvent.IMAGES, TimeLineEvent.ACTORS, TimeLineEvent.MUSICS, 
	 * TimeLineEvent.TRIGGERS, TimeLineEvent.STORY_SEQUENCES and 
	 * TimeLineEvent.ANIMATIONS.
	 * 
	 * @param code the code representing which list to get.
	 * @return the list with the given code.
	 */
	private ArrayList<String> getList(int code) {
		if (!infoList.containsKey(code)) {
			infoList.put(code, new ArrayList<String>());
		}
		return infoList.get(code);
	}

	/**
	 * Gets the dialogs that will be displayed in the village story.
	 * 
	 * @return the dialogs for this story.
	 */
	public ArrayList<DialogPackage> getDialogs() {
		return dialogs;
	}

	/**
	 * Gets the positions of the actors in the village story.
	 * 
	 * @return the positions of the actors.
	 */
	public HashMap<String, int[]> getPoses() {
		return poses;
	}

	/**
	 * Gets the time line information loaded from the file loaded by
	 * parseFile() method.
	 * 
	 * @return the list of time line events.
	 * @see #parseFile(String)
	 */
	public ArrayList<TimeLineEvent> getTimeLineEvents() {
		return info;
	}
	
	/**
	 * Gets the information of this village story loader.
	 * 
	 * @return the complete list of information about the loaded data.
	 */
	public HashMap<Integer, ArrayList<String>> getInfo() {
		return infoList;
	}
	
	/**
	 * Gets the text lists that has been loaded.
	 * 
	 * @return the text list loaded.
	 */
	public ArrayList<Text> getTextList() {
		return texts;
	}

	public ScrollableTexts getScrollableText() {
		return scrolltext;
	}
	
	/**
	 * Gets an boolean array representing which actor is showing and
	 * which is not. To check if actor returned by getActors().get(4)
	 * is showing just check if getsWhoseShowing()[4] is true.
	 * 
	 * @return an array containing information about which actors
	 * are showing.
	 */
	public boolean[] getWhoseShowing() {
		if (showing == null) {
			showing = new boolean[getList(TimeLineEvent.ACTORS).size()];
			Arrays.fill(showing, true);
		}
		return showing;
	}

	/**
	 * Gets the information for the village if a new village should be 
	 * initiated before the story sequence.
	 *  
	 * @return the information about the new village.
	 */
	public HashMap<String, String> newVillageInfo() {
		return newVillageInfo;
	}

	public boolean shouldPauseDrawings() {
		return drawPause ;
	}

	public boolean getFromVillage() {
		return fromVillage;
	}
	
	public boolean getPassVillage() {
		return passVillage;
	}
}
