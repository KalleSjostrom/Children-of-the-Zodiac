class_name GameMode
extends Fadeable
## Port of organizer.GameMode: super class of all the modes in the game. In
## charge of loading, fading in/out music and graphics and of the input
## detection modes.
##
## Port notes (no overloading in GDScript):
##  - Java's protected init(info, detectMode[, music]) is initGameMode(...).
##    Subclasses override init(info) and call initGameMode(info, mode).
##  - Java's protected resume(detectionMode[, fadein]) and
##    resume(detectionMode, fadeMusic, fadein) are resumeWith(...).
##  - update(elapsedTime) receives milliseconds; draw(g) has no time argument.
##
## Bridge to Godot scenes (new API, snake_case; docs/ARCHITECTURE.md): a mode
## may own a scene (create_scene), which Main shows under its World node while
## the mode is current and not loading.

const TRIANGLE := 0
const CIRCLE := 1
const CROSS := 2
const SQUARE := 3
const L2 := 4
const R2 := 5
const L1 := 6
const R1 := 7
const SELECT := 8
const L1R1 := 9
const L2R2 := 10
const START := 11
const UP := 12
const UP_DOWN := 12
const RIGHT := 13
const LEFT_RIGHT := 13
const DOWN := 14
const LEFT := 15
const NUMBER_OF_BUTTONS := 16

static var mute := false # = Values.check(Values.MUTE_MUSIC), set by Main

var infoMap = null
var inputManager: InputManager.InputManagers = GameCore.inputManager
var gameActions: Array = GameCore.gameActions
var nextPlace = ""
var mode := 0
var suspended := false
var done := false
var fadeOutStarted := false
var pausable := true
var logicLoading := true
var loading := true

var oggPlayer: OggStreamer
var music = null
var musicFadeOutSpeed := SoundValues.SLOW

## The scene of this mode (null for a legacy mode), see create_scene().
var scene_root: Node
var _scene_requested := false


## Override to return a new scene for this mode; null (the default) keeps the
## mode purely legacy. The scene must not hold a strong reference to the mode
## (the mode owns the scene, a reference back would leak both).
func create_scene() -> Node:
	return null


## scene_root, created by create_scene() on the first call. Main calls this
## once the mode is current and has finished loading.
func ensure_scene() -> Node:
	if not _scene_requested:
		_scene_requested = true
		scene_root = create_scene()
	return scene_root


## The scene Main shows under World while this mode is current: its own
## (ensure_scene) by default. A mode that presents another mode's scene
## overrides this (VillageStory shows its Village's); the scene stays owned
## by the mode whose scene_root it is, which alone frees it.
func shown_scene() -> Node:
	return ensure_scene()


## Game modes are dropped, not freed explicitly: free the scene with the mode.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(scene_root):
		if scene_root.is_inside_tree():
			scene_root.queue_free()
		else:
			scene_root.free()


## Initializes the game mode. Called by the Organizer when it is created.
func init(info) -> void:
	pass


## Java: protected void init(HashMap info, int detectMode[, boolean music]).
func initGameMode(info, detectMode: int, p_music: bool = true) -> void:
	infoMap = info
	if infoMap != null:
		nextPlace = infoMap.get("nextPlace")
		if p_music:
			var name = infoMap.get("music")
			var volume = infoMap.get("musicVolume")
			var initialVolume := Values.MAX_VOLUME
			if volume != null:
				initialVolume = J.parseFloat(volume)
			_initMusic(name, initialVolume)
	else:
		nextPlace = ""
	initInput(detectMode)
	mode = Values.NO_MODE_IS_SELECTED
	fadein = true
	fadeout = false
	done = false
	fadeOutStarted = false
	suspended = false


func initInput(detectionMode: int) -> void:
	for i in range(UP, LEFT + 1):
		gameActions[i].changeBehavior(detectionMode)


func changeInput(buttons: Array, detectionMode: int) -> void:
	for b in buttons:
		gameActions[b].changeBehavior(detectionMode)


func _initMusic(p_music, initialVolume: float) -> void:
	music = p_music
	if p_music != null and not mute:
		var gm: GameMode = Organizer.getOrganizer().getPreviousMode()
		if gm != null and gm.oggPlayer != null and gm.music != null \
				and (String(p_music).contains("continue") or p_music == gm.music):
			oggPlayer = gm.oggPlayer
			music = gm.music
		elif p_music == "No Music":
			pass
		else:
			oggPlayer = OggStreamer.new(p_music)
			oggPlayer.setInitVolume(initialVolume)
			if oggPlayer.isURLValid():
				var player := oggPlayer
				Scheduler.waitUntil(
					func(): return (gm == null or not gm.isMusicFadingDown()) and not isLoading(),
					func(): player.play(false, true))


func isMusicFadingDown() -> bool:
	if oggPlayer != null:
		return oggPlayer.isFadingDown()
	return false


func isFading() -> bool:
	return fadein or fadeout


## Java overloads setMusicMode(mode, fadeSpeed[, fadeLength[, playMode]]).
func setMusicMode(p_mode: int, fadeSpeed: int, fadeLength: float = SoundValues.ALL_THE_WAY,
		playMode: int = SoundValues.NORMAL) -> void:
	if oggPlayer != null:
		if p_mode == SoundValues.FADE_OUT:
			fadeLength = SoundValues.ALL_THE_WAY - fadeLength
		oggPlayer.fade(p_mode, fadeSpeed, fadeLength, playMode)


func resumeMusicWithFade(fadeSpeed: int) -> void:
	setMusicMode(SoundValues.FADE_IN, fadeSpeed, SoundValues.ALL_THE_WAY, SoundValues.RESUME_PLAY)


func pauseMusicWithFade(fadeSpeed: int) -> void:
	setMusicMode(SoundValues.FADE_OUT, fadeSpeed, SoundValues.ALL_THE_WAY, SoundValues.PAUSE)


func _fadeOutGameMode() -> bool:
	if not mute:
		if not fadeOutStarted:
			if not suspended:
				var cont := true
				if mode == Values.SWITCH_BACK:
					var gm: GameMode = Organizer.getOrganizer().getNextSuspendedMode()
					if gm != null:
						var lastMusic = gm.infoMap.get("music")
						var m = infoMap.get("music")
						if lastMusic == m:
							cont = false
				if cont:
					var info = Organizer.getOrganizer().getInformationFor(nextPlace)
					if info == null:
						info = getInfoForNextPlace()
					var m = null
					var dontFade: bool = nextPlace != null and String(nextPlace).contains("::continue::")
					if info != null:
						m = info.get("music")
						if not dontFade:
							if m != null and m != music and m != "continue":
								setMusicMode(SoundValues.FADE_OUT, musicFadeOutSpeed,
									SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN)
					if not dontFade:
						if info == null or m == null:
							setMusicMode(SoundValues.FADE_OUT, musicFadeOutSpeed,
								SoundValues.ALL_THE_WAY, SoundValues.KILL_MUSIC_ON_FADE_DOWN)
			fadeOutStarted = true
	fadeOut()
	done = not fadeout
	return done


func releaseAll() -> void:
	for i in NUMBER_OF_BUTTONS:
		gameActions[i].release()


func resetAll() -> void:
	for i in NUMBER_OF_BUTTONS:
		gameActions[i].reset()


func changeDirBehaviour(behavior: int) -> void:
	for i in range(UP, LEFT + 1):
		gameActions[i].changeBehavior(behavior)


## Updates the game mode. elapsedTime is in milliseconds.
func update(elapsedTime: float) -> void:
	pass


func updateFadeValue() -> void:
	if fadein:
		fadeIn()
		if fadeValue >= 1:
			Graphics.setFadeImage(Graphics.FADE_TO_BLACK)
	elif fadeout:
		_fadeOutGameMode()


## Steps the fade and draws it, last in every mode's frame. Bridge (phase 3
## step B, docs/ARCHITECTURE.md section 12): the Transition layer's Fade node
## draws it (Graphics.show_fade); --legacy=fades keeps the drawing.
func draw(g: Graphics) -> void:
	updateFadeValue()
	if Main.is_legacy("fades"):
		g.fadeOldSchool(fadeValue)
	else:
		g.show_fade(fadeValue)


## Java overloads switchGameMode(mode[, switchMusic[, fade]]).
func switchGameMode(p_mode: int, switchMusic = null, fade: bool = true) -> void:
	if switchMusic == null:
		switchMusic = p_mode != Values.MENU
	setSuspended(true, switchMusic, fade)
	mode = p_mode


func isSuspended() -> bool:
	return suspended


## Java overloads setSuspended(pause) and setSuspended(pause, fadeMusic, fade).
func setSuspended(pause: bool, fadeMusic: bool = true, fade: bool = true) -> void:
	if not pause:
		mode = Values.NO_MODE_IS_SELECTED
		inputManager.resetAllGameActions()
		fadeValue = 0.0 if fade else 1.0
		fadein = fade
		fadeout = false
		fadeOutStarted = false
		done = false
		suspended = false
		if fadeMusic:
			resumeMusicWithFade(SoundValues.FAST)
	else:
		suspended = true
		fadeout = fade
		done = not fade
		if fadeMusic:
			pauseMusicWithFade(SoundValues.FAST)


func resume() -> void:
	setSuspended(false)


## Java: resume(detectionMode), resume(detectionMode, fadein) and
## resume(detectionMode, fadeMusic, fadein).
func resumeWith(detectionMode: int, a = null, b = null) -> void:
	if a == null:
		setSuspended(false)
	elif b == null:
		setSuspended(false, true, a)
	else:
		setSuspended(false, a, b)
	initInput(detectionMode)


func resumedFromMenu() -> bool:
	var gm: GameMode = Organizer.getOrganizer().getPreviousMode()
	if gm != null:
		return gm is MainMenu
	return false


func killOggPlayer() -> void:
	if oggPlayer != null:
		oggPlayer.exit()


func exitWithoutFading(p_mode: int) -> void:
	done = true
	mode = p_mode
	killOggPlayer()


## Tries to enter the menu. Returns the thumbnail screen shot (an Image) or
## null if the mode is fading.
func enterMenu() -> Image:
	var screenShot: Image = null
	if not isFading():
		screenShot = Values.getMenuScreenShot()
		nextPlace = null
		switchGameMode(Values.MENU)
	return screenShot


## Exits this mode (fading out music and graphics) and sets the next mode.
func exit(p_mode: int) -> void:
	fadeout = true
	mode = p_mode


func getExitMode() -> int:
	return mode


func checkExit() -> int:
	if isDone() or mode == Values.MENU:
		return mode
	return Values.NO_MODE_IS_SELECTED


func isDone() -> bool:
	return done


func shouldGetInfoFromMain() -> bool:
	return getNextPlace() != "" and getNextPlace() != "_"


func getNextPlace() -> String:
	return "" if nextPlace == null else str(nextPlace)


func isPausable() -> bool:
	return pausable


func switchMusic(name: String, fadeSpeed: int) -> void:
	if oggPlayer != null:
		setMusicMode(SoundValues.FADE_OUT, fadeSpeed)
		var old := oggPlayer
		Scheduler.waitUntil(func(): return not old.isFadingDown(), func():
			old.exit()
			if name != "No Music":
				oggPlayer = OggStreamer.new(name)
				oggPlayer.play(false, true))
	else:
		Scheduler.after(fadeSpeed, func():
			if name != "No Music":
				oggPlayer = OggStreamer.new(name)
				oggPlayer.play(false, true))


## Override to create the information map for the next place (getNextPlace()
## must then return "").
func getInfoForNextPlace():
	return null


## Called by the organizer when this mode is about to be shut down.
func finishOff() -> void:
	pass


func isLoading() -> bool:
	return loading


func isLogicLoading() -> bool:
	return logicLoading


func loadingDone() -> void:
	if not logicLoading:
		loading = false


func setMusicFadeOutSpeed(time: int) -> void:
	musicFadeOutSpeed = time


static func isMuted() -> bool:
	return mute


func getName() -> String:
	if infoMap != null:
		var n = infoMap.get("name")
		return "" if n == null else str(n)
	return ""


func setGameAction() -> void:
	GameCore.setGameAction()
	gameActions = GameCore.gameActions
