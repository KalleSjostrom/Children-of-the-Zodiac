class_name InventorySave
extends Inventory
## Port of labyrinth.inventory.Save: a save point in the labyrinth. Arriving
## at it cures the party and shuffles the decks.
##
## Port note: draw(gl, dir = null) with dir != null is Java's
## Save.draw(Graphics g, int dir) (dir is the player angle; Graph calls it
## for save points). dir == null is the inherited Inventory.draw(Graphics).

var save = null


func _init(n = null, dir = null) -> void:
	super(n, dir, 0, "", 0)


func initDraw(gl):
	save = SaveSystem.new(node.getPos().getX(), node.getPos().getZ())


func activate(labyrinth):
	pass


func arrive(labyrinth):
	labyrinth.drawDialog("Your hp is restored and your deck is shuffled!", "Enter the menu to save the game.")
	SoundPlayer.playSound(SoundMap.LABYRINTH_SAVE_PLACE)
	Load.cureParty(1)
	Load.shuffleAllDecks()


func draw(gl, dir = null):
	if dir == null:
		super.draw(gl)
		return
	var g = gl
	g.setLightEnabled(false)
	save.update()
	save.draw(g, dir)
	g.setLightEnabled(true)


func setSettings():
	scale = BattleValues.CARD_SCALE
	zOff = 1.99


func getMapImage():
	return LabyrinthMap.save[0]


func isPassable(dir):
	return true


func isPassableOnThis(dir):
	return isPassable(dir)


func isDirectedTowards(dir):
	return true


func shouldDrawWhenOnlySeen():
	return false


func useMaterial():
	return true
