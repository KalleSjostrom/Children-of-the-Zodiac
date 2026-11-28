extends Node
## The autoload "Game" (phase 4.3; docs/ARCHITECTURE.md section 17): which
## game mode runs, the one before it and the suspended ones, the place asked
## for last, the switches between them and main.bank's places
## (PlaceRegistry). It took over the Java's organizer.Organizer with its rules
## unchanged:
##
## * The loading gate: a new mode is updated and drawn only after it has
##   loaded; draw ends the loading (ImageHandler's queue is always empty), so
##   a mode made in a frame's update draws in that frame and updates in the
##   next one.
## * Previous and current: a switch keeps the current mode as previous_mode
##   (alive until the next switch); a suspended one (left for the menu, a
##   store, a house or a villager's story) goes onto the suspended stack.
##   Going back (Values.SWITCH_BACK) resumes the stack's top, or swaps the
##   current and the previous mode when the stack is empty.
## * Exit after the fade: a mode's checkExit reports its exit mode once the
##   mode is done (GameMode: when its fade out ends, in its draw) or at once
##   for the menu. update then calls the mode's finishOff before it reads the
##   exit mode, the next place and its info: the title loads the game there.
## * next_place, the place asked for last (AutoPlay's "place="): "" after a
##   mode that names none (the menu, a store, a villager's story, going back).
## * jump_to (the debug console) leaves the current mode at once: no
##   finishOff, no fade, the suspended stack kept.
##
## Main calls start once (its command line), then update and draw in every
## frame (Main._process); nothing here runs on its own. The music policy and
## the rules inside the modes (the fade's done set in the draw) stay in
## GameMode until step C.

## The place the game starts at without --start or --load.
const TITLE_SCREEN := "Title Screen"

## main.bank's places (start reads them).
var places: PlaceRegistry
## The mode that runs (null before start).
var current_mode: GameMode
## The mode before it. The legacy modes read it (the menu's thumbnail and
## music, the music a mode continues, a villager's story's village) and a
## villager's story sets it (VillageStory).
var previous_mode: GameMode
## The place asked for last: a main.bank name or a prefixed one
## (PlaceRegistry), "" after a mode that names none.
var next_place: String = TITLE_SCREEN

var _suspended: Array[GameMode] = [] # the suspended modes, the last one first
var _mode := 0 # the mode the next switch makes (Values.TITLE, VILLAGE, ...)
var _next := true # whether the next switch reads next_place's info from main.bank
var _info: Variant = {} # the info the next mode gets (a Dictionary, or null)
var _class_map: Dictionary = {} # Values.getClassMap: mode -> the Java class name
var _core: GameCore # the input devices' setup, the pause and the pad lost overlay
var _start_time := "" # --start-time, for the first place only


## Starts the game from Main's command line options (Main._parse_args):
## --start=<place> ("_" for a space), --load=<slot>, --start-time=<day|night>,
## --status=<name>:<value>,... and --start-node=<address>:<direction> (the
## header of src/main/Main.gd). devices: the input devices Main adds
## (AutoPlay's). Parses main.bank and makes the first mode.
func start(options: Dictionary, devices: Array) -> void:
	_core = GameCore.new()
	_core.init()
	if options.has("start"):
		next_place = String(options["start"]).replace("_", " ")
	var load_slot := String(options.get("load", ""))
	if options.has("start-time"):
		_start_time = String(options["start-time"])
	var statuses := {}
	if options.has("status"):
		for s in String(options["status"]).split(",", false):
			var kv := s.split(":")
			statuses[kv[0]] = int(kv[1])
	var start_node: Array[int] = []
	if options.has("start-node"):
		var nd := String(options["start-node"]).split(":")
		start_node = [int(nd[0]), int(nd[1])]
	_core.init2(devices)
	_class_map = Values.getClassMap()
	places = PlaceRegistry.new()
	places.read()
	if load_slot != "":
		Load.loadGame(load_slot)
		if next_place == TITLE_SCREEN:
			next_place = str(Load.getStartLocation())
	for status_name: String in statuses:
		Database.addStatus(Values.convert(status_name), statuses[status_name])
	if start_node.size() == 2:
		# A labyrinth place starts at this node and facing, as a game saved
		# there does (COTZ-005).
		var place := places.get_place(next_place)
		if place != null and place.fields.has("map"):
			Load.labyrinthPosition = [place.map.replace(".map", ""), start_node[0], start_node[1]]
	_init_next()


## Updates the current mode and switches when it exits. elapsed_ms: the
## frame's game time in milliseconds.
func update(elapsed_ms: float) -> void:
	if current_mode == null or current_mode.isLoading():
		return
	current_mode.update(elapsed_ms)
	# Java: Select + Down opened the Cheater here; the debug console's
	# "cheater" does now (open_cheater, COTZ-006).
	if current_mode.checkExit() != Values.NO_MODE_IS_SELECTED:
		current_mode.finishOff()
		_mode = current_mode.getExitMode()
		_next = current_mode.shouldGetInfoFromMain()
		next_place = current_mode.getNextPlace()
		_info = current_mode.getInfoForNextPlace()
		if _mode == Values.SWITCH_BACK:
			_go_back()
		else:
			_init_next()


## The frame's drawing (the Java's GameCore.testDraw): Start's pause, the
## current mode behind the loading gate, then "Paused" or the game pad lost
## overlay.
func draw(g: Graphics) -> void:
	_core.preDraw(is_pausable())
	_draw_mode(g)
	g.checkError()
	_core.drawOverlays(g)


## Goes to a main.bank place now (the debug console), leaving the current
## mode without its finishOff or a fade, as the Cheater's jumps do; the
## suspended modes stay. The "Start" game is loaded first when none is.
func jump_to(place: String) -> void:
	if not Load.hasLoaded():
		Load.loadGame("Start")
	if current_mode != null:
		current_mode.exitWithoutFading(Values.EXIT)
	next_place = place
	_next = true
	_init_next()


## Opens the developer Cheater's menu of places (what Select + Down did,
## COTZ-006).
func open_cheater() -> void:
	if current_mode == null or current_mode is Cheater:
		return
	current_mode.exitWithoutFading(Values.CHEATER)
	_mode = current_mode.getExitMode()
	_init_next()


## The suspended mode a switch back resumes, or null.
func next_suspended_mode() -> GameMode:
	return null if _suspended.is_empty() else _suspended[0]


## Exits every suspended mode (Values.EXIT) and empties the stack: a village
## that is left drops the houses and stores it was suspended for.
func delete_suspended() -> void:
	while not _suspended.is_empty():
		_suspended.pop_front().exit(Values.EXIT)


## The suspended modes, the last one first.
func suspended_modes() -> Array[GameMode]:
	return _suspended.duplicate()


## True when Start pauses the current mode.
func is_pausable() -> bool:
	return current_mode != null and current_mode.isPausable()


## Drops the modes and the places at exit (Main._exit_tree, after it freed
## the scenes that are not shown and ExitCleanup released the cycles).
func release() -> void:
	current_mode = null
	previous_mode = null
	_suspended.clear()
	_info = null
	places = null


func _draw_mode(g: Graphics) -> void:
	ImageHandler.load(g)
	if current_mode == null:
		return
	if ImageHandler.getLoadQueueSize() == 0:
		current_mode.loadingDone()
	if current_mode.isLoading():
		return
	current_mode.draw(g)


## Makes the next mode (_mode, with next_place's info when _next).
func _init_next() -> void:
	var new_place := _next
	var leaving := current_mode
	_check_next()
	ImageHandler.setGameMode(_mode)
	if _mode == Values.LABYRINTH or _mode == Values.BOSS_BATTLE_AREA:
		Values.zoom(false)
		GameEventListener.set3D()
	elif _mode == Values.VILLAGE or _mode == Values.VILLAGE_STORY:
		Values.zoom(true)
		GameEventListener.set2D()
	else:
		Values.zoom(false)
		GameEventListener.set2D()
	var java_class: String = _class_map.get(_mode, "")
	if java_class == "":
		push_error("Game: no game mode class for mode " + str(_mode))
		return
	previous_mode = current_mode
	if current_mode != null and current_mode.isSuspended():
		_suspended.push_front(current_mode)
	current_mode = ClassRegistry.newInstance(java_class)
	var info: Variant = _info
	if _start_time != "" and info is Dictionary:
		# --start-time: the first place's info only.
		info = info.duplicate()
		info["time"] = _start_time
		_start_time = ""
	current_mode.init(info)
	_autosave_on_entering(new_place, leaving)


## Reads next_place's place and info from main.bank when the switch asks for
## it (an unknown place goes to the title, where Java threw).
func _check_next() -> void:
	if not _next:
		return
	var place := places.resolve(next_place)
	if place == null:
		push_error("Game: unknown place '%s' (not in main.bank)" % next_place)
		next_place = TITLE_SCREEN
		place = places.resolve(next_place)
	_info = places.info_of(place)
	_mode = place.mode
	_next = false


## Goes back to the last suspended mode, or to the previous one.
func _go_back() -> void:
	ImageHandler.swapGameMode()
	if _suspended.is_empty():
		var left := current_mode
		current_mode = previous_mode
		previous_mode = left
	else:
		previous_mode = current_mode
		current_mode = _suspended.pop_front()
	current_mode.resume()


## Port addition (COTZ-005): autosaves (Easy and Medium) when a village, a
## labyrinth floor, the world map or the airship is entered from another
## place; not when a game is loaded (from the title, the menu or the command
## line): that would overwrite the autosave with an older game.
func _autosave_on_entering(new_place: bool, leaving: GameMode) -> void:
	if not new_place or leaving == null or leaving is TitleScreen or leaving is MainMenu:
		return
	if _mode == Values.VILLAGE or _mode == Values.LABYRINTH or _mode == Values.LANDSCAPE \
			or _mode == Values.AIR_SHIP:
		Save.autosave_at(next_place)
