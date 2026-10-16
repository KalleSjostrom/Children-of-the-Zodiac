class_name TriggerDoor
extends InventoryDoor
## Port of labyrinth.inventory.TriggerDoor.
##
## A door that, when the player arrives at it the first time, shows dialogs,
## sets triggers, plays a sound and may offer a tutorial. Its data is read
## from <Values.LabyrinthTriggers><nextPlace>.trig.
##
## Port notes: init() is overridden to do nothing (as in Java), so the door
## setup of InventoryDoor.init runs from this constructor via super.init().
## The Java thread waiting for the labyrinth fade is Scheduler.waitUntil.

var dialog = Dialog.getDialog()
var dialogs = null
var triggers = null
var tutorial = null
var sound = null
var alt = null
var tutorialName = null


func _init(node = null, dir = null, openRoad = null, nextPlace = null, status = null, tok = null) -> void:
	super(node, dir, openRoad, nextPlace, status, tok)
	var triggerfilename: String = Organizer.convertKeepCase(nextPlace)
	triggerfilename += ".trig"
	var loader := TriggerLoader.new()
	loader.parseFile(triggerfilename)
	dialogs = loader.getDialogs()
	self.triggers = loader.getTrigger()
	sound = loader.getSound()
	tutorialName = loader.getTutorialName()
	super.init(openRoad, tok.nextToken(), tok)


func init(openRoad, nextPlace, tok):
	pass # Just override it!


func isDirectedTowards(dir):
	return true


func arrive(labyrinth):
	var lab = labyrinth
	super.arrive(lab)

	if getStatus() != 2:
		setStatus(2)
		if dialogs != null and dialogs.size() > 0:
			var seq = dialogs[0].getSequense()
			lab.drawDialog(seq)
		if triggers != null:
			Database.addStatus(triggers)
		if sound != null:
			var s = sound
			if lab.isFading():
				Scheduler.waitUntil(func(): return not lab.isFading(),
						func(): SoundPlayer.playSound(s))
			else:
				SoundPlayer.playSound(sound)
		lab.addTopLayer(self)


func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = ((int(lab.getPlayerAngle()) - 90) / 90 + 4) % 4
	if playerDir == dir:
		super.activate(lab)
	else:
		if tutorial == null and tutorialName != null:
			if dialog.isQuestion():
				alt = dialog.getCurrentAlternative()
				if alt != null and String(alt).begins_with("Sure"):
					tutorial = Tutorial.new(tutorialName, true)
					tutorial.increment()
					tutorial.setActive(true)
		elif tutorial != null:
			if tutorial.crossedPressed():
				# tutorial = null
				Dialog.getDialog().resetDialog()


func drawTopLayer(g):
	if tutorial != null:
		tutorial.drawTopLayer(g)


class TriggerLoader extends AbstractMapLoader:
	var triggers = {}
	var sound = null
	var tutorialName = null
	var parser = null
	var dialogs = []

	func getTrigger():
		return triggers

	func getTutorialName():
		return tutorialName

	func getSound():
		return sound

	func getDialogs():
		return dialogs

	## Java: parseFile(String filename) (filename == "": the name is in path).
	func parseFile(path: String, filename: String = ""):
		if filename == "":
			parser = Parser.new()
			super.parseFile(Values.LabyrinthTriggers, path)
		else:
			super.parseFile(path, filename)

	func executeCommand(command: String, tokenizer: StringTokenizer):
		var t := tokenizer
		var args: Array
		if command == "trigger":
			var name = null
			var value: int = 0
			while t.hasMoreTokens():
				args = Parser.getArgument(t.nextToken())
				if args[0] == "name":
					name = args[1]
				elif args[0] == "value":
					value = J.parseInt(args[1])
			triggers[name] = value
		elif command == "playSound":
			var name = null
			while t.hasMoreTokens():
				args = Parser.getArgument(t.nextToken())
				if args[0] == "name":
					name = Organizer.convertKeepCase(args[1])
			sound = name
		elif command == "tutorialName":
			var name = null
			while t.hasMoreTokens():
				args = Parser.getArgument(t.nextToken())
				if args[0] == "name":
					name = Organizer.convertKeepCase(args[1])
			tutorialName = name
		elif command == "dialog":
			parser.addDialog(t, dialogs, null)
		elif command == "dialogpacket":
			dialogs.append(parser.getDialogPacket(t))
