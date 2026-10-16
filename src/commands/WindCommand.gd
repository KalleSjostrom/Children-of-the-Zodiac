class_name WindCommand
extends Command
## Port of commands.WindCommand: a turbulent wind force.

const DEFAULT_TURBULENCE = 0.1
var wind = Vector3f.new()
var turbulence: float = DEFAULT_TURBULENCE
var windMagnitude: float = 0.0


func setForce(force):
	wind = force
	windMagnitude = wind.length()


func setTurbulence(value):
	turbulence = value


func execute(bodies, elapsedTime):
	var it = bodies.iterator()
	wind.addLocal(
		(J.random() - 0.5) * turbulence,
		(J.random() - 0.5) * turbulence,
		(J.random() - 0.5) * turbulence)
	wind.normalizeLocal().multLocal(windMagnitude)
	while it.hasNext():
		var b = it.next()
		if b.isAlive():
			b.addForce(wind.mult(b.getMass()))
