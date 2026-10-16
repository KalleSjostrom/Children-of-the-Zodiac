class_name MissionBomb
extends Inventory
## Port of labyrinth.inventory.MissionBomb: a bomb (rock blocking the way)
## that is part of a labyrinth mission. Dialog speakers of the form
## "<missionStatus>-<speaker>" are only shown at that mission status.
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
		var css: Array = J.split(cs, "-")
		if css.size() > 1:
			var i: int = J.parseInt(css[0])
			var mission = labyrinth.getMission()
			var ms: int = mission.getStatus()
			if i != ms:
				current += 1
				activate(labyrinth)
				return
			d[0] = css[1]
		if currentSpeaker != cs:
			currentSpeaker = cs
			first = not first
		labyrinth.drawDialog(first, String(d[0]).replace("()", ""), d[1], d[2], String(d[0]).contains("()"))
		current += 1
	elif not missionDone:
		var mission = labyrinth.getMission()
		mission.incrementStatus()
		missionDone = true
		SoundPlayer.playSound(SoundMap.LABYRINTH_DOOR_SLIDING_STONE)
		if mission.checkIfFinished():
			var missionDialogs = mission.getFinishedDialogs()
			if missionDialogs != null:
				dialogs = missionDialogs
				current = 0
		activate(labyrinth)
	else:
		doneForGood()


func doneForGood():
	currentTex = Object2D.INVISIBLE
	status = 1
	Database.addStatus(dataBaseName, status)


func getMapImage():
	return LabyrinthMap.bomb[status]


func isPassable(dir):
	return status != 0


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return true
