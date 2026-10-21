class_name Inventory
extends RefCounted
## Port of labyrinth.inventory.Inventory.
##
## This class is the abstract inventory. An inventory is a thing in the
## labyrinth, that the player can find. Examples of these is chest,
## buttons, doors and so on.
##
## Port notes:
## * Java's draw(Graphics g) and draw(GL2 gl, int dir) are merged into
##   draw(gl, dir = null): dir == null is draw(Graphics), otherwise the quad
##   of the inventory is emitted (no glBegin/glEnd) facing dir. No Java
##   subclass overrides draw(GL2, int), so the Graphics version calls the
##   non virtual helper _drawQuad().
## * Java's setHaveBeen() and setHaveBeen(String) are merged into
##   setHaveBeen(lastNodesName = null). The Java no-argument version (used
##   internally by the doors) is _setHaveBeen().

var node = null
var dataBaseName = ""
var image = ""
var images = null
var dir: int = 0
var status: int = 0
var scale: float = 0.0
var scale2: float = 0.0
var zOff: float = 0.0
var heightOffset: float = 0.0
var texture = null
var height: float = 0.0
var width: float = 0.0
var currentTex: int = 0
var haveBeenIn: bool = false
const Y_HEIGHT = 0
const Z_OFF = 1
const SCALE = 2
var info = null
static var map = null


## Creates a new inventory from the given information.
## n: the node where the inventory should be. dir: the direction the texture
## should face (Values.UP, .RIGHT, .DOWN, .LEFT). nrOfTexs: the number of
## textures to use. image: the name of the first image in the series.
## status: the status for this inventory according to the Database class.
func _init(n = null, dir = null, nrOfTexs = null, image = null, status = null) -> void:
	node = n
	self.dir = 0 if dir == null else dir
	self.image = image
	self.status = 0 if status == null else status
	var nr: int = 0 if nrOfTexs == null else nrOfTexs
	images = J.array(nr, null)
	texture = J.array(nr, null)
	setSettings()


## Initiates the drawings of the inventory.
func initDraw(gl):
	if image == null:
		return
	if images.size() > 1:
		for i in images.size():
			var temp: String = Values.LabyrinthTextures + image + str(i) + ".png"
			if GameResourceLoader.getResourceLoader().exists(temp):
				images[i] = temp
			else:
				images[i] = Values.LabyrinthTextures + image + str(i) + ".jpg"
			ImageHandler.addToCurrentLoadOnUse(images[i])
			texture[i] = ImageHandler.getTexture(images[i])
	else:
		images[0] = Values.LabyrinthTextures + image
		ImageHandler.addToCurrentLoadOnUse(images[0])
		texture[0] = ImageHandler.getTexture(images[0])
	setSize(0, scale)


func setSize(index, scale):
	if texture[index] == null:
		push_error("Inventory.setSize: missing texture for " + str(image))
		return
	height = texture[index].getHeight() * scale
	width = texture[index].getWidth() * scale


## Java overloads: draw(Graphics g) [dir == null] and draw(GL2 gl, int dir).
func draw(gl, dir = null):
	if dir != null:
		_drawQuad(gl, dir)
		return
	var g = gl
	if currentTex != Object2D.INVISIBLE:
		gl = g.getGL()
		if currentTex < texture.size() and texture[currentTex] != null:
			texture[currentTex].bind(g)
		gl.glBegin(Graphics.GL_QUADS)
		_drawQuad(gl, self.dir)
		gl.glEnd()


## Bridge (phase 2 step B, docs/ARCHITECTURE.md section 10): draw(g) without
## the drawing, for a floor its scene draws (Graph.show_inventory): the same
## checks and GL state changes (the texture it binds; its quad, recorded by
## DungeonQuads, leaves the same normal and texture coordinate current), and
## what it would draw: "visible", "frame" (the index of the texture),
## "state" (the render state, Graphics.render_state_3d) and "quad" (its
## vertices in eye space, as GLBackend would draw them).
## DungeonScene.show_object shows it.
func place_view(g, dir = null):
	if currentTex == Object2D.INVISIBLE:
		return {"visible": false}
	if currentTex < texture.size() and texture[currentTex] != null:
		texture[currentTex].bind(g)
	var state: Dictionary = g.render_state_3d()
	var quads := DungeonQuads.new(g)
	_drawQuad(quads, self.dir)
	return {"visible": true, "frame": currentTex, "state": state, "quad": quads.eye_space()}


## Java: protected void draw(GL2 gl, int dir).
func _drawQuad(gl, dir: int) -> void:
	var position = node.getPos()
	var x: float = position.getX()
	var x2: float
	var y: float = LabyrinthNode.FLOOR_HEIGHT + heightOffset
	var y2: float = y + height * scale2
	var z: float = position.getZ()
	var z2: float

	var flip := true
	match dir:
		0:
			# Back wall // SOUTH
			z = position.getZ() + zOff
			x = position.getX() - (width / 2) * scale2
			x2 = position.getX() + (width / 2) * scale2
			flip = false
			gl.glNormal3f(0, 0, -1.0)
			gl.glTexCoord2f(0 if flip else 1, 1)
			gl.glVertex3f(x, y, z)
			gl.glTexCoord2f(0 if flip else 1, 0)
			gl.glVertex3f(x, y2, z)
			gl.glTexCoord2f(1 if flip else 0, 0)
			gl.glVertex3f(x2, y2, z)
			gl.glTexCoord2f(1 if flip else 0, 1)
			gl.glVertex3f(x2, y, z)
		1:
			# Left Wall // WEST
			x = position.getX() - zOff
			z = position.getZ() + (width / 2) * scale2
			z2 = position.getZ() - (width / 2) * scale2
			gl.glNormal3f(1.0, 0, 0)
			gl.glTexCoord2f(0, 0)
			gl.glVertex3f(x, y2, z)
			gl.glTexCoord2f(0, 1)
			gl.glVertex3f(x, y, z)
			gl.glTexCoord2f(1, 1)
			gl.glVertex3f(x, y, z2)
			gl.glTexCoord2f(1, 0)
			gl.glVertex3f(x, y2, z2)
		2:
			# Front Wall // NORTH
			z = position.getZ() - zOff
			x = position.getX() - (width / 2) * scale2
			x2 = position.getX() + (width / 2) * scale2
			gl.glNormal3f(0, 0, 1.0)
			gl.glTexCoord2f(0, 0)
			gl.glVertex3f(x, y2, z)
			gl.glTexCoord2f(0, 1)
			gl.glVertex3f(x, y, z)
			gl.glTexCoord2f(1, 1)
			gl.glVertex3f(x2, y, z)
			gl.glTexCoord2f(1, 0)
			gl.glVertex3f(x2, y2, z)
		3:
			# Right Wall // EAST
			x = position.getX() + zOff
			z = position.getZ() + (width / 2) * scale2
			z2 = position.getZ() - (width / 2) * scale2
			gl.glNormal3f(-1.0, 0, 0)
			gl.glTexCoord2f(0, 0)
			gl.glVertex3f(x, y2, z2)
			gl.glTexCoord2f(0, 1)
			gl.glVertex3f(x, y, z2)
			gl.glTexCoord2f(1, 1)
			gl.glVertex3f(x, y, z)
			gl.glTexCoord2f(1, 0)
			gl.glVertex3f(x, y2, z)


## Sets the name of this inventory as it is marked in the data base.
func setDatabaseName(name):
	dataBaseName = name


## Gets the name of this inventory as it is marked in the database.
func getDatabaseName():
	return dataBaseName


## Gets the node where this inventory is located.
func getNode():
	return node


func getDirection():
	return dir


static func createMap():
	var m := {}
	m["Images/chest"] = InventoryInfo.new(0, 0, 3.5, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST)
	m["Images/pot"] = InventoryInfo.new(0, 0, 2, SoundMap.LABYRINTH_OPEN_STONE_BOX)
	m["Images/icepot"] = InventoryInfo.new(0, 0, 2, SoundMap.LABYRINTH_OPEN_STONE_BOX)
	m["Images/crate"] = InventoryInfo.new(0, 0, 3, SoundMap.LABYRINTH_OPEN_CRATE)
	m["Images/snowcrate"] = InventoryInfo.new(0, 0, 3, SoundMap.LABYRINTH_OPEN_CRATE)
	m["Images/lever"] = InventoryInfo.new(0, 1.0, 5.0, SoundMap.LABYRINTH_LEVER_PRESSED)
	m["Images/note1"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_NOTE_1)
	m["Images/note2"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_NOTE_2)
	m["Images/note3"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_NOTE_3)
	m["Images/note4"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_NOTE_4)
	m["Images/note5"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_NOTE_5)
	m["Images/5x5small.png"] = InventoryInfo.new(1.45, 1.99, 3, "")
	m["Images/4x4small.png"] = InventoryInfo.new(1.45, 1.99, 3, "")
	m["Images/1-9small.png"] = InventoryInfo.new(1.45, 1.99, 3, "")
	m["Images/ladderdown.png"] = InventoryInfo.new(-2.5, 0.3, 2.5, SoundMap.LABYRINTH_LADDER)
	m["Images/ladderup.png"] = InventoryInfo.new(0, 0.3, 2.5, SoundMap.LABYRINTH_LADDER)
	m["Images/sandstone.png"] = InventoryInfo.new(0, -1.5, 3.5, SoundMap.LABYRINTH_OPEN_STONE_BOX)
	m["Images/stub.png"] = InventoryInfo.new(0, 0, 2, SoundMap.LABYRINTH_OPEN_STUB)
	m["Images/volcano.png"] = InventoryInfo.new(-0.1, 0, 2.5, SoundMap.LABYRINTH_DOOR_STONE)
	m["Images/woodenbox"] = InventoryInfo.new(0, 0, 3, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST)
	m["Images/woodenbox1"] = InventoryInfo.new(0, 0, 3, SoundMap.LABYRINTH_OPEN_WOODEN_CHEST)
	m["Images/riddle"] = InventoryInfo.new(0, 0, 1, "")
	m["Images/bomb.png"] = InventoryInfo.new(1.5, 1.99, 3, SoundMap.LABYRINTH_SECRET)
	m["Images/stonebox"] = InventoryInfo.new(0, 0, 3.5, SoundMap.LABYRINTH_OPEN_STONE_BOX)
	m["Walls/prisondooru"] = InventoryInfo.new(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS)
	m["Walls/prisondoord"] = InventoryInfo.new(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS)
	m["Walls/airtemplestairdown"] = InventoryInfo.new(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS)
	m["Walls/airtemplestairup"] = InventoryInfo.new(0, 0, 0, SoundMap.LABYRINTH_STONE_STAIRS)
	return m


func getSettings():
	if Inventory.map == null:
		Inventory.map = createMap()
	return Inventory.map.get(image)


## This method activates the inventory. It is called when the player presses
## the cross button in front of this inventory. (abstract)
func activate(labyrinth):
	pass


## Sets the settings for the inventory textures (scale, y position and
## z offset). (abstract)
func setSettings():
	pass


## Parses the given string tokenizer and creates an inventory accordingly.
## It places that inventory at the correct place in the given graph and gets
## the status for the inventory from the database.
static func createInventory(t, map, labName):
	var command: String = t.nextToken()
	var commandName: String = J.split(command, "--")[0]
	var address: int = J.parseInt(t.nextToken())
	var dbName: String = Organizer.convert(labName + commandName + str(address))
	var status: int = Database.getStatusFor(dbName)
	var n = map.getNode(address)
	var dir: int = J.parseInt(t.nextToken())
	dir = Values.getCounterAngle(dir)
	var token: String = t.nextToken()
	var image: String = t.nextToken()
	var inv = null
	if command == "chest":
		var con: String = t.nextToken()
		var contentType: int = J.parseInt(con)
		var contentName: String = t.nextToken()
		var contentSize: int = t.countTokens()
		var info: Array = J.array(contentSize, null)
		for i in contentSize:
			info[i] = t.nextToken()
		inv = Chest.new(n, dir, J.parseInt(token), image,
				contentType, contentName, info, status)
	elif command == "riddle":
		var name: String = t.nextToken()
		var riddleClass: String = t.nextToken()
		var hinders: Array = getHinders(t, map)
		inv = Riddle.new(n, dir, name, image, status, riddleClass, hinders)
	elif command == "floorButton":
		var hinders: Array = getHinders(t, map)
		inv = FloorButton.new(n, dir, J.parseInt(token), image, status, hinders)
	elif command == "button":
		var hinders: Array = getHinders(t, map)
		inv = InventoryButton.new(n, dir, J.parseInt(token), image, status, hinders)
	elif command == "iceButton":
		var sound: String = t.nextToken().replace("_", " ")
		var hinders: Array = getHinders(t, map)
		inv = IceButton.new(n, dir, J.parseInt(token), image, status, hinders, sound)
	elif command == "aegisComboButton":
		var imageNr: int = J.parseInt(t.nextToken())
		var nr: int = J.parseInt(t.nextToken())
		var buttons: Array = J.array(nr, null)
		for i in buttons.size():
			var name: String = Organizer.convert(t.nextToken())
			buttons[i] = map.getInventory(name)
		var openDoor = null
		if t.hasMoreTokens():
			var doorToOpen: String = Organizer.convert(t.nextToken())
			openDoor = map.getInventory(doorToOpen)
		var combo := AegisComboButton.new(
				n, dir, J.parseInt(token), image, status, buttons, openDoor, imageNr)
		inv = combo
	elif command == "iceComboButton":
		var imageNr: int = J.parseInt(t.nextToken())
		var sound: String = t.nextToken().replace("_", " ")
		var nr: int = J.parseInt(t.nextToken())
		var buttons: Array = J.array(nr, null)
		for i in buttons.size():
			var name: String = Organizer.convert(t.nextToken())
			buttons[i] = map.getInventory(name)
		var openDoor = null
		if t.hasMoreTokens():
			var doorToOpen: String = Organizer.convert(t.nextToken())
			openDoor = map.getInventory(doorToOpen)
		var combo := IceComboButton.new(
				n, dir, J.parseInt(token), image, status,
				buttons, openDoor, imageNr, sound)
		inv = combo
	elif command.begins_with("door"):
		# token is used as openroad
		# image is used as nextPlace
		var d := InventoryDoor.new(n, dir, token, image, status, t)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("triggerDoor"):
		# token is used as openroad
		# image is used as nextPlace
		var d := TriggerDoor.new(n, dir, token, image, status, t)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("ladderDoor"):
		LadderDoor.goingUp = J.parseBoolean(t.nextToken())
		var next: String = t.nextToken()
		inv = LadderDoor.new(n, dir, token, image, status, t, next)
	elif command == "ifDoor":
		var d := IfDoor.new(n, dir, token, image, status, t)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("hinderDoor"):
		var nextPlace: String = t.nextToken()
		var vStart: int = -1
		if t.hasMoreTokens():
			vStart = J.parseInt(t.nextToken())
		var d = HinderDoor.new(
				n, dir, J.parseInt(token), image,
				status, nextPlace, vStart)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("hiddenHinderDoor"):
		var nextPlace: String = t.nextToken()
		var vStart: int = -1
		if t.hasMoreTokens():
			vStart = J.parseInt(t.nextToken())
		var d = HiddenHinderDoor.new(
				n, dir, J.parseInt(token), image,
				status, nextPlace, vStart)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("riddleDoor"):
		var nextPlace: String = t.nextToken()
		var vStart: int = -1
		if t.hasMoreTokens():
			vStart = J.parseInt(t.nextToken())
		var d = RiddleDoor.new(
				n, dir, J.parseInt(token), image,
				status, nextPlace, vStart)
		if command.contains("--"):
			d.setGoingUp(J.split(command, "--")[1] == "up")
		inv = d
	elif command.begins_with("addDoor"):
		var nextPlace: String = t.nextToken()
		var openStatus: int = J.parseInt(t.nextToken())
		var vStart: int = -1
		if t.hasMoreTokens():
			vStart = J.parseInt(t.nextToken())
		var add := AdditiveHinderDoor.new(
				n, dir, J.parseInt(token), image,
				status, nextPlace, vStart)
		add.setOpenStatus(openStatus)
		if command.contains("--"):
			add.setGoingUp(J.split(command, "--")[1] == "up")
		inv = add
	elif command == "bomb":
		inv = MissionBomb.new(n, dir, 1, image, status, t)
	elif command == "villager":
		inv = InventoryVillager.new(n, dir, 1, image, status, t)
	elif command == "simpleRiddle":
		inv = SimpleRiddle.new(n, dir, 1, image, status, t)
	elif command == "missionChest":
		inv = MissionChest.new(n, dir, 2, image, status, t)
	elif command == "boss":
		dbName = Organizer.convert(image)
		inv = InventoryBoss.new(n, image)
	elif command == "save":
		inv = InventorySave.new(n, dir)
	if inv != null:
		inv.setDatabaseName(dbName)
		inv.checkHaveBeen()
	else:
		push_error("The inventory " + dbName + " is null! exiting...")
		GameCore.exitGame()
		return null
	n.setInventory(inv)
	return inv


static func getHinders(t, map):
	var hinders: Array = J.array(t.countTokens(), null)
	var i := 0
	while t.hasMoreTokens():
		var name: String = Organizer.convert(t.nextToken())
		hinders[i] = map.getInventory(name)
		if hinders[i] == null:
			hinders[i] = DummyDoor.new(name)
		i += 1
	return hinders


func updateStatus():
	status = Database.getStatusFor(dataBaseName)
	if status == -1:
		status = 0
		Database.addStatus(dataBaseName, status)


func arrive(labyrinth):
	pass # Override for effect


## Java overloads setHaveBeen() and setHaveBeen(String lastNodesName); the
## String version of the base class just calls setHaveBeen().
func setHaveBeen(lastNodesName = null):
	_setHaveBeen()


## Java: the no-argument setHaveBeen() of this class (never overridden).
func _setHaveBeen() -> void:
	Database.addStatus(dataBaseName + "havebeenin", 1)
	haveBeenIn = true


func checkHaveBeen():
	haveBeenIn = Database.getStatusFor(dataBaseName + "havebeenin") == 1


func hasBeenIn():
	return haveBeenIn


func isDirectedTowards(dir):
	return false


func isPassable(dir):
	return false


func isPassableOnThis(dir):
	return false


func getMapImage():
	return null


func shouldDrawWhenOnlySeen():
	return false


func drawTopLayer(g):
	pass


func drawInMap(g, x, y, angle):
	var s = getMapImage()
	if s != null:
		var gt = ImageHandler.getTexture(s)
		var tex = gt.getTexture() if gt != null else null
		if tex != null:
			var gl = g.getGL()
			gl.glPushMatrix()
			gl.glTranslatef(x, y, 0)
			gl.glRotatef(-angle, 0, 0, 1)
			Utils3D.draw3D(g.getGL(), tex, 0, 0, 0, 0.1)
			gl.glPopMatrix()


func compareTo(i):
	return 1 if (1 if i.useMaterial() else 0) <= (1 if useMaterial() else 0) else -1


func useMaterial():
	return false


class InventoryInfo extends RefCounted:
	var height = 0.0
	var zOffset = 0.0
	var scale = 0.0
	var soundEffect = ""

	func _init(height = null, zOffset = null, scale = null, soundEffect = null) -> void:
		self.height = float(height)
		self.zOffset = float(zOffset)
		self.scale = float(scale)
		self.soundEffect = soundEffect

	func getHeightOffset():
		return height

	func getZOffset():
		return zOffset

	func getScale():
		return scale

	func getSoundEffect():
		return soundEffect

	func hasSoundEffect():
		return soundEffect != null
