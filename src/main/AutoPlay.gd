class_name AutoPlay
extends RefCounted
## Scripted input for testing the port (Main --autoplay=<file>).
##
## Script lines (times in milliseconds of game time):
##   wait <ms>            wait before the next command
##   tap <BUTTON> [ms]    press and release after ms (default 120)
##   press <BUTTON>       press and hold
##   release <BUTTON>     release
##   shot <name>          save a screenshot <shots dir>/<name>.png ("#" in the
##                        name becomes a running number, for shots in loops);
##                        in a zoomed cutscene also "[zoom] <name> scale=<s>"
##   log <text>           print text (and the current game mode, see _state)
##   pos [text]           print the player's village position (dev, for planning
##                        routes): "pos <text> x=<x> y=<y> dir=<d> back=<x>,<y>"
##                        in village pixels (back: the background scroll); in a
##                        labyrinth "pos <text> node=<address> dir=<d>
##                        cam=<x>,<z> angle=<a>" (the node, the facing 0-3 and
##                        the camera's location and angle in dungeon units and
##                        degrees); "pos <text> -" elsewhere
##   mark                 remember this line as the start of a loop (marks nest)
##   loopuntil <text> <ms> jump back to the last mark unless the state string
##                        ("mode=... sub=... place=...") contains <text>, or
##                        <ms> have passed since the mark was first reached
##                        ("!<text>": until the state does NOT contain <text>)
##   key <KEY>            press and release a keyboard key (a real key event,
##                        Godot's key names: F1, Enter, Escape, Tab, Up ...)
##   type <text>          type the text as key events (for the debug console)
##   console <line>       run a debug console command (DebugConsole, debug
##                        builds), e.g. "console cheater", "console goto Alares"
##   heading              remember the village player's facing, for the buttons
##                        AHEAD, BEHIND, ALEFT and ARIGHT (directions relative to
##                        it; a village's start facing points into the village)
##   guard <px>           in a village, let go of a held direction before the
##                        player gets within px of the village's edge or into
##                        the range of a hole door that opens in that direction
##                        (so a walk stays in the place); 0: off.
##                        Prints "guard <button> x=... y=..." when it lets go
##   quit                 quit the game
## Buttons: TRIANGLE CIRCLE CROSS SQUARE L1 R1 L2 R2 SELECT START UP DOWN LEFT RIGHT,
## and AHEAD BEHIND ALEFT ARIGHT after "heading"

var input := FakeInputManager.new()
var lines: PackedStringArray = []
var pos := 0
var wait_ms := 0.0
var shots_dir := ""
var _pending_shot := ""
var _releases: Array = []
var time_ms := 0.0
var _shot_counter := 0
var _marks: Array = [] # [line after the mark, time first reached]
var _heading := -1 # Values.UP.. LEFT, set by "heading"
var _guard := 0.0 # "guard" distance in village pixels, 0: off
var _held := {} # direction buttons held by press/tap -> true

const RELATIVE := {"AHEAD": 0, "ARIGHT": 1, "BEHIND": 2, "ALEFT": 3}


func _init(script_path: String, p_shots_dir: String) -> void:
	shots_dir = p_shots_dir
	var text := FileAccess.get_file_as_string(script_path)
	if text == "":
		push_error("AutoPlay: could not read " + script_path)
	for l in text.split("\n"):
		var t := l.strip_edges()
		if t != "" and not t.begins_with("#"):
			lines.append(t)


static func button(name: String) -> int:
	var map := {"TRIANGLE": GameMode.TRIANGLE, "CIRCLE": GameMode.CIRCLE,
		"CROSS": GameMode.CROSS, "SQUARE": GameMode.SQUARE, "L1": GameMode.L1,
		"R1": GameMode.R1, "L2": GameMode.L2, "R2": GameMode.R2,
		"SELECT": GameMode.SELECT, "START": GameMode.START, "UP": GameMode.UP,
		"DOWN": GameMode.DOWN, "LEFT": GameMode.LEFT, "RIGHT": GameMode.RIGHT}
	return map.get(name.to_upper(), -1)


## button() for the relative names AHEAD, BEHIND, ALEFT and ARIGHT too
## (relative to the facing remembered by "heading").
func _button(name: String) -> int:
	var rel: int = RELATIVE.get(name.to_upper(), -1)
	if rel == -1:
		return button(name)
	if _heading == -1:
		push_warning("AutoPlay: %s before heading; UP is ahead" % name)
	return GameMode.UP + (maxi(_heading, 0) + rel) % 4


func _press(b: int) -> void:
	input.pressButton(b)
	if b >= GameMode.UP and b <= GameMode.LEFT:
		_held[b] = true


func _release(b: int) -> void:
	input.releaseButton(b)
	_held.erase(b)


func update(elapsed: float) -> void:
	time_ms += elapsed
	for r in _releases.duplicate():
		r.t -= elapsed
		if r.t <= 0:
			_release(r.b)
			_releases.erase(r)
	wait_ms -= elapsed
	while wait_ms <= 0 and pos < lines.size():
		var parts := lines[pos].split(" ", false)
		pos += 1
		match parts[0]:
			"wait":
				wait_ms += float(parts[1])
			"tap":
				var b := _button(parts[1])
				_press(b)
				_releases.append({"b": b, "t": float(parts[2]) if parts.size() > 2 else 120.0})
			"press":
				_press(_button(parts[1]))
			"release":
				_release(_button(parts[1]))
			"heading":
				var village = _village()
				_heading = village.player.getDirection() if village != null else Values.UP
				print("[autoplay %.0f ms] heading %d" % [time_ms, _heading])
			"guard":
				_guard = float(parts[1])
			"shot":
				_shot_counter += 1
				_pending_shot = parts[1].replace("#", "%03d" % _shot_counter)
				print("[autoplay %.0f ms] shot %s %s" % [time_ms, parts[1], _state()])
				_print_zoom()
			"log":
				print("[autoplay %.0f ms] %s %s" % [time_ms, " ".join(parts.slice(1)), _state()])
			"pos":
				print("[autoplay %.0f ms] pos %s %s" % [time_ms, " ".join(parts.slice(1)), _player_pos()])
			"mark":
				# Marks nest: loopuntil uses (and on exit pops) the innermost one.
				if _marks.is_empty() or _marks.back()[0] != pos:
					_marks.append([pos, time_ms])
			"loopuntil":
				var st := _state()
				var want: String = parts[1]
				var met: bool = (not st.contains(want.substr(1))) if want.begins_with("!") else st.contains(want)
				var mark_time: float = _marks.back()[1] if not _marks.is_empty() else time_ms
				if met:
					print("[autoplay %.0f ms] loopuntil %s reached: %s" % [time_ms, parts[1], st])
					_marks.pop_back()
				elif time_ms - mark_time >= float(parts[2]):
					print("[autoplay %.0f ms] loopuntil %s TIMED OUT: %s" % [time_ms, parts[1], st])
					_marks.pop_back()
				elif not _marks.is_empty():
					pos = _marks.back()[0]
			"key":
				_send_key(OS.find_keycode_from_string(parts[1]), 0)
			"type":
				var text := lines[pos - 1].substr(lines[pos - 1].find(" ") + 1)
				for ch in text:
					_send_key(OS.find_keycode_from_string(ch.to_upper()) if ch != " " else KEY_SPACE,
							ch.unicode_at(0))
			"console":
				var line := lines[pos - 1].substr(lines[pos - 1].find(" ") + 1)
				if Main.instance != null and Main.instance.debug_console != null:
					Main.instance.debug_console.run(line)
				else:
					push_warning("AutoPlay: no debug console for: " + line)
			"quit":
				print("[autoplay] quit at %.0f ms" % time_ms)
				Scheduler.tree.quit()
			_:
				push_warning("AutoPlay: unknown command " + parts[0])
	if _guard > 0.0 and not _held.is_empty():
		_check_guard()


## "guard": lets go of each held direction that would take the village player
## within _guard pixels of the village's edge (Village.update leaves the
## place there) or into a hole door's range. Positions are Values [y, x].
func _check_guard() -> void:
	var village = _village()
	if village == null or Organizer.getOrganizer().currentGameMode != village:
		return
	var p: Array = village.player.getPos()
	for b: int in _held.keys():
		var d: int = b - GameMode.UP
		var x: float = p[Values.X] + (_guard if d == Values.RIGHT else -_guard if d == Values.LEFT else 0.0)
		var y: float = p[Values.Y] + (_guard if d == Values.DOWN else -_guard if d == Values.UP else 0.0)
		var leaves: bool = x < 0 or x > village.backgroundWidth or y < 0 or y > village.backgroundHeight
		if not leaves:
			# A hole door takes the player only when walking in one of its
			# directions (Door.canBeOpened, not called here: it may change the
			# door's state).
			var ahead := Values.createNormalFloatPoint(x, y)
			for door in village.holeDoors:
				if door.directions.has(d) and door.isInRange(ahead):
					leaves = true
					break
		if leaves:
			_release(b)
			print("[autoplay %.0f ms] guard %d x=%.1f y=%.1f" % [time_ms, d, p[Values.X], p[Values.Y]])


## For a shot in a cutscene that is zoomed (VillageStoryTimeLine scales the
## drawing around a static position; after a zoom out the scale stays a
## little above 1): "[zoom] <shot> scale=<s>". Not an "[autoplay" line, so
## parity compares do not see it; it tells which shots a zoom resamples.
func _print_zoom() -> void:
	var o := Organizer.getOrganizer()
	if o == null or not (o.currentGameMode is VillageStory) or o.currentGameMode.timeLine == null:
		return
	var t = o.currentGameMode.timeLine
	if t.scaling and t.useStaticPos:
		print("[zoom] %s scale=%.6f" % [_pending_shot, t.scale])


## The current village (also the one under a village story), or null.
func _village():
	var o := Organizer.getOrganizer()
	if o == null or o.currentGameMode == null:
		return null
	var village = o.currentGameMode
	if village is VillageStory:
		village = village.village
	if not (village is Village) or village.player == null:
		return null
	return village


## Sends a key press and release as real input events.
static func _send_key(keycode: Key, unicode: int) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.unicode = unicode
		ev.pressed = pressed
		Input.parse_input_event(ev)


## "mode=<Java class of the current game mode> place=<current place>", so
## headless runs show where the game is. "world=<node>" when Main's World
## shows a scene (docs/ARCHITECTURE.md).
func _state() -> String:
	var o := Organizer.getOrganizer()
	if o == null or o.currentGameMode == null:
		return "mode=<none>"
	var gm = o.currentGameMode
	var s := "mode=%s" % ClassRegistry.getClassName(gm)
	# Labyrinth runs battles/riddles as a sub game mode in labDrawable.
	if "runSubGameMode" in gm and gm.runSubGameMode and "labDrawable" in gm and gm.labDrawable != null:
		s += " sub=%s" % ClassRegistry.getClassName(gm.labDrawable)
		var b = gm.labDrawable.get("battle")
		if b != null and "mode" in b:
			s += " battlemode=%d" % b.mode
			if "enemies" in b and b.enemies != null:
				var names := []
				for e in b.enemies:
					names.append(str(e.getName()) if e != null and e.has_method("getName") else "?")
				s += " enemies=%s" % ",".join(names).replace(" ", "_")
	if Main.instance != null and Main.instance.world.get_child_count() > 0:
		s += " world=%s" % Main.instance.world.get_child(0).name
	return s + " place=%s fps=%d" % [str(o.nextPlace), Engine.get_frames_per_second()]


## "x=<x> y=<y> dir=<d> back=<x>,<y>" of the village player (also during a
## village story), the labyrinth position (_labyrinth_pos), "-" elsewhere.
## Village positions are Values [y, x] arrays.
func _player_pos() -> String:
	var village = _village()
	if village == null:
		return _labyrinth_pos()
	var p: Array = village.player.getPos()
	var b: Array = village.background.getPos()
	return "x=%.1f y=%.1f dir=%d back=%d,%d" % [p[Values.X], p[Values.Y],
		village.player.getDirection(), int(b[Values.X]), int(b[Values.Y])]


## "node=<address> dir=<facing 0-3> cam=<x>,<z> angle=<degrees>" in the
## current labyrinth (also during its battles), "-" elsewhere. The camera's
## location and angle are LabyrinthPlayer's, interpolated while moving or
## turning.
func _labyrinth_pos() -> String:
	var o := Organizer.getOrganizer()
	if o == null or not (o.currentGameMode is Labyrinth):
		return "-"
	var lab: Labyrinth = o.currentGameMode
	if lab.isLoading() or lab.player == null or lab.currentNode == null:
		return "-"
	var cam = lab.player.camera
	return "node=%d dir=%d cam=%.3f,%.3f angle=%.2f" % [lab.currentNode.getAddress(),
		lab.dir, cam.location[LabyrinthPosition.X], cam.location[LabyrinthPosition.Z], cam.angle]


func after_draw(node: Node) -> void:
	if _pending_shot == "" or shots_dir == "":
		return
	var tex := node.get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null:
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	var path := shots_dir.path_join(_pending_shot + ".png")
	img.save_png(path)
	print("[autoplay] screenshot " + path)
	_pending_shot = ""
