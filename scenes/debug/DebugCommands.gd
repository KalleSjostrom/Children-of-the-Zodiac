class_name DebugCommands
extends RefCounted
## The developer console's commands (DebugConsole): what each one takes,
## completing what is typed so far (complete) and running a line (run). An
## option is completed from its names, and a unique part of one is enough to
## run it ("goto alar" is "goto alares"). Switches (god) take on or off and
## flip without either.
##
## The commands go the game's own ways where it has them: places are entered
## through the Organizer like a door would, statuses through the Database.
## They are registered in _init, in groups for "help"; see GameCommands for
## the game's own.

## What running a command came to: whether it did it, and what to tell.
class Result:
	var ok: bool
	var text: String

	func _init(p_ok: bool, p_text: String) -> void:
		ok = p_ok
		text = p_text


## One of a command's arguments.
class Param:
	var name: String
	var help: String
	var optional := false
	## () -> PackedStringArray: the names it takes. An empty Callable for
	## anything (a number).
	var options: Callable
	## Only its options: the one a part typed is of runs. Otherwise they are
	## suggestions, and anything else is up to the command.
	var strict := true
	## Takes the rest of the line (names with spaces).
	var rest := false

	## Takes what is not one of its options too.
	func loose() -> Param:
		strict = false
		return self

	## Takes the rest of the line, spaces and all.
	func to_end() -> Param:
		rest = true
		return self

	func usage() -> String:
		return ("[%s]" if optional else "<%s>") % name


class ConsoleCommand:
	var name: String
	var help: String
	## Where help lists it.
	var group: String
	var params: Array[Param] = []
	## (args: PackedStringArray) -> Result. The args as typed, options
	## completed, optional ones left out not there.
	var run: Callable

	func usage() -> String:
		var words: PackedStringArray = [name]
		for param in params:
			words.push_back(param.usage())
		return " ".join(words)


## Something the line typed so far can go on with.
class Suggestion:
	## The line with it, "" for a hint at what to type next that cannot be
	## completed.
	var line: String
	var label: String
	var detail: String

	func _init(p_line: String, p_label: String, p_detail: String) -> void:
		line = p_line
		label = p_label
		detail = p_detail


const ON_OFF: PackedStringArray = ["on", "off"]

var _commands: Dictionary = {}
var _console: DebugConsole
## Where _add puts the next commands (help lists them under it).
var _group := ""


func _init(console: DebugConsole) -> void:
	_console = console
	_group = "General"
	_add("help", "Lists the commands, or tells about one", _help, [
		_opt("command", _command_names)])
	_add("clear", "Clears the console", _clear)
	_add("quit", "Quits the game", _quit)
	GameCommands.register(self)


# --- Running and completing ---

## Runs the line: the command (a unique part of its name will do) with its
## arguments.
func run(line: String) -> Result:
	var words: PackedStringArray = line.strip_edges().split(" ", false)
	if words.is_empty():
		return done("")
	var found: PackedStringArray = _resolve(words[0], _command_names())
	if found.size() != 1:
		return fail(_not_one("command", words[0], found) + " (help lists them)")
	var command: ConsoleCommand = _commands[found[0]]
	var args: PackedStringArray = _split_args(words.slice(1), command)
	if args.size() > command.params.size():
		return fail("Too many arguments: %s" % command.usage())
	for i in range(command.params.size()):
		var param: Param = command.params[i]
		if i >= args.size():
			if not param.optional:
				return fail("Usage: %s" % command.usage())
			continue
		if not param.options.is_valid():
			continue
		var options: PackedStringArray = param.options.call()
		var matches: PackedStringArray = _resolve(args[i], options)
		if matches.size() == 1:
			args[i] = matches[0]
		elif param.strict:
			return fail("%s (%s)" % [_not_one(param.name, args[i], matches), _some(options)])
	return command.run.call(args)


## What the line typed so far can go on with: the commands its word is part
## of (those it starts first), or the options of the argument being typed, or
## a hint at what that argument takes. Nothing for an empty line.
func complete(line: String) -> Array[Suggestion]:
	var suggestions: Array[Suggestion] = []
	var words: PackedStringArray = line.split(" ", false)
	if words.is_empty():
		return suggestions
	var new_word: bool = line.ends_with(" ")
	if words.size() == 1 and not new_word:
		for command_name in _matching(words[0], _command_names()):
			var command: ConsoleCommand = _commands[command_name]
			var more := " " if not command.params.is_empty() else ""
			suggestions.push_back(Suggestion.new(command_name + more, command.usage(), command.help))
		return suggestions

	var found: PackedStringArray = _resolve(words[0], _command_names())
	if found.size() != 1:
		return suggestions
	var command: ConsoleCommand = _commands[found[0]]
	var args: PackedStringArray = words.slice(1)
	var index: int = args.size() if new_word else args.size() - 1
	var typing := ""
	# An argument that takes the rest of the line completes all of it.
	for i in range(command.params.size()):
		if command.params[i].rest and index >= i:
			typing = " ".join(args.slice(i)) + (" " if new_word and args.size() > i else "")
			index = i
			break
	if typing == "" and not new_word:
		typing = args[args.size() - 1]
	if index >= command.params.size():
		return suggestions
	var start: String = " ".join(words.slice(0, index + 1)) + " "
	var param: Param = command.params[index]
	var more := " " if index + 1 < command.params.size() else ""
	if param.options.is_valid():
		for option in _matching(typing, param.options.call()):
			suggestions.push_back(Suggestion.new(start + option + more, option, ""))
	if suggestions.is_empty() or not param.strict:
		suggestions.push_back(Suggestion.new("", param.usage(), param.help))
	return suggestions


## The words of the arguments, an argument that takes the rest of the line
## as one.
static func _split_args(words: PackedStringArray, command: ConsoleCommand) -> PackedStringArray:
	for i in range(command.params.size()):
		if command.params[i].rest and words.size() > i:
			var args: PackedStringArray = words.slice(0, i)
			args.push_back(" ".join(words.slice(i)))
			return args
	return words


# --- Registering (GameCommands uses these too) ---

## Starts a group of commands for help.
func group(group_name: String) -> void:
	_group = group_name


func _add(command_name: String, help: String, run_command: Callable, params: Array = []) -> void:
	var command := ConsoleCommand.new()
	command.name = command_name
	command.help = help
	command.group = _group
	command.params.assign(params)
	command.run = run_command
	_commands[command_name] = command


## Adds a command: its name, help, (args) -> Result and its parameters.
func add(command_name: String, help: String, run_command: Callable, params: Array = []) -> void:
	_add(command_name, help, run_command, params)


## A required argument; options: () -> PackedStringArray, or an empty
## Callable for anything.
static func arg(param_name: String, options: Callable, help := "") -> Param:
	var param := Param.new()
	param.name = param_name
	param.options = options
	param.help = help
	return param


## An optional argument.
static func opt(param_name: String, options: Callable, help := "") -> Param:
	var param: Param = arg(param_name, options, help)
	param.optional = true
	return param


## A switch's on or off; without either it flips.
static func switch() -> Param:
	return opt("on|off", func() -> PackedStringArray: return ON_OFF)


## The switch's new state: what is asked for, else the other one.
static func flip(args: PackedStringArray, now: bool) -> bool:
	return args[0] == "on" if not args.is_empty() else not now


static func on_off(on: bool) -> String:
	return "on" if on else "off"


static func done(text: String) -> Result:
	return Result.new(true, text)


static func fail(text: String) -> Result:
	return Result.new(false, text)


func _opt(param_name: String, options: Callable, help := "") -> Param:
	return opt(param_name, options, help)


## The options the word stands for: the one it is, else the ones it starts,
## else the ones it is part of (any case).
static func _resolve(word: String, options: PackedStringArray) -> PackedStringArray:
	var lower: String = word.to_lower()
	for option in options:
		if option.to_lower() == lower:
			return PackedStringArray([option])
	var starting: PackedStringArray = []
	var containing: PackedStringArray = []
	for option in options:
		var o: String = option.to_lower()
		if o.begins_with(lower):
			starting.push_back(option)
		elif o.contains(lower):
			containing.push_back(option)
	return starting if not starting.is_empty() else containing


## The options the word typed so far can go on with, those it starts first.
static func _matching(word: String, options: PackedStringArray) -> PackedStringArray:
	var lower: String = word.to_lower()
	var starting: PackedStringArray = []
	var containing: PackedStringArray = []
	for option in options:
		var o: String = option.to_lower()
		if o.begins_with(lower):
			starting.push_back(option)
		elif o.contains(lower):
			containing.push_back(option)
	return starting + containing


static func _not_one(what: String, word: String, matches: PackedStringArray) -> String:
	if matches.is_empty():
		return "No %s %s" % [what, word]
	return "%s could be %s" % [word, _some(matches, " or ")]


## The first options of a list, for messages.
static func _some(options: PackedStringArray, separator := ", ") -> String:
	if options.size() <= 12:
		return separator.join(options)
	return separator.join(options.slice(0, 12)) + " ... (%d)" % options.size()


func _command_names() -> PackedStringArray:
	return PackedStringArray(_commands.keys())


# --- General ---

func _help(args: PackedStringArray) -> Result:
	if not args.is_empty():
		var command: ConsoleCommand = _commands[args[0]]
		var lines: PackedStringArray = [command.usage(), "  " + command.help]
		for param in command.params:
			var about: PackedStringArray = []
			if param.help != "":
				about.push_back(param.help)
			if param.options.is_valid():
				about.push_back(_some(param.options.call()))
			if not about.is_empty():
				lines.push_back("  %s: %s" % [param.name, "; ".join(about)])
		return done("\n".join(lines))
	var width := 0
	for command: ConsoleCommand in _commands.values():
		width = maxi(width, command.usage().length())
	var lines: PackedStringArray = []
	var current := ""
	for command: ConsoleCommand in _commands.values():
		if command.group != current:
			current = command.group
			lines.push_back("-- %s" % current)
		lines.push_back("%s  %s" % [command.usage().rpad(width), command.help])
	lines.push_back("Tab completes, Up and Down pick a suggestion or an earlier line, Escape closes.")
	return done("\n".join(lines))


func _clear(_args: PackedStringArray) -> Result:
	_console.clear_output()
	return done("")


func _quit(_args: PackedStringArray) -> Result:
	_console.get_tree().quit()
	return done("")
