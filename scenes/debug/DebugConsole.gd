class_name DebugConsole
extends CanvasLayer
## The developer console (COTZ-006), in debug builds (Main adds it): the key
## under Escape (§ or `) or F1 opens it over the top half of the screen, and
## a command typed there runs with Enter. "help" lists the commands
## (DebugCommands); they replace the developer Cheater.
##
## What is typed is completed as it goes: the suggestions under the line are
## the commands, or the options of the argument being typed; Tab takes the
## one picked and Up and Down pick another. Without suggestions Up and Down
## go through the lines run before, which are kept between runs
## (HISTORY_PATH). Escape or the key that opened it closes it.
##
## While it is open it has the keyboard: Main does not hand key events to
## the game then (Main._input), the line edit gets them, and opening it
## releases the game's buttons so that none stays held. A game pad keeps
## playing. The game is not paused.
##
## Built in code, after the Democracy Defenders console.

## The keys that open and close it: the key under Escape and F1.
const TOGGLE_KEYS: Array[Key] = [KEY_QUOTELEFT, KEY_SECTION, KEY_F1]
## Over the game's layers (LegacyLayer 1, UI 2, Transition 3).
const LAYER := 50
const FONT_NAMES: PackedStringArray = ["Consolas", "Cascadia Mono", "Courier New", "monospace"]
const FONT_SIZE := 15
## How much of the screen's height it takes.
const HEIGHT := 0.5
## Shown at once; the list scrolls with the one picked.
const MAX_SUGGESTIONS := 10
const SUGGESTIONS_WIDTH := 0.9
const MAX_HISTORY := 100
const MAX_OUTPUT_PARAGRAPHS := 1000
const HISTORY_PATH := "user://debug_console_history.txt"
const BACKGROUND := Color(0.05, 0.06, 0.08, 0.9)
const ECHO_COLOR := Color(0.55, 0.6, 0.7)
const TEXT_COLOR := Color(0.92, 0.92, 0.92)
const ERROR_COLOR := Color(1.0, 0.45, 0.4)
const PICKED_COLOR := Color(1.0, 0.85, 0.3)
const HINT_COLOR := Color(0.55, 0.6, 0.7)

var commands: DebugCommands
## Where the lines run are kept between runs, "" for nowhere.
var history_path := HISTORY_PATH
var is_open := false

var _panel: PanelContainer
var _output: RichTextLabel
var _line: LineEdit
var _suggestion_box: PanelContainer
var _suggestion_text: RichTextLabel

var _suggestions: Array[DebugCommands.Suggestion] = []
## The suggestion Tab takes, -1 for none.
var _picked := -1
## Lines run, the latest last.
var _history: PackedStringArray = []
## Going through the history: how far back (0 the latest), -1 on the line
## being typed.
var _history_index := -1
## The line being typed, while going through the history.
var _typed := ""


func _ready() -> void:
	layer = LAYER
	commands = DebugCommands.new(self)
	_load_history()
	_build()
	_panel.visible = false
	_suggestion_box.visible = false


func _build() -> void:
	var font := SystemFont.new()
	font.font_names = FONT_NAMES
	var console_theme := Theme.new()
	console_theme.default_font = font
	console_theme.default_font_size = FONT_SIZE
	var background := StyleBoxFlat.new()
	background.bg_color = BACKGROUND
	background.set_content_margin_all(4)

	var screen: Vector2 = get_viewport().get_visible_rect().size
	_panel = PanelContainer.new()
	_panel.theme = console_theme
	_panel.add_theme_stylebox_override("panel", background)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_bottom = roundf(screen.y * HEIGHT)
	add_child(_panel)
	var rows := VBoxContainer.new()
	_panel.add_child(rows)

	_output = RichTextLabel.new()
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.focus_mode = Control.FOCUS_NONE
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", TEXT_COLOR)
	rows.add_child(_output)

	_line = LineEdit.new()
	_line.keep_editing_on_text_submit = true
	_line.placeholder_text = "help lists the commands"
	_line.context_menu_enabled = false
	_line.text_changed.connect(_on_line_text_changed)
	_line.text_submitted.connect(_on_line_text_submitted)
	rows.add_child(_line)

	_suggestion_box = PanelContainer.new()
	_suggestion_box.theme = console_theme
	_suggestion_box.add_theme_stylebox_override("panel", background)
	_suggestion_box.position = Vector2(0, _panel.offset_bottom)
	_suggestion_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_suggestion_box)
	_suggestion_text = RichTextLabel.new()
	_suggestion_text.fit_content = true
	_suggestion_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_suggestion_text.custom_minimum_size.x = roundf(screen.x * SUGGESTIONS_WIDTH)
	_suggestion_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_suggestion_box.add_child(_suggestion_text)


func open() -> void:
	if is_open:
		return
	is_open = true
	_release_game_buttons()
	_panel.visible = true
	_line.grab_focus()
	_line.edit()
	_refresh_suggestions()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_panel.visible = false
	_suggestion_box.visible = false
	_line.unedit()
	_line.release_focus()


## Runs the line as if typed and shows what came of it, the console open or
## not (AutoPlay's "console" lines use it).
func run(line: String) -> DebugCommands.Result:
	_print("> " + line, ECHO_COLOR)
	var result: DebugCommands.Result = commands.run(line)
	if result == null: # the command failed with a script error
		result = DebugCommands.fail("The command failed (see the log)")
	print("DebugConsole: > %s%s%s" % [line, "" if result.ok else " FAILED",
			"" if result.text == "" else "
" + result.text])
	if result.text != "":
		_print(result.text, TEXT_COLOR if result.ok else ERROR_COLOR)
	return result


func clear_output() -> void:
	_output.clear()


func _print(text: String, color: Color) -> void:
	if _output.get_paragraph_count() > MAX_OUTPUT_PARAGRAPHS:
		_output.remove_paragraph(0)
	if not _output.get_parsed_text().is_empty():
		_output.newline()
	_output.push_color(color)
	_output.add_text(text)
	_output.pop()


## Releases every button the game sees as held (the key that opens the
## console may come while one is down).
static func _release_game_buttons() -> void:
	for action in GameCore.gameActions:
		if action != null:
			action.release()


# --- Input ---

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null:
		return
	if key.pressed and not key.echo and _is_toggle(key):
		if is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not is_open or not key.pressed:
		return
	match key.keycode:
		KEY_ESCAPE:
			close()
		KEY_TAB:
			_take_suggestion()
		KEY_UP:
			_go(-1)
		KEY_DOWN:
			_go(1)
		KEY_PAGEUP:
			_scroll(-1)
		KEY_PAGEDOWN:
			_scroll(1)
		_:
			return # typing: the line edit gets it through the GUI
	get_viewport().set_input_as_handled()


static func _is_toggle(key: InputEventKey) -> bool:
	return TOGGLE_KEYS.has(key.keycode) or TOGGLE_KEYS.has(key.physical_keycode) \
			or key.unicode == "§".unicode_at(0) or key.unicode == "`".unicode_at(0)


func _on_line_text_changed(_text: String) -> void:
	_history_index = -1
	_refresh_suggestions()


func _on_line_text_submitted(line: String) -> void:
	_line.clear()
	_history_index = -1
	if line.strip_edges() != "":
		_remember(line.strip_edges())
		run(line.strip_edges())
	_refresh_suggestions()


## Up (-1) or down (1): to another suggestion while there are some to take,
## else through the history.
func _go(step: int) -> void:
	if _history_index < 0 and _picked >= 0:
		_pick(step)
	else:
		_browse_history(-step)


func _scroll(pages: int) -> void:
	var bar: VScrollBar = _output.get_v_scroll_bar()
	bar.value += pages * bar.page


# --- Suggestions ---

func _refresh_suggestions() -> void:
	_suggestions = commands.complete(_line.text) if is_open and _history_index < 0 else []
	_picked = -1
	for i in range(_suggestions.size()):
		if _suggestions[i].line != "":
			_picked = i
			break
	_show_suggestions()


## The next suggestion that can be taken, that way round.
func _pick(step: int) -> void:
	var count: int = _suggestions.size()
	for i in range(1, count + 1):
		var index: int = posmod(_picked + step * i, count)
		if _suggestions[index].line != "":
			_picked = index
			break
	_show_suggestions()


func _take_suggestion() -> void:
	if _history_index >= 0 or _picked < 0:
		return
	_line.text = _suggestions[_picked].line
	_line.caret_column = _line.text.length()
	_refresh_suggestions()


func _show_suggestions() -> void:
	_suggestion_box.visible = not _suggestions.is_empty()
	if _suggestions.is_empty():
		return
	_suggestion_text.clear()
	var first: int = clampi(_picked - MAX_SUGGESTIONS + 1, 0, maxi(_suggestions.size() - MAX_SUGGESTIONS, 0))
	var last: int = mini(first + MAX_SUGGESTIONS, _suggestions.size())
	for i in range(first, last):
		var suggestion: DebugCommands.Suggestion = _suggestions[i]
		if i > first:
			_suggestion_text.newline()
		var color: Color = PICKED_COLOR if i == _picked else (HINT_COLOR if suggestion.line == "" else TEXT_COLOR)
		_suggestion_text.push_color(color)
		_suggestion_text.add_text(("> " if i == _picked else "  ") + suggestion.label)
		_suggestion_text.pop()
		if suggestion.detail != "":
			_suggestion_text.push_color(HINT_COLOR)
			_suggestion_text.add_text("   " + suggestion.detail)
			_suggestion_text.pop()
	if _suggestions.size() > last or first > 0:
		_suggestion_text.newline()
		_suggestion_text.push_color(HINT_COLOR)
		_suggestion_text.add_text("  (%d of %d)" % [_picked + 1, _suggestions.size()])
		_suggestion_text.pop()
	_suggestion_box.reset_size()


# --- History ---

## Further back (1) or forward (-1) through the lines run before, back to the
## one being typed.
func _browse_history(step: int) -> void:
	var index: int = clampi(_history_index + step, -1, _history.size() - 1)
	if index == _history_index:
		return
	if _history_index < 0:
		_typed = _line.text
	_history_index = index
	_line.text = _typed if index < 0 else _history[_history.size() - 1 - index]
	_line.caret_column = _line.text.length()
	if index < 0:
		_refresh_suggestions()
	else:
		_suggestions = []
		_picked = -1
		_show_suggestions()


func _remember(line: String) -> void:
	if not _history.is_empty() and _history[_history.size() - 1] == line:
		return
	_history.push_back(line)
	if _history.size() > MAX_HISTORY:
		_history = _history.slice(_history.size() - MAX_HISTORY)
	if history_path == "":
		return
	var file := FileAccess.open(history_path, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_history))


func _load_history() -> void:
	if history_path == "" or not FileAccess.file_exists(history_path):
		return
	for line in FileAccess.get_file_as_string(history_path).split("\n", false):
		_history.push_back(line)
	if _history.size() > MAX_HISTORY:
		_history = _history.slice(_history.size() - MAX_HISTORY)


func _process(_delta: float) -> void:
	# A click elsewhere takes the focus off the line; the keyboard stays the
	# console's.
	if is_open and not _line.has_focus():
		_line.grab_focus()
		_line.edit()
