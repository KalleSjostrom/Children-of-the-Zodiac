class_name PointBody
extends RefCounted
## Port of bodies.PointBody: a point mass with force, velocity and position.

var force = Vector3f.new()
var velocity = Vector3f.new()
var position = Vector3f.new()
var mass: float = 0.0
var inverseMass: float = 0.0


## Java: update(float elapsedTime). The body parameter only exists because the
## skeleton merged signatures; it is ignored.
func update(elapsedTime, body = null):
	var position = getPosition()
	var force = getForce()
	var velocity = getVelocity()
	var invMass: float = getInverseMass()
	# Same as velocity.addLocal(force.mult(elapsedTime * invMass)) and
	# position.addLocal(velocity.mult(elapsedTime)), without temporaries.
	var k: float = elapsedTime * invMass
	velocity.addLocal(force.x * k, force.y * k, force.z * k)
	position.addLocal(velocity.x * elapsedTime, velocity.y * elapsedTime, velocity.z * elapsedTime)
	setForce(getDefaultForce())


func addViscousDrag(k):
	addForce(velocity.mult(-k))


func addDrag(c):
	addForce(velocity.mult(-c * velocity.length()))


func addForce(f):
	force.addLocal(f)


func getForce():
	return force


func getDefaultForce():
	return Vector3f.new()


func getVelocity():
	return velocity


func getPosition():
	return position


func getMass():
	return mass


func getInverseMass():
	return inverseMass


func setForce(force):
	self.force = force


func setVelocity(velocity):
	self.velocity = velocity


func setPosition(position):
	self.position = position


func setMass(mass):
	self.mass = mass
	inverseMass = 1.0 / float(mass)
