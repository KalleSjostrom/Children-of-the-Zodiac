/*
 * Classname: Door.java
 * 
 * Version information: 0.7.0
 *
 * Date: 13/09/2008
 */
package labyrinth.inventory;

import graphics.Graphics;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import labyrinth.Labyrinth;
import labyrinth.Node;
import menu.tutorial.Tutorial;

import organizer.AbstractMapLoader;
import organizer.Organizer;

import sound.SoundPlayer;
import villages.utils.Dialog;
import villages.utils.DialogSequence;
import villages.villageStory.DialogPackage;
import villages.villageStory.Parser;

/**
 * This class is the inventory door. An inventory is a thing in the 
 * labyrinth, that the player can find. If the player finds the node 
 * where this inventory resides, the player can enter the door and
 * be transported to the place named nextPlace in this class..
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 13 Sep 2008
 */
public class TriggerDoor extends Door {

	private Dialog dialog = Dialog.getDialog();
	private ArrayList<DialogPackage> dialogs;
	private HashMap<String, Integer> triggers;
	private Tutorial tutorial;
	
	private String sound;
	private String alt;
	private String tutorialName;

	public TriggerDoor(Node node, int dir, String openRoad, String nextPlace,
			int status, StringTokenizer tok) {
		super(node, dir, openRoad, nextPlace, status, tok);
		String triggerfilename = Organizer.convertKeepCase(nextPlace);
		triggerfilename += ".trig";
		TriggerLoader loader = new TriggerLoader();
		loader.parseFile(triggerfilename);
		dialogs = loader.getDialogs();
		this.triggers = loader.getTrigger();
		sound = loader.getSound();
		tutorialName = loader.getTutorialName();
		super.init(openRoad, tok.nextToken(), tok);
	}
	
	protected void init(String openRoad, String nextPlace, StringTokenizer tok) {
		// Just override it!
	}
	
	public boolean isDirectedTowards(int dir) {
		return true;
	}
	
	@Override
	public void arrive(final Labyrinth lab) {
		super.arrive(lab);
		
		if (getStatus() != 2) {
			setStatus(2);
			if (dialogs != null && dialogs.size() > 0) {
				ArrayList<DialogSequence> seq = dialogs.get(0).getSequense();
				lab.drawDialog(seq);
			}
			if (triggers != null) {
				Database.addStatus(triggers);
			}
			if (sound != null) {
				if (lab.isFading()) {
					new Thread() {
						public void run() {
							while (lab.isFading()) {
								Values.sleep(100);
							}
							SoundPlayer.playSound(sound);
						}
					}.start();
				} else {
					SoundPlayer.playSound(sound);
				}
			}
			lab.addTopLayer(this);
		}
	}

	@Override
	public void activate(Labyrinth lab) {
		int playerDir = ((lab.getPlayerAngle() - 90) / 90 + 4) % 4;
		if (playerDir == dir) {
			super.activate(lab);
		} else {
			if (tutorial == null && tutorialName != null) {
				if (dialog.isQuestion()) {
					alt = dialog.getCurrentAlternative();
					if (alt != null && alt.startsWith("Sure")) {
						tutorial = new Tutorial(tutorialName, true);
						tutorial.increment();
						tutorial.setActive(true);
					}
				}
			} else if (tutorial != null) {
				if (tutorial.crossedPressed()) {
//					tutorial = null;
					Dialog.getDialog().resetDialog();
				}
			}
		}
	}
	
	public void drawTopLayer(Graphics g) {
		if (tutorial != null) {
			tutorial.drawTopLayer(g);
		}
	}
	
	private static class TriggerLoader extends AbstractMapLoader {
		
		private HashMap<String, Integer> triggers = new HashMap<String, Integer>();
		private String sound;
		private String tutorialName;
		private Parser parser;
		private ArrayList<DialogPackage> dialogs = new ArrayList<DialogPackage>();

		public HashMap<String, Integer> getTrigger() {
			return triggers;
		}
		
		public String getTutorialName() {
			return tutorialName;
		}

		public String getSound() {
			return sound;
		}

		public ArrayList<DialogPackage> getDialogs() {
			return dialogs;
		}

		@Override
		protected void parseFile(String filename) {
			parser = new Parser();
			super.parseFile(Values.LabyrinthTriggers, filename);
		}

		protected void executeCommand(String command, StringTokenizer t) {
			String[] args;
			if (command.equals("trigger")) {
				String name = null;
				int value = 0;
				while (t.hasMoreTokens()) {
					args = Parser.getArgument(t.nextToken());
					if (args[0].equals("name")) {
						name = args[1];
					} else if (args[0].equals("value")){
						value = Integer.parseInt(args[1]);
					}
				}
				triggers.put(name, value);
			} else if (command.equals("playSound")) {
				String name = null;
				while (t.hasMoreTokens()) {
					args = Parser.getArgument(t.nextToken());
					if (args[0].equals("name")) {
						name = Organizer.convertKeepCase(args[1]);
					}
				}
				sound = name;
			} else if (command.equals("tutorialName")) {
				String name = null;
				while (t.hasMoreTokens()) {
					args = Parser.getArgument(t.nextToken());
					if (args[0].equals("name")) {
						name = Organizer.convertKeepCase(args[1]);
					}
				}
				tutorialName = name;
			} else if (command.equals("dialog")) {
				parser.addDialog(t, dialogs, null);
			} else if (command.equals("dialogpacket")) {
				dialogs.add(parser.getDialogPacket(t));
			}
		}
	}
}
