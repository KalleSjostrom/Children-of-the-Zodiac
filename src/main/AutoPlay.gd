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
##                        name becomes a running number, for shots in loops)
##   log <text>           print text (and the current game mode, see _state)
##   pos [text]           print the player's village position (dev, for planning
##                        routes): "pos <text> x=<x> y=<y> dir=<d> back=<x>,<y>"
##                        in village pixels (back: the background scroll), or
##                        "pos <text> -" outside a village
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
##   quit                 quit the game
## Buttons: TRIANGLE CIRCLE CROSS SQUARE L1 R1 L2 R2 SELECT START UP DOWN LEFT RIGHT

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


func update(elapsed: float) -> void:
	time_ms += elapsed
	for r in _releases.duplicate():
		r.t -= elapsed
		if r.t <= 0:
			input.releaseButton(r.b)
			_releases.erase(r)
	wait_ms -= elapsed
	while wait_ms <= 0 and pos < lines.size():
		var parts := lines[pos].split(" ", false)
		pos += 1
		match parts[0]:
			"wait":
				wait_ms += float(parts[1])
			"tap":
				var b := button(parts[1])
				input.pressButton(b)
				_releases.append({"b": b, "t": float(parts[2]) if parts.size() > 2 else 120.0})
			"press":
				input.pressButton(button(parts[1]))
			"release":
				input.releaseButton(button(parts[1]))
			"shot":
				_shot_counter += 1
				_pending_shot = parts[1].replace("#", "%03d" % _shot_counter)
				print("[autoplay %.0f ms] shot %s %s" % [time_ms, parts[1], _state()])
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
## village story), "-" elsewhere. Positions are Values [y, x] arrays.
func _player_pos() -> String:
	var o := Organizer.getOrganizer()
	if o == null or o.currentGameMode == null:
		return "-"
	var village = o.currentGameMode
	if village is VillageStory:
		village = village.village
	if not (village is Village) or village.player == null:
		return "-"
	var p: Array = village.player.getPos()
	var b: Array = village.background.getPos()
	return "x=%.1f y=%.1f dir=%d back=%d,%d" % [p[Values.X], p[Values.Y],
		village.player.getDirection(), int(b[Values.X]), int(b[Values.Y])]


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
