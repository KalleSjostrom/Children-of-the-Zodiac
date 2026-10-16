class_name Values
extends RefCounted
## Port of info.Values: game wide constants and helpers.
##
## NOTE: positions created with createNormalPoint are stored as [y, x]
## (Values.X == 1, Values.Y == 0), exactly as in the original.

const s := "/"
const res := "res/"
const maps := "maps/"
const lib := "lib/"

# The paths to the different resource folders
const MainRes := res + "Main/"
const MainMap := maps + "Main/"
const TitleImages := res + "Title/"
const Music := res + "Music/"
const StoryImages := res + "Story/"
const Banks := maps + "Banks/"
const BattleImages := res + "Battle/"
const EnemyMaps := maps + "Battle/EnemyMaps/"
const LabyrinthMaps := maps + "Labyrinth/"
const LabyrinthTriggers := maps + "Labyrinth/Triggers/"
const LabyrinthTextures := res + "Labyrinth/"
const VillageImages := res + "Village/"
const VillageMaps := maps + "Village/"
const LandscapeMaps := maps + "Landscape/"
const LandscapeImages := res + "Landscape/"
const MenuImages := res + "Menu/"
const StoreImages := res + "Store/"
const Cards := res + "Cards/"
const SoundEffects := res + "SoundEffects/"
const BattleSoundEffects := "Battle/"
const BattleBarImages := res + "Battle/bar/"
const EnemyImages := res + "Battle/enemies/"
const MiniGamesImages := res + "MiniGames/"
const MiniGamesMaps := maps + "MiniGames/"
const AnimationImages := VillageImages + "Characters/Animation/"
const Shaders := res + "Shaders/"
const Emotions := res + "Emotions/"
const StorySequences := maps + "Story/Sequences/"
const ParticleSystemsImages := res + "ParticleSystems/"
const ParticleSystemsMaps := maps + "ParticleSystems/"
const Tutorials := maps + "Tutorials/"

const MAX_VOLUME := 0.9

# The different modes in the game
const TITLE := 0
const STORY := 1
const VILLAGE := 2
const LANDSCAPE := 3
const LABYRINTH := 4
const BATTLE := 5
const MENU := 6
const WEAPONSTORE := 7
const CHURCH := 8
const HOUSE := 9
const INN := 10
const CARDSTORE := 11
const LIBRARY := 12
const STORY_SEQUENSE := 13
const VILLAGE_STORY := 14
const AIR_SHIP := 15
const CHEATER := 16
const SWITCH_BACK := 17
const EXIT := 18
const GAME_OVER := 19
const LANDSCAPE_TEST := 20
const BATTLE_TEST := 21
const NEW_MENU := 22
const BOSS_BATTLE_AREA := 23
const NO_MODE_IS_SELECTED := -1

# Input control
const DETECT_ALL := 0
const DETECT_INIT := 1
const DETECT_AS_KEY := 2

# Locations and directions
static var DIRECTIONS := [-1, 1, 1, -1]
static var COUNTER_DIRECTIONS := [1, 1, -1, -1]
static var TO_ANGLE := [90.0, 180.0, -90.0, 0.0]
const X := 1
const Y := 0
const UP := 0
const RIGHT := 1
const DOWN := 2
const LEFT := 3

# Frame rate
static var FPS := 60
static var INTERVAL := 1000.0 / 60
static var LOGIC_INTERVAL := 1000.0 / 60
## Not in Java: the frame time the original really ran at. Its FPSAnimator
## slept a fixed 23 ms after every vsynced frame, so it ran at about 30 FPS
## (not FPS = 60). Logic that changes per update rather than per second (the
## particles' fading) was tuned at this rate.
const ORIGINAL_FRAME_MS := 1000.0 / 30

# The resolution
static var RESOLUTIONS := [768, 1024]
static var ORIGINAL_RESOLUTION := [768, 1024]
static var WIDE_SCREEN_HEIGHT := 576.0
static var RESOLUTION_X_PRECENT := 1.0
static var RESOLUTION_Y_PRECENT := 1.0
const SMALLER := 600
const SMALL := 800
const MEDIUM := 1024
const LARGE := 1152
const LARGER := 1280
const DYNAMIC_SIZE := 0
const MANUAL := -1
static var resMode := 0
const ASPECT_RATIO_16_9 := 16.0 / 9.0
const ASPECT_RATIO_8_5 := 8.0 / 5.0
const ASPECT_RATIO_4_3 := 4.0 / 3.0

static var ATTRIBUTE_MAP := _createAttributeMap()
static var SETTINGS_MAP := _createSettingsMap()

const FULL_SCREEN := 0
const MUTE_MUSIC := 1
const SOUND_EFFECTS := 2

const LEVEL_UP_LEVEL := 25

const PLAIN := 0
const BOLD := 1

const WHITE := 1.0

static var rand := JRandom.new()
static var drawLists := {}


## Port of the enum Values.characters.
class characters extends RefCounted:
	static var KIN := characters.new(0, "Kin")
	static var CELIS := characters.new(1, "Celis")
	static var BOREALIS := characters.new(2, "Borealis")
	static var ZALZI := characters.new(3, "Zalzi")
	static var NO_CHARACTER := characters.new(-1, "No Char")

	var index := 0
	var name := ""

	func _init(p_index: int, p_name: String) -> void:
		index = p_index
		name = p_name

	func getIndex() -> int:
		return index

	func getName() -> String:
		return name

	static func values() -> Array:
		return [KIN, CELIS, BOREALIS, ZALZI, NO_CHARACTER]

	## getCharacter(String name) or getCharacter(int index).
	static func getCharacter(key) -> characters:
		for c in [KIN, CELIS, BOREALIS, ZALZI]:
			if (key is String and key == c.name) or (key is int and key == c.index):
				return c
		return NO_CHARACTER


static func initAL() -> void:
	pass


static func soundEnabled() -> bool:
	return SETTINGS_MAP[SOUND_EFFECTS]


static func init() -> void:
	pass


static func loadFont() -> void:
	Graphics._loadFonts()


## Java returned a java.awt.Font; here the font type and size are returned as
## [type, size] so ImageGraphics.setFont(...) can use them.
static func getFont(f: int, size: int = -1) -> Array:
	if size == -1:
		return [PLAIN, f]
	return [f, size]


## Blocks the main thread (Java Thread.sleep). Do NOT use this to wait for
## something that the main loop must update (music fades etc.): use
## Scheduler.after / Scheduler.waitUntil / await Scheduler.sleep instead.
static func sleep(time: int) -> void:
	OS.delay_msec(time)


## Not in Java: the length (ms) of the next update step for logic tuned at
## the original's frame rate, given the ms not yet simulated; 0 = no step this
## frame. Steps of ORIGINAL_FRAME_MS, but one step per frame for all the time
## when a frame is longer (as the original did below 30 FPS), so no time is
## lost and no frame does more than one step.
static func originalFrameStep(pending: float) -> float:
	if pending < ORIGINAL_FRAME_MS:
		return 0.0
	return ORIGINAL_FRAME_MS if pending < 2 * ORIGINAL_FRAME_MS else pending


static func createNormalPoint(x: int, y: int) -> Array:
	var p := [0, 0]
	p[X] = x
	p[Y] = y
	return p


static func createNormalFloatPoint(x: float, y: float) -> Array:
	var p := [0.0, 0.0]
	p[X] = float(x)
	p[Y] = float(y)
	return p


static func convertToFloatArray(pos: Array) -> Array:
	return createNormalFloatPoint(pos[X], pos[Y])


static func getCounterAngle(dir: int) -> int:
	return absi((dir + 2) % 4)


static func getClassMap() -> Dictionary:
	var classMap := {}
	classMap[TITLE] = "title.TitleScreen"
	classMap[STORY] = "story.Story"
	classMap[CHEATER] = "organizer.Cheater"
	classMap[LABYRINTH] = "labyrinth.Labyrinth"
	classMap[CHURCH] = "store.Church"
	classMap[LANDSCAPE] = "landscape.Landscape"
	classMap[STORY_SEQUENSE] = "story.StorySequence"
	classMap[VILLAGE] = "villages.Village"
	classMap[WEAPONSTORE] = "store.WeaponStore"
	classMap[INN] = "store.Inn"
	classMap[CARDSTORE] = "store.CardStore"
	classMap[LIBRARY] = "store.Library"
	classMap[HOUSE] = "store.House"
	classMap[MENU] = "menu.MainMenu"
	classMap[VILLAGE_STORY] = "villages.villageStory.VillageStory"
	classMap[GAME_OVER] = "title.GameOver"
	classMap[AIR_SHIP] = "landscape.airship.AirLandscape"
	classMap[LANDSCAPE_TEST] = "villages.Landscape"
	classMap[BATTLE_TEST] = "battleTest.BattleTest"
	classMap[BOSS_BATTLE_AREA] = "battle.BossBattleArea"
	return classMap


static func _createAttributeMap() -> Array:
	return [Creature.ATTACK, Creature.MAGIC_ATTACK, Creature.SUPPORT_ATTACK,
		Creature.AGILITY, Creature.DEFENSE, Creature.MAGIC_DEFENSE,
		Creature.HIT, Creature.EVADE]


static func _createSettingsMap() -> Array:
	var map := [false, false, false, false, false]
	map[FULL_SCREEN] = true
	map[MUTE_MUSIC] = false
	map[SOUND_EFFECTS] = true
	return map


static func parseLine(line: String) -> void:
	var tokenizer := StringTokenizer.new(line)
	var lineOk := line != "" and line != " " and line != "\t"
	if lineOk and tokenizer.hasMoreTokens():
		var command := tokenizer.nextToken()
		_executeCommand(command, tokenizer)


static func _executeCommand(command: String, t: StringTokenizer) -> void:
	if command == "set":
		var args := Parser.getArgument(t.nextToken())
		var setting: String = args[0]
		if setting == "fps":
			if String(args[1]).is_valid_int():
				FPS = int(args[1])
				INTERVAL = roundf(1000.0 / FPS)
			else:
				_error("It must be an integer number after fps in settings.txt")
		elif setting == "resolution":
			match args[1]:
				"dynamic":
					resMode = DYNAMIC_SIZE
				"smallest":
					resMode = SMALLER
				"small":
					resMode = SMALL
				"medium":
					resMode = MEDIUM
				"large":
					resMode = LARGE
				"largest":
					resMode = LARGER
				_:
					resMode = MANUAL
					var size := J.split(args[1], ":")
					RESOLUTIONS = createNormalPoint(int(size[0]), int(size[1]))
		elif setting == "fullscreen":
			SETTINGS_MAP[FULL_SCREEN] = J.parseBoolean(args[1])


static func _error(string: String) -> void:
	push_error("Fatal error: " + string + " (setting default)")


static func setResolution(width: int, height: int) -> void:
	RESOLUTIONS = createNormalPoint(width, height)
	RESOLUTION_X_PRECENT = RESOLUTIONS[X] / float(ORIGINAL_RESOLUTION[X])
	RESOLUTION_Y_PRECENT = RESOLUTIONS[Y] / float(ORIGINAL_RESOLUTION[Y])


## Takes a screen shot and scales it to 183 x 137 (used by the menu).
static func getMenuScreenShot() -> Image:
	var g := GameEventListener.getG()
	if g == null:
		return null
	var im := g.copyFrame()
	if im == null:
		return null
	return GraphicHelp.scaleImage(im, 183, 137)


static func add(one: Array, two: Array, constant: float) -> void:
	for i in one.size():
		one[i] += two[i] * constant


static func copyArray(y: Array) -> Array:
	return y.duplicate()


static func swapInt(array: Array, first: int, second: int) -> void:
	var temp = array[first]
	array[first] = array[second]
	array[second] = temp


static func check(setting: int) -> bool:
	return SETTINGS_MAP[setting]


static func angleToDirection(angle: float) -> int:
	return int(fmod(((angle - 90) / 90 + 4), 4))


static func angleToDirection2(angle: float) -> int:
	return int(fmod(((angle + 90) / 90 + 4), 4))


static func printStackTrace(size: int) -> void:
	print_stack()


static func zoom(small: bool) -> void:
	if small:
		var percent := 1.0
		var x := J.round(1024 * percent)
		var y := J.round(768 * percent)
		ORIGINAL_RESOLUTION = createNormalPoint(x, y)
		WIDE_SCREEN_HEIGHT = 0.75 * y
	else:
		ORIGINAL_RESOLUTION = createNormalPoint(1024, 768)
