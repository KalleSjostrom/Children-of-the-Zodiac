class_name Villager
extends InstructionFollower
## Port of villages.Villager: a villager in a village. A villager has its own
## animation and a path to follow. It also has things to say and the player
## can have a dialog with it.

var dialog = []
var storedTriggers = null
var filename = ""
var seqFilePath = ""
var seqFileName = null
var constraints = null
var constraintTrigger = null
var sequence: bool = false
var pause: bool = false
var talking: bool = false
var loadingDialog: bool = false
## Java HashMap<Integer, ArrayList<DialogSequence>>.
var responses = {}
var status: int = 0
var range: int = 30
var prePause = [false, false]
## Java public field getResponses (unused).
var getResponses_ = null

## Constructs a new villager with the given name. path is the name of the
## folder for the current village.
func _init(n = null, path = null, status = null) -> void:
	super()
	name = n
	self.status = status
	seqFilePath = path + "/villagers/"
	VillagerLoader.new(self).parseFile(path + "/villagers/" + name)
	setInstructions(0)


## Java overloads: Villager.loadImages(String name, int nr) and the inherited
## Sprite.loadImages(path, name[, nr]).
func loadImages(path, name, nr = null):
	if nr == null and name is int:
		var n: String = path
		if n.begins_with("char/"):
			n = n.replace("char/", "")
			super.loadImages(Values.VillageImages + "Characters/", n, name)
		else:
			super.loadImages(Values.VillageImages + seqFilePath, n, name)
	else:
		super.loadImages(path, name, nr)


## Updates the current dialog to the dialog with the given (status) number.
func updateDialog(number):
	sequence = false
	VillagerLoader.new(self).loadNewDialog(number)


func checkStoryDialog():
	return storyDialog


func relinquishStoryDialog():
	storyDialog = false


## Sets whether or not this villager is talking to the player. The given
## direction is where the villager should look.
func setTalking(talking, direction):
	self.talking = talking
	if talking:
		var s: int = Database.getStatusFor(getName())
		if s != status:
			status = s
			updateDialog(s)
		doCheck()
		standStill(direction)
	else:
		moving = instruction.isMoving()
		setImages()


func doCheck():
	var falseFound: bool = false
	if constraints != null and constraintTrigger != null:
		var i: int = 0
		while i < constraints.size() and not falseFound:
			var check: bool = false
			var c: String = constraints[i].replace("_", " ")
			if c.begins_with("s."):
				c = c.replace("s.", "")
				if c.contains("="):
					var a: Array = J.split(c, "=")
					var st: int = Database.getStatusFor(a[0])
					check = st == J.parseInt(a[1])
				elif c.contains(">"):
					var a: Array = J.split(c, ">")
					var st: int = Database.getStatusFor(a[0])
					check = st > J.parseInt(a[1])
				elif c.contains("<"):
					var a: Array = J.split(c, "<")
					var st: int = Database.getStatusFor(a[0])
					check = st < J.parseInt(a[1])
			elif c.begins_with("a."):
				c = c.replace("a.", "")
				var a: Array = J.split(c, "=")
				var b: Array = J.split(a[1], "-")
				var battles: int = Load.getPartyItems().getBattles()
				check = battles >= J.parseInt(b[0]) and battles <= J.parseInt(b[1])
			elif c.begins_with("c."):
				c = c.replace("c.", "")
				var list = Load.getCharacters()
				check = false
				for cha in list:
					if cha.getName() == c:
						check = true
						break
			else:
				check = Load.getPartyItems().hasItem(c)
			if not check:
				falseFound = true
			i += 1
		if not falseFound:
			var triggs = constraintTrigger
			var st: int = 0
			if String(triggs[1]).strip_edges().is_valid_int():
				st = J.parseInt(triggs[1])
			else:
				st = Database.getStatusFor(triggs[1])
			Database.addStatus(triggs[0], st)
			updateDialog(st)


func isBusy():
	return pause or talking


func isDialogSequence():
	return sequence


func getSequenceFilename():
	return seqFileName


## Java overloads: Villager.checkCollision(float[] p) (max distance 25) and
## the inherited Sprite.checkCollision(...).
func checkCollision(checkPos, maxDistance = null, direction = null):
	if maxDistance == null:
		return super.checkCollision(checkPos, 25)
	return super.checkCollision(checkPos, maxDistance, direction)


## Checks if this villager is close enough to be talked to.
func checkTalkable(p, direction):
	var talkable: bool = false
	if inRange(p, range, true):
		var py: float = p[Values.Y] + Sprite.STANDARD_HEIGHT
		var posy: float = pos[Values.Y] + self.getHeight()
		var distx: float = abs(p[Values.X] - pos[Values.X])
		var disty: float = abs(py - posy)
		match direction:
			Values.UP:
				talkable = posy < py and distx < disty
			Values.RIGHT:
				talkable = pos[Values.X] > p[Values.X] and distx > disty
			Values.DOWN:
				talkable = posy > py and distx < disty
			Values.LEFT:
				talkable = pos[Values.X] < p[Values.X] and distx > disty
	return talkable


## Java overloads: Villager.update(float f, Player player, boolean reset)
## and the inherited InstructionFollower.update(int elapsedTime).
func update(f, player = null, reset = null):
	if reset == null:
		return super.update(f)
	# Java's parameter is a float, so this is Sprite.update(float), never
	# InstructionFollower.update(int) (which scales time by the instruction).
	super.update(float(f))

	if player != null:
		setPause(checkCollision(player.getPos()))
	if not isBusy() and not storyDialog:
		move(reset, f)
	return isMoving()


func setPause(p):
	pause = p
	if not prePause[0] and pause:
		prePause[1] = isMoving()
		if prePause[1]:
			standStill()
	if prePause[0] and not pause:
		if prePause[1]:
			move()
	prePause[0] = pause


func updateVillager(elapsedTime):
	super.update(elapsedTime)
	move(true, elapsedTime)


## Java overloads: draw(Graphics g) (inherited) and draw(Graphics g, int bx, int by):
## the background position is used to draw the villager relative to it.
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
		return
	drawX = J.round(pos[Values.X] + x)
	drawY = J.round(pos[Values.Y] + y)
	if isVisible():
		super.draw(g)


## Bridge (phase 1 step B): draw(g, x, y) without drawing (see Sprite.place_view).
func place_view(x, y):
	drawX = J.round(pos[Values.X] + x)
	drawY = J.round(pos[Values.Y] + y)
	if isVisible():
		return [place_sprite(drawX, drawY), drawX, drawY]
	return []


func getDialog():
	return dialog


func getStoredTriggers():
	var ret = storedTriggers
	storedTriggers = null
	return ret


func _to_string():
	return str(name)


func getResponses():
	return responses


## Loads the information about the villager from a file. Java inner class:
## the outer villager is passed as v.
class VillagerLoader extends AbstractMapLoader:
	var v = null
	var alt = [null, null, null, null]
	var dialogName = null
	var firstLine = null
	var secondLine = null
	var altIndex: int = 0
	var question: bool = false
	var dialogIndex: int = -1
	var altPaths: bool = false
	var gift = null
	var triggers = null
	var beforeTriggers = null
	var triggerAdds = null
	var questionNr: int = 0
	var prices = null
	var inputQ: bool = false
	var imageName = null
	var takeAmount: int = 0
	var takeName = null
	var forstatus: int = -1
	var open: bool = true
	var whisper: bool = false

	func _init(villager = null) -> void:
		v = villager

	## Java overloads: VillagerLoader.parseFile(String name) and the inherited
	## parseFile(path, filename).
	func parseFile(path: String, filename: String = ""):
		if filename != "":
			super.parseFile(path, filename)
			return
		var name: String = path
		var plainName: Array = J.split(name, "/")
		v.constraints = null
		v.constraintTrigger = null
		v.status = Database.getStatusFor(plainName[plainName.size() - 1])
		if v.status == -1:
			print("Villager: could not find: " + str(plainName[plainName.size() - 1])
					+ " in the database. Using default value!")
			v.status = 1
		v.filename = name
		super.parseFile(Values.VillageMaps, name + ".char")

	## Loads the new dialog with the given status number.
	func loadNewDialog(dialogNr):
		v.status = dialogNr
		v.dialog.clear()
		v.constraints = null
		v.constraintTrigger = null
		var reader = GameResourceLoader.getResourceLoader().getBufferedReader(
				Values.VillageMaps + v.filename + ".char")
		if reader == null:
			return
		var found: bool = false
		while not found:
			var line = reader.readLine()
			if line == null:
				# Java: NullPointerException caught by the try/catch.
				break
			if String(line).strip_edges() == "end":
				found = true
				continue
			parseLineForDialogChange(line)
		reader.close()

	func parseLineForDialogChange(line):
		var tokenizer := StringTokenizer.new(line)
		if line == "" or line.begins_with("#"):
			return
		if tokenizer.hasMoreTokens():
			var command: String = tokenizer.nextToken()
			executeDialogCommand(command, line, tokenizer)

	## Creates the dialog sequence associated with the villager.
	func executeDialogCommand(command, line, tok):
		if command == "dialog":
			var number: int = J.parseInt(tok.nextToken())
			v.loadingDialog = number == v.status
			# Port fix (COTZ-023): an assert, once, instead of quitting the game.
			if v.loadingDialog:
				assert(v.instructions.check(), "Villager %s: its walk does not end where it starts" % v.name)
		if v.loadingDialog:
			if command == "check":
				var trigName: String = tok.nextToken().replace("_", " ")
				var trigVal: String = tok.nextToken()
				v.constraints = J.split(tok.nextToken(), ":")
				v.constraintTrigger = [trigName, trigVal]
			elif command == "n":
				line = J.substring(line, 2, line.length())
				dialogName = line.replace("_", " ")
				whisper = false
			elif command == "whisper":
				whisper = true
			elif command == "fl":
				firstLine = line.replace("fl ", "")
				if firstLine.contains("--"):
					firstLine = modifyLine(firstLine)
				secondLine = ""
			elif command == "sl":
				var temp: String = tok.nextToken()
				if temp == "end":
					secondLine = ""
				else:
					secondLine = line.replace("sl ", "")
					if secondLine.contains("--"):
						secondLine = modifyLine(secondLine)
			elif command == "f":
				var first: bool = J.parseBoolean(tok.nextToken())
				var ds := DialogSequence.new(dialogName, firstLine, secondLine, first, question, whisper)
				ds.prices = prices
				prices = [0, 0, 0, 0]
				ds.setGift(gift)
				ds.setTake(takeName, takeAmount)
				takeName = null
				ds.setTriggers(triggers)
				ds.setBeforeTriggers(beforeTriggers)
				ds.setTriggerAdds(triggerAdds)
				triggers = null
				triggerAdds = null
				gift = null
				if altPaths:
					v.responses.get(dialogIndex).append(ds)
				else:
					v.dialog.append(ds)
				if imageName != null:
					ds.setImage(imageName)
					imageName = null
				if inputQ:
					ds.setInputQ(true)
					ds.setQuestionNr(questionNr)
					inputQ = false
					question = false
				elif question:
					ds.setAlternatives(alt.duplicate())
					ds.setQuestionNr(questionNr)
					question = false
					altIndex = 0
			elif command == "price":
				if prices == null:
					# Java would throw a NullPointerException here.
					prices = [0, 0, 0, 0]
				prices[0] = J.parseInt(tok.nextToken())
				prices[1] = J.parseInt(tok.nextToken())
				prices[2] = J.parseInt(tok.nextToken())
				prices[3] = J.parseInt(tok.nextToken())
			elif command == "take":
				takeName = tok.nextToken().replace("_", " ")
				takeAmount = 1
				if tok.hasMoreTokens():
					takeAmount = J.parseInt(tok.nextToken())
			elif command.begins_with("*"):
				altPaths = true
				command = command.replace("*", "")
				dialogIndex = J.parseInt(command)
				v.responses[dialogIndex] = []
			elif command == "endAlts":
				altPaths = false
			elif command == "inputQ":
				inputQ = true
				question = true
				questionNr = J.parseInt(tok.nextToken())
			elif command == "q":
				question = true
				if tok.hasMoreTokens():
					questionNr = J.parseInt(tok.nextToken())
			elif command == "alt":
				alt[altIndex] = tok.nextToken().replace("_", " ")
				altIndex += 1
			elif command == "showImage":
				imageName = Values.VillageImages + tok.nextToken()
			elif command == "gift":
				var contentName: String = tok.nextToken()
				var type: int = J.parseInt(tok.nextToken())
				var content = Loot.createContent(contentName, type, tok)
				gift = Loot.new(contentName, null, null, type, content, null)
			elif command == "run":
				v.sequence = true
				v.seqFileName = tok.nextToken().replace("_", " ")
			elif command == "trigger":
				var tname: String = tok.nextToken().replace("_", " ")
				var number: int = J.parseInt(tok.nextToken())
				if triggers == null:
					triggers = {}
				triggers[tname] = number
			elif command == "beforeTrigger":
				var tname: String = tok.nextToken().replace("_", " ")
				var number: int = J.parseInt(tok.nextToken())
				if beforeTriggers == null:
					beforeTriggers = {}
				beforeTriggers[tname] = number
			elif command == "triggeradd":
				var tname: String = tok.nextToken().replace("_", " ")
				var number: int = J.parseInt(tok.nextToken())
				if triggerAdds == null:
					triggerAdds = {}
				triggerAdds[tname] = number
			elif command == "storeTrigger":
				v.storedTriggers = tok.nextToken()

	func modifyLine(line):
		var ls: Array = J.split(line, "--")
		if ls[1] == "getBattles":
			line = ls[0] + str(Load.getPartyItems().getBattles()) + ls[2]
		return line

	func executeCommand(command: String, tokenizer: StringTokenizer):
		if command == "forstatus":
			var fs: int = J.parseInt(tokenizer.nextToken())
			if forstatus == -1:
				if fs == v.status or fs == -1:
					forstatus = fs
					open = true
				else:
					open = false
			else:
				if fs != v.status:
					open = false
		elif command == "in":
			if open:
				v.instructions.executeCommand(command, tokenizer)
		elif command == "start":
			if open:
				var startX: int = J.parseInt(tokenizer.nextToken())
				var startY: int = J.parseInt(tokenizer.nextToken())
				v.pos = Values.createNormalFloatPoint(startX, startY)
		elif command == "range":
			if open:
				v.range = J.parseInt(tokenizer.nextToken())
		elif command.to_lower() == "image":
			if open:
				var iname: String = tokenizer.nextToken().replace("_", " ")
				var number: int = 16
				if tokenizer.hasMoreTokens():
					number = J.parseInt(tokenizer.nextToken())
					if tokenizer.hasMoreTokens():
						v.height = J.parseInt(tokenizer.nextToken())
						v.width = J.parseInt(tokenizer.nextToken())
					else:
						v.height = Sprite.STANDARD_HEIGHT
						v.width = Sprite.STANDARD_WIDTH
				v.loadImages(iname, number)
		else:
			executeDialogCommand(command, lastLine, tokenizer)
