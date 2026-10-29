class_name TimeMission
extends Mission
## Port of labyrinth.mission.TimeMission.

var string = "Time: "
var time: float = 0.0
var min: int = 0
var sec: int = 0
var gameOver: bool = false

func init(info):
	setDatabaseName(info[MissionFactory.DATABASE_NAME])
	if getStatus() == -1:
		setStatus(150)
	addTriggers(info)

func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.startText()
	super.update()
	g.setFontSize(40)
	Graphics.setTextColor(1)
	var status: int = getStatus()
	time += Values.INTERVAL
	if time > 1000:
		time = 0
		status -= 1
		setStatus(status)
	if isFinished(status):
		show_line(g, "Time's up!", int(800 + getXtrans() * 300))
		if not gameOver:
			var m = Organizer.getOrganizer().getCurrentMode()
			var l: Labyrinth = m as Labyrinth
			Database.addStatus("pensara prison--floor 1.mapchest25", 1)
			Database.addStatus("pensara prison--floor 3.mapchest185", 1)
			Database.addStatus("pensara prison--floor 6.mapchest110", 1)
			Database.addStatus("The Prison Cell", 0)
			l.exit("Pensara Prison--Floor 5-mark0", true)
			gameOver = true
	else:
		sec = status % 60
		min = status / 60
		show_line(g, string + str(min) + ":" + ("0" if sec < 10 else "") + str(sec), int(800 + getXtrans() * 300))
	g.finishText()

func initDraw(g: Graphics):
	pass

func isFinished(status):
	return status <= 0
