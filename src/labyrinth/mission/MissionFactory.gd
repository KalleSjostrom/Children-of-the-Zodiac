class_name MissionFactory
extends RefCounted
## Port of labyrinth.mission.MissionFactory.

const CLASS = 0
const DATABASE_NAME = 1
const TRIGGER_START = 2

static func createMission(info):
	var mission = null
	if info != null:
		mission = ClassRegistry.newInstance("labyrinth.mission." + str(info[CLASS]))
		if mission != null:
			mission.init(info)
	return mission
