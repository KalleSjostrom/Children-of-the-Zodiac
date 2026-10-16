class_name DialogPackage
extends RefCounted
## Port of villages.villageStory.DialogPackage: a list of dialog sequences
## with a start and stop time. Constructors DialogPackage() and
## DialogPackage(name, start, stop) are merged.

var sequense = []
var startTime: int = 0
var stopTime: int = 0
var name = null

func _init(name = null, start = null, stop = null) -> void:
	sequense = []
	if start != null:
		self.name = name
		startTime = start
		stopTime = stop

func add(ds):
	sequense.append(ds)

func getSequense():
	return sequense

func getStartTime():
	return startTime

func getStopTime():
	return stopTime

func getName():
	return name
