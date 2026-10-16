class_name MissionChest
extends Inventory
## Port of labyrinth.inventory.MissionChest: a chest that is part of a
## labyrinth mission. Activating it shows its dialogs, increments the mission
## status and then shows the mission's finished dialogs (if finished).
##
## dialogs is an Array of [speaker, line1, line2] arrays.

var dialogs = []
var current: int = 0
var currentSpeaker = null
var first: bool = true
var missionDone: bool = false


func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null, t = null) -> void:
	super(n, dir, nrOfTexs, image, status)
	if status == 1:
		currentTex = Object2D.INVISIBLE
		current = J.INT_MAX
	else:
		current = 0
		currentTex = 0
		while t.hasMoreTokens():
			var dial: Array = J.array(3, null)
			var s: Array = Parser.getArgument(t.nextToken())
			dial[0] = s[0]
			s = Parser.getText(t, s[1])
			dial[1] = s[0]
			dial[2] = s[1] if s.size() > 1 else ""
			dialogs.append(dial)
		if dialogs.size() > 0:
			currentSpeaker = dialogs[0][0]


func setSettings():
	scale = BattleValues.CARD_SCALE
	info = getSettings()
	heightOffset = info.getHeightOffset()
	zOff = info.getZOffset()
	scale2 = info.getScale()


func activate(labyrinth):
	if current < dialogs.size():
		var d: Array = dialogs[current]
		var cs: String = d[0]
		if currentSpeaker != cs:
			currentSpeaker = cs
			first = not first

		if d[0] == "gift":
			currentTex = 1
			var name: String = String(d[1]).replace("_", " ")
			# Load.getPartyItems().addItem(name, 1)
			SoundPlayer.playSound(info.getSoundEffect())
			labyrinth.drawDialog("Zalzi took " + name + " from the chest.", "")
		else:
			labyrinth.drawDialog(first, d[0], d[1], d[2], String(d[0]).contains("()"))
		current += 1
	elif not missionDone:
		var mission = labyrinth.getMission()
		mission.incrementStatus()
		missionDone = true
		if mission.checkIfFinished():
			var missionDialogs = mission.getFinishedDialogs()
			if missionDialogs != null:
				dialogs = missionDialogs
				current = 0
		activate(labyrinth)
	else:
		doneForGood()
		# labyrinth.exitDialog(true)


func doneForGood():
	status = 1
	Database.addStatus(dataBaseName, status)


func getMapImage():
	var st: int = Database.getStatusFor(dataBaseName)
	if st == -1:
		st = 0
		Database.addStatus(dataBaseName, 0)
	return LabyrinthMap.chest[st]


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
