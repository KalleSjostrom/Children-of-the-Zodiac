class_name BattleTest
extends GameMode
## Port of battleTest.BattleTest: a game mode that starts a test battle.

var manager = null
var inited: bool = false
var name: String = Organizer.convert("Empyrian_Temple--The_Zodiac")


func _init() -> void:
	inited = false
	manager = BattleManager.new()
	var info = {}
	info["music"] = "battle"
	info["boss"] = "false"
	info["name"] = name
	manager.init(info)


## Java init(HashMap info): loads the textures of the enemy group.
func init(info, lab = null, hinders = null):
	var ef = EnemyFactory.getEnemyFactory()
	name = Organizer.convert(name)
	var eg = ef.getEnemyGroup(name)
	eg.loadTextures()
	logicLoading = false


func update(elapsedTime: float):
	manager.update(elapsedTime)
	if manager.getBattleMode() == BattleManager.EXIT:
		var list = Load.getCharacters()
		for i in range(list.size()):
			list[i].resetBattleStats()
		manager.killOggPlayer()
		super.exitWithoutFading(Values.BATTLE_TEST)
		nextPlace = ""
	super.update(elapsedTime)


func draw(g, alpha = null):
	g.loadIdentity()
	g.setColor(1)
	g.setLightEnabled(false)

	if not inited:
		manager.initDraw(g)
		inited = true
	manager.draw(g)
