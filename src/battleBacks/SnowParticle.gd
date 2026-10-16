class_name BattleBackSnowParticle
extends BattleParticle
## Port of battleBacks.SnowParticle: a snow flake of the battle background.

static var color_ = [1.0, 1.0, 1.0, 1.0]
static var size_ = [0.1, 0.1]


func getSize():
	return size_


func getColor():
	return color_


func shouldResurrect():
	return pos.y < -4.2


func getInitialHeight():
	return rand.nextFloat() * 14 - 7
