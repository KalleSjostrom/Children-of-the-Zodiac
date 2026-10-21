class_name FloorButton
extends Inventory
## Port of labyrinth.inventory.FloorButton: a button in the floor that is
## pressed when the player arrives at its node. It adds 1 to the status of
## its hinders (DummyDoor / AdditiveHinderDoor).
##
## Port note: draw(gl, dir = null): dir == null is Java's draw(Graphics);
## otherwise the inherited Inventory.draw(GL2, int).

var hinders = null


func _init(node = null, dir = null, nrOfTexs = null, image = null, status = null, hinder = null) -> void:
	super(node, dir, nrOfTexs, image, status)
	var st: int = 0 if status == null else status
	hinders = hinder
	currentTex = st
	if st == -1:
		self.status = 0


func draw(gl, dir = null):
	if dir != null:
		super.draw(gl, dir)
		return
	var g = gl
	texture[status].bind(g)
	g.beginQuads()
	node.drawOneFloor(g)
	g.end()


## Bridge (phase 2 step B): draw without the drawing (Inventory.place_view):
## the image of its status, drawn as its node's floor.
func place_view(g, dir = null):
	texture[status].bind(g)
	var state: Dictionary = g.render_state_3d()
	var quads := DungeonQuads.new(g)
	node.drawOneFloor(quads)
	return {"visible": true, "frame": status, "state": state, "quad": quads.eye_space()}


func arrive(labyrinth):
	if status == 0:
		SoundPlayer.playSound(SoundMap.LABYRINTH_SECRET)
		status = 1
		Database.addStatus(dataBaseName, 1)
		updateDoorStatus(hinders, 1)


func setSettings():
	pass


func activate(labyrinth):
	pass


static func updateDoorStatus(hinders, status):
	for i in hinders.size():
		if hinders[i] is DummyDoor:
			hinders[i].addStatus(status)
		elif hinders[i] is AdditiveHinderDoor:
			hinders[i].addStatus(status)


func getMapImage():
	return LabyrinthMap.lever[status]


func isPassable(dir):
	return true


func isDirectedTowards(dir):
	return true


func isPassableOnThis(dir):
	return true


func shouldDrawWhenOnlySeen():
	return false
