class_name IfDoor
extends InventoryDoor
## Port of labyrinth.inventory.IfDoor: a door whose destination depends on a
## database status. nextPlaces[0] is "condition==value", nextPlaces[1] the
## place used (once) when the condition holds, nextPlaces[2] the other place.

var condition = ""
var conditionStatus: int = 0
var trueCase = ""
var falseCase = ""
static var ALWAYS_FALSE: int = -2


func _init(node = null, dir = null, openRoad = null, next = null, status = null, tok = null) -> void:
	super(node, dir, openRoad, next, status, tok)
	var temp: Array = J.split(nextPlaces[0], "==")
	condition = Organizer.convert(temp[0])
	conditionStatus = J.parseInt(temp[1])
	trueCase = nextPlaces[1]
	falseCase = nextPlaces[2]


func activate(labyrinth):
	var lab = labyrinth
	var playerDir: int = ((int(lab.getPlayerAngle()) - 90) / 90 + 4) % 4
	if playerDir == dir:
		for i in openRoad.size():
			var road: String = openRoad[i]
			if road != "dontopen":
				Database.addStatus("road" + road, 1) # road

		status = Database.getStatusFor(dataBaseName)
		status = 0 if status == -1 else status
		var next: String
		if status == ALWAYS_FALSE:
			next = falseCase
		else:
			var s: int = Database.getStatusFor(condition)
			if s == conditionStatus:
				var trueStatus: int = Database.getStatusFor(Organizer.convert(trueCase))
				if trueStatus == -1:
					next = trueCase
					status = ALWAYS_FALSE
					Database.addStatus(dataBaseName, status)
					Database.addStatus(Organizer.convert(trueCase), 1)
					Organizer.getOrganizer().updateNextPlaceFor(trueCase, falseCase)
				else:
					next = falseCase
			else:
				next = falseCase
		super.enter(lab, info)
		lab.exitLabyrinth(Values.EXIT)
		_setHaveBeen()
		if next.contains("-pos"):
			var split: Array = J.split(next, "-pos")
			next = split[0]
			VillageLoader.staticStartPos = J.parseInt(split[1])
		lab.setNextPlace(next)
