class_name FireMission
extends Mission
## Port of labyrinth.mission.FireMission.

var string = "Found: "
const DONE_CRITERION = 2

func init(info):
	setDatabaseName(info[MissionFactory.DATABASE_NAME])
	if getStatus() == -1:
		setStatus(0)
	addTriggers(info)

func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	g.startText()
	super.update()
	g.setFontSize(40)
	Graphics.setTextColor(1)
	var status: int = getStatus()
	if isFinished(status):
		show_line(g, "Mission done!", int(800 + getXtrans() * 300))
	else:
		show_line(g, string + str(status) + "/" + str(DONE_CRITERION), int(800 + getXtrans() * 300))
	g.finishText()

func initDraw(g: Graphics):
	pass

func isFinished(status):
	return status == DONE_CRITERION
