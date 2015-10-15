package villages.villageStory;

import static story.TimeLineEvent.ACTOR_CONTROLL;
import static story.TimeLineEvent.ANIMATION_INDEX;
import static story.TimeLineEvent.BACKGROUND_FADE_TARGET;
import static story.TimeLineEvent.CENTER_SCREEN;
import static story.TimeLineEvent.COLOR;
import static story.TimeLineEvent.COLOR_SPEED;
import static story.TimeLineEvent.EMOTION;
import static story.TimeLineEvent.EMOTION_SHAKE;
import static story.TimeLineEvent.EMOTION_SHOW;
import static story.TimeLineEvent.FADE_IMAGE;
import static story.TimeLineEvent.FADE_TARGET;
import static story.TimeLineEvent.FADE_TIME;
import static story.TimeLineEvent.INDEX;
import static story.TimeLineEvent.INFO_IMAGE_MODE;
import static story.TimeLineEvent.INFO_IMAGE_SCROLL_MODE;
import static story.TimeLineEvent.INFO_IMAGE_SCROLL_SPEED;
import static story.TimeLineEvent.KIND;
import static story.TimeLineEvent.MOVE_ACCELERATION;
import static story.TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION;
import static story.TimeLineEvent.MOVE_DIRECTION;
import static story.TimeLineEvent.MOVE_DISTANCE;
import static story.TimeLineEvent.MOVE_DURATION;
import static story.TimeLineEvent.MOVE_SPEED;
import static story.TimeLineEvent.MOVE_X;
import static story.TimeLineEvent.MOVE_Y;
import static story.TimeLineEvent.PARTICLE_SYS_FADE_CUTOFF;
import static story.TimeLineEvent.PARTICLE_SYS_FADE_SPEED;
import static story.TimeLineEvent.PARTICLE_SYS_FADE_SWIFTNESS;
import static story.TimeLineEvent.PLAY_MODE;
import static story.TimeLineEvent.POS_X;
import static story.TimeLineEvent.POS_Y;
import static story.TimeLineEvent.SCREEN_ZOOM_IN;
import static story.TimeLineEvent.SCREEN_ZOOM_TIME;
import static story.TimeLineEvent.SCREEN_ZOOM_USE_STATIC_POS;
import static story.TimeLineEvent.SIZE;
import static story.TimeLineEvent.TARGET;
import static story.TimeLineEvent.TIME;
import static story.TimeLineEvent.TIME_OF_DAY;
import static story.TimeLineEvent.TRIGGER_VALUE;
import static story.TimeLineEvent.TYPE;
import static story.TimeLineEvent.TYPE_NO_FADE;
import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.NoSuchElementException;
import java.util.StringTokenizer;

import organizer.Organizer;

import story.ScrollableTexts.ScrollableText;
import story.Text;
import story.TimeLineEvent;
import villages.utils.DialogSequence;

public class Parser {
	
	private HashMap<String, Integer> variables = new HashMap<String, Integer>();
	private static int lineNr;
	private static String lastLine;
	private int time;
	
	public static void reset() {
		lineNr = 0;
	}
	
	public TimeLineEvent getTimeLineEvent(StringTokenizer tok) {
		int[] ins = new int[11];
		String[] argument;
		String key;
		ins[TYPE] = TYPE_NO_FADE;
		ins[MOVE_ACTOR_FACE_DIRECTION] = ins[TIME_OF_DAY] = -1;
		while (tok.hasMoreTokens()) {
			argument = getArgument(tok.nextToken());
			key = argument[0];
			if (key.equals("type") || key.equals("ty")) {
				ins[TYPE] = getValue(argument[1]);
			} else if (key.equals("time") || key.equals("t")) {
				ins[TIME] = getValue(argument[1]);
			} else if (key.equals("timea") || key.equals("ta")) {
				time += getValue(argument[1]);
				ins[TIME] = time;
			} else if (key.equals("index") || key.equals("i")) {
				ins[INDEX] = getValue(argument[1]);
			} else if (key.equals("fadetime") || key.equals("ft")) {
				ins[FADE_TIME] = getValue(argument[1]);
			} else if (key.equals("fadetarget")) {
				ins[FADE_TARGET] = getValue(argument[1]);
			} else if (key.equals("kind") || key.equals("k")) {
				ins[KIND] = getValue(argument[1]);
			} else if (key.equals("pos") || key.equals("p")) {
				int[] pos = getPos(argument[1]);
				ins[POS_X] = pos[0];
				ins[POS_Y] = pos[1];
			} else if (key.equals("day") || key.equals("da")) {
				ins[TIME_OF_DAY] = getValue(argument[1]);
			} else if (key.equals("distance") || key.equals("dis")) {
				ins[MOVE_DISTANCE] = getValue(argument[1]);
			} else if (key.equals("duration") || key.equals("du")) {
				ins[MOVE_DURATION] = getValue(argument[1]);
			} else if (key.equals("direction") || key.equals("dir")) {
				ins[MOVE_DIRECTION] = getValue(argument[1]);
			} else if (key.equals("acceleration") || key.equals("acc")) {
				ins[MOVE_ACCELERATION] = getValue(argument[1]);
			} else if (key.equals("facedirection") || key.equals("fd")) {
				ins[MOVE_ACTOR_FACE_DIRECTION] = getValue(argument[1]);
			} else if (key.equals("scrollmode") || key.equals("sm")) {
				ins[INFO_IMAGE_SCROLL_MODE] = getValue(argument[1]);
			} else if (key.equals("imagetype") || key.equals("it")) {
				ins[INFO_IMAGE_MODE] = getValue(argument[1]);
			} else if (key.equals("movepos") || key.equals("mp")) {
				int[] pos = getPos(argument[1]);
				ins[MOVE_X] = pos[0];
				ins[MOVE_Y] = pos[1];
				ins[MOVE_DIRECTION] = pos[2];
			} else if (key.equals("value") || key.equals("v")) {
				ins[TRIGGER_VALUE] = getValue(argument[1]);
			} else if (key.equals("emotion") || key.equals("e")) {
				ins[EMOTION] = getValue(argument[1]);
			} else if (key.equals("show") || key.equals("s")) {
				ins[EMOTION_SHOW] = getValue(argument[1]);
			} else if (key.equals("shake") || key.equals("sh")) {
				ins[EMOTION_SHAKE] = getValue(argument[1]);
			} else if (key.equals("controll") || key.equals("c")) {
				ins[ACTOR_CONTROLL] = getValue(argument[1]);
			} else if (key.equals("actor") || key.equals("a")) {
				ins[TARGET] = getValue(argument[1]);
				ins[POS_X] = -1;
				ins[MOVE_X] = -1;
			} else if (key.equals("speed") || key.equals("sp")) {
				ins[MOVE_SPEED] = getValue(argument[1]);
				ins[MOVE_DURATION] = -1;
			} else if (key.equals("mode") || key.equals("m")) {
				ins[PLAY_MODE] = getValue(argument[1]);
			} else if (key.equals("center") || key.equals("ce")) {
				ins[CENTER_SCREEN] = getValue(argument[1]);
			} else if (key.equals("animation") || key.equals("an")) {
				ins[ANIMATION_INDEX] = getValue(argument[1]);
			} else if (key.equals("color") || key.equals("co")) {
				ins[COLOR] = getValue(argument[1]);
			} else if (key.equals("colorspeed") || key.equals("cos")) {
				ins[COLOR_SPEED] = getValue(argument[1]);
			} else if (key.equals("fadeimage") || key.equals("fi")) {
				ins[FADE_IMAGE] = getValue(argument[1]);
			} else if (key.equals("size") || key.equals("si")) {
				ins[SIZE] = getValue(argument[1]);
			} else if (key.equals("scrollSpeed") || key.equals("ss")) {
				ins[INFO_IMAGE_SCROLL_SPEED] = getValue(argument[1]);
			} else if (key.equals("sysfadespeed") || key.equals("sfs")) {
				ins[PARTICLE_SYS_FADE_SPEED] = getValue(argument[1]);
			} else if (key.equals("syscutoff") || key.equals("sc")) {
				ins[PARTICLE_SYS_FADE_CUTOFF] = getValue(argument[1]);
			} else if (key.equals("sysswiftness") || key.equals("sw")) {
				ins[PARTICLE_SYS_FADE_SWIFTNESS] = getValue(argument[1]);
			} else if (key.equals("zoomin")) {
				ins[SCREEN_ZOOM_IN] = getValue(argument[1]);
			} else if (key.equals("zoomtime")) {
				ins[SCREEN_ZOOM_TIME] = getValue(argument[1]);
			} else if (key.equals("usestaticpos")) {
				ins[SCREEN_ZOOM_USE_STATIC_POS] = getValue(argument[1]);
			} else if (key.equals("fadebackto")) {
				ins[BACKGROUND_FADE_TARGET] = getValue(argument[1]);
			} else {
				error("Unrecognizable instruction " + key);
			}
		}
		if (ins[MOVE_ACTOR_FACE_DIRECTION] == -1) {
			ins[MOVE_ACTOR_FACE_DIRECTION] = ins[MOVE_DIRECTION];
		}
		return new TimeLineEvent(ins);
	}
	
	public static String[] getArgument(String input) {
		String[] parts = null;
		if (input.contains("=")) {
			parts = input.split("=", 2);
		} else {
			error("The string: " + input + " does not match key=val");
		}
		return parts;
	}
	
	public int[] getPos(String string) {
		int[] retVal = null;
		if (string.contains(";")) {
			String[] pos = string.split(";");
			retVal = new int[3];
			retVal[0] = getValue(pos[0]);
			retVal[1] = getValue(pos[1]);
			retVal[2] = pos.length > 2 ? getValue(pos[2]) : 0;
		} else {
			error("The string: " + string + " does not contain a ;");
		}
		return retVal;
	}
	
	public float[] getFloatPos(String string) {
		float[] retVal = null;
		if (string.contains(";")) {
			String[] pos = string.split(";");
			retVal = new float[3];
			retVal[0] = getFloat(pos[0]);
			retVal[1] = getFloat(pos[1]);
			retVal[2] = pos.length > 2 ? getFloat(pos[2]) : 0;
		} else {
			error("The string: " + string + " does not contain a ;");
		}
		return retVal;
	}

	public int getValue(String string) {
		string = string.trim();
		Integer i = variables.get(string);
		if (i == null) {
			try {
				i = Integer.parseInt(string);
			} catch (NumberFormatException e) {
				error("NumberFormatException (" + string + ")");
			}
		}
		return i;
	}
	
	public float getFloat(String string) {
		string = string.trim();
		float f = 0;
		try {
			f = Float.parseFloat(string);
		} catch (NumberFormatException e) {
			error("NumberFormatException (" + string + ")");
		}
		return f;
	}

	public static void error(String string) {
		try {
			throw new IllegalArgumentException(lineNr + ": " + string + "\n\t" + lastLine);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(-1);
		}
	}

	protected float[] getLongPos(StringTokenizer tok) {
		float[] pos = null;
		while (tok.hasMoreTokens()) {
			if (pos == null) {
				pos = new float[3];
				pos[2] = -1;
			}
			String[] argument = getArgument(tok.nextToken());
			String key = argument[0];
			if (key.equals("pos")) {
				int[] temp = getPos(argument[1]);
				pos[Values.X] = temp[0];
				pos[Values.Y] = temp[1];
			} else if (key.equals("angle")) {
				pos[2] = getValue(argument[1]);
			} else {
				error("Unrecognizable argument: " + key);
			}
		}
		return pos;
	}

	public void show(StringTokenizer tok, boolean[] showing) {
		String[] argument;
		String key;
		int index = 0;
		boolean shows = false;
		while (tok.hasMoreTokens()) {
			argument = getArgument(tok.nextToken());
			key = argument[0];
			if (key.equals("index")) {
				index = getValue(argument[1]);
			} else if (key.equals("value")) {
				shows = getValue(argument[1]) == 1;
			} else {
				error("Show instruction got an unrecognizable argument: " + key);
			}
		}
		showing[index] = shows;		
	}
	
	// dialogpacket name=0 starttime=4000 endtime=4500
	public DialogPackage getDialogPacket(StringTokenizer tok) {
		String[] argument;
		String key;
		String name = null;
		int starttime = time;
		int endtime = -1;
		while (tok.hasMoreTokens()) {
			argument = getArgument(tok.nextToken());
			key = argument[0];
			if (key.equals("name")) {
				name = argument[1]; // no getText 
			} else if (key.equals("starttime")) {
				starttime = getValue(argument[1]);
			} else if (key.equals("endtime")) {
				endtime = getValue(argument[1]);
			} else if (key.equals("starttimea")) {
				time += getValue(argument[1]);
				starttime = time;
			} else if (key.equals("endtimea")) {
				time += getValue(argument[1]);
				endtime = time;
			} else if (key.equals("duration")) {
				endtime = starttime + getValue(argument[1]);
			} else {
				error("Create dialog packet got an unrecognizable argument: " + key);
			}
		}
		if (endtime == -1) {
			endtime = starttime + 1;
		}
		return new DialogPackage(name, starttime, endtime);
	}
	
	protected DialogPackage addSingleDialog(StringTokenizer tok) {
		String[] argument;
		String key;
		String name = "";
		int starttime = time;
		int endtime = -1;
		DialogPackage dp = null;
		while (tok.hasMoreTokens()) {
			argument = getArgument(tok.nextToken());
			key = argument[0];
			if (key.equals("starttime")) {
				starttime = getValue(argument[1]);
			} else if (key.equals("endtime")) {
				endtime = getValue(argument[1]);
			} else if (key.equals("starttimea")) {
				time += getValue(argument[1]);
				starttime = time;
			} else if (key.equals("endtimea")) {
				time += getValue(argument[1]);
				endtime = time;
			} else if (key.equals("duration")) {
				endtime = starttime + getValue(argument[1]);
			} else if (key.equals("<")) {
				if (endtime == -1) {
					endtime = starttime + 1;
				}
				dp = new DialogPackage(name, starttime, endtime);
				addDialog(tok, null, dp);
			} else {
				error("Create dialog packet got an unrecognizable argument: " + key);
			}
		}
		return dp;
	}

	public void addDialog(StringTokenizer tok, ArrayList<DialogPackage> dialogs, DialogPackage altPackage) {
		getDialogPackage(tok, dialogs, altPackage);
	}
	
	public DialogSequence getDialogSequence(StringTokenizer tok) {
		return getDialogPackage(tok, null, null).getSequense().get(0);
	}
	
	private DialogPackage getDialogPackage(
			StringTokenizer tok, ArrayList<DialogPackage> dialogs, 
			DialogPackage altPackage) {
		String[] argument;
		String key;
		String name = null;
		String[] text = null;
		String[] alts = null;
		boolean first = true;
		boolean whisper = false;
		boolean question = false;
		DialogSequence ds = null;
		DialogPackage dialogPackage = null;
		
		while (tok.hasMoreTokens()) {
			argument = getArgument(tok.nextToken());
			key = argument[0];
			if (key.equals("packetname")) {
				dialogPackage = getPackage(dialogs, argument[1]);
			} else if (key.equals("name")) {
				name = getText(tok, argument[1])[0];
			} else if (key.equals("text")) {
				text = getText(tok, argument[1]);
			} else if (key.equals("first")) {
				first = getValue(argument[1]) == 1;
			} else if (key.equals("whisper")) {
				whisper = getValue(argument[1]) == 1;
			} else if (key.equals("alts")) {
				alts = Organizer.convertKeepCase(argument[1]).split(";");
				question = true;
			} else {
				error("Create dialog packet got an unrecognizable argument: " + key);
			}
		}
		
		if (text != null) {
			String fl = text.length > 0 ? text[0] : "";
			String sl = text.length > 1 ? text[1] : "";
			ds = new DialogSequence(name, fl, sl, first, question, whisper);
			
			if (question) {
				ds.setAlternatives(alts);
			}
			
			if (altPackage != null) {
				altPackage.add(ds);
				return altPackage;
			} else if (dialogPackage == null) {
				dialogPackage = new DialogPackage();
			}
			dialogPackage.add(ds);
		} else {
			error("Unexpected error when adding a dialog");
		}
		return dialogPackage;
	}
	
	public Text getText(StringTokenizer tok) {
		String[] argument;
		String key;
		String[] text = null;
		int[] pos = null;
		boolean whisper = false;
		int color = 1;
		int size = Text.SIZE;
		
		while (tok.hasMoreTokens()) {
			String s = tok.nextToken();
			argument = getArgument(s);
			key = argument[0];
			if (key.equals("lines")) {
				text = getText(tok, argument[1]);
			} else if (key.equals("pos")) {
				pos = getPos(argument[1]);
			} else if (key.equals("whisper")) {
				whisper = Boolean.parseBoolean(argument[1]);
			} else if (key.equals("color")) {
				color = Integer.parseInt(argument[1]);
			} else if (key.equals("size")) {
				size = Integer.parseInt(argument[1]);
			} else {
				error("Getting text got an unrecognizable argument: " + key);
			}
		}
		Text t = null;
		if (text != null && pos != null) {
			String t1 = text.length == 1 ? "" : text[1];
			t = new Text(text[0], t1);
			t.setPos(pos);
			t.setWhisper(whisper);
			t.setSize(size);
			t.setColor(color);
		}
		return t;
	}
	
	public ScrollableText getScrollText(StringTokenizer tok) {
		String[] argument;
		String key;
		
		ScrollableText st = new ScrollableText();
		
		while (tok.hasMoreTokens()) {
			String s = tok.nextToken();
			argument = getArgument(s);
			key = argument[0];
			if (key.equals("text")) {
				st.setText(getText(tok, argument[1])[0]);
			} else if (key.equals("x")) {
				st.setX(getValue(argument[1]));
			} else if (key.equals("size")) {
				st.setFontSize(getValue(argument[1]));
			} else if (key.equals("bold")) {
				st.setIsBold(getValue(argument[1]) == 1);
			} else if (key.equals("distance")) {
				st.setDistance(getValue(argument[1]));
			} else {
				error("Getting text got an unrecognizable argument: " + key);
			}
		}
		return st;
	}
	
	private static boolean blah(String string, StringBuffer sb) {
		boolean found = false;
		boolean done = false;
		if (string.startsWith("\"")) {
			string = string.substring(1);
		}
		if (string.contains("\"")) {
			String left = string.substring(0, string.indexOf("\""));
			string = string.substring(string.indexOf("\""));
			sb.append(left + " ");
			found = true;
			done = true;
		}
		if (string.contains(";")) {
			sb.append(" ---- ");
			found = true;
			done = blah(string.split(";")[1], sb);
		}
		if (!found) {
			sb.append(string + " ");
		}
		return done;
	}

	public static String[] getText(StringTokenizer tok, String first) {
		StringBuffer sb = new StringBuffer();
		String string = first;
		boolean done = false;
		boolean done2 = !done;
		while (done2) {
			done = blah(string, sb);
			done2 = tok.hasMoreTokens() && !done;
			if (!done) {
				try {
					string = tok.nextToken();
				} catch (NoSuchElementException e) {
					error("NoSuchElementException");
				}
			}
		}
		String[] lines = sb.toString().split(" ---- ");
		for (int i = 0; i < lines.length; i++) {
			lines[i] = lines[i].trim();
		}
		return lines;
	}

	private DialogPackage getPackage(ArrayList<DialogPackage> dialogs, String string) {
		for (int i = 0; i < dialogs.size(); i++) {
			DialogPackage dp = dialogs.get(i);
			if (dp.getName().equals(string)) {
				return dp;
			}
		}
		error("No dialog package with the name: " + string);
		return null;
	}

	public void updateLineCounter(int lineCount, String line) {
		lineNr = lineCount;
		lastLine = line;
	}

	public void addVariable(StringTokenizer tok) {
		if (tok.hasMoreTokens()) {
			String[] args = getArgument(tok.nextToken());
			variables.put(args[0], Integer.parseInt(args[1]));
		} else {
			error("Empty var statement.");
		}
	}

	public int variableSize() {
		return variables.size();
	}
}
