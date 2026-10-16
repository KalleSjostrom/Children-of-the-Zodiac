class_name Body
extends PointBody
## Port of bodies.Body: a point body with size, life, color and a parent
## particle system.

var size: float = 1.0
var radius: float = 0.0
var waitForEmit: bool = false
var parent = null
var life: float = 0.0
var rgb = [0.0, 0.0, 0.0]
var queued: bool = false
var emittedFrom = null


func reset():
	life = 1
	setVelocity(Vector3f.new())
	setForce(getDefaultForce())


## Java: setColor(Vector3f v). (The second parameter comes from the merged
## skeleton signature and is unused.)
func setColor(c, a = null):
	rgb[0] = c.x
	rgb[1] = c.y
	rgb[2] = c.z


func setLife(l):
	life = l


func kill():
	life = 0


## Java overloads: draw(Graphics g, GameTexture t, Vector3f pPos) and the
## empty draw(Graphics g, int x, int y).
func draw(g, t = null, pPos = null):
	if t is GameTexture:
		if isAlive():
			g.setColor4(rgb, life)
			var pos = getPosition()
			t.drawMany(g, pos.x + pPos.x, -(pos.y + pPos.y), modifySize(size))


func modifySize(size):
	return size


func getSize():
	return size


func getParent():
	return parent


func getRadius():
	return radius


func isDead():
	return not isAlive()


func isAlive():
	return life > 0


func isWaitingForEmit():
	return waitForEmit


func setSize(s):
	size = s


func setRadius(r):
	radius = r


func setParent(particleSystem):
	self.parent = particleSystem


func isQueuedForEmittance():
	return queued


func queueForEmittance():
	queued = true


func dequeueForEmittance():
	queued = false


func getLife():
	return life


func setEmitPosition(emitPosition):
	emittedFrom = emitPosition


func getEmitPosition():
	return emittedFrom
