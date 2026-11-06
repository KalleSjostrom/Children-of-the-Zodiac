extends CanvasLayer
## The HD look's tuning panel (docs/LOOK_PROTOTYPES_PLAN.md 10.7, 10.8): F2
## shows or hides it on an HD floor; Escape hides it too, and does not quit the
## game while it is shown. A row per setting of HDLook.KNOBS: a slider to drag
## and a box with the value to type in (Enter takes it, Escape leaves the box;
## a value past the slider's ends can be typed), or a switch,
## and a button that puts the setting back to the floor's default
## (HDLook.map_defaults; dim while it is at it). A row whose setting does
## nothing on the floor as it is now (HDLook.inactive: the sun on a floor
## without a sky, the drifting fog's while drift is 0) is greyed out and
## locked, its label's tooltip saying why. A change takes effect at once
## (HDLook.apply) and stays for the session, as the console's "look" sets it.
## Save saves the panel's settings as the floor's defaults
## (HDLook.save_map_defaults); Copy puts the settings changed from the look's
## own defaults on the clipboard as a console line (and prints it); Reset puts
## the panel's settings back to the floor's defaults.
##
## While a box has the focus the keys are the panel's, not the game's
## (Main._input); clicking or dragging does not move the player.

## Over the game's layers, under the debug console (50).
const LAYER := 45
const TOGGLE_KEY := KEY_F2
const WIDTH := 350.0
const FONT_SIZE := 13
const LABEL_WIDTH := 104.0
const BOX_WIDTH := 86.0
## A row's button back to the floor's default: yellow while the setting is
## off it, faint while it is at it.
const REVERT := "↺"
const REVERT_SIZE := 18
const REVERT_FAINT := Color(0.6, 0.65, 0.75, 0.25)
## A row whose setting does nothing on the floor (HDLook.inactive): greyed
## out to this opacity, its slider, box or switch locked.
const INACTIVE_ALPHA := 0.35
const BACKGROUND := Color(0.05, 0.06, 0.08, 0.85)
const HEADING_COLOR := Color(1.0, 0.85, 0.3)
const HINT_COLOR := Color(0.6, 0.65, 0.75)

## Shown or hidden, for the session (the panel is made again at every floor
## entry).
static var shown := false

var _look # HDLook (untyped: it preloads this script)
var _knobs: Array
var _settings: Dictionary
var _defaults: Dictionary
var _panel: PanelContainer
var _hint: Label
var _sliders := {} # key -> HSlider
var _boxes := {} # key -> SpinBox
var _checks := {} # key -> CheckButton
var _reverts := {} # key -> Button, every row's
var _rows := {} # key -> HBoxContainer


## look: the floor's HDLook (its change, revert, save_map_defaults and
## map_defaults); knobs: HDLook.KNOBS; settings: HDLook.settings; defaults:
## their own defaults (the look's, not the floor's).
func _init(look, knobs: Array, settings: Dictionary, defaults: Dictionary) -> void:
	_look = look
	_knobs = knobs
	_settings = settings
	_defaults = defaults
	name = "HDTuner"
	layer = LAYER


func _ready() -> void:
	_build()
	_panel.visible = shown


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var console: DebugConsole = Main.instance.debug_console if Main.instance != null else null
	if console != null and console.is_open:
		return
	if key.keycode == TOGGLE_KEY:
		_show_panel(not shown)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ESCAPE and _panel.is_visible_in_tree():
		# Escape leaves the box, else hides the panel; it does not reach the
		# game (InputKeyBoardManager: Escape quits).
		if _in_box():
			_leave_box()
		else:
			_show_panel(false)
		get_viewport().set_input_as_handled()


func _show_panel(on: bool) -> void:
	shown = on
	_panel.visible = on
	if not on:
		_leave_box()


func _build() -> void:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE
	var background := StyleBoxFlat.new()
	background.bg_color = BACKGROUND
	background.set_corner_radius_all(4)
	background.set_content_margin_all(8)
	_panel = PanelContainer.new()
	_panel.theme = theme
	_panel.add_theme_stylebox_override("panel", background)
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -WIDTH - 8.0
	_panel.offset_right = -8.0
	_panel.offset_top = 8.0
	_panel.offset_bottom = -8.0
	add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := Label.new()
	title.text = "%s (F2)" % _look.look_name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(_button("Save", _save))
	head.add_child(_button("Copy", _copy))
	head.add_child(_button("Reset", _reset))
	var map := Label.new()
	map.text = _look.map_name.get_basename()
	map.add_theme_color_override("font_color", HINT_COLOR)
	column.add_child(map)
	_hint = Label.new()
	_hint.add_theme_color_override("font_color", HINT_COLOR)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.visible = false
	column.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for group: Array in _knobs:
		var heading := Label.new()
		heading.text = group[0]
		heading.add_theme_color_override("font_color", HEADING_COLOR)
		rows.add_child(heading)
		for knob: Array in group[1]:
			rows.add_child(_row(knob))
	_show_active()


func _button(text: String, pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(pressed)
	return b


## A row for knob ([key, min, max, step], or [key] for a switch).
func _row(knob: Array) -> Control:
	var key: String = knob[0]
	var row := HBoxContainer.new()
	_rows[key] = row
	var label := Label.new()
	label.text = key
	label.custom_minimum_size.x = LABEL_WIDTH
	# For its tooltip (_show_active).
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(label)
	var revert := _button(REVERT, _revert.bind(key))
	# No margins: the larger glyph keeps the rows' height.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		revert.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	revert.add_theme_font_size_override("font_size", REVERT_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		revert.add_theme_color_override(state, HEADING_COLOR)
	revert.add_theme_color_override("font_disabled_color", REVERT_FAINT)
	_reverts[key] = revert
	_show_revert(key)
	if knob.size() == 1:
		var check := CheckButton.new()
		check.button_pressed = _settings[key]
		check.text = "on" if check.button_pressed else "off"
		check.focus_mode = Control.FOCUS_NONE
		check.toggled.connect(func(on: bool) -> void:
			check.text = "on" if on else "off"
			_change(key, on))
		_checks[key] = check
		row.add_child(check)
		# The revert buttons line up at the rows' ends.
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gap)
		row.add_child(revert)
		return row
	var slider := HSlider.new()
	var box := SpinBox.new()
	for r: Range in [slider, box]:
		r.min_value = knob[1]
		r.max_value = knob[2]
		r.step = knob[3]
		r.value = _settings[key]
	# The arrow keys move the player, not the slider.
	slider.focus_mode = Control.FOCUS_NONE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.allow_greater = true
	box.allow_lesser = true
	box.select_all_on_focus = true
	box.custom_minimum_size.x = BOX_WIDTH
	slider.value_changed.connect(func(v: float) -> void:
		box.set_value_no_signal(v)
		_change(key, v))
	box.value_changed.connect(func(v: float) -> void:
		slider.set_value_no_signal(v)
		_change(key, v))
	var line := box.get_line_edit()
	# The box takes the value on Enter first (its own connection), then lets
	# go of the keyboard.
	line.text_submitted.connect(func(_text: String) -> void: line.release_focus())
	line.focus_entered.connect(_release_game_buttons)
	_sliders[key] = slider
	_boxes[key] = box
	row.add_child(slider)
	row.add_child(box)
	row.add_child(revert)
	return row


## Sets the setting key to value (in its type) and applies it.
func _change(key: String, value: Variant) -> void:
	var now: Variant = _settings[key]
	if now is int:
		value = roundi(value)
	elif now is float:
		# As the box shows it: the step's rounding makes 1.7 1.7000000000000002,
		# which a saved file would keep.
		value = str(float(value)).to_float()
	_after_change(key, _look.change(key, value))


## The setting key back to the floor's default.
func _revert(key: String) -> void:
	var applied: bool = _look.revert(key)
	_show(key)
	_after_change(key, applied)


## After the setting key changed: applied (HDLook.apply's answer) or not.
func _after_change(key: String, applied: bool) -> void:
	_show_revert(key)
	# One setting may switch others off or on (drift 0: the drifting fog's).
	_show_active()
	if applied:
		_hint.visible = false
	else:
		_say("%s takes effect when the floor is entered again (console: look %s)" % [key, _look.look_name])


## The row of key shows the setting's value.
func _show(key: String) -> void:
	var v: Variant = _settings[key]
	if _checks.has(key):
		_checks[key].set_pressed_no_signal(v)
		_checks[key].text = "on" if v else "off"
	else:
		_sliders[key].set_value_no_signal(v)
		_boxes[key].set_value_no_signal(v)
	_show_revert(key)


## The row's revert button: dim while the setting is at the floor's default;
## its tooltip says the default.
func _show_revert(key: String) -> void:
	var b: Button = _reverts[key]
	var default: Variant = _look.map_defaults[key]
	b.disabled = _settings[key] == default
	b.tooltip_text = "Back to this map's default: %s" % _text(default)
	if default != _defaults[key]:
		b.tooltip_text += " (the look's: %s)" % _text(_defaults[key])


## Greys out the rows whose settings do nothing on the floor as it is now
## (HDLook.inactive; the label's tooltip says why) and locks their slider,
## box or switch. Their revert buttons still work.
func _show_active() -> void:
	for key: String in _rows:
		var why: String = _look.inactive(key)
		var row: HBoxContainer = _rows[key]
		row.modulate.a = INACTIVE_ALPHA if why != "" else 1.0
		(row.get_child(0) as Label).tooltip_text = why
		if _checks.has(key):
			_checks[key].disabled = why != ""
		else:
			_sliders[key].editable = why == ""
			_boxes[key].editable = why == ""
			_boxes[key].get_line_edit().focus_mode = Control.FOCUS_NONE if why != "" else Control.FOCUS_ALL


func _save() -> void:
	var bad: String = _look.save_map_defaults()
	if bad != "":
		_say(bad)
		return
	for key: String in _reverts:
		_show_revert(key)
	var where := "%s [%s]" % [_look.maps_file(), _look.map_name]
	print("HDTuner: saved the defaults of ", where)
	_say("Saved as this map's defaults: " + where)


func _copy() -> void:
	var parts := PackedStringArray()
	for key: String in _settings:
		var v: Variant = _settings[key]
		if v != _defaults[key]:
			parts.append("%s=%s" % [key, _text(v)])
	var line := "look %s %s" % [_look.look_name, " ".join(parts)]
	DisplayServer.clipboard_set(line)
	print("HDTuner: ", line)
	_say("Copied: " + line if not parts.is_empty() else "Nothing changed from the defaults")


func _reset() -> void:
	for key: String in _reverts:
		_look.revert(key)
		_show(key)
	_show_active()
	_say("Back to this map's defaults")


## A setting's value as the console writes it.
static func _text(v: Variant) -> String:
	return ("on" if v else "off") if v is bool else str(v)


func _say(text: String) -> void:
	_hint.text = text
	_hint.visible = true


## True while one of the panel's boxes has the keyboard.
func _in_box() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and _panel.is_ancestor_of(focus)


func _leave_box() -> void:
	if _in_box():
		get_viewport().gui_get_focus_owner().release_focus()


## As the debug console does when it opens: no game button stays held while
## a box has the keys.
static func _release_game_buttons() -> void:
	for action in GameCore.gameActions:
		if action != null:
			action.release()
