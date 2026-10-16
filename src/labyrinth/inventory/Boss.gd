class_name InventoryBoss
extends Inventory
## Port of labyrinth.inventory.Boss.
##
## This class is the inventory boss. If the player walks on the node where
## this inventory resides, the Database class is called to find out whether
## the boss is alive or not. This inventory does not have any textures but is
## only a launcher for the boss battle.

var name = ""


## Creates a new boss inventory which will reside on the given node.
func _init(node = null, name = null) -> void:
	super(node, 1, 0, null, 0)
	self.name = name


## Enters the boss battle in the given labyrinth if the boss is alive.
func enterBossBattle(labyrinth):
	if isAlive():
		labyrinth.enterBattle(true, name)


func setSettings():
	pass # Not used by boss


func activate(labyrinth):
	pass # Not used by Boss


func initDraw(gl):
	pass # Not used by Boss


## Java's draw(Graphics) does nothing: the drawings of the boss are taken
## care of by the battle. draw(gl, dir) is the inherited Inventory version.
func draw(gl, dir = null):
	if dir != null:
		super.draw(gl, dir)


## Checks in the database if the boss is alive or not.
func isAlive():
	status = Database.getStatusFor(dataBaseName)
	return status == 1


func getMapImage():
	return null


func drawInMap(g, x, y, angle):
	pass


func isPassable(dir):
	return true


func isPassableOnThis(dir):
	return true


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return false
