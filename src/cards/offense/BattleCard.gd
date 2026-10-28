class_name BattleCard
extends Card
## Port of cards.offense.BattleCard.
##
## The battle card is the most basic of physical attacking cards. It has
## nothing special about it.

static var SHORT_INFO = ["Attack", ""]
static var SOUNDS = [
	SoundMap.BATTLE_ATTACK_KIN, SoundMap.BATTLE_ATTACK_CELIS,
	SoundMap.BATTLE_ATTACK_BOREALIS, SoundMap.BATTLE_ATTACK_ZALZI
]
var lastAttacker = 0


## Calculates the effect of a "Battle"-card used by the attacker on the
## given target. This card will damage the target.
func use(target, attacker):
	return attack(target, attacker)


func createAttackPercent():
	return STANDARD_ATTACK


func createTextInfo():
	return [
		"This card is often found in every adventurers deck. It is",
		"the fundamental part of any deck because of its cheapness",
		"and versatilely of not beeing bound by an element."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	playBattleSound(s, i[0])


static func playBattleSound(effect, delay):
	if delay > 0:
		# Java: a thread sleeping delay ms before playing the sound.
		Scheduler.after(delay, func(): SoundPlayer.playSoundWithRandom(effect, 2))
	else:
		SoundPlayer.playSoundWithRandom(effect, 2)


func getAnimation(info):
	var attacker = info.getAttacker()
	if attacker != null:
		lastAttacker = attacker.getIndex()
	return BattleCard.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	psp.add(ParticleSystem.new(getDefaultBattleCardSettings(info.getLevel())), 0)
	if info.getAttacker().getName() == "Zalzi":
		psp.add(ParticleSystem.new(getDefaultBattleCardSettings(info.getLevel())), 280)
	return psp


static func getDefaultBattleCardSettings(level):
	var settings = AnimationSettingsFactory.getDefaultSword()
	var source = settings.getVector(AnimSettings.SOURCE)
	var targetvec = settings.getVector(AnimSettings.TARGET)

	var size: float = 0.0
	match level:
		1:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.024)
			size = 0.5
		2:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.022)
			size = 0.6
		3:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.02)
			size = 0.7
		_:
			pass

	source.x = (ParticleSystem.rand.nextDouble() - 0.5) * size
	source.y = ParticleSystem.rand.nextDouble()
	source.y -= 1
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.08)

	targetvec.x = source.x + (size if source.x <= 0 else -size)
	targetvec.y = source.y + (size if source.y <= 0 else -size)
	var st = source.subtract(targetvec)
	var l: float = st.length() / 2.0
	source.addLocal(st.mult(l))
	targetvec.subtractLocal(st.mult(l))
	var sb := SwordBackground.new(source, targetvec)
	settings.setSystemDrawable(AnimSettings.SYSTEM_DRAWABLE, sb)
	return settings
