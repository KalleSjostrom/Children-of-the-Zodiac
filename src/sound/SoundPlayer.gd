class_name SoundPlayer
extends RefCounted
## Port of sound.SoundPlayer: plays sound effects from res/SoundEffects/.

const MAX_VOLUME := 1.0
const POOL_SIZE := 12

static var enabled := true
static var volumes := {}
static var _players: Array = []
static var _next := 0
static var _cache := {}
static var audioParent: Node


static func _static_init() -> void:
	volumes[SoundMap.MAGICS_BLIZZARD] = 0.7


static func playSound(name) -> void:
	if name == null or str(name) == "":
		return
	if not enabled or not Values.soundEnabled() or audioParent == null:
		return
	var stream := _getStream(str(name))
	if stream == null:
		return
	var p := _player()
	p.stream = stream
	var v: float = volumes.get(name, MAX_VOLUME)
	p.volume_db = linear_to_db(v)
	p.play()


static func playSoundWithRandom(name: String, nr: int) -> void:
	var ra := J.randInt(nr) + 1
	playSound(name + str(ra) + ".wav")


static func _getStream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := GameResourceLoader.resolve(Values.SoundEffects + name)
	if path == "" and not name.ends_with(".wav"):
		path = GameResourceLoader.resolve(Values.SoundEffects + name + ".wav")
	var s: AudioStream = null
	if path != "":
		s = load(path)
	else:
		push_warning("SoundPlayer: sound not found: " + name)
	_cache[name] = s
	return s


static func _player() -> AudioStreamPlayer:
	if _players.size() < POOL_SIZE:
		var p := AudioStreamPlayer.new()
		audioParent.add_child(p)
		_players.append(p)
		return p
	# Reuse an idle player, or the oldest one.
	for i in POOL_SIZE:
		var p: AudioStreamPlayer = _players[(_next + i) % POOL_SIZE]
		if not p.playing:
			_next = (_next + i + 1) % POOL_SIZE
			return p
	var q: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	return q
