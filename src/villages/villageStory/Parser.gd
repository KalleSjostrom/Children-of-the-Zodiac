class_name Parser
extends RefCounted
## Port of villages.villageStory.Parser.
##
## FRAMEWORK NOTE: the static helpers below (reset, getArgument, getText(tok,
## first), error, updateLineCounter) are used by the core loaders and must be
## kept. The instance method Java getText(StringTokenizer) is named
## getTextObject(tok) in this port because GDScript has no overloading.

static var lineNr := 0
static var lastLine := ""

var variables := {}
var time := 0


static func reset() -> void:
	lineNr = 0


## Splits "key=value" into [key, value]. Only the first '=' splits.
static func getArgument(input: String) -> Array:
	var parts = null
	if input.contains("="):
		parts = J.split(input, "=", 2)
		if parts.size() < 2:
			parts.append("")
	else:
		error("The string: " + input + " does not match key=val")
		parts = [input, ""]
	return parts


static func error(string: String) -> void:
	push_error("Parser: " + str(lineNr) + ": " + string + "\n\t" + lastLine)


static func _blah(string: String, sb: Array) -> bool:
	var found := false
	var done := false
	if string.begins_with("\""):
		string = string.substr(1)
	if string.contains("\""):
		var left := string.substr(0, string.find("\""))
		string = string.substr(string.find("\""))
		sb[0] += left + " "
		found = true
		done = true
	if string.contains(";"):
		sb[0] += " ---- "
		found = true
		var parts := J.split(string, ";")
		done = _blah(parts[1] if parts.size() > 1 else "", sb)
	if not found:
		sb[0] += string + " "
	return done


## Reads a quoted text (possibly spanning several tokens) starting with
## 'first'. Lines are separated by ';'. Returns the lines (String array).
static func getText(tok: StringTokenizer, first: String) -> Array:
	var sb := [""]
	var string := first
	var done := false
	var done2 := not done
	while done2:
		done = _blah(string, sb)
		done2 = tok.hasMoreTokens() and not done
		if not done:
			if tok.hasMoreTokens():
				string = tok.nextToken()
			else:
				error("NoSuchElementException")
	var lines := J.split(sb[0], " ---- ")
	for i in lines.size():
		lines[i] = String(lines[i]).strip_edges()
	return lines


func updateLineCounter(lineCount: int, line: String) -> void:
	lineNr = lineCount
	lastLine = line


func getValue(string: String) -> int:
	string = string.strip_edges()
	if variables.has(string):
		return variables[string]
	if not string.is_valid_int():
		error("NumberFormatException (" + string + ")")
		return 0
	return string.to_int()


func getFloat(string: String) -> float:
	string = string.strip_edges()
	if not (string.is_valid_float() or string.is_valid_int()):
		error("NumberFormatException (" + string + ")")
		return 0.0
	return J.parseFloat(string)


func getPos(string: String) -> Array:
	var retVal = null
	if string.contains(";"):
		var pos := J.split(string, ";")
		retVal = [0, 0, 0]
		retVal[0] = getValue(pos[0])
		retVal[1] = getValue(pos[1])
		retVal[2] = getValue(pos[2]) if pos.size() > 2 else 0
	else:
		error("The string: " + string + " does not contain a ;")
	return retVal


func getFloatPos(string: String) -> Array:
	var retVal = null
	if string.contains(";"):
		var pos := J.split(string, ";")
		retVal = [0.0, 0.0, 0.0]
		retVal[0] = getFloat(pos[0])
		retVal[1] = getFloat(pos[1])
		retVal[2] = getFloat(pos[2]) if pos.size() > 2 else 0.0
	else:
		error("The string: " + string + " does not contain a ;")
	return retVal


func addVariable(tok: StringTokenizer) -> void:
	if tok.hasMoreTokens():
		var args := getArgument(tok.nextToken())
		variables[args[0]] = J.parseInt(args[1])
	else:
		error("Empty var statement.")


func variableSize() -> int:
	return variables.size()


func getTimeLineEvent(tok):
	var ins := J.array(11, 0)
	var argument
	var key: String
	ins[TimeLineEvent.TYPE] = TimeLineEvent.TYPE_NO_FADE
	ins[TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION] = -1
	ins[TimeLineEvent.TIME_OF_DAY] = -1
	while tok.hasMoreTokens():
		argument = getArgument(tok.nextToken())
		key = argument[0]
		if key == "type" or key == "ty":
			ins[TimeLineEvent.TYPE] = getValue(argument[1])
		elif key == "time" or key == "t":
			ins[TimeLineEvent.TIME] = getValue(argument[1])
		elif key == "timea" or key == "ta":
			time += getValue(argument[1])
			ins[TimeLineEvent.TIME] = time
		elif key == "index" or key == "i":
			ins[TimeLineEvent.INDEX] = getValue(argument[1])
		elif key == "fadetime" or key == "ft":
			ins[TimeLineEvent.FADE_TIME] = getValue(argument[1])
		elif key == "fadetarget":
			ins[TimeLineEvent.FADE_TARGET] = getValue(argument[1])
		elif key == "kind" or key == "k":
			ins[TimeLineEvent.KIND] = getValue(argument[1])
		elif key == "pos" or key == "p":
			var pos = getPos(argument[1])
			ins[TimeLineEvent.POS_X] = pos[0]
			ins[TimeLineEvent.POS_Y] = pos[1]
		elif key == "day" or key == "da":
			ins[TimeLineEvent.TIME_OF_DAY] = getValue(argument[1])
		elif key == "distance" or key == "dis":
			ins[TimeLineEvent.MOVE_DISTANCE] = getValue(argument[1])
		elif key == "duration" or key == "du":
			ins[TimeLineEvent.MOVE_DURATION] = getValue(argument[1])
		elif key == "direction" or key == "dir":
			ins[TimeLineEvent.MOVE_DIRECTION] = getValue(argument[1])
		elif key == "acceleration" or key == "acc":
			ins[TimeLineEvent.MOVE_ACCELERATION] = getValue(argument[1])
		elif key == "facedirection" or key == "fd":
			ins[TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION] = getValue(argument[1])
		elif key == "scrollmode" or key == "sm":
			ins[TimeLineEvent.INFO_IMAGE_SCROLL_MODE] = getValue(argument[1])
		elif key == "imagetype" or key == "it":
			ins[TimeLineEvent.INFO_IMAGE_MODE] = getValue(argument[1])
		elif key == "movepos" or key == "mp":
			var pos = getPos(argument[1])
			ins[TimeLineEvent.MOVE_X] = pos[0]
			ins[TimeLineEvent.MOVE_Y] = pos[1]
			ins[TimeLineEvent.MOVE_DIRECTION] = pos[2]
		elif key == "value" or key == "v":
			ins[TimeLineEvent.TRIGGER_VALUE] = getValue(argument[1])
		elif key == "emotion" or key == "e":
			ins[TimeLineEvent.EMOTION] = getValue(argument[1])
		elif key == "show" or key == "s":
			ins[TimeLineEvent.EMOTION_SHOW] = getValue(argument[1])
		elif key == "shake" or key == "sh":
			ins[TimeLineEvent.EMOTION_SHAKE] = getValue(argument[1])
		elif key == "controll" or key == "c":
			ins[TimeLineEvent.ACTOR_CONTROLL] = getValue(argument[1])
		elif key == "actor" or key == "a":
			ins[TimeLineEvent.TARGET] = getValue(argument[1])
			ins[TimeLineEvent.POS_X] = -1
			ins[TimeLineEvent.MOVE_X] = -1
		elif key == "speed" or key == "sp":
			ins[TimeLineEvent.MOVE_SPEED] = getValue(argument[1])
			ins[TimeLineEvent.MOVE_DURATION] = -1
		elif key == "mode" or key == "m":
			ins[TimeLineEvent.PLAY_MODE] = getValue(argument[1])
		elif key == "center" or key == "ce":
			ins[TimeLineEvent.CENTER_SCREEN] = getValue(argument[1])
		elif key == "animation" or key == "an":
			ins[TimeLineEvent.ANIMATION_INDEX] = getValue(argument[1])
		elif key == "color" or key == "co":
			ins[TimeLineEvent.COLOR] = getValue(argument[1])
		elif key == "colorspeed" or key == "cos":
			ins[TimeLineEvent.COLOR_SPEED] = getValue(argument[1])
		elif key == "fadeimage" or key == "fi":
			ins[TimeLineEvent.FADE_IMAGE] = getValue(argument[1])
		elif key == "size" or key == "si":
			ins[TimeLineEvent.SIZE] = getValue(argument[1])
		elif key == "scrollSpeed" or key == "ss":
			ins[TimeLineEvent.INFO_IMAGE_SCROLL_SPEED] = getValue(argument[1])
		elif key == "sysfadespeed" or key == "sfs":
			ins[TimeLineEvent.PARTICLE_SYS_FADE_SPEED] = getValue(argument[1])
		elif key == "syscutoff" or key == "sc":
			ins[TimeLineEvent.PARTICLE_SYS_FADE_CUTOFF] = getValue(argument[1])
		elif key == "sysswiftness" or key == "sw":
			ins[TimeLineEvent.PARTICLE_SYS_FADE_SWIFTNESS] = getValue(argument[1])
		elif key == "zoomin":
			ins[TimeLineEvent.SCREEN_ZOOM_IN] = getValue(argument[1])
		elif key == "zoomtime":
			ins[TimeLineEvent.SCREEN_ZOOM_TIME] = getValue(argument[1])
		elif key == "usestaticpos":
			ins[TimeLineEvent.SCREEN_ZOOM_USE_STATIC_POS] = getValue(argument[1])
		elif key == "fadebackto":
			ins[TimeLineEvent.BACKGROUND_FADE_TARGET] = getValue(argument[1])
		else:
			error("Unrecognizable instruction " + key)
	if ins[TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION] == -1:
		ins[TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION] = ins[TimeLineEvent.MOVE_DIRECTION]
	return TimeLineEvent.new(ins)


## Java: protected float[] getLongPos(StringTokenizer). Returns null when the
## tokenizer is empty, else [y, x, angle] (angle -1 if not given).
func getLongPos(tok):
	var pos = null
	while tok.hasMoreTokens():
		if pos == null:
			pos = [0.0, 0.0, -1.0]
		var argument = getArgument(tok.nextToken())
		var key: String = argument[0]
		if key == "pos":
			var temp = getPos(argument[1])
			pos[Values.X] = float(temp[0])
			pos[Values.Y] = float(temp[1])
		elif key == "angle":
			pos[2] = float(getValue(argument[1]))
		else:
			error("Unrecognizable argument: " + key)
	return pos


func show(tok, showing):
	var argument
	var key: String
	var index: int = 0
	var shows: bool = false
	while tok.hasMoreTokens():
		argument = getArgument(tok.nextToken())
		key = argument[0]
		if key == "index":
			index = getValue(argument[1])
		elif key == "value":
			shows = getValue(argument[1]) == 1
		else:
			error("Show instruction got an unrecognizable argument: " + key)
	showing[index] = shows


## dialogpacket name=0 starttime=4000 endtime=4500
func getDialogPacket(tok):
	var argument
	var key: String
	var name = null
	var starttime: int = time
	var endtime: int = -1
	while tok.hasMoreTokens():
		argument = getArgument(tok.nextToken())
		key = argument[0]
		if key == "name":
			name = argument[1]
		elif key == "starttime":
			starttime = getValue(argument[1])
		elif key == "endtime":
			endtime = getValue(argument[1])
		elif key == "starttimea":
			time += getValue(argument[1])
			starttime = time
		elif key == "endtimea":
			time += getValue(argument[1])
			endtime = time
		elif key == "duration":
			endtime = starttime + getValue(argument[1])
		else:
			error("Create dialog packet got an unrecognizable argument: " + key)
	if endtime == -1:
		endtime = starttime + 1
	return DialogPackage.new(name, starttime, endtime)


func addSingleDialog(tok):
	var argument
	var key: String
	var name: String = ""
	var starttime: int = time
	var endtime: int = -1
	var dp = null
	while tok.hasMoreTokens():
		argument = getArgument(tok.nextToken())
		key = argument[0]
		if key == "starttime":
			starttime = getValue(argument[1])
		elif key == "endtime":
			endtime = getValue(argument[1])
		elif key == "starttimea":
			time += getValue(argument[1])
			starttime = time
		elif key == "endtimea":
			time += getValue(argument[1])
			endtime = time
		elif key == "duration":
			endtime = starttime + getValue(argument[1])
		elif key == "<":
			if endtime == -1:
				endtime = starttime + 1
			dp = DialogPackage.new(name, starttime, endtime)
			addDialog(tok, null, dp)
		else:
			error("Create dialog packet got an unrecognizable argument: " + key)
	return dp


func addDialog(tok, dialogs, altPackage):
	_getDialogPackage(tok, dialogs, altPackage)


func getDialogSequence(tok):
	return _getDialogPackage(tok, null, null).getSequense()[0]


## Java: private DialogPackage getDialogPackage(tok, dialogs, altPackage).
func _getDialogPackage(tok, dialogs, altPackage):
	var argument
	var key: String
	var name = null
	var text = null
	var alts = null
	var first: bool = true
	var whisper: bool = false
	var question: bool = false
	var ds = null
	var dialogPackage = null

	while tok.hasMoreTokens():
		argument = getArgument(tok.nextToken())
		key = argument[0]
		if key == "packetname":
			dialogPackage = getPackage(dialogs, argument[1])
		elif key == "name":
			name = getText(tok, argument[1])[0]
		elif key == "text":
			text = getText(tok, argument[1])
		elif key == "first":
			first = getValue(argument[1]) == 1
		elif key == "whisper":
			whisper = getValue(argument[1]) == 1
		elif key == "alts":
			alts = J.split(Organizer.convertKeepCase(argument[1]), ";")
			question = true
		else:
			error("Create dialog packet got an unrecognizable argument: " + key)

	if text != null:
		var fl: String = text[0] if text.size() > 0 else ""
		var sl: String = text[1] if text.size() > 1 else ""
		ds = DialogSequence.new(name, fl, sl, first, question, whisper)
		if question:
			ds.setAlternatives(alts)
		if altPackage != null:
			altPackage.add(ds)
			return altPackage
		elif dialogPackage == null:
			dialogPackage = DialogPackage.new()
		dialogPackage.add(ds)
	else:
		error("Unexpected error when adding a dialog")
	return dialogPackage


## Java: the instance method Text getText(StringTokenizer tok).
func getTextObject(tok):
	var argument
	var key: String
	var text = null
	var pos = null
	var whisper: bool = false
	var color: int = 1
	var size: int = Text.SIZE

	while tok.hasMoreTokens():
		var s: String = tok.nextToken()
		argument = getArgument(s)
		key = argument[0]
		if key == "lines":
			text = getText(tok, argument[1])
		elif key == "pos":
			pos = getPos(argument[1])
		elif key == "whisper":
			whisper = J.parseBoolean(argument[1])
		elif key == "color":
			color = J.parseInt(argument[1])
		elif key == "size":
			size = J.parseInt(argument[1])
		else:
			error("Getting text got an unrecognizable argument: " + key)
	var t = null
	if text != null and pos != null:
		var t1: String = "" if text.size() == 1 else text[1]
		t = Text.new(text[0], t1)
		t.setPos(pos)
		t.setWhisper(whisper)
		t.setSize(size)
		t.setColor(color)
	return t


func getScrollText(tok):
	var argument
	var key: String
	var st = ScrollableTexts.ScrollableText.new()
	while tok.hasMoreTokens():
		var s: String = tok.nextToken()
		argument = getArgument(s)
		key = argument[0]
		if key == "text":
			st.setText(getText(tok, argument[1])[0])
		elif key == "x":
			st.setX(getValue(argument[1]))
		elif key == "size":
			st.setFontSize(getValue(argument[1]))
		elif key == "bold":
			st.setIsBold(getValue(argument[1]) == 1)
		elif key == "distance":
			st.setDistance(float(getValue(argument[1])))
		else:
			error("Getting text got an unrecognizable argument: " + key)
	return st


func getPackage(dialogs, string):
	for i in range(dialogs.size()):
		var dp = dialogs[i]
		if dp.getName() == string:
			return dp
	error("No dialog package with the name: " + string)
	return null
