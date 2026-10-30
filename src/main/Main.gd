class_name Main
extends Node
## Entry point of the port (the original's organizer.Game + Screen +
## FPSAnimator + GameEventListener.display()).
##
## Every frame: input -> scheduled tasks/music fades -> Organizer.update(ms)
## -> draw through the OpenGL emulation (Graphics/GLBackend, on LegacyLayer)
## -> show the current game mode's scene under World (_sync_world).
## The scene tree and the bridge are described in docs/ARCHITECTURE.md.
##
## Command line options (after "--"):
##   --start=<place>     start at a place from main.bank instead of the title
##   --load=<slot>       load a saved game slot (or an absolute path to a .sav
##                       file, without the extension)
##   --start-time=<day|night>  dev only: start the first place at this time of
##                       day (villages load their "at Night" variant)
##   --status=<name>:<value>[,...]  dev only: set Database statuses after the
##                       save is loaded ("_" in names stands for a space)
##   --start-node=<address>:<direction>  dev only: a labyrinth --start place
##                       starts at this node, facing this direction (0-3), as
##                       a game saved there does (COTZ-005), not at its door
##   --autoplay=<file>   feed scripted button presses (see tools/autoplay)
##   --shots=<dir>       save screenshots requested by the autoplay script
##   --quit-after-ms=<n> quit after n milliseconds of game time
##   --fixed-step        advance the game by exactly 1000/60 ms per frame
##   --seed=<n>          deterministic run (implies --fixed-step): seeded random
##                       numbers and a game clock instead of the wall clock, so
##                       two runs of an autoplay script give the same frames
##   --uncapped          no frame rate cap or vsync (fast parity runs; with --seed)
##   --legacy=<a,b,...>  keep the legacy path of these subsystems (is_legacy;
##                       docs/ARCHITECTURE.md section 7 lists them)
##   --bridge-test       the world map shows tools/bridge_test/BridgeTest.tscn (dev only;
##                       implies --legacy=world_map)
##   --no-encounters     dev only: no random battles in labyrinths (Labyrinth.noEncounters;
##                       steps are still counted), for parity tours of dungeon floors;
##                       the console's "noenemies" switches it
##   --hide-particles    dev only: the particles draw nothing (they still run): the
##                       village and cutscene systems, the dungeon weather and save
##                       points, the card and enemy effects; for parity runs that
##                       compare everything else
##   --minimap-node      dev only: the labyrinth's minimap is drawn by nodes
##                       (MapRenderer.show_map; it changes battle frames by 1/255,
##                       docs/MODERNIZATION_PLAN.md 8.3), not by the 3D bridge
##   --casts=<round>/... dev only: the rounds the console's "cast next" plays
##                       (scenes/debug/GameCommands.gd; parity cases effects_*)
##
## In debug builds the developer console (scenes/debug/DebugConsole.gd)
## opens with the key under Escape or F1; it replaces the Cheater.
##
## Exported builds start in (borderless) full screen, run from the editor
## windowed (project.godot: display/window/size/mode.template); F and
## Alt+Enter toggle it (GameCore.setFullScreen).

static var instance: Main
## --bridge-test: Landscape.create_scene returns the bridge test scene.
static var bridge_test := false
## --no-encounters: labyrinths start no random battles (Labyrinth.init).
static var no_encounters := false
## --hide-particles: village and cutscene particle systems are not drawn.
static var hide_particles := false
## --minimap-node (dev): the minimap's batches are nodes (Labyrinth.draw).
static var minimap_node := false
static var _legacy: PackedStringArray = []

## The current game mode's scene goes here (see _sync_world).
@onready var world: Node = $World
## Parent of GLBackend's canvas items (CanvasLayer 1, above World).
@onready var legacy_canvas: Node2D = $LegacyLayer/Canvas
## The layers of new code over it (CanvasLayer 2 and 3): the dialog boxes
## and the fades, shown in the legacy frame's order (Graphics.show_ui).
@onready var ui_layer: CanvasLayer = $UI
@onready var transition_layer: CanvasLayer = $Transition

var organizer: Organizer
var graphics: Graphics
var backend: GLBackend
var audio: Node
var _zero_time := 0
var _args := {}
var _fixed_step := false
var autoplay: AutoPlay
## The developer console (debug builds only, else null).
var debug_console: DebugConsole
var _world_scene: Node # the scene currently under World, if any
## The cutscene mode last seen by _fast_cutscene (instance id), and whether
## Circle has been up since it started.
var _cutscene_id := 0
var _cutscene_armed := false
## The cutscene the console's "skip cutscene" runs to its end (instance id,
## COTZ-018), 0: none.
var _skip_cutscene_id := 0

## Updates per frame while Circle is held in a cutscene (COTZ-007).
const CUTSCENE_SPEED := 3
## Updates per frame while a cutscene is skipped.
const CUTSCENE_SKIP_SPEED := 40


func _ready() -> void:
	instance = self
	Scheduler.tree = get_tree()
	Engine.max_fps = Values.FPS
	_parse_args()
	_fixed_step = _args.has("fixed-step") or _args.has("seed")
	if _args.has("seed"):
		_init_deterministic(int(_args["seed"]))
	if _args.has("uncapped"):
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if _args.has("legacy"):
		_legacy = String(_args["legacy"]).split(",", false)
	bridge_test = _args.has("bridge-test")
	# The bridge test shows its scene in place of the world map's background
	# tiles, so the world map stays legacy (docs/ARCHITECTURE.md section 8).
	if bridge_test and not is_legacy("world_map"):
		_legacy.append("world_map")
	no_encounters = _args.has("no-encounters")
	hide_particles = _args.has("hide-particles")
	minimap_node = _args.has("minimap-node")

	audio = Node.new()
	audio.name = "Audio"
	add_child(audio)
	OggStreamer.audioParent = audio
	SoundPlayer.audioParent = audio

	var layers: Array[CanvasLayer] = [ui_layer, transition_layer]
	backend = GLBackend.new(self, legacy_canvas, layers)
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
	if _args.has("start-time"):
		organizer.startTime = String(_args["start-time"])
	if _args.has("status"):
		for s in String(_args["status"]).split(",", false):
			var kv := s.split(":")
			organizer.startStatuses[kv[0]] = int(kv[1])
	if _args.has("start-node"):
		var nd := String(_args["start-node"]).split(":")
		organizer.startNode = [int(nd[0]), int(nd[1])]
	organizer.init_(obs)
	_zero_time = Time.get_ticks_msec()
	if OS.is_debug_build():
		debug_console = DebugConsole.new()
		debug_console.name = "DebugConsole"
		add_child(debug_console)


## True when --legacy lists the subsystem (or "all"): code converted to
## scenes keeps its legacy path for parity runs (docs/ARCHITECTURE.md).
static func is_legacy(subsystem: String) -> bool:
	return _legacy.has(subsystem) or _legacy.has("all")


## Seeds every random generator from one seed and switches the game's time
## reads to the game clock (J.deterministic). The JRandoms below are static
## and were created (randomly seeded) when their scripts loaded.
func _init_deterministic(seed_value: int) -> void:
	J.setDeterministic(seed_value)
	Values.rand.setSeed(J.nextSeed())
	WeatherParticle.rand.setSeed(J.nextSeed())
	SaveParticle.rand.setSeed(J.nextSeed())
	BattleParticle.rand.setSeed(J.nextSeed())
	BodiesParticleSystem.rand.setSeed(J.nextSeed())
	ParticleSystem.rand.setSeed(J.nextSeed())
	# Not from J's seed sequence: the GPU effects came after the goldens, and a
	# seed drawn there would shift every later JRandom (encounters, battles).
	ParticleSystem.gpu_rand.setSeed(hash("gpu effects %d" % seed_value))
	# Godot's global generator (randf() & co. in new code), seeded without
	# drawing from J's seed sequence.
	seed(hash("global %d" % seed_value))
	# Start from the shipped saves only (Save.saveDir()).
	if DirAccess.dir_exists_absolute(Save.DETERMINISTIC_SAVE_DIR):
		for f in DirAccess.get_files_at(Save.DETERMINISTIC_SAVE_DIR):
			DirAccess.remove_absolute(Save.DETERMINISTIC_SAVE_DIR.path_join(f))
	print("Main: deterministic run, seed %d" % seed_value)


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
	# Alt+Enter toggles full screen, also while the console is open; the
	# game does not see it (Enter alone is Start).
	var key := event as InputEventKey
	if key != null and key.pressed and key.alt_pressed \
			and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		if not key.echo:
			GameCore.setFullScreen()
		get_viewport().set_input_as_handled()
		return
	# While the console is open the keys are its (DebugConsole).
	if debug_console != null and debug_console.is_open:
		return
	GameCore.inputManager.handleEvent(event)


func _process(delta: float) -> void:
	# GameCore.update(): elapsed milliseconds since the last frame.
	var now := Time.get_ticks_msec()
	var elapsed := float(now - _zero_time)
	_zero_time = now
	if _fixed_step:
		elapsed = 1000.0 / Values.FPS
	if J.deterministic:
		J.advanceGameClock(elapsed)
	if autoplay != null:
		autoplay.update(elapsed)
	GameCore.inputManager.poll(elapsed)
	Scheduler.process(elapsed)
	OggStreamer.tickAll(elapsed)

	_update_organizer(elapsed)

	# GameEventListener.display()
	backend.begin_frame()
	graphics.beginFrame(GameEventListener.is3D())
	organizer.testDraw(graphics)
	backend.end_frame()
	_sync_world()

	if autoplay != null:
		autoplay.after_draw(self)
	if J.deterministic:
		Scheduler.processTimers(elapsed)
	if _args.has("quit-after-ms") and now - Engine.get_meta("start_ms", 0) > int(_args["quit-after-ms"]):
		get_tree().quit()


## Organizer.update, CUTSCENE_SPEED times while Circle is held in a cutscene
## (VillageStory, COTZ-007). Most cutscene motion moves a fixed step per
## update (actors, the camera, zooms), so the update is repeated instead of
## given a longer elapsed time; the music, the Scheduler and the fades done
## per drawn frame keep their pace. The extra updates stop when the mode
## changes (the cutscene ends) or starts loading. A skipped cutscene gets
## CUTSCENE_SKIP_SPEED updates and Cross before each of them.
func _update_organizer(elapsed: float) -> void:
	var mode: GameMode = organizer.getCurrentMode()
	var skipped: VillageStory = mode as VillageStory if _skipping_cutscene(mode) else null
	var steps := CUTSCENE_SPEED if _fast_cutscene(mode) else 1
	if skipped != null:
		steps = CUTSCENE_SKIP_SPEED
		skipped.timeLine.crossPressed()
	organizer.update(elapsed)
	for i in range(steps - 1):
		if organizer.getCurrentMode() != mode or mode.isLoading():
			break
		if skipped != null:
			skipped.timeLine.crossPressed()
		organizer.update(elapsed)


## Runs the given cutscene to its end: its updates and dialogs as fast as
## _update_organizer goes (the console's "skip cutscene", COTZ-018).
func skip_cutscene(story: VillageStory) -> void:
	_skip_cutscene_id = story.get_instance_id()


## True while the cutscene to skip is the current mode and has loaded.
func _skipping_cutscene(mode: GameMode) -> bool:
	if _skip_cutscene_id == 0:
		return false
	if mode == null or mode.get_instance_id() != _skip_cutscene_id:
		_skip_cutscene_id = 0
		return false
	return not mode.isLoading()


## True while Circle is held in a cutscene. Circle has to be let go once
## after the cutscene started: one held while sprinting into a story trigger
## does not speed it up.
func _fast_cutscene(mode: GameMode) -> bool:
	if not (mode is VillageStory) or mode.isLoading():
		_cutscene_id = 0
		return false
	var held: bool = GameCore.gameActions[GameMode.CIRCLE].isPressedDontReset()
	if mode.get_instance_id() != _cutscene_id:
		_cutscene_id = mode.get_instance_id()
		_cutscene_armed = not held
	elif not held:
		_cutscene_armed = true
	return held and _cutscene_armed


## Shows the current game mode's scene (GameMode.shown_scene) under World
## while the mode is not loading; the scene of a mode that is no longer
## current is removed from the tree but not freed (GameMode frees it).
func _sync_world() -> void:
	var mode: GameMode = organizer.getCurrentMode()
	var scene: Node = null
	if mode != null and not mode.isLoading():
		scene = mode.shown_scene()
	if not is_instance_valid(_world_scene):
		_world_scene = null
	if scene == _world_scene:
		return
	if _world_scene != null and _world_scene.get_parent() == world:
		world.remove_child(_world_scene)
	# A Camera2D in the removed scene leaves the canvas transform behind.
	get_viewport().canvas_transform = Transform2D.IDENTITY
	_world_scene = scene
	if scene != null:
		world.add_child(scene)


func _enter_tree() -> void:
	Engine.set_meta("start_ms", Time.get_ticks_msec())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OggStreamer.stopAll()


func _exit_tree() -> void:
	if backend != null:
		backend.free_all()
	# The scenes of modes that are not shown (suspended for the menu, or the
	# previous mode) are not in the tree: free them, and the dungeon
	# materials, before the renderer shuts down (it reports them otherwise).
	if organizer != null:
		var modes: Array = [organizer.currentGameMode, organizer.previousGameMode]
		modes.append_array(organizer.suspendedGameModes.queue)
		for m in modes:
			if m != null and is_instance_valid(m.scene_root) and not m.scene_root.is_inside_tree():
				m.scene_root.free()
	DungeonMaterials.clear_cache()
