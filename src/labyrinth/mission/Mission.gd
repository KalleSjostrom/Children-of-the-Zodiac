class_name Mission
extends Hideable
## Port of labyrinth.mission.Mission.

var status: int = 0
var dbName = ""
var triggers = {}
var dialogs = null
var conditions = {}

func _init() -> void:
	super(0)
	setAxis(X)
	setLimit(true)
	setMovementSpeed(true)

func checkIfFinished():
	var done: bool = false
	status = Database.getStatusFor(dbName)
	done = isFinished(status)
	if done:
		Database.addStatus(triggers)
	return done

## Abstract in Java (draw(Graphics g)).
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	pass

## Abstract in Java (init(ArrayList<String> info)).
func init(boss):
	pass

## Abstract in Java.
func isFinished(status):
	return false

func addTriggers(info):
	for i in range(MissionFactory.TRIGGER_START, info.size()):
		var s: String = info[i]
		var args: Array = J.split(s, "&&")
		if args[0] == "trigger":
			triggers[args[1]] = J.parseInt(args[2])
		elif args[0] == "dialog":
			if dialogs == null:
				dialogs = []
			var dialog: Array = ["", "", ""]
			for j in range(1, args.size()):
				dialog[j - 1] = args[j]
			dialogs.append(dialog)
		elif args[0] == "extranext":
			var key: int = J.parseInt(args[1])
			var value: String = args[2]
			var ms: int = Database.getStatusFor("mission" + value)
			if ms <= 0:
				conditions[key] = value

func getStatus():
	status = Database.getStatusFor(dbName)
	return status

func setStatus(status):
	self.status = status
	Database.addStatus(dbName, status)

func getDatabaseName():
	return dbName

func setDatabaseName(name):
	self.dbName = name

func getTriggers():
	return triggers

func setTriggers(triggers):
	self.triggers = triggers

func getFinishedDialogs():
	return dialogs

func incrementStatus():
	setStatus(getStatus() + 1)

func getNext():
	var c = conditions.get(status)
	var ms: int = Database.getStatusFor("mission" + str(c))
	if ms == -1 or ms == 0:
		return c
	return null

func resetNext():
	var c = conditions.get(status)
	Database.addStatus("mission" + str(c), 1)
