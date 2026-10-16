class_name ChameleonStrike
extends Card
## Port of cards.offense.ChameleonStrike.
##
## Attacks using the element opposite the enemy's element (the element
## bonus is applied by Card.actuallAttack, which checks for this class).

static var SHORT_INFO = [
	"Attack using the element", "opposite the enemy's element"]
var lastAttacker = 0


func use(target, attacker):
	return attack(target, attacker)


func createAttackPercent():
	return STANDARD_ATTACK_HIGH


func createTextInfo():
	return [
		"As the chameleon changes appearance after environment, this card changes",
		"its element depending on target. It can swiftly turn into flames or frosty",
		"ice, blow a gale or shake the ground. Their strenght is turned to weakness."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Attacks with the element opposite the enemy's element")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	BattleCard.playBattleSound(s, 800)


func getAnimation(info):
	var attacker = info.getAttacker()
	if attacker != null:
		lastAttacker = attacker.getIndex()
	return ChameleonStrike.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())

	var cutSize: float = 0.0
	var particleSize: float = 0.0
	match info.getLevel():
		1:
			cutSize = 0.5
			particleSize = 0.1
		2:
			cutSize = 0.7
			particleSize = 0.2
		3:
			cutSize = 0.9
			particleSize = 0.3
	settings.setVector(AnimSettings.TARGET, Vector3f.new(cutSize, cutSize, -6.0))
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(-cutSize, -cutSize, -6.0))
	psp.add(ParticleSystem.new(settings), 800)

	var def = AnimationSettingsFactory.getDefault()
	def.getVector(AnimSettings.SOURCE).z = 0.0
	def.setValue(AnimSettings.SIZE, particleSize)
	def.setValue(AnimSettings.SPEED, 15.0)
	def.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, -14.0))
	def.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0))
	var period: float = 0.225 * 3
	var radius: float = 0.25

	settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DESTROYED))

	settings = AnimationSettingsFactory.getCircleWave(def, FIRE_ELEMENT, 0.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.006)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.006)
	Card.setSourceTargetVectorToLength(14.0, settings)

	settings.setValue(AnimSettings.EMITTER_TYPE, float(ParticleSystem.INTERPOLATING_EMITTER_TYPE))
	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(0.0, 0.001, 0.0))
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.12)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.03)
	settings.setValue(AnimSettings.NR_PARTICLES, 600.0)

	var wave := CircularWave.new(period, radius * 3, 0.0, false, true, -6.0)
	settings.setValue(AnimSettings.COLOR, float(FIRE_ELEMENT))
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.ROUND))
	psp.add(ParticleSystem.new(settings), 0)

	wave = CircularWave.new(period, radius * 2.5, PI / 2, false, true, -6.0)
	settings.setValue(AnimSettings.COLOR, float(EARTH_ELEMENT))
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.ROUND))
	psp.add(ParticleSystem.new(settings), 0)

	wave = CircularWave.new(period, radius * 2, PI, false, true, -6.0)
	settings.setValue(AnimSettings.COLOR, float(WIND_ELEMENT))
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.ROUND))
	psp.add(ParticleSystem.new(settings), 0)

	wave = CircularWave.new(period, radius * 1.5, 3 * PI / 2.0, false, true, -6.0)
	settings.setValue(AnimSettings.COLOR, float(ICE_ELEMENT))
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.ROUND))
	psp.add(ParticleSystem.new(settings), 0)
	return psp
