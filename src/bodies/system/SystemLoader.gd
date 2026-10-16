class_name SystemLoader
extends AbstractMapLoader
## Port of bodies.system.SystemLoader: loads the particle system definitions
## (Values.ParticleSystemsMaps + "particleSystems.info") and builds systems.

const EMITTER_SHAPE = 0
const EMITTER = 1
const PARTICLE = 2
const SYSTEM = 3
var shapeSettings = {}
var emitterSettings = {}
var particleSettings = {}
var systemSettings = {}
var parser = Parser.new()


static func getLoader():
	var loader = SystemLoader.new()
	loader.parseFile("particleSystems")
	return loader


## Java overloads: parseFile(String fileName) (filename == "", the name is in
## path) and the inherited parseFile(String path, String filename).
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.ParticleSystemsMaps, path + ".info")
	else:
		super.parseFile(path, filename)


func buildSystem(name):
	var systems = []

	var settings = systemSettings.get(name)
	var emitName = settings.getString(SystemSettings.EMITTER_NAME)
	var eSettings = emitterSettings.get(emitName)

	var shapeName = eSettings.getString(EmitterSettings.SHAPE_NAME)
	var sSettings = shapeSettings.get(shapeName)

	var emitter = EmitterFactory.createEmitter(eSettings, sSettings)

	var warmUpEmitterName = settings.getString(SystemSettings.WARM_UP_SHAPE_NAME)
	var warmUpShape = null
	if warmUpEmitterName != null:
		var warmUpEmitterSettings = shapeSettings.get(warmUpEmitterName)
		warmUpShape = EmitterFactory.getShape(warmUpEmitterSettings)

	var particleName = settings.getString(SystemSettings.PARTICLE_NAME)
	var pSettings = particleSettings.get(particleName)

	var p = BodiesParticleSystem.new(settings, pSettings, emitter, warmUpShape)
	systems.append(p)
	var s = eSettings.getString(EmitterSettings.SLAVE_NAME)
	if s != null and emitter is MasterSlaveEmitter:
		var slave = getSystem(s, emitter)
		emitter.setSystems(p, slave)
		systems.append(slave)
		var warmUp: int = p.getWarmUp()
		# Java: Values.LOGIC_INTERVAL; one step each (see ParticleSystem.update).
		for i in range(warmUp):
			p.update(Values.ORIGINAL_FRAME_MS)
			slave.update(Values.ORIGINAL_FRAME_MS)
		p.setWarmUp(0)
	return systems


func getSystem(name, emitter):
	var settings = systemSettings.get(name)

	var particleName = settings.getString(SystemSettings.PARTICLE_NAME)
	var pSettings = particleSettings.get(particleName)

	return BodiesParticleSystem.new(settings, pSettings, emitter, null)


func executeCommand(command: String, tokenizer: StringTokenizer):
	var tok = tokenizer
	parser.updateLineCounter(lineCount, lastLine)
	if command == "import":
		var file = Parser.getArgument(tok.nextToken())[1]
		parseFile(Values.ParticleSystemsMaps, file)
		lineCount -= parser.variableSize()
	elif command == "var":
		parser.addVariable(tok)
	elif command == "new":
		var args = Parser.getArgument(tok.nextToken())
		command = args[0]
		var value = args[1]
		if command == "type":
			var type: int = parser.getValue(value)
			match type:
				EMITTER_SHAPE:
					createEmitterShape(tok)
				EMITTER:
					createEmitter(tok)
				PARTICLE:
					createParticle(tok)
				SYSTEM:
					createSystem(tok)
				_:
					Parser.error("Type argument must be either of the static variables: " +
						"EMITTER_SHAPE, EMITTER, PARTICLE or SYSTEM in the class SystemLoader")
		else:
			Parser.error("A new command must start with the type argument!")


func createSystem(tok):
	var settings = SystemSettings.new()
	while tok.hasMoreTokens():
		var args = Parser.getArgument(tok.nextToken())
		var command = args[0]
		var value = args[1]
		if command == "name":
			settings.setName(value)
		elif command == "particle":
			settings.setString(SystemSettings.PARTICLE_NAME, value)
		elif command == "nrParticles":
			settings.setValue(SystemSettings.NR_PARTICLES, parser.getValue(value))
		elif command == "emitter":
			settings.setString(SystemSettings.EMITTER_NAME, value)
		elif command == "texture":
			settings.setString(SystemSettings.TEXTURE, value)
		elif command == "additive":
			settings.setValue(SystemSettings.ADDITIVE, parser.getValue(value))
		elif command == "warmUp":
			settings.setValue(SystemSettings.WARM_UP_LENGTH, parser.getValue(value))
		elif command == "warmUpShape":
			settings.setString(SystemSettings.WARM_UP_SHAPE_NAME, value)
		elif command == "background":
			settings.setString(SystemSettings.BACKGROUND, value)
	systemSettings[settings.getName()] = settings


func createParticle(tok):
	var settings = ParticleSettings.new()
	while tok.hasMoreTokens():
		var args = Parser.getArgument(tok.nextToken())
		var command = args[0]
		var value = args[1]
		if command == "name":
			settings.setName(value)
		elif command == "mass":
			settings.setString(ParticleSettings.MASS, value)
		elif command == "kind":
			settings.setValue(ParticleSettings.KIND, parser.getValue(value))
		elif command == "color":
			settings.setVector(ParticleSettings.COLOR, parser.getFloatPos(value))
		elif command == "size":
			settings.setString(ParticleSettings.SIZE, value)
		elif command == "fade":
			settings.setVector(ParticleSettings.FADE, parser.getFloatPos(value))
		elif command == "settings":
			settings.setString(ParticleSettings.SETTINGS, value)
	particleSettings[settings.getName()] = settings


func createEmitter(tok):
	var settings = EmitterSettings.new()
	while tok.hasMoreTokens():
		var args = Parser.getArgument(tok.nextToken())
		var command = args[0]
		var value = args[1]
		if command == "name":
			settings.setName(value)
		elif command == "kind":
			settings.setValue(EmitterSettings.KIND, parser.getValue(value))
		elif command == "force":
			settings.setVector(EmitterSettings.FORCE, parser.getFloatPos(value))
		elif command == "timeStep":
			settings.setString(EmitterSettings.EMITTANCE_TIME_STEP, value)
		elif command == "useshape":
			settings.setString(EmitterSettings.SHAPE_NAME, value)
		elif command == "slave":
			settings.setString(EmitterSettings.SLAVE_NAME, value)
	emitterSettings[settings.getName()] = settings


func createEmitterShape(tok):
	var settings = ShapeSettings.new()
	while tok.hasMoreTokens():
		var args = Parser.getArgument(tok.nextToken())
		var command = args[0]
		var value = args[1]
		if command == "name":
			settings.setName(value)
		elif command == "kind":
			settings.setValue(ShapeSettings.KIND, parser.getValue(value))
		elif command == "pos":
			settings.setVector(ShapeSettings.POSITION, parser.getPos(value))
		elif command == "point":
			settings.setVector(ShapeSettings.POINTS, parser.getPos(value))
		elif command == "angle":
			settings.setValue(ShapeSettings.ANGLE, parser.getValue(value))
		elif command == "image":
			settings.setString(ShapeSettings.IMAGE, value)
		elif command == "flipX":
			settings.setValue(ShapeSettings.FLIP_HORIZONTALLY, parser.getValue(value))
		elif command == "flipY":
			settings.setValue(ShapeSettings.FLIP_VERTICALLY, parser.getValue(value))
		elif command == "scaleX":
			settings.setValue(ShapeSettings.SCALE_X, parser.getFloat(value))
		elif command == "scaleY":
			settings.setValue(ShapeSettings.SCALE_Y, parser.getFloat(value))
		elif command.begins_with("point"):
			var temp = J.split(command, ":")
			var nr: int = J.parseInt(temp[1])
			settings.setVector(ShapeSettings.POINTS + nr, parser.getPos(value))
	shapeSettings[settings.getName()] = settings


static func getValueFromInterval(s):
	var val: float
	if s == null:
		return 0.0

	if String(s).contains("-"):
		var interval = J.split(s, "-")
		var first: float = J.parseFloat(interval[0])
		var second: float = J.parseFloat(interval[1])
		var max_: float = maxf(first, second)
		var min_: float = minf(first, second)
		val = J.random() * (max_ - min_) + min_
	else:
		val = J.parseFloat(s)
	return val


## Local helper (not in Java): the keys of a Settings object in the order a
## Java HashMap<Integer, ...> iterates them (ascending). Accepts whatever the
## settings port's iterator() returns (Java-style iterator, Array or Dictionary).
static func settingKeys(settings) -> Array:
	var it = settings.iterator()
	var keys: Array = []
	if it is Array:
		keys = it.duplicate()
	elif it is Dictionary:
		keys = it.keys()
	elif it != null:
		while it.hasNext():
			keys.append(it.next())
	keys.sort()
	return keys
