class_name AttackInfo
extends RefCounted
## Port of battle.enemy.AttackInfo: information about an enemy attack
## (name, power, type, element, frames of the animation, effects ...).
## Port note: the field isAll is isAll_ (the method isAll() keeps its name).

static var NOP = null
var name = ""
var power: float = 0.0
var probability: float = 0.0
var type: int = 0
var element: int = 0
var target: int = 0
var isAll_: bool = false
var frames = null
var effects = []


static func _static_init() -> void:
	NOP = AttackInfo.new("nop", 0.0, Slot.NO_TYPE, Card.NO_ELEMENT,
			false, 0.0, null, CharacterRow.NO_TARGET)


func _init(name = null, power = null, type = null, element = null, isAll = null, probability = null, frames = null, target = null) -> void:
	effects = []
	self.name = name
	self.power = float(power) if power != null else 0.0
	self.type = int(type) if type != null else 0
	self.element = int(element) if element != null else 0
	self.isAll_ = bool(isAll) if isAll != null else false
	self.probability = float(probability) if probability != null else 0.0
	self.frames = frames
	self.target = int(target) if target != null else 0


func getFrames():
	return frames


func getType():
	return type


func getName():
	return name


func getPower():
	return power


func getElement():
	return element


func getTarget():
	return target


func isAll():
	return isAll_


func getProbability():
	return probability


func getEffects():
	return effects


# Setters #

func setElement(element):
	self.element = element


func setType(type):
	self.type = type


func setName(name):
	self.name = name


func setPower(power):
	self.power = power


func addFrame(f):
	frames.append(f)


func setOnAll(onAll):
	self.isAll_ = onAll


func setTarget(target):
	self.target = target


func setProbability(probability):
	self.probability = probability


func addEffects(effects):
	self.effects.append_array(effects)


func _to_string():
	return ("[AttackInfo=(" +
			"Name=" + str(name) +
			" Power=" + str(power) +
			" Type=" + str(type) +
			" Element=" + str(element) +
			" Is all=" + str(isAll_) +
			" Probability=" + str(probability) +
			" Frames=" + str(frames) +
			" Effects=" + str(effects) +
			" Target=" + str(target) + ")]")


class AttackInfos extends RefCounted:
	var infos = []
	var useThisInfoOnlyOnce: bool = false

	func _init(onlyOnce = null) -> void:
		infos = []
		useThisInfoOnlyOnce = bool(onlyOnce) if onlyOnce != null else false

	func add(info):
		infos.append(info)

	func getRandom():
		var index: int = Values.rand.nextInt(infos.size())
		return infos[index]

	func shouldUseThisInfoOnlyOnce():
		return useThisInfoOnlyOnce


class Frame extends RefCounted:
	var frame: int = 0
	var animTime: int = 0
	var usePreloaded_: bool = false
	var defaultFrame: bool = false
	var shake: bool = false
	var cameraShake: bool = false
	var hitFrame: bool = false
	var soundEffect = null
	var cardInfo = null
	var riseSpeed: float = 0.0
	var shouldExit_: bool = false
	var shouldHit_: bool = false
	var shouldClearSystems_: bool = false
	var shouldPreload_: bool = false
	var startMusic = null
	var characterMode_: int = 0

	func _init(frame = null, animTime = null, shouldHit = null, usePreloaded = null, defaultFrame = null, shake = null, cameraShake = null, soundEffect = null, cardInfo = null, riseSpeed = null, shouldExit = null, shouldClearSystems = null, startMusic = null, shouldPreload = null, characterMode = null) -> void:
		self.frame = int(frame) if frame != null else 0
		self.animTime = int(animTime) if animTime != null else 0
		self.shouldHit_ = bool(shouldHit) if shouldHit != null else false
		self.usePreloaded_ = bool(usePreloaded) if usePreloaded != null else false
		self.defaultFrame = bool(defaultFrame) if defaultFrame != null else false
		self.shake = bool(shake) if shake != null else false
		self.cameraShake = bool(cameraShake) if cameraShake != null else false
		self.soundEffect = soundEffect
		self.cardInfo = cardInfo
		self.riseSpeed = float(riseSpeed) if riseSpeed != null else 0.0
		self.shouldExit_ = bool(shouldExit) if shouldExit != null else false
		self.shouldClearSystems_ = bool(shouldClearSystems) if shouldClearSystems != null else false
		self.startMusic = startMusic
		self.shouldPreload_ = bool(shouldPreload) if shouldPreload != null else false
		self.characterMode_ = int(characterMode) if characterMode != null else 0

	func getFrame():
		return frame

	func getAnimTime():
		return animTime

	func isHistFrame():
		return hitFrame

	func usePreloaded():
		return usePreloaded_

	func isDefault():
		return defaultFrame

	func shouldShake():
		return shake

	func shouldCameraShake():
		return cameraShake

	func getSoundEffect():
		return soundEffect

	func playSoundEffect():
		return soundEffect != null

	func shouldSwitchMusic():
		return startMusic != null

	func _to_string():
		return ("(f=" + str(frame) + ",a" + str(animTime) + ",p" + str(usePreloaded_)
				+ ",d" + str(defaultFrame) + ",s" + str(shake) + ",se" + str(soundEffect) + ")")

	func getCardSystem(enemy, target):
		var c = cardInfo.getCard()
		enemy.setTempSource(cardInfo.getSource())
		var onEnemy: bool = ClassRegistry.getClassName(c).contains("support")
		var info = BattleAnimation.AnimationInfo.new()
		info.setTarget(target)
		info.setEnemy(enemy)
		info.setOnEnemy(onEnemy)
		return c.getAnimation(info)

	func hasCard():
		return cardInfo != null

	func getCard():
		return cardInfo.getCard()

	func getRiseSpeed():
		return riseSpeed

	func shouldRise():
		return riseSpeed != 0

	func shouldExit():
		return shouldExit_

	func shouldHit():
		return shouldHit_

	func shouldClearSystems():
		return shouldClearSystems_

	func getMusic():
		return startMusic

	func shouldPreload():
		return shouldPreload_

	func characterMode():
		return characterMode_
