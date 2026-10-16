class_name BombMission
extends Mission
## Port of labyrinth.mission.BombMission.

var string = "Bombs Disarmed: "
const DONE_CRITERION = 3

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
		g.drawMultiString("Mission done!", int(800 + getXtrans() * 300), 50)
	else:
		g.drawMultiString(string + str(status) + "/" + str(DONE_CRITERION), int(700 + getXtrans() * 350), 50)
	g.finishText()

func initDraw(g: Graphics):
	pass

func isFinished(status):
	return status == DONE_CRITERION
