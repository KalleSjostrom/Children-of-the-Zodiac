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


## Bridge (particles phase, docs/ARCHITECTURE.md section 9): execute's
## turbulence for elapsedTime seconds of a smoke system that a
## VillageParticles2D draws (no bodies): the wind turns as 30 steps a second
## would turn it, as a per-second rate (each component gets the variance of
## those steps' random turns), then keeps its magnitude.
func drift(elapsedTime):
	var k: float = turbulence * sqrt(30.0 * elapsedTime)
	wind.addLocal(
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * k,
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * k,
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * k)
	wind.normalizeLocal().multLocal(windMagnitude)


func execute(bodies, elapsedTime):
	var it = bodies.iterator()
	wind.addLocal(
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * turbulence,
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * turbulence,
		(BodiesParticleSystem.rand.nextDouble() - 0.5) * turbulence)
	wind.normalizeLocal().multLocal(windMagnitude)
	while it.hasNext():
		var b = it.next()
		if b.isAlive():
			b.addForce(wind.mult(b.getMass()))
