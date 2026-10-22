class_name Earth
extends Magic
## Port of cards.magic.Earth: the basic magic with earth attribute.

static var SHORT_INFO = ["Earth magic", ""]
static var SOUNDS = [SoundMap.MAGICS_EARTH, SoundMap.MAGICS_EARTH, SoundMap.MAGICS_EARTH]
static var DELAYS = [295, 200, 200]


func setElement():
	element = EARTH_ELEMENT


func createTextInfo():
	return [
			"The element of the earth itself, the gaia, which all the living walk",
			"upon is containied in this card. The earth will crush all enemies",
			"under its immense weight, putting out their last breath of air."]


func getVeryShortInfo():
	return SHORT_INFO


func use(target, attacker):
	return rolled_hit(target, attacker)


## The hit is rolled first: a missed enemy does not shake (COTZ-014).
func getAnimation(info):
	info.setLevel(getLevel())
	return Earth.getStaticAnimation(info, roll_hits(info))


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


## hit: false when every enemy attacked is missed (no shake).
static func getStaticAnimation(info, hit = true):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	if info.isOnEnemy():
		settings.setVector(AnimSettings.SOURCE, Vector3f.new((J.random() - 0.5) * 2, 3.0, -5.9))
		settings.setBoolean(AnimSettings.DESTROY_ENEMY_SHAKE, hit)
	else:
		var source = info.getEnemy().getTempSource()
		# Enemy attacks may name the card without a source vector (goblin,
		# Stonecrusher: "c=m+Earth"). Java passed the null on and the
		# particle systems failed to build (COTZ-009); use the default the
		# other magic cards use.
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0) if source == null else source)
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -1.0, -3.0))
		settings.setBoolean(AnimSettings.DESTROY_CAMERA_SHAKE, true)
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.05)
	settings.setValue(AnimSettings.SPEED, 4)
	settings.setValue(AnimSettings.SIZE, 0.2)
	settings.setValue(AnimSettings.LIFE_MULTIPLIER, 0.1)
	settings.setValue(AnimSettings.NR_PARTICLES, 400)
	settings.setValue(AnimSettings.PARTICLE_MASS, 0.1)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.15, 0.15, 0.15))
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 14)
	# RESET VELOCITY ON IMPACT
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.1, 0.0))
	settings.setValue(AnimSettings.COLOR, EARTH_ELEMENT)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.NR_TEXTURES, 3)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JONAS_ROUND)
	settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JONAS_ROUND_2)
	settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.ROUND)
	settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.SHARP)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0)
	settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, true)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 1)
	Card.setTargetSourceVectorToLength(4.0, settings)
	var distance: float = 1.0

	var lvl: int = info.getLevel()
	# Java switch with fall through (case 3 -> 2 -> 1).
	if lvl == 3:
		settings.getVector(AnimSettings.SOURCE).x -= distance
		psp.add(ParticleSystem.new(settings), 200)
		settings.getVector(AnimSettings.SOURCE).x += distance
	if lvl == 3 or lvl == 2:
		settings.getVector(AnimSettings.SOURCE).x += distance
		psp.add(ParticleSystem.new(settings), 100)
		settings.getVector(AnimSettings.SOURCE).x -= distance
	if lvl == 3 or lvl == 2 or lvl == 1:
		psp.add(ParticleSystem.new(settings), 0)

	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)
	settings.setValue(AnimSettings.SIZE, 0.15)
	settings.setValue(AnimSettings.NR_PARTICLES, 100)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.275, 0.275, 0.275))

	if lvl == 3:
		settings.getVector(AnimSettings.SOURCE).x -= distance
		psp.add(ParticleSystem.new(settings, info.getEnemy()), 200)
		settings.getVector(AnimSettings.SOURCE).x += distance
	if lvl == 3 or lvl == 2:
		settings.getVector(AnimSettings.SOURCE).x += distance
		psp.add(ParticleSystem.new(settings, info.getEnemy()), 100)
		settings.getVector(AnimSettings.SOURCE).x -= distance
	if lvl == 3 or lvl == 2 or lvl == 1:
		psp.add(ParticleSystem.new(settings, info.getEnemy()), 0)
	return psp
