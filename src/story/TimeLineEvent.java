/*
 * Classname: TimeLineEvent.java
 * 
 * Version information: 0.7.0
 *
 * Date: 05/10/2008
 */
package story;

import java.util.Arrays;
import java.util.StringTokenizer;

/**
 * This class contains information concerning a time line event. An event
 * is a point on a time line where an event takes place. An event could be
 * an image fading in, an image scrolling, zooming or something like that.
 * 
 * @author 		Kalle Sjöström.
 * @version 	0.7.0 - 05 Oct 2008
 */
public class TimeLineEvent implements Comparable<TimeLineEvent> {
	
	public static final int TYPE = 0;
	public static final int TIME = 1;
	public static final int INDEX = 2;
	public static final int FADE_TIME = 3;
	public static final int KIND = 4;

	public static final int TYPE_NO_FADE = 0;
	public static final int TYPE_FADE_IN = 1;
	public static final int TYPE_FADE_OUT = 2;
	
	
	public static final int KIND_IMAGE = 0;
	public static final int KIND_TEXT = 1;
	public static final int KIND_VILLAGE = 2;
	public static final int KIND_MUSIC = 3;
	public static final int KIND_MUSIC_OVERWRITE_VILLAGE_MUSIC = 4;
	public static final int KIND_MUSIC_OVERWRITE_STORY_MUSIC = 41;
	public static final int KIND_END = 5;
	public static final int KIND_END_SEQ = 28;
	
	public static final int KIND_TRIGGER = 7;
	public static final int KIND_TRIGGER_INN = 8;
	
	public static final int KIND_SCREEN_MOVE_DIST = 9;
	public static final int KIND_SCREEN_MOVE_TO = 10;
	public static final int KIND_SCREEN_MOVE_POS = 11;
	public static final int KIND_SCREEN_MOVE_STOP = 12;
	public static final int KIND_SCREEN_MOVE_GO = 13;
	public static final int KIND_SCREEN_MOVE_CENTER = 14;
	
	public static final int KIND_ACTOR_SHOW = 15;
	public static final int KIND_ACTOR_HIDE = 16;
	public static final int KIND_ACTOR_MOVE_TO_RELATIVE = 17;
	public static final int KIND_ACTOR_MOVE_DIST = 18;
	public static final int KIND_ACTOR_MOVE_TO = 19;
	public static final int KIND_ACTOR_MOVE_STOP = 20;
	public static final int KIND_ACTOR_DEACCELERATE = 21;
	public static final int KIND_ACTOR_LOOK_TO = 22;
	public static final int KIND_ACTOR_QUEUE_MOVE = 23;
	public static final int KIND_ACTOR_ANIMATION = 24;
	public static final int KIND_ACTOR_EMOTION = 25;
	public static final int KIND_ACTOR_CONTROLL = 26;
	public static final int KIND_ACTOR_RESET_VILLAGER = 27;
	public static final int KIND_SET_COLOR = 29;
	public static final int KIND_SET_VILLAGE_BACKGROUND = 30;
	public static final int KIND_SET_FADE_IMAGE = 31;
	public static final int KIND_SET_DRAW_PAUSE = 32;
	public static final int KIND_REMOVE = 33;
	public static final int KIND_LEVEL_UP = 34;
	public static final int KIND_ADD_SPRITE_ON_TOP_LAYER = 35;
	public static final int KIND_ADD_SPRITE_ON_BOTTOM_LAYER = 36;
	public static final int KIND_FADE_PARTICLE_SYSTEM = 37;
	public static final int KIND_SCREEN_ZOOM = 38;
	public static final int KIND_CURE_ALL = 39;
	public static final int KIND_SCROLL_TEXT = 40;
	
	public static final int BACKGROUND_POS_X = 2;
	public static final int BACKGROUND_POS_Y = 3;
	public static final int BACKGROUND_MOVE_TIME = 5;
	
	// Only for music
	public static final int PLAY_MODE = 5;
	public static final int FADE_TARGET = 6;
	
	// Only for text
	public static final int POS_X = 5;
	public static final int POS_Y = 6;
	public static final int TARGET = 7;
	
	public static final int BACKGROUND_FADE_TARGET = 8;
	
	// Only for village
	public static final int TIME_OF_DAY = 5;
	// Only for images.
	public static final int INFO_IMAGE_SCROLL_MODE = 5;
	public static final int INFO_IMAGE_MODE = 6;
	public static final int SIZE = 7;
	public static final int INFO_IMAGE_SCROLL_SPEED = 8;
	// Only for triggers
	public static final int TRIGGER_VALUE = 5;
	// Only for char animation
	public static final int ANIMATION_CHARACTER_INDEX = 5;
	public static final int ANIMATION_INDEX = 6;
	
	public static final int EMOTION = 5;
	public static final int EMOTION_SHOW = 6;
	public static final int EMOTION_SHAKE = 7;
	
	public static final int SHOW_CURRENT_IMAGE = 6;
	
	public static final int CENTER_SCREEN = 5;
	
	public static final int SCREEN_ZOOM_IN = 7;
	public static final int SCREEN_ZOOM_TIME = 8;
	public static final int SCREEN_ZOOM_USE_STATIC_POS = 9;
	
	public static final int IMAGE_SCROLL_MODE_NORMAL = 0;
	public static final int IMAGE_SCROLL_MODE_ZOOM = 1;
	public static final int IMAGE_SCROLL_MODE_SCROLL_RIGHT = 2;
	public static final int IMAGE_SCROLL_MODE_SCROLL_DOWN = 3;
	
	public static final int IMAGE_MODE_BACKFLASH = 0;
	public static final int IMAGE_MODE_TRANSLUCENT_UNDER_ACTOR = 1;
	public static final int IMAGE_MODE_TRANSLUCENT_OVER_ACTOR = 2;
	public static final int IMAGE_MODE_COVERALL = 3;
	public static final int IMAGE_MODE_STORY = 4;
	
	public static final int PAUSE = 4;
	
	public static final int IMAGES = 0;
	public static final int ACTORS = 1;
	public static final int MUSICS = 2;
	public static final int TRIGGERS = 3;
	public static final int STORY_SEQUENCES = 4;
	public static final int ANIMATIONS = 5;
	public static final int PARTICLE_SYSTEMS = 6;
	
	public static final int ACTOR_CONTROLL = 5;
	
	public static final int MOVE_DIRECTION = 5;
	public static final int MOVE_DURATION = 6;
	public static final int MOVE_DISTANCE = 7;
	public static final int MOVE_ACTOR_FACE_DIRECTION = 8;
	public static final int MOVE_X = 9;
	public static final int MOVE_Y = 10;
	
	public static final int MOVE_ACCELERATION = 8;
	public static final int MOVE_SPEED = 8;
	
	public static final int COLOR = 5;
	public static final int COLOR_SPEED = 6;
	
	public static final int FADE_IMAGE= 6;
	
	public static final int PARTICLE_SYS_FADE_SPEED = 5;
	public static final int PARTICLE_SYS_FADE_SWIFTNESS = 6;
	public static final int PARTICLE_SYS_FADE_CUTOFF = 7;

	private int[] information;

	/**
	 * Creates a new time line event based on the info in the
	 * given array.
	 * 
	 * @param info the information concerning the event.
	 */
	public TimeLineEvent(int[] info) {
		information = info;
	}

	/**
	 * Gets the information concerning the event on a time line.
	 * 
	 * @return the information of the event.
	 */
	public int[] getInformation() {
		return information;
	}

	/**
	 * Gets the type of the event.
	 * 
	 * @return the type of event on the time line.
	 */
	public int getType() {
		return information[TYPE];
	}

	/**
	 * Gets the point in time that the event should take place.
	 * 
	 * @return the time of the event.
	 */
	public int getTime() {
		return information[TIME];
	}

	/**
	 * Gets the information represented by the given value. This method
	 * can be called with the static values in this class that starts
	 * with INFO_.
	 * 
	 * @param type the information to get.
	 * @return the information about the event with the given index. 
	 */
	public int getInfo(int type) {
		return information[type];
	}

	/**
	 * Gets the position of the event. This position is the coordinate of the
	 * text or image depending on the kind of event.
	 * 
	 * @return the position of the event.
	 */
	public int[] getPos() {
		return new int[]{
				getInfo(POS_X), getInfo(POS_Y)
			};
	}

	/**
	 * Checks if the event should fade in or out.
	 * 
	 * @return true if this event should fade in or out.
	 */
	public boolean isFade() {
		return getType() == TYPE_FADE_IN || getType() == TYPE_FADE_OUT;
	}
	
	/**
	 * This method creates a new time line event based on the information
	 * in the given tokenizer.
	 * 
	 * @param tokenizer the tokenizer containing the information about the
	 * time line event.
	 * @return the time line event based on the information in the given 
	 * tokenizer. 
	 */
	public static TimeLineEvent createNew(StringTokenizer tokenizer) {
		int size = tokenizer.countTokens();
		int[] inst = new int[size];
		for (int i = 0; i < size; i++) {
			inst[i] = Integer.parseInt(tokenizer.nextToken());
		}
		return new TimeLineEvent(inst);
	}

	/**
	 * Checks if this events contains the information with the given index.
	 * This can be used to avoid ArrayIndexOutOfBoundsException. If this 
	 * method returns true, it is safe to call getInfo() with the same
	 * argument as this method.
	 * 
	 * @param index the index to check.
	 * @return true if the information with the given index exists.
	 */
	public boolean doesInfoExist(int index) {
		return index < information.length && index >= 0;
	}

	public int compareTo(TimeLineEvent tle) {
		int value = 0;
		if (information[TIME] > tle.information[TIME]) {
			value = 1;
		} else if (information[TIME] < tle.information[TIME]) {
			value = -1;
		}
		return value;
	}
	
	public String toString() {
		return Arrays.toString(information);
	}
}
