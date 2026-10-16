class_name Flame
extends Card
## Port of cards.magic.Flame: a flame animation card (fire element). Its
## battle methods are unfinished stubs in the original (use returns null).

static var SHORT_INFO = ["Fire magic", ""]


func getSimpleName():
	return "Fire"


func setElement():
	element = FIRE_ELEMENT


func createTextInfo():
	return [
			"The firey ball of magic will rush toward the target and disintegrate",
			"upon impact. The hot flames created with supreme magic will melt",
			"even the coldes of barriers leaving but a puddle of water."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return []


func getSoundEffectDelay():
	return []


func getAnimation(info):
	return Flame.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.4)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.4)
	settings.setValue(AnimSettings.SIZE, 0.2)
	settings.setValue(AnimSettings.SPEED, 0)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(5.0, 1.0, 0.0).multLocal(0.001))
	var depth: float = -6.0
	var enemy = info.getEnemy()
	if enemy != null:
		depth = enemy.getInfo().get_(EnemyInfo.DEPTH)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, depth))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, depth - 0.5))
	settings.setValue(AnimSettings.NR_PARTICLES, 3000)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.FLAME_EMITTER_TYPE)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
	settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT)
	psp.add(0, FlameParticleSystem.new(settings, enemy), 0)
	return psp


func use(target, attacker):
	# TODO (original): Auto-generated method stub
	return null


func createAttackPercent():
	# TODO (original): Auto-generated method stub
	return null


func createShortInfo():
	# TODO (original): Auto-generated method stub
	pass
