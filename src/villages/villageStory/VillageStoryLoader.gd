class_name VillageStoryLoader
extends AbstractMapLoader
## Port of villages.villageStory.VillageStoryLoader: parses a village story
## sequence file (Values.StorySequences + name + ".seq").
## The field newVillageInfo is newVillageInfo_ (the method keeps its name).
## parseFile(name) (one argument) loads Values.StorySequences + name + ".seq".

var poses = {}
var newVillageInfo_ = {}
var dialogs = []
var info = []
var texts = []
var scrolltext = null
var showing = null
var parser = Parser.new()
## Java HashMap<Integer, ArrayList<String>>.
var infoList = {}
var drawPause: bool = false
var fromVillage: bool = false
var passVillage: bool = false

func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.StorySequences, path + ".seq")
	else:
		super.parseFile(path, filename)

func executeCommand(command: String, tokenizer: StringTokenizer):
	var tok := tokenizer
	parser.updateLineCounter(lineCount, lastLine)
	if command == "import":
		var file: String = Parser.getArgument(tok.nextToken())[1]
		parseFile(Values.StorySequences, file)
		lineCount -= parser.variableSize()
	elif command == "info":
		var arguments
		while tok.hasMoreTokens():
			arguments = Parser.getArgument(tok.nextToken())
			newVillageInfo_[arguments[0]] = Parser.getText(tok, arguments[1])[0]
	elif command == "actor":
		var name: String = Parser.getText(tok, Parser.getArgument(tok.nextToken())[1])[0]
		getList(TimeLineEvent.ACTORS).append(name)
		var pos = null
		if tok.hasMoreTokens():
			pos = parser.getPos(Parser.getArgument(tok.nextToken())[1])
		if pos != null:
			poses[name] = pos
	elif command == "pos":
		var name: String = Parser.getText(tok, Parser.getArgument(tok.nextToken())[1])[0]
		var pos = null
		if tok.hasMoreTokens():
			pos = parser.getPos(Parser.getArgument(tok.nextToken())[1])
		if pos != null:
			poses[name] = pos
	elif command == "set":
		# Java has a second, unreachable "set" branch (drawpause); it is
		# unreachable in the original too and therefore left out.
		var val: String = tok.nextToken()
		if val == "fromvillage":
			fromVillage = true
		elif val == "passvillage":
			passVillage = true
	elif command == "ins":
		var t = parser.getTimeLineEvent(tok)
		info.append(t)
	elif command == "show":
		if showing == null:
			showing = J.array(getList(TimeLineEvent.ACTORS).size(), true)
		parser.show(tok, showing)
	elif command == "dialogpacket":
		dialogs.append(parser.getDialogPacket(tok))
	elif command == "var":
		parser.addVariable(tok)
	elif command == "text":
		texts.append(parser.getTextObject(tok))
	elif command == "newscrolltext":
		scrolltext = ScrollableTexts.new()
		var args = Parser.getArgument(tok.nextToken())
		var cmd: String = args[0]
		var argument: String = args[1]
		if cmd == "speed":
			scrolltext.setSpeed(J.parseFloat(argument))
	elif command == "scrolltext":
		scrolltext.add(parser.getScrollText(tok))
	elif command == "load":
		var args = Parser.getArgument(tok.nextToken())
		var cmd: String = args[0]
		var argument: String = Parser.getText(tok, args[1])[0]
		if cmd == "image":
			if argument != "black":
				argument = Values.StoryImages + argument + ".jpg"
				ImageHandler.addToCurrentLoadNow(argument)
			getList(TimeLineEvent.IMAGES).append(argument)
		elif cmd == "translucent":
			if argument != "black":
				ImageHandler.addToCurrentLoadNow(argument)
			getList(TimeLineEvent.IMAGES).append(argument)
		elif cmd == "music":
			getList(TimeLineEvent.MUSICS).append(argument)
		elif cmd == "trigger":
			getList(TimeLineEvent.TRIGGERS).append(Organizer.convert(argument))
		elif cmd == "character":
			Load.loadNewCharacter(argument)
		elif cmd == "animation":
			getList(TimeLineEvent.ANIMATIONS).append(argument)
		elif cmd == "story":
			getList(TimeLineEvent.STORY_SEQUENCES).append(argument)
		elif cmd == "particleSystem":
			getList(TimeLineEvent.PARTICLE_SYSTEMS).append(argument)
	elif command == "unload":
		var args = Parser.getArgument(tok.nextToken())
		var cmd: String = args[0]
		var argument: String = Parser.getText(tok, args[1])[0]
		if cmd == "character":
			Load.unloadNewCharacter(argument)
	elif command == "dialog":
		parser.addDialog(tok, dialogs, null)
	elif command == "dialogsingle":
		dialogs.append(parser.addSingleDialog(tok))
	else:
		Parser.error("Unknown command: " + lastLine)

func getList(code):
	if not infoList.has(code):
		infoList[code] = []
	return infoList[code]

func getDialogs():
	return dialogs

func getPoses():
	return poses

func getTimeLineEvents():
	return info

func getInfo():
	return infoList

func getTextList():
	return texts

func getScrollableText():
	return scrolltext

func getWhoseShowing():
	if showing == null:
		showing = J.array(getList(TimeLineEvent.ACTORS).size(), true)
	return showing

func newVillageInfo():
	return newVillageInfo_

func shouldPauseDrawings():
	return drawPause

func getFromVillage():
	return fromVillage

func getPassVillage():
	return passVillage
