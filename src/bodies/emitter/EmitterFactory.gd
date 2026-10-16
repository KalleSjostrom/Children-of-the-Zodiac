class_name EmitterFactory
extends RefCounted
## Port of bodies.emitter.EmitterFactory.

const REGULAR = 0
const MASTER_SLAVE = 1
const LINE = 0
const BOX = 1
const CIRCLE = 2
const IMAGE = 3


static func createEmitter(eSettings, sSettings):
	var shape = getShape(sSettings)
	var emitter = null
	var kind: int = int(eSettings.getValue(EmitterSettings.KIND))
	match kind:
		REGULAR:
			emitter = BodiesEmitter.new(eSettings, shape)
		MASTER_SLAVE:
			emitter = MasterSlaveEmitter.new(eSettings, shape)
	return emitter


static func getShape(settings):
	var shape = null
	var kind: int = int(settings.getValue(ShapeSettings.KIND))
	match kind:
		LINE:
			shape = LineShape.new(settings)
		BOX:
			shape = BoxShape.new(settings)
		CIRCLE:
			shape = CircleShape.new(settings)
		IMAGE:
			shape = ImageShape.new(settings)
	return shape
