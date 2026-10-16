class_name CrushingSaber
extends Card
## Port of cards.offense.CrushingSaber.
##
## A battle card with one addition: the chance of an armor break exists.
## The hit is calculated in getAnimation (useBefore) so the animation can
## show whether the armor was crushed; use() returns that result.

static var SHORT_INFO = ["Attack + chance of", "breaking enemy's armor"]
var lastAttacker = 0
var preCalculatedElement = null
var armorCrush = false


## The crush blow will destroy the target's armor for the rest of the turn
## if the crush is successful.
func use(target, attacker):
	return preCalculatedElement


func useBefore(target, attacker):
	armorCrush = false
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		var fullName := ""
		var simpleName := "crush"
		var ret: int = Card.checkPreferences3(
				target, attacker, null, false, self, fullName, simpleName)
		if ret == Card.IMMUNE:
			he = attack(target, attacker, "Immune!", true)
		elif ret == Card.HIT:
			he = hit(target, attacker)
		elif ret == Card.MISS:
			he = attack(target, attacker, "Failed to crush armor!", true)
	return he


func hit(target, attacker):
	var he = null
	var ans: int = target.crushArmor()
	if ans == Creature.ARMOR_ALREADY_CRUSHED:
		he = attack(target, attacker, "Armor already crushed!", true)
	elif ans == Creature.ARMOR_CRUSHED:
		armorCrush = true
		he = attack(target, attacker, "Armor crushed!", true)
	elif ans == Creature.HAS_NO_ARMOR:
		he = attack(target, attacker, "Has no armor!", true)
	return he


func createAttackPercent():
	return SPECIAL_ATTACK


func createEffectChancePercent():
	return STANDARD_EFFECT_CHANCE


func createTextInfo():
	return [
		"A powerfull blow, strikes down on the target, like the Hammer of",
		"Thor, rendering the targets armor useless for a while. Yet, the",
		"armor will recover due to the magical nature of the crushing saber."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Chance of breaking enemy's armor: " + str(J.round(getEffectChanceToHit() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	BattleCard.playBattleSound(s, 1000)


func getAnimation(info):
	if info.isOnEnemy():
		var attacker = info.getAttacker()
		if attacker != null:
			lastAttacker = attacker.getIndex()
		preCalculatedElement = useBefore(info.getEnemy().getEnemy(), attacker)
	return CrushingSaber.getStaticAnimation(info, armorCrush)


static func getStaticAnimation(info, armorCrush):
	var psp := ParticleSystemPacket.new()
	var settings
	if not info.isOnEnemy():
		settings = AnimationSettingsFactory.getDefaultNoFade()

		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.012)
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.012)
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, 0.0, 0.0))
		settings.setValue(AnimSettings.SIZE, 0.01)
		settings.setValue(AnimSettings.SPEED, 0.4)
		settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
		var depth: float = -6.0
		var enemy = info.getEnemy()
		if enemy != null:
			depth = enemy.getInfo().get_(EnemyInfo.DEPTH)
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, depth))
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, depth - 0.5))
		settings.setVector(AnimSettings.COLLISION_VECTOR, Vector3f.new(-1.9, 1.9, -1.9))

		settings.setValue(AnimSettings.NR_PARTICLES, 5000.0)
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.005)
		settings.setValue(AnimSettings.EMITTER_TYPE, float(ParticleSystem.SHATTER_EMITTER_TYPE))
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100.0)
		settings.setValue(AnimSettings.DESTROY_MODE, float(ParticleValues.PLAIN_DESTROY))

		settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.PIXEL))
		settings.setValue(AnimSettings.COLOR, float(Card.FIRE_ELEMENT))
		settings.setValue(AnimSettings.BLEND_MODE, float(ParticleSystem.BLEND_MODE_NO_BLEND))
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)

		psp.add(0, ParticleSystem.new(settings, enemy), 0)
		return psp

	settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())
	if not armorCrush:
		psp.add(ParticleSystem.new(settings), 0)
	else:
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.04)

		psp.add(ParticleSystem.new(settings), 1000)

		settings = AnimationSettingsFactory.getDefaultNoFade()

		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.012)
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.012)
		settings.setValue(AnimSettings.SIZE, 0.01)
		settings.setValue(AnimSettings.SPEED, 0.4)
		settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
		var depth: float = -6.0
		var enemy = info.getEnemy()
		if enemy != null:
			depth = enemy.getInfo().get_(EnemyInfo.DEPTH)
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, depth))
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, depth - 0.5))
		settings.setVector(AnimSettings.COLLISION_VECTOR, Vector3f.new(-1.9, 1.9, -1.9))

		settings.setValue(AnimSettings.NR_PARTICLES, 5000.0)
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.005)
		settings.setValue(AnimSettings.EMITTER_TYPE, float(ParticleSystem.SHATTER_EMITTER_TYPE))
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100.0)

		settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.PIXEL))
		settings.setValue(AnimSettings.COLOR, float(Card.FIRE_ELEMENT))
		psp.add(0, ShatterParticleSystem.new(settings, enemy), 0)
	return psp
