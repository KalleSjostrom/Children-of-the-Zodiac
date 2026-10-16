class_name TimeLineEvent
extends RefCounted
## Port of story.TimeLineEvent: an event on a time line (an int[] of info).
## compareTo is kept; sort with sort_custom(func(a, b): return a.compareTo(b) < 0).

const TYPE = 0
const TIME = 1
const INDEX = 2
const FADE_TIME = 3
const KIND = 4
const TYPE_NO_FADE = 0
const TYPE_FADE_IN = 1
const TYPE_FADE_OUT = 2
const KIND_IMAGE = 0
const KIND_TEXT = 1
const KIND_VILLAGE = 2
const KIND_MUSIC = 3
const KIND_MUSIC_OVERWRITE_VILLAGE_MUSIC = 4
const KIND_MUSIC_OVERWRITE_STORY_MUSIC = 41
const KIND_END = 5
const KIND_END_SEQ = 28
const KIND_TRIGGER = 7
const KIND_TRIGGER_INN = 8
const KIND_SCREEN_MOVE_DIST = 9
const KIND_SCREEN_MOVE_TO = 10
const KIND_SCREEN_MOVE_POS = 11
const KIND_SCREEN_MOVE_STOP = 12
const KIND_SCREEN_MOVE_GO = 13
const KIND_SCREEN_MOVE_CENTER = 14
const KIND_ACTOR_SHOW = 15
const KIND_ACTOR_HIDE = 16
const KIND_ACTOR_MOVE_TO_RELATIVE = 17
const KIND_ACTOR_MOVE_DIST = 18
const KIND_ACTOR_MOVE_TO = 19
const KIND_ACTOR_MOVE_STOP = 20
const KIND_ACTOR_DEACCELERATE = 21
const KIND_ACTOR_LOOK_TO = 22
const KIND_ACTOR_QUEUE_MOVE = 23
const KIND_ACTOR_ANIMATION = 24
const KIND_ACTOR_EMOTION = 25
const KIND_ACTOR_CONTROLL = 26
const KIND_ACTOR_RESET_VILLAGER = 27
const KIND_SET_COLOR = 29
const KIND_SET_VILLAGE_BACKGROUND = 30
const KIND_SET_FADE_IMAGE = 31
const KIND_SET_DRAW_PAUSE = 32
const KIND_REMOVE = 33
const KIND_LEVEL_UP = 34
const KIND_ADD_SPRITE_ON_TOP_LAYER = 35
const KIND_ADD_SPRITE_ON_BOTTOM_LAYER = 36
const KIND_FADE_PARTICLE_SYSTEM = 37
const KIND_SCREEN_ZOOM = 38
const KIND_CURE_ALL = 39
const KIND_SCROLL_TEXT = 40
const BACKGROUND_POS_X = 2
const BACKGROUND_POS_Y = 3
const BACKGROUND_MOVE_TIME = 5
const PLAY_MODE = 5
const FADE_TARGET = 6
const POS_X = 5
const POS_Y = 6
const TARGET = 7
const BACKGROUND_FADE_TARGET = 8
const TIME_OF_DAY = 5
const INFO_IMAGE_SCROLL_MODE = 5
const INFO_IMAGE_MODE = 6
const SIZE = 7
const INFO_IMAGE_SCROLL_SPEED = 8
const TRIGGER_VALUE = 5
const ANIMATION_CHARACTER_INDEX = 5
const ANIMATION_INDEX = 6
const EMOTION = 5
const EMOTION_SHOW = 6
const EMOTION_SHAKE = 7
const SHOW_CURRENT_IMAGE = 6
const CENTER_SCREEN = 5
const SCREEN_ZOOM_IN = 7
const SCREEN_ZOOM_TIME = 8
const SCREEN_ZOOM_USE_STATIC_POS = 9
const IMAGE_SCROLL_MODE_NORMAL = 0
const IMAGE_SCROLL_MODE_ZOOM = 1
const IMAGE_SCROLL_MODE_SCROLL_RIGHT = 2
const IMAGE_SCROLL_MODE_SCROLL_DOWN = 3
const IMAGE_MODE_BACKFLASH = 0
const IMAGE_MODE_TRANSLUCENT_UNDER_ACTOR = 1
const IMAGE_MODE_TRANSLUCENT_OVER_ACTOR = 2
const IMAGE_MODE_COVERALL = 3
const IMAGE_MODE_STORY = 4
const PAUSE = 4
const IMAGES = 0
const ACTORS = 1
const MUSICS = 2
const TRIGGERS = 3
const STORY_SEQUENCES = 4
const ANIMATIONS = 5
const PARTICLE_SYSTEMS = 6
const ACTOR_CONTROLL = 5
const MOVE_DIRECTION = 5
const MOVE_DURATION = 6
const MOVE_DISTANCE = 7
const MOVE_ACTOR_FACE_DIRECTION = 8
const MOVE_X = 9
const MOVE_Y = 10
const MOVE_ACCELERATION = 8
const MOVE_SPEED = 8
const COLOR = 5
const COLOR_SPEED = 6
const FADE_IMAGE = 6
const PARTICLE_SYS_FADE_SPEED = 5
const PARTICLE_SYS_FADE_SWIFTNESS = 6
const PARTICLE_SYS_FADE_CUTOFF = 7
var information = null

func _init(info = null) -> void:
	information = info

func getInformation():
	return information

func getType():
	return information[TYPE]

func getTime():
	return information[TIME]

func getInfo(type):
	return information[type]

func getPos():
	return [getInfo(POS_X), getInfo(POS_Y)]

func isFade():
	return getType() == TYPE_FADE_IN or getType() == TYPE_FADE_OUT

static func createNew(tokenizer):
	var size: int = tokenizer.countTokens()
	var inst := J.array(size, 0)
	for i in range(size):
		inst[i] = J.parseInt(tokenizer.nextToken())
	return TimeLineEvent.new(inst)

func doesInfoExist(index):
	return index < information.size() and index >= 0

func compareTo(tle):
	var value: int = 0
	if information[TIME] > tle.information[TIME]:
		value = 1
	elif information[TIME] < tle.information[TIME]:
		value = -1
	return value

func _to_string():
	var parts := []
	for v in information:
		parts.append(str(v))
	return "[" + ", ".join(parts) + "]"
