class_name AbstractTimeLine
extends Fadeable
## Port of story.AbstractTimeLine: a time line used by story sequences.
## Time is counted in milliseconds (update receives ms). The Java semaphore
## around mode is not needed (single threaded).

const DIALOG = 1
const NORMAL = 3
const WAITING_FOR_INPUT = 0
const WAITING_FOR_ACTORS = 2
const DIALOG_WAITING_FOR_ACTORS = 4
const NOT_DONE = 0
const TIME_LINE_DONE = 1
const INPUT_DONE = 2
const ALL_DONE = 3
const RUNNING = 1
var info = []
var doneMode: int = NOT_DONE
var nextInitTime: int = 0
var nextStopTime: int = 0
var currentTime: int = 0
var modeAccess = null
var mode: int = NORMAL
var searchingForDialog: bool = false

func update(elapsedTime: float):
	if mode % 2 == RUNNING:
		if searchingForDialog:
			if currentTime >= nextInitTime:
				setNextStartTime()
				searchingForDialog = false
		else:
			if currentTime >= nextStopTime:
				setNextStopTime()
				searchingForDialog = true
		currentTime += int(elapsedTime)
		if info.size() > 0:
			var tli = info[0]
			while currentTime >= tli.getTime():
				executeCommand(tli)
				J.removeAt(info, 0)
				if info.size() > 0:
					tli = info[0]
				else:
					break

func setMode(newMode):
	mode = newMode

func getMode():
	return mode

func compareMode(compareMode):
	return mode == compareMode

## Abstract.
func setNextStartTime():
	pass

## Abstract.
func setNextStopTime():
	pass

## Abstract.
func executeCommand(info):
	pass
