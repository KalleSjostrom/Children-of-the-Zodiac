class_name Resurrect
extends SupportCard
## Port of cards.support.Resurrect: resurrects a dead character and cures it.

static var SHORT_INFO = ["Resurrects + cures hp", ""]
static var SOUNDS = [SoundMap.MAGICS_RESURRECT]
static var DELAYS = [0]


func use(target, attacker):
	var mess := ""
	var miss := true
	if target is Character:
		var c = target
		miss = c.isAlive()
		if not miss:
			mess = "Resurrected!"
		c.cureFromDead()
	var he
	if miss:
		he = HitElement.new(self, -1, HitElement.MISS, "")
	else:
		he = cure(attacker, mess)
	return he


func createAttackPercent():
	return RESURRECT_CURE


func createTextInfo():
	return [
		"The power of resurrection lays within grasp. Mighty forces of the",
		"heavens will be called upon to aid the passed friend of the wielder.",
		"Life is returned to those who lost it when battling a powerful foe."]


func createShortInfo():
	setShortInfo("Brings life to the dead")
	setShortInfo("Cure power " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Resurrect.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()

	settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DEAD))
	if not info.isOnEnemy():
		if info.isOnAll():
			var list: Array = Load.getCharacters()
			for i in range(list.size()):
				var c = list[i]
				if not c.isAlive():
					Cure.addTargetToSettings(i, settings)
					Cure.addToSystemPacket(psp, settings)
		else:
			if not Load.getCharacters()[info.getTarget()].isAlive():
				Cure.addTargetToSettings(info.getTarget(), settings)
				Cure.addToSystemPacket(psp, settings)
	else:
		var x: float = -0.4
		var y: float = -0.6
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(x, y, -2.0))
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, y + 2, -2.0))
		var l := Line.new(settings.getVector(AnimSettings.SOURCE), 0.8)
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l)
		Cure.addToSystemPacket(psp, settings)
	return psp
