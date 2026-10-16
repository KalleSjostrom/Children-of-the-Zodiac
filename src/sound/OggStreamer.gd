class_name OggStreamer
extends RefCounted
## Port of sound.OggStreamer: plays a music track. A track "Name" consists of
## res/Music/Name1.ogg (played once) and Name2.ogg (looped). If there is no
## second part, the first part loops. Fades step every 100 ms like the
## original's FadeThread.

static var fadeThreads := {} # url name -> OggStreamer currently fading it
static var _active: Array = []
static var audioParent: Node

var url: Array = [null, null]
var volume := Values.MAX_VOLUME
var fadeOut := false
var fadeIn := false
var updating := true
var mute := false
var name := ""

var _player: AudioStreamPlayer
var _incTime := 0.0
var _fadeTarget := 0.0
var _fadePlayMode := SoundValues.NORMAL
var _fadeAccum := 0.0
var _fading := false
var _paused := false
var _onLoop := false


func _init(p_name: String = "") -> void:
	name = p_name
	url = getURL(p_name)


func play(p_fadeIn: bool, p_play: bool) -> void:
	_open()
	playback(p_play and not mute)
	if p_fadeIn and not mute:
		fade(SoundValues.FADE_IN, 2500, SoundValues.ALL_THE_WAY, SoundValues.NORMAL)
	else:
		setVolume(volume)


func _open() -> void:
	if _player != null or url[0] == null or audioParent == null:
		return
	_player = AudioStreamPlayer.new()
	_player.name = "Music_" + name.validate_node_name()
	_player.bus = "Master"
	audioParent.add_child(_player)
	_player.finished.connect(_onFinished)
	_player.volume_db = linear_to_db(0.0)
	if not _active.has(self):
		_active.append(self)


func _loadStream(path: String, loop: bool) -> AudioStream:
	var s = load(path)
	if s is AudioStreamOggVorbis:
		s = s.duplicate()
		s.loop = loop
	return s


func playback(begin: bool) -> void:
	if _player == null:
		return
	var intro_is_loop: bool = url[1] == url[0]
	_onLoop = intro_is_loop
	_player.stream = _loadStream(url[0], intro_is_loop)
	_player.play()
	_paused = not begin
	_player.stream_paused = not begin


func _onFinished() -> void:
	if not updating or _player == null:
		return
	if not _onLoop:
		_onLoop = true
		_player.stream = _loadStream(url[1], true)
		_player.play()


func setVolume(newVolume: float) -> void:
	volume = newVolume
	if _player != null:
		_player.volume_db = linear_to_db(maxf(volume, 0.0))


func setInitVolume(p_volume: float) -> void:
	if p_volume == 0:
		mute = true
		fadeIn = false
		fadeOut = false
	else:
		volume = p_volume


func mute_() -> void:
	mute = true
	fadeIn = false
	fadeOut = false
	volume = 0
	setVolume(volume)


## Fades the music. mode: SoundValues.FADE_IN / FADE_OUT, time in ms,
## volumeTarget: the volume to reach, playMode: what to do when done
## (SoundValues.NORMAL, RESUME_PLAY, PAUSE or KILL_MUSIC_ON_FADE_DOWN).
func fade(mode: int, time: int, volumeTarget: float, playMode: int) -> void:
	if volumeTarget != volume:
		var key: String = "No Music" if url[0] == null else url[0]
		var other: OggStreamer = fadeThreads.get(key)
		if other != null and other._fading:
			other._finishFade()
		fadeThreads[key] = self
		fadeIn = mode == SoundValues.FADE_IN
		fadeOut = not fadeIn
		_incTime = 0.0 if time == 0 else 50.0 / (time * 0.9)
		_fadeTarget = volumeTarget
		_fadePlayMode = playMode
		_fadeAccum = 0.0
		_fading = true
		_checkResume(playMode)
		if not _active.has(self):
			_active.append(self)
	else:
		_checkResume(playMode)
		_checkPause(playMode)
		_checkExit(playMode)


func _incrementVolume(fadeTarget: float) -> void:
	if _incTime == 0:
		volume = fadeTarget if fadeIn else 0.0
	else:
		var value := 1 if fadeIn else -1
		volume += value * (_incTime * (1 + (volume * 2)))


func _checkFadeMode(fadeLength: float) -> bool:
	if fadeIn:
		return volume >= fadeLength
	elif fadeOut:
		return volume <= fadeLength
	return false


func _tick(delta_ms: float) -> void:
	if not _fading:
		return
	_fadeAccum += delta_ms
	while _fading and _fadeAccum >= 100.0:
		_fadeAccum -= 100.0
		if not _checkFadeMode(_fadeTarget) and isFading():
			_incrementVolume(_fadeTarget)
			setVolume(volume)
		else:
			_finishFade()


func _finishFade() -> void:
	_fading = false
	_checkPause(_fadePlayMode)
	_checkExit(_fadePlayMode)
	fadeOut = false
	fadeIn = false


func _checkResume(mode: int) -> void:
	if mode == SoundValues.RESUME_PLAY and _player != null and (_paused or not _player.playing):
		setVolume(volume)
		_paused = false
		_player.stream_paused = false
		if not _player.playing:
			_player.play()


func _checkPause(mode: int) -> void:
	if mode == SoundValues.PAUSE and _player != null and not _paused:
		setVolume(volume)
		_paused = true
		_player.stream_paused = true


func _checkExit(mode: int) -> void:
	if mode == SoundValues.KILL_MUSIC_ON_FADE_DOWN:
		exit()


func exit() -> void:
	updating = false
	_fading = false
	if _player != null:
		_player.stop()
		_player.queue_free()
		_player = null
	_active.erase(self)


func isFading() -> bool:
	return fadeOut or fadeIn


func isFadingDown() -> bool:
	return fadeOut


func isPlaying() -> bool:
	return _player != null and _player.playing and not _paused


func getURL(songName: String) -> Array:
	var u: Array = [null, null]
	var p1 := GameResourceLoader.resolve(Values.Music + songName + "1.ogg")
	if p1 != "":
		u[0] = p1
	elif songName != "" and songName != "No Music":
		push_warning("The song " + songName + "1.ogg does not exist")
	var p2 := GameResourceLoader.resolve(Values.Music + songName + "2.ogg")
	u[1] = p2 if p2 != "" else u[0]
	return u


func isURLValid() -> bool:
	return url[0] != null


func getName() -> String:
	return name


## Called by the main loop every frame.
static func tickAll(delta_ms: float) -> void:
	for s in _active.duplicate():
		s._tick(delta_ms)


## Stops all music (used when quitting).
static func stopAll() -> void:
	for s in _active.duplicate():
		s.exit()
