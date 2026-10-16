class_name Camera
extends RefCounted
## Port of labyrinth.Camera: manages the view in the labyrinth. It is the
## players "eyes" or the camera.
##
## Port note: shakeit(time) started a Java thread that changed the shake
## offsets every 50 ms; here shakeit2 is a coroutine (await Scheduler.sleep)
## started without await.

var location = null
var angle: float = 0.0
static var mode: int = 0
static var shakeoffx: float = 0.0
static var shakeoffy: float = 0.0


## Constructs a new camera with the location set to the origin.
func _init() -> void:
	location = [0.0, 0.0]


## Gets the location of the camera.
func getLocation():
	return location


## Sets the location of the camera to the given location.
func setLocation(p_location) -> void:
	location = p_location


## Turns the view so that the view of the screen matches that of the camera.
func lookAt(g) -> void:
	g.rotate(angle + 90, 0, 1, 0)
	if angle == 0 or angle == 180:
		g.translate(-location[LabyrinthPosition.X], shakeoffy,
			-location[LabyrinthPosition.Z] + shakeoffx)
	else:
		g.translate(-location[LabyrinthPosition.X] + shakeoffx, shakeoffy,
			-location[LabyrinthPosition.Z])


## Shakes the camera for the given time (in milliseconds).
static func shakeit(time) -> void:
	shakeit2(time)


static func shakeit2(time) -> void:
	var max_: int = int(time) / 50
	for j in max_:
		await Scheduler.sleep(50)
		var m: float = 0.05 # .1f
		mode += 1
		mode %= 3
		match mode:
			0:
				shakeoffx = m
			1:
				shakeoffx = 0
			2:
				shakeoffx = -m
			3:
				shakeoffy = m
			4:
				shakeoffy = 0
			5:
				shakeoffy = -m
	shakeoffx = 0
	shakeoffy = 0


## Updates this cameras location and angle based on the given position.
func updatePosition(position) -> void:
	location[LabyrinthPosition.X] = position.getX()
	location[LabyrinthPosition.Z] = position.getZ()
	angle = position.getAngle()
