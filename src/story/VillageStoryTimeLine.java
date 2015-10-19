/*
 * Classname: TimeLine.java
 * 
 * Version information: 0.7.0
 *
 * Date: 04/10/2008
 */
package story;

import static story.TimeLineEvent.ACTOR_CONTROLL;
import static story.TimeLineEvent.BACKGROUND_FADE_TARGET;
import static story.TimeLineEvent.COLOR;
import static story.TimeLineEvent.COLOR_SPEED;
import static story.TimeLineEvent.EMOTION;
import static story.TimeLineEvent.EMOTION_SHAKE;
import static story.TimeLineEvent.EMOTION_SHOW;
import static story.TimeLineEvent.FADE_IMAGE;
import static story.TimeLineEvent.FADE_TARGET;
import static story.TimeLineEvent.FADE_TIME;
import static story.TimeLineEvent.IMAGES;
import static story.TimeLineEvent.IMAGE_MODE_BACKFLASH;
import static story.TimeLineEvent.IMAGE_MODE_COVERALL;
import static story.TimeLineEvent.IMAGE_MODE_STORY;
import static story.TimeLineEvent.IMAGE_MODE_TRANSLUCENT_OVER_ACTOR;
import static story.TimeLineEvent.IMAGE_MODE_TRANSLUCENT_UNDER_ACTOR;
import static story.TimeLineEvent.INDEX;
import static story.TimeLineEvent.INFO_IMAGE_MODE;
import static story.TimeLineEvent.KIND;
import static story.TimeLineEvent.KIND_ACTOR_ANIMATION;
import static story.TimeLineEvent.KIND_ACTOR_CONTROLL;
import static story.TimeLineEvent.KIND_ACTOR_DEACCELERATE;
import static story.TimeLineEvent.KIND_ACTOR_EMOTION;
import static story.TimeLineEvent.KIND_ACTOR_HIDE;
import static story.TimeLineEvent.KIND_ACTOR_LOOK_TO;
import static story.TimeLineEvent.KIND_ACTOR_MOVE_DIST;
import static story.TimeLineEvent.KIND_ACTOR_MOVE_STOP;
import static story.TimeLineEvent.KIND_ACTOR_MOVE_TO;
import static story.TimeLineEvent.KIND_ACTOR_MOVE_TO_RELATIVE;
import static story.TimeLineEvent.KIND_ACTOR_QUEUE_MOVE;
import static story.TimeLineEvent.KIND_ACTOR_RESET_VILLAGER;
import static story.TimeLineEvent.KIND_ACTOR_SHOW;
import static story.TimeLineEvent.KIND_ADD_SPRITE_ON_BOTTOM_LAYER;
import static story.TimeLineEvent.KIND_ADD_SPRITE_ON_TOP_LAYER;
import static story.TimeLineEvent.KIND_CURE_ALL;
import static story.TimeLineEvent.KIND_END;
import static story.TimeLineEvent.KIND_END_SEQ;
import static story.TimeLineEvent.KIND_FADE_PARTICLE_SYSTEM;
import static story.TimeLineEvent.KIND_IMAGE;
import static story.TimeLineEvent.KIND_LEVEL_UP;
import static story.TimeLineEvent.KIND_MUSIC;
import static story.TimeLineEvent.KIND_MUSIC_OVERWRITE_VILLAGE_MUSIC;
import static story.TimeLineEvent.KIND_MUSIC_OVERWRITE_STORY_MUSIC;
import static story.TimeLineEvent.KIND_REMOVE;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_CENTER;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_DIST;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_GO;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_POS;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_STOP;
import static story.TimeLineEvent.KIND_SCREEN_MOVE_TO;
import static story.TimeLineEvent.KIND_SCREEN_ZOOM;
import static story.TimeLineEvent.KIND_SCROLL_TEXT;
import static story.TimeLineEvent.KIND_SET_COLOR;
import static story.TimeLineEvent.KIND_SET_DRAW_PAUSE;
import static story.TimeLineEvent.KIND_SET_FADE_IMAGE;
import static story.TimeLineEvent.KIND_SET_VILLAGE_BACKGROUND;
import static story.TimeLineEvent.KIND_TEXT;
import static story.TimeLineEvent.KIND_TRIGGER;
import static story.TimeLineEvent.KIND_TRIGGER_INN;
import static story.TimeLineEvent.KIND_VILLAGE;
import static story.TimeLineEvent.MOVE_ACCELERATION;
import static story.TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION;
import static story.TimeLineEvent.MOVE_DIRECTION;
import static story.TimeLineEvent.MOVE_DISTANCE;
import static story.TimeLineEvent.MOVE_DURATION;
import static story.TimeLineEvent.MOVE_X;
import static story.TimeLineEvent.MOVE_Y;
import static story.TimeLineEvent.MUSICS;
import static story.TimeLineEvent.PLAY_MODE;
import static story.TimeLineEvent.POS_X;
import static story.TimeLineEvent.POS_Y;
import static story.TimeLineEvent.SHOW_CURRENT_IMAGE;
import static story.TimeLineEvent.TIME_OF_DAY;
import static story.TimeLineEvent.TYPE_FADE_IN;
import factories.Load;
import graphics.DoubleBackground;
import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import info.Database;
import info.Values;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.concurrent.Semaphore;

import java.util.logging.*;
import organizer.GameMode;
import organizer.Organizer;

import sound.OggStreamer;
import sound.SoundPlayer;
import sound.SoundValues;
import sprite.DefaultSprite;
import sprite.Sprite;
import villages.Village;
import villages.Villager;
import villages.utils.AnimatedObjects;
import villages.utils.Dialog;
import villages.utils.PartyMember;
import villages.utils.Player;
import villages.utils.SortingElement;
import villages.villageStory.Actor;
import villages.villageStory.DialogPackage;
import villages.villageStory.VillageStory;
import villages.villageStory.VillageStoryLoader;
import bodies.system.ParticleSystem;
import bodies.system.SystemLoader;
import character.Character;

/**
 * This time line is used in story modes like when the characters in the
 * game are talking to villagers. All the sprites is turned into actors
 * and their instructions is executed and updated by the time line.  
 * 
 * @author 		Kalle Sjöström.
 * @version 	0.7.0 - 04 Oct 2008
 */
public class VillageStoryTimeLine extends AbstractTimeLine {
	
	private static final int VILLAGE_MODE = 0;
	private static final int BACKFLASH_MODE = 1;
	private static final int STORY_MODE = 2;
	private static final int TRANSLUCENT_MODE_OVER_ACTOR = 3;
	private static final int COVERALL_MODE = 4;
	private static final int TRANSLUCENT_MODE_UNDER_ACTOR = 5;

	private ArrayList<Actor> members = 
		new ArrayList<Actor>();
	private ArrayList<DialogPackage> dialogs;
	private ArrayList<Sprite> removedVillagers = 
		new ArrayList<Sprite>();
	private ArrayList<Text> textList;
	private ScrollableTexts scrollableText;
	private HashMap<String, int[]> positions;
	private HashMap<Integer, ArrayList<String>> infoList;
	private Dialog dialog = Dialog.getDialog();
	private Text currentText;
	private VillageStory story;
	private SortingElement[] elements;
	private DoubleBackground background;
	private ImageSettings currentImage;
	private OggStreamer[] oggPlayers;
	private Semaphore crossAccess = new Semaphore(1);
	private int imageMode = -1;
	private int currentDialog = -1;
	private boolean[] showing;
	private boolean playersAdded;
	private boolean centerScreen = true;
	private int centerScreenIndex = -1;
	private boolean fromVillage;
	private Logger logger = Logger.getLogger("VillageStoryTimeLine");
	
	
	/**
	 * Creates a time line from the given story loader. This loader contains
	 * the actors, positions, dialogs and so on for the story sequence. 
	 * 
	 * @param vsl the story loader containing the information 
	 * for the time line.
	 * @param village the village where the story is executed.
	 */
	public VillageStoryTimeLine(VillageStoryLoader vsl, Village village) {
		DefaultSprite.reset();
		infoList = vsl.getInfo();
		textList = vsl.getTextList();
		scrollableText = vsl.getScrollableText();
		positions = vsl.getPoses();
		fromVillage = vsl.getFromVillage();
		logger.log(Level.FINE, "From village " + fromVillage);
		dialogs = vsl.getDialogs();
		drawPause = vsl.shouldPauseDrawings();
		setTimeLineEvents(vsl);
		showing = vsl.getWhoseShowing();
		nextInitTime = dialogs.size() > 0 ? dialogs.get(0).getStartTime() : 0;
		nextStopTime = dialogs.size() > 0 ? dialogs.get(0).getStopTime() : 0;
		background = village.getBackground();
		
		setMode(WAITING_FOR_ACTORS);
		fadein = fadeout = false;
		fadeValue = 1;
		ArrayList<String> music = infoList.get(MUSICS);
		if (music != null && music.size() > 0) {
			oggPlayers = new OggStreamer[infoList.get(MUSICS).size()];
		}
	}

	private void setTimeLineEvents(VillageStoryLoader vsl) {
		info = vsl.getTimeLineEvents();
		TimeLineEvent[] evs = new TimeLineEvent[info.size()];
		info.toArray(evs);
		Arrays.sort(evs);
		info.clear();
		info.addAll(Arrays.asList(evs));		
	}

	/**
	 * This method initiates the time line based on the information in 
	 * the given story.
	 * 
	 * @param story the story to base the time line on.
	 */
	public void init(VillageStory story) {
		this.story = story;
		elements = new SortingElement[members.size()];
		for (int i = 0; i < members.size(); i++) {
			elements[i] = new SortingElement(members.get(i).getPos()[Values.Y], i);
		}
	}

	/**
	 * Converts all the characters in the player party to actors
	 * and initiates their starting positions. 
	 * 
	 * @param player the player object containing all the party members.
	 * @param fromVillage true if the story is initiated from a village.
	 */
	public void setParty(Player player, boolean fromVillage) {
		ArrayList<PartyMember> pmlist = player.getPartyMembers();
		int size = members.size();
		ArrayList<Character> list = Load.getCharacters();
		if (pmlist.size() < list.size()) {
			for (Character c : list) {
				boolean found = false;
				String name = c.getName();
				for (int i = 0; i < pmlist.size() && !found; i++) {
					found = pmlist.get(i).getName().equalsIgnoreCase(name);
				}
				if (!found) {
					pmlist.add(new PartyMember(name));
				}
			}
		}
		for (int i = 0; i < pmlist.size(); i++) {
			PartyMember pm = pmlist.get(i);
			pm.setPos(pm.getPosAsFloatArray());
			ArrayList<String> actors = infoList.get(TimeLineEvent.ACTORS);
			boolean found = false;
			for (int j = 0; j < actors.size() && !found; j++) {
				found = actors.get(j).equals(pm.getName());
			}
			if (found) {
				Actor a = new Actor(pm);
				int[] pos = positions.get(pm.getName());
				if (pos != null) {
					if (this.fromVillage) {
						float[] newPos = new float[2];
						newPos[Values.X] = pos[Values.X];
						newPos[Values.Y] = pos[Values.Y];
						a.setPos(newPos);
					} else if (!fromVillage) {
						float[] newPos = new float[2];
						newPos[Values.X] = pos[Values.X] + 40;
						newPos[Values.Y] = pos[Values.Y] + 40;
						a.setPos(newPos);
					}
				}
				if (centerScreenIndex == -1) {
					centerScreenIndex = members.size();
				}
				members.add(a);
			}
		}
		for (int i = 0; i < members.size(); i++) {
			Actor a = members.get(i);
			String name = a.getName();
			int[] pos = positions.get(name);
			a.initStartLocation(pos, members);
		}
		playersAdded = members.size() > size;
		int[] pos = positions.get("Background");
		if (pos != null) {
			background.setPos(0, -pos[0]);
			background.setPos(1, -pos[1]);
		} else if (playersAdded) {
			background.centerAround(getPos(centerScreenIndex));
		}
	}

	/**
	 * Adds any extra actors to this story.
	 */
	private void addExtras() {
		ArrayList<String> actors = infoList.get(TimeLineEvent.ACTORS);
		for (int i = 0; i < actors.size(); i++) {
			if (actors.get(i).contains("Extras")) {
				String name = actors.get(i);
				int[] p = positions.get(name);
				String[] n = name.split("Extras");
				int images = 16;
				if (n.length > 1) {
					images = Integer.parseInt(n[1]);
				}
				name = n[0];
				if (name.contains("Prop")) {
					name = name.replace("Prop", "");
				}
				Actor a = new Actor(name, images);
				if (p != null) {
					a.setPos(p);
				}
				members.add(a);
			}
		}
	}

	private void addParticleSystem() {
		ArrayList<String> actors = infoList.get(TimeLineEvent.ACTORS);
		for (int i = 0; i < actors.size(); i++) {
			if (actors.get(i).contains("System")) {
				String name = actors.get(i);
				SystemLoader sl = SystemLoader.getLoader();
				ArrayList<ParticleSystem> system = sl.buildSystem(Organizer.convert(name));
				
				int[] p = positions.get(name);
				Actor a = new Actor(system.get(0));
				if (p != null) {
					a.setPos(p);
				}
				members.add(a);
			}
		}
	}

	/**
	 * This method checks the villagers in the given map to see if any of them
	 * is listed as actors in the story. Those who are listed will be converted
	 * to actors and stored in a separate list so that they can be added back 
	 * to the village list of villagers when the story is done.
	 * 
	 * @param villagers a map of villagers containing at least those villagers 
	 * that should be actors in this story. It's perfectly ok for the map to 
	 * contain more than the actors for the story. For example, it is all right
	 * to call this method with all the villagers in a village and let this 
	 * method sort out the needed actors.  
	 */
	public void setVillagers(HashMap<Integer, Sprite> villagers) {
		ArrayList<Integer> remove = new ArrayList<Integer>();
		
		ArrayList<String> actors = infoList.get(TimeLineEvent.ACTORS);
		for (int i = 0; i < actors.size(); i++) {
			String actorName = actors.get(i).replace("_", " ");
			Iterator<Integer> it = villagers.keySet().iterator();
			while (it.hasNext()) {
				int index = it.next();
				Sprite as = villagers.get(index);
				if (as instanceof Villager) {
					Villager v = (Villager) as;
					if (actorName.startsWith(v.getName())) {
						members.add(new Actor(v));
						remove.add(index);
						break;
					}
				}
			}
		}
		actors = infoList.get(TimeLineEvent.ACTORS);
		Iterator<Integer> it = villagers.keySet().iterator();
		while (it.hasNext()) {
			int index = it.next();
			Sprite as = villagers.get(index);
			if (as instanceof AnimatedObjects) {
				boolean found = false;
				for (int i = 0; i < actors.size() && !found; i++) {
					if (found = actors.get(i).equals("Anim")) {
						actors.remove(i);
						members.add(new Actor(as));
						remove.add(index);
					}
				}
			}
		}
		for (int i = 0; i < remove.size(); i++) {
			removedVillagers.add(villagers.remove(remove.get(i)));
		}
		addExtras();
		addParticleSystem();
	}

	/**
	 * Updates this time line.
	 * 
	 * @param time the amount of time that has elapsed since this method 
	 * was last called.
	 */
	public synchronized void update(int elapsedTime) {
		if (scrollText != null) {
			scrollText.update(elapsedTime);
		}
		if (doneMode != ALL_DONE) {
			super.update(elapsedTime);
			if (currentImage != null) {
				currentImage.update();
			}
			if (centerScreen) {
				centerScreen(centerScreenIndex);
			}
			boolean wait = checkWait(elapsedTime);
			if (wait && compareMode(WAITING_FOR_ACTORS)) {
				setMode(NORMAL);
			} else if (doneMode == INPUT_DONE) {
				boolean end = !compareMode(WAITING_FOR_ACTORS);
				if (end && centerScreen) {
					end = centerScreen(-1);
				}
				if (end) {
					story.end(getPos(-1), removedVillagers, playersAdded);
					doneMode = ALL_DONE;
				}
				return;
			}
			background.update(elapsedTime);
		}
		if (scaling) {
			float t2 = timeStep * timeStep;
			if (x <= timeStep) {
				velocity = 4*x*((1f/timeStep) - (x/t2));
				float max = 2*timeStep - (4f/3f)*timeStep;
				x++;
				scale2 += velocity;
				scale = in ? scale2/max + 1 : 2 - scale2/max;
			}
		}
		if (!drawPause) {
			updateFadeValue();
			if (currentText != null) {
//				if (bFadeUp) {
//					fadeValue += bFadeSpeed;
//					if (fadeValue >= 1) {
//						bFadeUp = false;
//						fadeValue = 1;
//					}
//				} else if (bFadeDown) {
//					fadeValue += bFadeSpeed;
//					if (fadeValue <= bFadeTarget) {
//						bFadeDown = false;
//						fadeValue = bFadeTarget;
//					}
//				}
				if (fadeValue != bFadeTarget) {
				}
				currentText.updateFadeValue();
			}
		}
	}
	
	private boolean scaling = false;
	private float velocity = 0;
	private float scale = 1;
	private float scale2 = 0;
	private int x = 0;
	private float timeStep;
	private boolean in;
	private float[] staticPos;
	private boolean useStaticPos;
	private float bFadeTarget;
	private float bFadeSpeed;
	private boolean bFadeDown;
	private boolean bFadeUp;
	private ScrollableTexts scrollText;
	
	private void setScaling(int time, boolean in, boolean useStaticPos, float[] pos) {
		scaling = true;
		velocity = 0;
		scale2 = 0;
		x = 0;
		timeStep = time / Values.LOGIC_INTERVAL;
		staticPos = pos;
		this.useStaticPos = useStaticPos;
		this.in = in;
	}
	
	/**
	 * Initializes the given time line event.
	 * 
	 * @param event the time line event to initialize.
	 */
	@SuppressWarnings("fallthrough")
	protected void executeCommand(TimeLineEvent event) {
		int index = event.getInfo(INDEX);
		int kind = event.getInfo(KIND);
		switch(kind) {
		case KIND_IMAGE :
			switch (event.getInfo(INFO_IMAGE_MODE)) {
			case IMAGE_MODE_BACKFLASH : imageMode = BACKFLASH_MODE; break;
			case IMAGE_MODE_TRANSLUCENT_UNDER_ACTOR : imageMode = TRANSLUCENT_MODE_UNDER_ACTOR; break;
			case IMAGE_MODE_TRANSLUCENT_OVER_ACTOR : imageMode = TRANSLUCENT_MODE_OVER_ACTOR; break;
			case IMAGE_MODE_COVERALL : imageMode = COVERALL_MODE; break;
			case IMAGE_MODE_STORY : imageMode = STORY_MODE; break;
			}
			initImageKind(event, index);
			break;
		case KIND_TEXT :
			currentText = textList.get(index);
			currentText.checkFade(event);
			bFadeTarget = event.getInfo(BACKGROUND_FADE_TARGET);
			bFadeTarget = bFadeTarget == 0 ? 100 : bFadeTarget;
			bFadeTarget /= 100;
			if (fadeValue < bFadeTarget) {
				bFadeUp = true;
				bFadeDown = false;
				bFadeSpeed = .02f;
			} else {
				bFadeUp = false;
				bFadeDown = true;
				bFadeSpeed = -.02f;
			}
			break;
		case KIND_SCROLL_TEXT :
			scrollText = scrollableText;
			break;
		case KIND_VILLAGE :
			imageMode = VILLAGE_MODE;
			checkFade(event);
			if (event.doesInfoExist(TIME_OF_DAY)) {
				int time = event.getInfo(TIME_OF_DAY);
				if (time != -1) {
					// Values.DAY = time == 1;
				}
			}
			if (event.getInfo(SHOW_CURRENT_IMAGE) == 0) {
				currentImage = null;
			}
			break;
		case KIND_MUSIC :
			initMusicKind(event, index);
			break;
		case KIND_MUSIC_OVERWRITE_VILLAGE_MUSIC :
			story.setOggplayerAsVillageCurrent(oggPlayers[index - 1]);
			break;
		case KIND_MUSIC_OVERWRITE_STORY_MUSIC :
			story.setOggplayerAsStoryCurrent(oggPlayers[index - 1]);
			break;
		case KIND_END_SEQ :
			playersAdded = false;
			// No break, because KIND_END should be run also.
		case KIND_END :
			doneMode = TIME_LINE_DONE;
			setMode(WAITING_FOR_INPUT);
			updateCross();
			break;
		case KIND_TRIGGER :
			ArrayList<String> list = infoList.get(TimeLineEvent.STORY_SEQUENCES);
			list = infoList.get(TimeLineEvent.TRIGGERS);
			String key = list.get(index);
			int value = event.getInfo(TimeLineEvent.TRIGGER_VALUE);
			Database.addStatus(key, value);
			boolean found = false;
			for (int i = 0; i < members.size() && !found; i++) {
				String name = members.get(i).getName();
				if (name != null && name.equals(key)) {
					found = true;
					members.get(i).updateDialog(value);
				}
			}
			if (!found) {
				GameMode gm = Organizer.getOrganizer().getPreviousMode();
				found = false;
				for (Sprite s : removedVillagers) {
					if (s instanceof Villager) {
						Villager v = (Villager) s;
						if (v.getName().equalsIgnoreCase(key)) {
							v.updateDialog(value);
							found = true;
						}
					}
				}
				if (!found) {
					if (gm instanceof Village) {
						Village v = (Village) gm;				
						v.updateVillagerDialog(key, value);
					}
				}
			}
			break;
		case KIND_TRIGGER_INN :
			list = infoList.get(TimeLineEvent.TRIGGERS);
			String innName = list.get(index);
			value = event.getInfo(TimeLineEvent.TRIGGER_VALUE);
			String sequenceName = list.get(value);
			Database.storeTriggers(innName, sequenceName);
			break;
		case KIND_SCREEN_MOVE_DIST :
			int distance = event.getInfo(MOVE_DISTANCE);
			int direction = event.getInfo(MOVE_DIRECTION);
			float duration = event.getInfo(MOVE_DURATION);
			direction = Values.getCounterAngle(direction);
			background.move(distance, direction, duration);
			break;
		case KIND_SCREEN_MOVE_TO :
			int x = -event.getInfo(MOVE_X);
			int y = -event.getInfo(MOVE_Y);
			duration = event.getInfo(MOVE_DURATION);
			background.moveTo(x, y, (int) duration);
			break;
		case KIND_SCREEN_MOVE_POS :
			float[] p = new float[2];
			p[Values.X] = event.getInfo(MOVE_X);
			p[Values.Y] = event.getInfo(MOVE_Y);
			if (p[0] == -1 && p[1] == -1) {
				p = members.get(event.getInfo(TimeLineEvent.TARGET)).getPos();
				background.centerAround(p);
			} else {
				background.setPos(Values.X, (int) -p[Values.X]);
				background.setPos(Values.Y, (int) -p[Values.Y]);
			}
			break;
		case KIND_SCREEN_MOVE_STOP :
			background.stopScreen();
			break;
		case KIND_SCREEN_MOVE_GO :
			float acceleration = event.getInfo(MOVE_ACCELERATION) / 1000000f;
			distance = event.getInfo(MOVE_DISTANCE);
			direction = event.getInfo(MOVE_DIRECTION);
			duration = event.getInfo(MOVE_DURATION);
			direction = Values.getCounterAngle(direction);
			background.moveScreen(acceleration, distance, duration, direction);
			break;
		case KIND_SCREEN_MOVE_CENTER :
			centerScreenIndex = index;
			centerScreen = event.getInfo(TimeLineEvent.CENTER_SCREEN) == 1;
			break;
		case KIND_SCREEN_ZOOM :
			boolean in = event.getInfo(TimeLineEvent.SCREEN_ZOOM_IN) == 1;
			int time = event.getInfo(TimeLineEvent.SCREEN_ZOOM_TIME);
			boolean staticPos = event.getInfo(TimeLineEvent.SCREEN_ZOOM_USE_STATIC_POS) == 1;
			p = new float[2];
			p[Values.X] = event.getInfo(POS_X);
			p[Values.Y] = event.getInfo(POS_Y);
			setScaling(time, in, staticPos, p);
			break;
		case KIND_ACTOR_SHOW : 
			showing[index] = true;
			p = new float[2];
			p[Values.X] = event.getInfo(MOVE_X);
			p[Values.Y] = event.getInfo(MOVE_Y);
			Actor actor = members.get(index);
			if (!(p[0] == -1 && p[1] == -1)) {
				actor.setPos(p);
			}
			int dir = event.getInfo(MOVE_DIRECTION);
			if (dir != -1) {
				actor.setMoving(true);
				actor.stop(dir);
			}
			break;
		case KIND_ACTOR_HIDE : 
			showing[index] = false;
			break;
		case KIND_ACTOR_MOVE_TO_RELATIVE :
			x = event.getInfo(MOVE_X);
			y = event.getInfo(MOVE_Y);
			duration = event.getInfo(MOVE_DURATION);
			members.get(index).moveToRel(x, y, duration);
			break;
		case KIND_ACTOR_MOVE_DIST :
			direction = event.getInfo(MOVE_DIRECTION);
			int faceDirection = event.getInfo(MOVE_ACTOR_FACE_DIRECTION);
			distance = event.getInfo(MOVE_DISTANCE);
			duration = event.getInfo(MOVE_DURATION);
			members.get(index).move(distance, direction, faceDirection, duration);
			break;
		case KIND_ACTOR_MOVE_TO :
			x = event.getInfo(MOVE_X);
			y = event.getInfo(MOVE_Y);
			if (x == -1) {
				int target = event.getInfo(TimeLineEvent.TARGET);
				float[] posf = members.get(target).getPos(); 
				x = (int) posf[Values.X];
				y = (int) posf[Values.Y];
			}
			duration = event.getInfo(MOVE_DURATION);
			if (duration == -1) {
				float speed = event.getInfo(TimeLineEvent.MOVE_SPEED) / 10000f;
				members.get(index).moveToWithSpeed(x, y, speed);
			} else {
				members.get(index).moveTo(x, y, duration);
			}
			break;
		case KIND_ACTOR_MOVE_STOP :
			direction = event.getInfo(MOVE_DIRECTION);
			members.get(index).stop(direction);
			break;
		case KIND_ACTOR_DEACCELERATE :
			members.get(index).deaccelerateActor();
			break;
		case KIND_ACTOR_LOOK_TO :
			x = event.getInfo(POS_X);
			y = event.getInfo(POS_Y);
			if (x == -1) {
				int target = event.getInfo(TimeLineEvent.TARGET);
				float[] posf = members.get(target).getPos(); 
				x = (int) posf[Values.X];
				y = (int) posf[Values.Y];
			}
			members.get(index).lookTo(x, y);
			break;
		case KIND_ACTOR_QUEUE_MOVE :
			distance = event.getInfo(MOVE_DISTANCE);
			direction = event.getInfo(MOVE_DIRECTION);
			duration = event.getInfo(MOVE_DURATION);
			members.get(index).queueMove(distance, direction, duration);
			break;
		case KIND_ACTOR_ANIMATION :
			list = infoList.get(TimeLineEvent.ANIMATIONS);
			String name = list.get(index);
			name = Values.AnimationImages + name + ".png";
			
			int actorIndex = event.getInfo(TimeLineEvent.TARGET);
			actor = members.get(actorIndex);
			
			int pos = event.getInfo(TimeLineEvent.ANIMATION_INDEX);
			actor.addAnimation(name, pos);
			actor.animate(pos);
			break;
		case KIND_ACTOR_EMOTION :
			int emotion = event.getInfo(EMOTION);
			boolean show = event.getInfo(EMOTION_SHOW) == 1;
			boolean shake = event.getInfo(EMOTION_SHAKE) == 1;
			members.get(index).setEmotion(show, emotion, shake);
			break;
		case KIND_ACTOR_CONTROLL :
			members.get(index).setControll(event.getInfo(ACTOR_CONTROLL) == 1);
			break;
		case KIND_ACTOR_RESET_VILLAGER :
			members.get(index).resetVillager();
			break;
		case KIND_SET_COLOR :
			color[index] = event.getInfo(COLOR) / 10000f;
			colorSpeed[index] = event.getInfo(COLOR_SPEED) / 10000f;
			break;
		case KIND_SET_VILLAGE_BACKGROUND :
			ArrayList<String> images = infoList.get(IMAGES);
			String newBack = index < 0 ? null : images.get(index);
			village.setBackground(newBack);
			break;
		case KIND_SET_FADE_IMAGE :
			Graphics.setFadeImage(event.getInfo(FADE_IMAGE));
			break;
		case KIND_SET_DRAW_PAUSE :
			drawPause = index == 1;	
			break;
		case KIND_REMOVE :
			removedVillagers.remove(index);
			break;
		case KIND_LEVEL_UP :
			ArrayList<Character> chars = Load.getCharacters();
			for (int i = 0; i < chars.size(); i++) {
				chars.get(i).levelUp();
			}
			break;
		case KIND_CURE_ALL :
			chars = Load.getCharacters();
			for (int i = 0; i < chars.size(); i++) {
				chars.get(i).cureFromDead();
				chars.get(i).curePercent(1);
			}
			break;
		case KIND_ADD_SPRITE_ON_BOTTOM_LAYER :
			Sprite s = members.get(index).getSprite();
			if (s instanceof DefaultSprite) {
				((DefaultSprite) s).placeOnBottomLevel();
				village.addSprite(s);
			}
			break;
		case KIND_ADD_SPRITE_ON_TOP_LAYER :
			s = members.get(index).getSprite();
			if (s instanceof DefaultSprite) {
				((DefaultSprite) s).placeOnTopLevel();
				village.addSprite(s);
			}
			break;
		case KIND_FADE_PARTICLE_SYSTEM :
			list = infoList.get(TimeLineEvent.PARTICLE_SYSTEMS);
			name = list.get(index);
			ParticleSystem ps = village.getParticleSystem(name);
			boolean fade = event.isFade();
			boolean increase = event.getType() == TimeLineEvent.TYPE_FADE_OUT;
			float speed = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_SPEED) / 10000f;
			float swiftness = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_SWIFTNESS) / 10000f;
			float cutoff = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_CUTOFF) / 10000f;
			
			ps.getEmitter().setFade(
					fade, speed, swiftness, increase, cutoff);
			break;
		}
	}

	/**
	 * Initiates the music event. The given index is the index of the declared
	 * music information.
	 * 
	 * @param event the time line event. This must be of a music kind.
	 * @param index the index of the music information.
	 */
	private void initMusicKind(TimeLineEvent event, int index) {
		ArrayList<String> music = infoList.get(MUSICS);
		logger.log(Level.FINE, "Init music kind " + music + " " + event.isFade());
		int fade = 0;
		if (event.isFade()) {
			boolean fadeIn = event.getType() == TYPE_FADE_IN;
			fade = fadeIn ? SoundValues.FADE_IN : SoundValues.FADE_OUT;
		}
		final int time = event.getInfo(FADE_TIME);
		final int playMode = event.getInfo(PLAY_MODE);
		int fadeTarget = event.getInfo(FADE_TARGET);
		fadeTarget = fadeTarget == 0 ? 100 : fadeTarget;
		logger.log(Level.FINE, "Time " + time + " " + playMode);
		
		if (index == 0) {
			story.setMusicMode(
					fade, time, (fadeTarget / 100f) * Values.MAX_VOLUME, playMode);
		} else {
			String songName = music.get(index - 1);
			logger.log(Level.FINE, "Song name " + songName);
			setMusicMode(songName, fade, time, playMode, index - 1);
		}
	}

	/**
	 * This method changes the music of the story.
	 * 
	 * @param songName the name of the music to play.
	 * @param fade the fade mode. This is either SoundValues.FADE_IN 
	 * or .FADE_OUT.
	 * @param time the amount of time in milliseconds to fade.
	 * @param playMode the playing mode. This is either SoundValues.RESUME,
	 * .SoundValues.NORMAL or SoundValues.PAUSE.
	 * @param index 
	 */
	private void setMusicMode(final String songName, 
			final int fade, final int time, final int playMode, final int index) {
		if (songName.endsWith(".wav")) {
			SoundPlayer.playSound("Story/" + songName);
		} else {
			if (oggPlayers[index] == null) {
				new Thread() {
					public void run() {
						oggPlayers[index] = new OggStreamer(songName);
						oggPlayers[index].play(false, playMode == SoundValues.NORMAL || playMode == SoundValues.RESUME_PLAY);
						oggPlayers[index].fade(fade, time, SoundValues.ALL_THE_WAY, playMode);
					}
				}.start();
			} else {
				oggPlayers[index].fade(fade, time, SoundValues.allTheWay(fade), playMode);
			}
		}
	}

	/**
	 * Initiates the next image mode. The image list containing the
	 * image to be initiated is gotten from the story loader given
	 * in the constructor.
	 * 
	 * @param info the information about the image mode. 
	 * @param index the index of image in the image list.
	 */
	private void initImageKind(TimeLineEvent info, int index) {
		checkFade(info);
		ArrayList<String> images = infoList.get(IMAGES);
		String name = images.get(index);
		boolean found = false;
		if (currentImage != null) {
			if (name.equals(currentImage.name)) {
				currentImage.init(info);
				found = true;
			}
		}
		if (!found) {
			currentImage = new ImageSettings(name, info);
		}
	}

	/**
	 * Checks all the actors on the time line. This method updates all of them
	 * if they are showing and checks if they are waiting and if their 
	 * instructions are done. The returned value is true if ALL the actors is 
	 * waiting. 
	 * 
	 * @param time the amount of time that has elapsed since the last
	 * call to this method.
	 * @return true if all the actors are waiting. 
	 */
	private boolean checkWait(int time) {	
		boolean wait = true;
		for (int i = 0; i < members.size(); i++) {
			if (showing[i]) {
				Actor actor = members.get(i);
				actor.update(time);
				if (wait) {
					wait = actor.isWaiting();
				}
			}
		}
		return wait;
	}

	/**
	 * Initiates the next event on the time line.
	 */
	protected void setNextStartTime() {
		currentDialog++;
		if (currentDialog < dialogs.size()) {
			dialog.setDS(dialogs.get(currentDialog).getSequense(), null);
			setMode(DIALOG);
			nextStopTime = dialogs.get(currentDialog).getStopTime();
			if (currentDialog + 1 < dialogs.size()) {
				nextInitTime = dialogs.get(currentDialog + 1).getStartTime();
			}
		} else {
			nextInitTime = Integer.MAX_VALUE;
		}
	}

	/**
	 * Sets the next stop time, the time that the next event should stop.
	 */
	protected void setNextStopTime() {
		if (currentDialog + 1 < dialogs.size()) {
			nextStopTime = dialogs.get(currentDialog + 1).getStopTime();
			/*if (compareMode(NORMAL)) {
				setMode(WAITING_FOR_ACTORS);
			} else*/ if (compareMode(DIALOG)) {
				setMode(WAITING_FOR_INPUT);
			}
		} else {
			if (compareMode(DIALOG)) {
				setMode(WAITING_FOR_INPUT);
			}
			nextStopTime = Integer.MAX_VALUE;
		}
	}

	/**
	 * This method draws the actors in the sequence. It uses an 
	 * array of SortingElements to sort the actors yPos value to
	 * make sure that the villagers are drawn in the correct order.
	 * 
	 * @param g the graphics to draw on.
	 * @param village the village where this story takes place.
	 */
	float[] color = new float[]{1, 1, 1, 1};
	float[] colorSpeed = new float[4];
	private Village village;
	private boolean drawPause = false;
	
	public synchronized void draw(Graphics g) {
		updateFadeValue();
		if (currentText != null) {
			currentText.updateFadeValue();
		}
		if (scaling && useStaticPos) {
			g.translate(staticPos[Values.X], staticPos[Values.Y], 0);
			g.scale(scale);
			g.translate(-staticPos[Values.X], -staticPos[Values.Y], 0);
		}
		if (!drawPause) {
			for (int i = 0; i < color.length; i++) {
				if (colorSpeed[i] < 0 && color[i] > 0) {
					color[i] += colorSpeed[i];
				} else if (colorSpeed[i] > 0 && color[i] < 1) {
					color[i] += colorSpeed[i];
				}
			}
			
			// g.setFadeColor(color[0], color[1], color[2], color[3]);
			village.drawBottom(g);
			if (imageMode == BACKFLASH_MODE) {
				if (currentImage != null && currentImage.equals("black")) {
					g.fadeOldSchool(0);
				} else if (currentImage != null) {
					currentImage.draw(g);
				}
			}
			int x = (int) background.getPos()[Values.X];
			int y = (int) background.getPos()[Values.Y];
		
			for (int i = 0; i < members.size(); i++) {
				Actor actor = members.get(i);
				if (actor.getSprite() instanceof DefaultSprite) {
					elements[i].setYpos(actor.getSprite().getY());
				} else {
					elements[i].setYpos(actor.getPos()[Values.Y]);
				}
				elements[i].setIndex(i);
			}
			if (imageMode == TRANSLUCENT_MODE_UNDER_ACTOR) {
				g.setColor(1, 1, 1, fadeValue);
				currentImage.draw(g);
				g.setColor(1);
			}
			Arrays.sort(elements);
			for (int i = 0; i < elements.length; i++) {
				int index = elements[i].getIndex();
				if (showing[index]) {
					Actor actor = members.get(index);
					actor.draw(g, x, y);
				}
			}

			if (imageMode != BACKFLASH_MODE) {
				village.drawTop(g, null);
			}
			for (int i = 0; i < members.size(); i++) {
				members.get(i).drawEmotion(g);
			}
			drawTop(g);
		}
	}

	/**
	 * Draws the top layer of this time line. This means drawing the
	 * dialog if a dialog should be displayed.
	 * 
	 * @param g the graphics to draw on.
	 */
	public void drawTop(Graphics g) {
		if (imageMode == COVERALL_MODE) {
			currentImage.draw(g);
		}
		if (imageMode == STORY_MODE) {
			currentImage.draw(g);
			currentImage.drawTextBack(g);
		}
		g.setFontSize(30);
		if (imageMode == VILLAGE_MODE && currentImage != null) {
			g.setColor(1);
			currentImage.draw(g);
			g.setColor(1);
		}
		if (compareMode(DIALOG) || compareMode(WAITING_FOR_INPUT))  {
			g.loadIdentity();
			dialog.draw(g);
		}
		if (fadeValue < 1 && 
				imageMode != TRANSLUCENT_MODE_OVER_ACTOR && 
				imageMode != TRANSLUCENT_MODE_UNDER_ACTOR) {
			g.fadeOldSchool(fadeValue);
		}
		if (currentText != null) {
			currentText.draw(g);
		}
		if (scrollText != null) {
			scrollText.draw(g);
		}
		if (imageMode == TRANSLUCENT_MODE_OVER_ACTOR) {
			g.setColor(1, 1, 1, fadeValue);
			currentImage.draw(g);
			g.setColor(1);
		}
	}
	
	/**
	 * Centers the screen around the players.
	 * 
	 * @param index    
	 * @return true if screen is centered.
	 */
	private boolean centerScreen(int index) {
		float[] p = getPos(index);
		if (p != null) {
			boolean[] done = new boolean[2];
			int hx = Values.ORIGINAL_RESOLUTION[Values.X] / 2;
			int hy = Values.ORIGINAL_RESOLUTION[Values.Y] / 2;
			for (int i = 0; i < 2; i++) {
				int gubbe = (int) (p[i] + background.getPos()[i]);
				int half = i == Values.X ? hx : hy;
				if (gubbe > half && !background.checkUpRight(i)) {
					background.move(i, -1);
				} else if (gubbe < half && !background.checkDownLeft(i)) {
					background.move(i, 1);
				} else {
					done[i] = true;
				}
			}
			return done[0] && done[1];
		}
		return true;
	}

	/**
	 * Gets the position of the main character in the player party.
	 * This is Kin in this case.
	 * 
	 * @param index the index of the member to get (in list members) or -1 if
	 * it should get the first playable character in the list (Kin). 
	 * @return the position of the actor with the given index.
	 */
	public float[] getPos(int index) {
		if (index == -1) {
			int size = Load.getCharacters().size();
			index = members.size() - size;
		}
		if (index >= 0) {
			Actor a = members.get(index);
			if (a != null) {
				return a.getPos();
			}
		}
		return null;
	}

	/**
	 * This method is called when the cross button is pressed.
	 * It will only have effect if a dialog is currently showing or
	 * if the time line is waiting for input for some other reason.
	 */
	public void crossPressed() {
		if (compareMode(DIALOG) || compareMode(WAITING_FOR_INPUT)) {
			if (dialog.isFinished()) {
				updateCross();
			}
		}
	}

	/**
	 * This method is called when the cross button is pressed and the time line
	 * is waiting for input. Depending on which mode the time line is in, 
	 * different actions is taken.
	 */
	private void updateCross() {
		acquire();
		if (compareMode(WAITING_FOR_INPUT)) {
			if (doneMode == TIME_LINE_DONE) {
				if (playersAdded) {
					float[] pos = getPos(-1);
					String charName;
					Actor a;
					ArrayList<Character> characters = Load.getCharacters();
					for (int i = 0; i < members.size(); i++) {
						boolean found = false;
						a = members.get(i);
						for (int j = 0; j < characters.size(); j++) {
							charName = characters.get(j).getName();
							if (charName.equals(a.getName())) {
								found = true;
								a.createStopInstructions(pos);
							}
						}
						if (!found) {
							//a.createStopInstructions(new float[]{0, 0});
							logger.log(Level.WARNING, "Couldn't find character " + a.getName());
						}
					}
				}
				setMode(WAITING_FOR_ACTORS);
				doneMode = INPUT_DONE;
				// centerScreen = true; //FIXME Previously false and uncommented
			} else {
				//setMode(WAITING_FOR_ACTORS);
				setMode(NORMAL);
			}
		} else if (compareMode(DIALOG)) {
			setMode(NORMAL);
		}
		crossAccess.release();
	}

	/**
	 * Acquires the cross press semaphore.
	 */
	private void acquire() {
		try {
			crossAccess.acquire();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	public void killOggPlayer() {
		if (oggPlayers != null) {
			for (int i = 0; i < oggPlayers.length; i++) {
				if (oggPlayers[i] != null) {
					oggPlayers[i].exit();
				}
			}
		}
	}

	public void setVillage(Village village) {
		this.village = village;
	}
	
	private class ImageSettings {
		public boolean scrollingRight;
		public boolean scrollingDown;
		
		public float scroll;
		public float scrollDownMax;
		public float scrollDownMin;
		public float offsetx;
		public float offsety;
		public float zoom = 1;
		public float size = 1;
		public String name;
		public int width;
		public int height;
		private float scrollSpeed;
		private int[] pos;
		
		public ImageSettings(String name, TimeLineEvent info) {
			this.name = name;
			init(info);
		}
	
		public void init(TimeLineEvent info) {
			int tSize = info.getInfo(TimeLineEvent.SIZE);
			if (tSize != 0) {
				size = tSize / 100f;
			}
			int imageKind = info.getInfo(TimeLineEvent.INFO_IMAGE_SCROLL_MODE);
			pos = new int[]{info.getInfo(TimeLineEvent.MOVE_X), info.getInfo(TimeLineEvent.MOVE_Y)};
			GameTexture tex = ImageHandler.getTexture(name);
			scrollSpeed = info.getInfo(TimeLineEvent.INFO_IMAGE_SCROLL_SPEED) / 10000f;
			float tempScroll = scroll;
			width = tex.getWidth();
			height = (int) (tex.getHeight() * size);
//			if (!fadeout) {
//				scroll = 0;
//				zoom = 1;
//				offsetx = 0;
//				offsety = 0;
//			}
			switch (imageKind) {
			case TimeLineEvent.IMAGE_SCROLL_MODE_ZOOM : 
				zoom = 2f;
				offsetx = -270;// 512f;
				offsety = -80;//384;
				break;
			case TimeLineEvent.IMAGE_SCROLL_MODE_SCROLL_RIGHT :
				scrollingRight = true;
				scrollingDown = false; 
				break;
			case TimeLineEvent.IMAGE_SCROLL_MODE_NORMAL : 
				scrollingRight = scrollingDown = false; break;
			case TimeLineEvent.IMAGE_SCROLL_MODE_SCROLL_DOWN :
				scroll = 0;
				scrollDownMax = Math.abs(height) - Math.abs(Values.WIDE_SCREEN_HEIGHT);
				scrollingDown = !(scrollingRight = false); break;
			case TimeLineEvent.PAUSE :
				scroll = tempScroll; break;
			}
		}

		public void draw(Graphics g) {
			g.drawImage(name, pos[0], pos[1], size);
		}
			
		public void drawTextBack(Graphics g) {
			g.loadIdentity();
			g.drawImage(Graphics.textBack, 0, 576, 1, 1);
		}

		public void update() {
			zoom = zoom <= 1 ? 1 : zoom - .0007f * zoom;
			if (scrollingRight) {
				scroll -= scrollSpeed;
			} else if (currentImage.scrollingDown) {
				scroll = Math.min(scrollDownMax, scroll + scrollSpeed);
			}
			offsetx += offsetx >= 0 ? 0 : .3f;
			offsety += offsety >= 0 ? 0 : .084375; // (72 / 256) * .3f
		}
	}
}
