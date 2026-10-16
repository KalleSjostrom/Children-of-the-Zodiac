class_name Enemy3D
extends Creature3D
## Port of battle.character.Enemy3D: an enemy in the 3D battle. It shows
## information about life and progress (unknown values as "???").

var showLife: bool = false
var showName: bool = false
var info = null


func _init(side = null, e = null) -> void:
	super(side, e)
	info = ["", ""]
	setInfo()
	showLife = info[Bestiary.Stats.HP] != "???"
	showName = info[Bestiary.Stats.NAME] != "???"


func setInfo():
	var stats = Bestiary.getBestiary().getStats(creature)
	var stat: Array = stats.getInfo()
	info[0] = stat[Bestiary.Stats.NAME]
	info[1] = stat[Bestiary.Stats.HP]


func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if isVisible():
		super.draw(g)


## Draws the name and life of the enemy on the info image.
func drawInfo(g):
	showLife = info[Bestiary.Stats.HP] != "???"
	showName = info[Bestiary.Stats.NAME] != "???"

	var name: String = creature.getName() if showName else "???"

	GraphicHelp.drawStringWithBlackFrame(g, name, 5, 30, 34, JColor.WHITE, 3, Values.BOLD)
	GraphicHelp.drawStringWithBlackFrame(g, "Elem:", 5, 70, 26, JColor.WHITE, 3, Values.BOLD)

	var life: String = creature.getLife() if showLife else "???"
	var hp: float = creature.getAttribute(Creature.HP)
	var max_: float = creature.getAttribute(Creature.MAX_HP)
	var c: Color
	if showLife and (hp / max_ < 0.2):
		c = JColor.red
	else:
		c = JColor.white
	GraphicHelp.drawStringWithBlackFrame(g, life, 5, 100, 30, c, 3, Values.BOLD)


## Not used for enemies.
func initCreature(g):
	pass


## Not used: the enemy image is not shown here.
func drawImage(g):
	pass
