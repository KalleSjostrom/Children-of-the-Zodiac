/*
 * Classname: Villager.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/05/08
 */
package villages;

import factories.Load;
import graphics.Graphics;
import info.Database;
import info.Values;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.StringTokenizer;

import java.util.logging.*;

import character.Character;

import organizer.AbstractMapLoader;
import organizer.ResourceLoader;

import sprite.InstructionFollower;
import sprite.Sprite;
import villages.utils.DialogSequence;
import villages.utils.Loot;
import villages.utils.Player;

/**
 * This class manages a villager in a village.
 * A villager has its own animation and a path to follow.
 * It also has thing to say and you can have a dialog with it.
 * 
 * It has one subclasses which is VillagerLoader.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0  - 13 May 2008
 */
public class Villager extends InstructionFollower {

	private ArrayList<DialogSequence> dialog = new ArrayList<DialogSequence>();
	private String storedTriggers = null;
	private String filename;
	private String seqFilePath;
	private String seqFileName;
	private String[] constraints;
	private String[] constraintTrigger;

	private boolean sequence = false;
	private boolean pause = false;
	private boolean talking;
	private boolean loadingDialog = false;
	private HashMap<Integer, ArrayList<DialogSequence>> responses = new HashMap<Integer, ArrayList<DialogSequence>>();
	private int status;
	private int range = 30;
	private static Logger logger = Logger.getLogger("Villager");

	/**
	 * Constructs a new villager with the given name from the images from 
	 * the given path.  
	 * 
	 * @param n the name of the villager.
	 * @param path the location of its instructions or village name.
	 * (actually just the name of the folder for the current village).
	 * @param status 
	 */
	public Villager(String n, String path, int status) {
		name = n;
		this.status = status;
		seqFilePath = path + "/villagers/";
		new VillagerLoader().parseFile(path + "/villagers/" + name);
		setInstructions(0);
	}

	/**
	 * Loads the images used to depict the villager with the given name.
	 * 
	 * @param name the prefix name of the images used.
	 * @param nr the number of images in the sprite animation.
	 */
	public void loadImages(String name, int nr) {
		if (name.startsWith("char/")) {
			name = name.replace("char/", "");
			super.loadImages(Values.VillageImages + "Characters/", name, nr);
		} else {
			super.loadImages(Values.VillageImages + seqFilePath, name, nr);
		}
	}

	/**
	 * Updates the current dialog to the dialog with the given number.
	 * This dialog number is equal to the status for this villager which
	 * is used in the database and can be triggered.
	 * 
	 * @param number the number of the dialog to be updated.
	 */
	public void updateDialog(int number) {
		sequence = false;
		new VillagerLoader().loadNewDialog(number);
	}

	/**
	 * Checks whether this village is in a story sequence and is ready
	 * for a dialog.
	 * 
	 * @return true if the villager is ready for a dialog in the story 
	 * sequence.
	 */
	protected boolean checkStoryDialog() {
		return storyDialog;
	}

	/**
	 * This method is called after the dialog in the story sequence has
	 * been completed, to release the hold of the villager and let 
	 * the villager continue with their instructions.
	 */
	protected void relinquishStoryDialog() {
		storyDialog = false;
	}

	/**
	 * Sets whether or not this villager is talking to the player or not.
	 * The given direction is where the villager to look to either face
	 * the player or look in its original direction.
	 * 
	 * @param talking true if the villager will start talking and false if
	 * the villager should stop.
	 * @param direction the direction the villager should face.
	 */
	protected void setTalking(boolean talking, int direction) {
		this.talking = talking;
		if (talking) {
			int s = Database.getStatusFor(getName());
			if (s != status) {
				status = s;
				updateDialog(s);
			}
			doCheck();
			standStill(direction);
		} else {
			moving = instruction.isMoving();
			setImages();
		}
	}

	private void doCheck() {
		boolean falseFound = false;
		if (constraints != null && constraintTrigger != null) {
			logger.log(Level.FINE, "Do check " + Arrays.toString(constraints));
			for (int i = 0; i < constraints.length && !falseFound; i++) {
				boolean check = false;
				String c = constraints[i].replace("_", " ");
				if (c.startsWith("s.")) {
					c = c.replace("s.", "");
					if (c.contains("=")) {
						String[] a = c.split("=");
						int status = Database.getStatusFor(a[0]);
						check = status == Integer.parseInt(a[1]);
					} else if (c.contains(">")) {
						String[] a = c.split(">");
						int status = Database.getStatusFor(a[0]);
						check = status > Integer.parseInt(a[1]);
					} else if (c.contains("<")) {
						String[] a = c.split("<");
						int status = Database.getStatusFor(a[0]);
						check = status < Integer.parseInt(a[1]);
					}
				} else if (c.startsWith("a.")) {
					c = c.replace("a.", "");
					String[] a = c.split("=");
					String[] b = a[1].split("-");
					int battles = Load.getPartyItems().getBattles();
					check = battles >= Integer.parseInt(b[0])
					&& battles <= Integer.parseInt(b[1]);
				} else if (c.startsWith("c.")) {
					c = c.replace("c.", "");
					ArrayList<Character> list = Load.getCharacters();
					check = false;
					for (Character cha : list) {
						if (cha.getName().equals(c)) {
							check = true;
							break;
						}
					}
				} else {
					check = Load.getPartyItems().hasItem(c);
				}
				if (!check) {
					falseFound = true;
				}
			}
			if (!falseFound) {
				String[] triggs = constraintTrigger;
				int status = 0;
				try {
					status = Integer.parseInt(triggs[1]);
				} catch (NumberFormatException e) {
					status = Database.getStatusFor(triggs[1]);
				}
				Database.addStatus(triggs[0], status);
				updateDialog(status);
			}
		}
	}

	/**
	 * Checks if this villager is busy. This could be either that the villager
	 * is talking or something else. If the villager is busy he will not 
	 * be updated, he will stand still. 
	 * 
	 * @return true if this villager is busy.
	 */
	private boolean isBusy() {
		return pause || talking;
	}

	/**
	 * Checks if the villager, when talked to, will initiate a story sequence.
	 * 
	 * @return true if the villager will start a sequence when talked too.
	 */
	protected boolean isDialogSequence() {
		return sequence;
	}

	/**
	 * Gets the name of the file containing the sequence information.
	 * This method will return null if isDialogSequence() returns false.
	 * 
	 * @return the name of the story sequence file containing the sequence.
	 */
	protected String getSequenceFilename() {
		return seqFileName;
	}

	/**
	 * Check if this villager has collided with the player
	 * 
	 * @param p an integer array with the position. 
	 * @return true if a collision has occurred.
	 */
	protected boolean checkCollision(float[] p) {
		return checkCollision(p, 25);
	}

	/**
	 * Checks if this villager is close enough to be talked to.
	 * 
	 * @param p the position of the player.
	 * @param direction the direction of the player.
	 * @return true if the player can talk to this villager.
	 */
	protected boolean checkTalkable(float[] p, int direction) {
		boolean talkable = false;
		if (inRange(p, range, true)) {
			float py = p[Values.Y] + Sprite.STANDARD_HEIGHT;
			float posy = pos[Values.Y] + this.getHeight();
			float distx = Math.abs(p[Values.X] - pos[Values.X]);
			float disty = Math.abs(py - posy);
			switch (direction) {
			case Values.UP : 
				talkable = posy < py && distx < disty;
				break;
			case Values.RIGHT : 
				talkable = pos[Values.X] > p[Values.X] && distx > disty;
				break;
			case Values.DOWN :
				talkable = posy > py && distx < disty;
				break;
			case Values.LEFT : 
				talkable = pos[Values.X] < p[Values.X] && distx > disty;
				break;
			}
		}
		return talkable;
	}

	/**
	 * Updates this villager, and checks for collision.
	 * 
	 * @param f the amount of time that has elapsed.
	 * @param player the player to check collision against, null
	 * if no collision testing should be made.
	 * @param reset true if the instructions should be reseted.
	 * @return true if the villager is moving.
	 */
	protected boolean update(float f, Player player, boolean reset) {
		super.update(f);
		
		if (player != null) {
			setPause(checkCollision(player.getPos()));
		}
		if (!isBusy() && !storyDialog) {
			move(reset, f);
		}
		return isMoving();
	}

	public void setPause(boolean p) {
		pause = p;
		if (!prePause[0] && pause) {
			if (prePause[1] = isMoving()) {
				standStill();
			}
		}
		if (prePause[0] && !pause) {
			if (prePause[1]) {
				move();
			}
		}
		prePause[0] = pause;
	}

	private boolean[] prePause = new boolean[2];
	public ArrayList<ArrayList<DialogSequence>> getResponses;

	public void updateVillager(int elapsedTime) {
		super.update(elapsedTime);
		move(true, elapsedTime);
	}

	/**
	 * Draws the villager on the given graphics2D object.
	 * The background position is used to draw the villager in 
	 * relation to the village background. This means that if the background 
	 * has moved, so has the villager (in some sense).
	 * 
	 * @param g the graphics2D object to draw on.
	 * @param bx the x position of the background.
	 * @param by the y position of the background.
	 */
	public void draw(Graphics g, int bx, int by) {
		drawX = Math.round(pos[Values.X] + bx);
		drawY = Math.round(pos[Values.Y] + by);
		if (isVisible()) {
			draw(g);
		}
	}

	/**
	 * Gets the dialog sequence that will take place if the player
	 * talks to this villager.
	 * 
	 * @return dialog the dialog sequence.
	 */
	protected ArrayList<DialogSequence> getDialog() {
		return dialog;
	}

	/**
	 * Gets the stored trigger in this villager.
	 * 
	 * @return the stored trigger in this villager.
	 */
	protected String getStoredTriggers() {
		String ret = storedTriggers;
		storedTriggers = null;
		return ret;
	}

	public String toString() {
		return name;
	}

	public HashMap<Integer, ArrayList<DialogSequence>> getResponses() {
		return responses;
	}

	/**
	 * This class loads the information about the villager from a file.
	 * 
	 * @author      Kalle Sj�str�m
	 * @version     0.7.0 - 13 May 2008
	 */
	private class VillagerLoader extends AbstractMapLoader {

		private String[] alt = new String[4];
		private String dialogName;
		private String firstLine;
		private String secondLine;
		private int altIndex = 0;
		private boolean question = false;
		private int dialogIndex = -1;
		private boolean altPaths;
		private Loot gift;
		private HashMap<String, Integer> triggers;
		private HashMap<String, Integer> beforeTriggers;
		private HashMap<String, Integer> triggerAdds;
		private int questionNr;
		private int[] prices;
		private boolean inputQ;
		private String imageName;
		private int takeAmount;
		private String takeName;
		private int forstatus = -1;
		private boolean open = true;
		private boolean whisper;

		/**
		 * This method parses the file with the given filename 
		 * and sends each line to parseLine() for parsing.
		 * 
		 * @param name the name of the char file.
		 */
		protected void parseFile(String name) {
			String[] plainName = name.split("/");
			constraints = constraintTrigger = null;
			status = Database.getStatusFor(
					plainName[plainName.length - 1]);
			if (status == -1) {
				logger.log(Level.WARNING, 
						"Could not find: " + 
						plainName[plainName.length - 1] + 
				" in the database.");
				logger.info("Using default value!");
				status = 1;
			}
			filename = name;
			parseFile(Values.VillageMaps, name+".char");
		}

		/**
		 * Loads the new dialog with the given status number. This is used
		 * after someone has triggered another villager to make sure that 
		 * the correct dialog is used.
		 * 
		 * @param dialogNr the number of the new dialog.
		 */
		protected void loadNewDialog(int dialogNr) {
			status = dialogNr;
			dialog.clear();
			constraints = constraintTrigger = null;
			InputStream is = 
				ResourceLoader.getResourceLoader().getFileInputStream(
						Values.VillageMaps + filename + ".char");
			try {
				BufferedReader reader = 
					new BufferedReader(new InputStreamReader(is));
				boolean found = false;
				while (!found) {
					String line = reader.readLine();
					if (line.trim().equals("end")) {
						found = true;
						continue;
					}
					parseLineForDialogChange(line);
				}
				reader.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}

		/**
		 * This method takes out the command from each line and sends
		 * it to execute dialog command.
		 * 
		 * @param line the line to be parsed.
		 */
		private void parseLineForDialogChange(String line) {
			StringTokenizer tokenizer = new StringTokenizer(line);
			if (line.equals("") || line.startsWith("#")) {
				return;
			}
			if (tokenizer.hasMoreElements()) {
				String command = tokenizer.nextToken();
				executeDialogCommand(command, line, tokenizer);
			}
		}

		/**
		 * This method creates the dialog sequence associated for the villager. 
		 * 
		 * @param command the command to execute.
		 * @param line the line of text to be parsed in the execution.
		 * @param tok the tokenizer used to get the tokens.
		 */
		private void executeDialogCommand(String command, String line, 
				StringTokenizer tok) {
			if (command.equals("dialog")) {
				int number = Integer.parseInt(tok.nextToken());
				loadingDialog = number == status;
				instructions.check();
			}
			if (loadingDialog) {
				if (command.equals("check")) {
					String trigName = tok.nextToken().replace("_", " ");
					String trigVal = tok.nextToken();
					constraints = tok.nextToken().split(":");
					constraintTrigger = new String[]{trigName, trigVal};
				} else if (command.equals("n")) {
					line = line.substring(2, line.length());
					dialogName = line.replace("_", " ");
					whisper = false;
				} else if (command.equals("whisper")) {
					whisper = true;
				} else if (command.equals("fl")) {
					firstLine = line.replace("fl ", "");
					if (firstLine.contains("--")) {
						firstLine = modifyLine(firstLine);
					}
					secondLine = "";
				} else if (command.equals("sl")) {
					String temp = tok.nextToken();
					if (temp.equals("end")) {
						secondLine = "";
					} else {
						secondLine = line.replace("sl ", "");
						if (secondLine.contains("--")) {
							secondLine = modifyLine(secondLine);
						}
					}
				} else if (command.equals("f")) {
					boolean first = Boolean.parseBoolean(tok.nextToken());
					DialogSequence ds = new DialogSequence(
							dialogName, firstLine, secondLine, first, question, whisper);
					ds.prices = prices;
					prices = new int[4];
					ds.setGift(gift);
					ds.setTake(takeName, takeAmount);
					takeName = null;
					ds.setTriggers(triggers);
					ds.setBeforeTriggers(beforeTriggers);
					ds.setTriggerAdds(triggerAdds);
					triggers = null;
					triggerAdds = null;
					gift = null;
					if (altPaths) {
						responses.get(dialogIndex).add(ds);
					} else {
						dialog.add(ds);
					}
					if (imageName != null) {
						ds.setImage(imageName);
						imageName = null;
					}
					if (inputQ) {
						ds.setInputQ(true);
						ds.setQuestionNr(questionNr);
						inputQ = false;
						question = false;
					} else if (question) {
						ds.setAlternatives(alt.clone());
						ds.setQuestionNr(questionNr);
						question = false;
						altIndex = 0;
					}
				} else if (command.equals("price")) {
					prices[0] = Integer.parseInt(tok.nextToken());
					prices[1] = Integer.parseInt(tok.nextToken());
					prices[2] = Integer.parseInt(tok.nextToken());
					prices[3] = Integer.parseInt(tok.nextToken());
				} else if (command.equals("take")) {
					takeName = tok.nextToken().replace("_", " ");
					takeAmount = 1;
					if (tok.hasMoreTokens()) {
						takeAmount = Integer.parseInt(tok.nextToken());
					}
				} else if (command.startsWith("*")) {
					altPaths = true;
					command = command.replace("*", "");
					dialogIndex = Integer.parseInt(command);
					responses.put(dialogIndex, new ArrayList<DialogSequence>());
				} else if (command.equals("endAlts")) {
					altPaths = false;
				} else if (command.equals("inputQ")) {
					inputQ = true;
					question = true;
					questionNr = Integer.parseInt(tok.nextToken());
				} else if (command.equals("q")) {
					question = true;
					if (tok.hasMoreTokens()) {
						questionNr = Integer.parseInt(tok.nextToken());
					}
				} else if (command.equals("alt")) {
					alt[altIndex++] = tok.nextToken().replace("_", " ");
				} else if (command.equals("showImage")) {
					imageName = Values.VillageImages + tok.nextToken();
				} else if (command.equals("gift")) {
					String contentName = tok.nextToken();
					int type = Integer.parseInt(tok.nextToken());
					Object content = Loot.createContent(contentName, type, tok);
					gift = new Loot(contentName, null, null, type, content, null);
				} else if (command.equals("run")) {
					sequence = true;
					seqFileName = tok.nextToken().replace("_", " ");
				} else if (command.equals("trigger")) {
					String name = tok.nextToken().replace("_", " ");
					int number = Integer.parseInt(tok.nextToken());
					if (triggers == null) {
						triggers = new HashMap<String, Integer>();
					}
					triggers.put(name, number);
				} else if (command.equals("beforeTrigger")) {
					String name = tok.nextToken().replace("_", " ");
					int number = Integer.parseInt(tok.nextToken());
					if (beforeTriggers == null) {
						beforeTriggers = new HashMap<String, Integer>();
					}
					beforeTriggers.put(name, number);
				} else if (command.equals("triggeradd")) {
					String name = tok.nextToken().replace("_", " ");
					int number = Integer.parseInt(tok.nextToken());
					if (triggerAdds == null) {
						triggerAdds = new HashMap<String, Integer>();
					}
					triggerAdds.put(name, number);
				} else if (command.equals("storeTrigger")) {
					storedTriggers = tok.nextToken();
				}
			}
		}

		private String modifyLine(String line) {
			String[] ls = line.split("--");
			if (ls[1].equals("getBattles")) {
				line = ls[0] + Load.getPartyItems().getBattles() + ls[2];
			}
			return line;
		}

		/**
		 * @inheritDoc
		 */
		protected void executeCommand(String command, StringTokenizer tokenizer) {
			if (command.equals("forstatus")) {
				int fs = Integer.parseInt(tokenizer.nextToken());
				// 
				if (forstatus == -1) {
					if (fs == status || fs == -1) {
						forstatus = fs;
						open = true;
					} else {
						open = false;
					}
				} else {
					if (fs != status) {
						open = false;
					}
				}
			} else if (command.equals("in")) {
				if (open) {
					instructions.executeCommand(command, tokenizer);
				}
			} else if (command.equals("start")) {
				if (open) {
					int startX = Integer.parseInt(tokenizer.nextToken());
					int startY = Integer.parseInt(tokenizer.nextToken());
					pos = Values.createNormalFloatPoint(startX, startY);
				}
			} else if (command.equals("range")) {
				if (open) {
					range = Integer.parseInt(tokenizer.nextToken());
				}
			} else if (command.equalsIgnoreCase("image")) {
				if (open) {
					String name = tokenizer.nextToken().replace("_", " ");
					int number = 16;
					if (tokenizer.hasMoreTokens()) {
						number = Integer.parseInt(tokenizer.nextToken());
						if (tokenizer.hasMoreTokens()) {
							height = Integer.parseInt(tokenizer.nextToken());
							width = Integer.parseInt(tokenizer.nextToken());
						} else {
							height = STANDARD_HEIGHT;
							width = STANDARD_WIDTH;
						}
					}
					loadImages(name, number);
				}
			} else {
				executeDialogCommand(command, lastLine, tokenizer);
			}
		}
	}
}
