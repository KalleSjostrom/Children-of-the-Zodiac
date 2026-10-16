class_name Demolish
extends Card
## Port of cards.magic.Demolish: lowers the attack and defense of the target.
## The effect is calculated in getAnimation (useBefore) so the animation can
## show whether it worked; use() then returns the precalculated element.

static var SHORT_INFO = ["Offense & Defense down", ""]
static var SOUNDS = [SoundMap.MAGICS_DEMOLISH, SoundMap.MAGICS_DEMOLISH, SoundMap.MAGICS_DEMOLISH]
static var DELAYS = [825, 0, 0]
var preCalculatedElement = null
var demolished = false


func use(target, attacker):
	return preCalculatedElement


func useBefore(target, attacker):
	demolished = false
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		target.boostAttack(TURNS_TO_BOOST_MANY, -getAttackPercent())
		target.boostDefense(TURNS_TO_BOOST_MANY, -getAttackPercent())
		demolished = true
		he = HitElement.new(self, -1, HitElement.NORMAL, "Off & Def down!")
	return he


func createAttackPercent():
	return STANDARD_BOOST_LOW


func createTextInfo():
	return [
			"Sends away spheres of burning antimatter creating a black hole",
			"of colossal proportions. This will have severe effect on the targets",
			"physical attributes due to the cosmic energy pouring out of the hole."]


func createShortInfo():
	setShortInfo("Lowers enemy's attack and defense with " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	info.setLevel(getLevel())
	preCalculatedElement = useBefore(info.getEnemy().getEnemy(), info.getAttacker())
	return Demolish.getStaticAnimation(info, demolished)


static func getStaticAnimation(info, p_demolished):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	var enemy = info.getEnemy()
	if p_demolished:
		pass # Make enemy smaller
	else:
		enemy = null
		# Don't =)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEMOLISH_EMITTER_TYPE)
	settings.setValue(AnimSettings.SPEED, 6.0)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK)
	var period: float = 1.5
	var amplitude: float = 0.5
	var wave = CircularWave.new(period, amplitude, 0.0, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.NR_PARTICLES, 1)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 1)
	settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, true)
	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(0.0, 0.0, 0.0))
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	settings.getVector(AnimSettings.SOURCE).z = 0.0
	Card.setSourceTargetVectorToLength(6.0, settings)
	var delay: int = 230
	var sizescalar: float = 1.5
	settings.setValue(AnimSettings.SIZE, 0.2 * sizescalar)
	psp.add(SphereParticleSystem.new(settings, enemy), 0)
	settings.setValue(AnimSettings.SIZE, 0.15 * sizescalar)
	psp.add(SphereParticleSystem.new(settings, enemy), delay)
	settings.setValue(AnimSettings.SIZE, 0.12 * sizescalar)
	psp.add(SphereParticleSystem.new(settings, enemy), delay * 2)
	settings.setValue(AnimSettings.SIZE, 0.08 * sizescalar)
	psp.add(SphereParticleSystem.new(settings, enemy), delay * 3)
	if info.getLevel() == 1:
		return psp

	wave = CircularWave.new(period, amplitude, 2 * PI / 3, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.SIZE, 0.2 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), 0)
	settings.setValue(AnimSettings.SIZE, 0.15 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay)
	settings.setValue(AnimSettings.SIZE, 0.12 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay * 2)
	settings.setValue(AnimSettings.SIZE, 0.08 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay * 3)
	if info.getLevel() == 2:
		return psp

	wave = CircularWave.new(period, amplitude, 4 * PI / 3, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	settings.setValue(AnimSettings.SIZE, 0.2 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), 0)
	settings.setValue(AnimSettings.SIZE, 0.15 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay)
	settings.setValue(AnimSettings.SIZE, 0.12 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay * 2)
	settings.setValue(AnimSettings.SIZE, 0.08 * sizescalar)
	psp.add(SphereParticleSystem.new(settings), delay * 3)
	return psp


## Cross like
static func getAlternativeStaticAnimation(nrTarget, target, onEnemy, onAll, enemy):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_MULTIPLE_TIMES)
	settings.setValue(AnimSettings.SIZE, 0.15)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0)
	settings.setValue(AnimSettings.SPEED, 3)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.05, 0.05, 0.05))
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.NR_PARTICLES, 150)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.1)
	var info = ParticleSystem.calcInterpolationInfo(settings)

	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK)
	var wave = UpDownSideWave.new(1.0, 0.2, 0.0, info, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)

	wave = UpDownSideWave.new(1.0, 0.2, 0.0, info, true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)

	wave = UpDownSideWave.new(1.0, 0.2, PI, info, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)

	wave = UpDownSideWave.new(1.0, 0.2, PI, info, true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)
	return psp
