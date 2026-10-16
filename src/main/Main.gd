extends Node2D
## Entry point of the port (the original's organizer.Game + Screen +
## FPSAnimator + GameEventListener.display()).
##
## Every frame: input -> scheduled tasks/music fades -> Organizer.update(ms)
## -> draw through the OpenGL emulation (Graphics/GLBackend).
##
## Command line options (after "--"):
##   --start=<place>     start at a place from main.bank instead of the title
##   --load=<slot>       load a saved game slot
##   --autoplay=<file>   feed scripted button presses (see tools/autoplay)
##   --shots=<dir>       save screenshots requested by the autoplay script
##   --quit-after-ms=<n> quit after n milliseconds of game time

static var instance: Node2D

var organizer: Organizer
var graphics: Graphics
var backend: GLBackend
var audio: Node
var _zero_time := 0
var _args := {}
var autoplay: AutoPlay


func _ready() -> void:
	instance = self
	Scheduler.tree = get_tree()
	Engine.max_fps = Values.FPS
	_parse_args()

	audio = Node.new()
	audio.name = "Audio"
	add_child(audio)
	OggStreamer.audioParent = audio
	SoundPlayer.audioParent = audio

	backend = GLBackend.new(self)
	graphics = Graphics.new(backend)
	GameEventListener.g = graphics
	GameCore.screen = self

	for s in J.split(String(_args.get("settings", "")), ","):
		if s != "":
			Values.parseLine(s.replace("_", " "))

	GameMode.mute = Values.check(Values.MUTE_MUSIC) or _args.has("mute")

	var obs: Array = []
	if _args.has("autoplay"):
		autoplay = AutoPlay.new(_args["autoplay"], _args.get("shots", ""))
		obs.append(autoplay.input)

	organizer = Organizer.new()
	if _args.has("start"):
		organizer.nextPlace = String(_args["start"]).replace("_", " ")
	if _args.has("load"):
		organizer.loadSlot = String(_args["load"])
	organizer.init_(obs)
	_zero_time = Time.get_ticks_msec()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("--"):
			s = s.substr(2)
		var eq := s.find("=")
		if eq >= 0:
			_args[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			_args[s] = true


func _input(event: InputEvent) -> void:
	GameCore.inputManager.handleEvent(event)


func _process(delta: float) -> void:
	# GameCore.update(): elapsed milliseconds since the last frame.
	var now := Time.get_ticks_msec()
	var elapsed := float(now - _zero_time)
	_zero_time = now
	if _args.has("fixed-step"):
		elapsed = 1000.0 / Values.FPS
	if autoplay != null:
		autoplay.update(elapsed)
	GameCore.inputManager.poll(elapsed)
	Scheduler.process(elapsed)
	OggStreamer.tickAll(elapsed)

	organizer.update(elapsed)

	# GameEventListener.display()
	backend.begin_frame()
	graphics.beginFrame(GameEventListener.is3D())
	organizer.testDraw(graphics)
	backend.end_frame()

	if autoplay != null:
		autoplay.after_draw(self)
	if _args.has("quit-after-ms") and now - Engine.get_meta("start_ms", 0) > int(_args["quit-after-ms"]):
		get_tree().quit()


func _enter_tree() -> void:
	Engine.set_meta("start_ms", Time.get_ticks_msec())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OggStreamer.stopAll()


func _exit_tree() -> void:
	if backend != null:
		backend.free_all()
