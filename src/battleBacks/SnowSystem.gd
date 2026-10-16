class_name BattleBackSnowSystem
extends BattleSystem
## Port of battleBacks.SnowSystem: snow falling in the battle background.

static var FORCE = Vector3f.new(0, -0.003, 0)


func getParticle():
	return BattleBackSnowParticle.new()


func getTextureName():
	return "snowparticle.png"


func getNumberOfParticles():
	return 1000


func getForce():
	return FORCE
