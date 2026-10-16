class_name EnemyLoader
extends AbstractMapLoader
## Port of factories.EnemyLoader: loads one enemy from its .enemy file
## (Values.EnemyMaps + lower case name + ".enemy").

var attributes = J.array(14, 0.0)
var attackSpec: bool = false
var enemy = null
var info = EnemyInfo.new()
var script_ = null
var parser = Parser.new()
var name = ""
var diesound = null
var attackInfo = null
var triggers = {}
var items = {}
var cardPreferences = null
var startFrame: int = 0
var bd = BossDialog.new()
var current = BossesDialog.new()


func _init(p_name = null) -> void:
	parseFile(p_name)
	enemy.setInfo(info)
	enemy.setDbName(Organizer.convert(p_name))


## Java: protected void parseFile(String filename).
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.EnemyMaps, path.to_lower() + ".enemy")
	else:
		super.parseFile(path, filename)


func executeCommand(command: String, tokenizer: StringTokenizer):
	var t: StringTokenizer = tokenizer
	if attackSpec:
		if command == "}":
			attackSpec = false
			info.setAttack(attackInfo)
		else:
			executeAttackSpec(command, t)
	else:
		executeStringCommand(command, t)


func executeAttackSpec(command, t):
	while true:
		var args: Array = Parser.getArgument(command)
		command = args[0]
		var val: String = args[1]
		if command == "type":
			var type: int
			if val.to_lower() == "off":
				type = Slot.ATTACK
			elif val.to_lower() == "mag":
				type = Slot.MAGIC
			elif val.to_lower() == "sup":
				type = Slot.SUPPORT
			elif val.to_lower() == "no":
				type = Slot.NO_TYPE
			else:
				type = J.parseInt(val)
			attackInfo.setType(type)
		elif command == "name":
			attackInfo.setName(Organizer.convertKeepCase(val))
		elif command == "power":
			attackInfo.setPower(J.parseFloat(val))
		elif command == "anim":
			var frameNames: Array = J.split(val, "--")
			for s0 in frameNames:
				var s: String = s0
				s = s.replace("(", "")
				s = s.replace(")", "")
				var frame: int = 0
				var animTime: int = 100
				var characterMode: int = 0
				var usePreloaded: bool = false
				var defaultFrame: bool = false
				var shake: bool = false
				var cameraShake: bool = false
				var shouldHit: bool = false
				var shouldExit: bool = false
				var shouldClearSystems: bool = false
				var shouldPreload: bool = false
				var temps: Array = J.split(s, ",")
				var soundEffect = null
				var startMusic = null
				var cinfo = null
				var riseSpeed: float = 0.0
				for temp in temps:
					if temp != "":
						args = Parser.getArgument(temp)
						command = args[0]
						val = args[1]
						if command.begins_with("f"):
							frame = J.parseInt(val)
						elif command.begins_with("a"):
							animTime = J.parseInt(val)
						elif command.begins_with("h"):
							shouldHit = J.parseBoolean(val)
						elif command.begins_with("u"):
							usePreloaded = J.parseBoolean(val)
						elif command.begins_with("d"):
							defaultFrame = J.parseBoolean(val)
						elif command.begins_with("se"):
							soundEffect = val
						elif command.begins_with("sm"):
							startMusic = Organizer.convertKeepCase(val)
						elif command.begins_with("s"):
							shake = J.parseBoolean(val)
						elif command.begins_with("cs"):
							cameraShake = J.parseBoolean(val)
						elif command.begins_with("exit"):
							shouldExit = J.parseBoolean(val)
						elif command.begins_with("r"):
							riseSpeed = J.parseFloat(val)
						elif command.begins_with("cps"):
							shouldClearSystems = J.parseBoolean(val)
						elif command.begins_with("pl"):
							shouldPreload = J.parseBoolean(val)
						elif command.begins_with("cm"):
							characterMode = J.parseInt(val)
						elif command.begins_with("c"):
							# m+Earth:.9;.8;-6
							var c: String = ""
							var source = null
							if val.contains(":"): # Has source vector
								var cardTemp: Array = J.split(val, ":")
								c = cardTemp[0]
								var v: String = cardTemp[1]
								var va: Array = J.split(v, ";")
								source = Vector3f.new(
										J.parseFloat(va[0]),
										J.parseFloat(va[1]),
										J.parseFloat(va[2]))
							else:
								c = val
							var ca: Array = J.split(c, "\\+")
							var card = null
							if ca.size() == 2:
								card = Card.createCard(Card.getPrefix(ca[0]) + ca[1], 1, false)
							else:
								var level: int = J.parseInt(ca[1])
								card = Card.createCard(Card.getPrefix(ca[0]) + ca[2], level, false)
							cinfo = CardInfo.new(card, source)
				var f = AttackInfo.Frame.new(
						frame, animTime, shouldHit, usePreloaded,
						defaultFrame, shake, cameraShake, soundEffect,
						cinfo, riseSpeed, shouldExit, shouldClearSystems,
						startMusic, shouldPreload, characterMode)
				attackInfo.addFrame(f)
		elif command == "onAll":
			attackInfo.setOnAll(J.parseBoolean(val))
		elif command == "target":
			var target: int
			if val == "rand":
				target = CharacterRow.RANDOM
			else:
				target = J.parseInt(val)
			attackInfo.setTarget(target)
		elif command == "element":
			var element: int
			if val == "neutral":
				element = Card.NO_ELEMENT
			elif val == "fire":
				element = Card.FIRE_ELEMENT
			elif val == "ice":
				element = Card.ICE_ELEMENT
			elif val == "earth":
				element = Card.EARTH_ELEMENT
			elif val == "wind":
				element = Card.WIND_ELEMENT
			else:
				element = J.parseInt(val)
			attackInfo.setElement(element)
		elif command == "probability" or command == "p":
			attackInfo.setProbability(J.parseFloat(val))
		elif command == "effect":
			attackInfo.addEffects(EnemyAttackEffect.createEffects(val))
		command = null
		if t.hasMoreTokens():
			command = t.nextToken()
		if command == null:
			break


func executeStringCommand(command, t):
	if command == "name":
		name = Organizer.convertKeepCase(t.nextToken())
	elif command == "defense":
		attributes[Creature.DEFENSE] = float(J.parseInt(t.nextToken()))
	elif command == "trigger":
		var args: Array = Parser.getArgument(t.nextToken())
		triggers[args[0]] = J.parseInt(args[1])
	elif command == "item":
		var args: Array = Parser.getArgument(t.nextToken())
		items[args[0]] = J.parseInt(args[1])
	elif command == "diesound":
		diesound = Organizer.convertKeepCase(t.nextToken())
	elif command == "startFrame":
		startFrame = J.parseInt(t.nextToken())
	elif command == "magicDefense":
		attributes[Creature.MAGIC_DEFENSE] = float(J.parseInt(t.nextToken()))
	elif command == "agility":
		attributes[Creature.AGILITY] = float(J.parseInt(t.nextToken()))
	elif command == "evade":
		attributes[Creature.EVADE] = float(J.parseInt(t.nextToken()))
	elif command == "hit":
		attributes[Creature.HIT] = float(J.parseInt(t.nextToken()))
	elif command == "attack":
		attributes[Creature.ATTACK] = float(J.parseInt(t.nextToken()))
	elif command == "support":
		attributes[Creature.SUPPORT_ATTACK] = float(J.parseInt(t.nextToken()))
	elif command == "magic":
		attributes[Creature.MAGIC_ATTACK] = float(J.parseInt(t.nextToken()))
	elif command == "hp":
		attributes[Creature.MAX_HP] = float(J.parseInt(t.nextToken()))
		attributes[Creature.HP] = attributes[Creature.MAX_HP]
	elif command == "element":
		attributes[Creature.ELEMENT] = float(J.parseInt(t.nextToken()))
	elif command == "gold":
		attributes[Creature.GOLD_SPOILS] = float(J.parseInt(t.nextToken()))
	elif command == "experience":
		attributes[Creature.EXPERIENCE_SPOILS] = float(J.parseInt(t.nextToken()))
	elif command == "criticalChance":
		attributes[Creature.CRITICAL_HIT_PRECENT] = float(J.parseInt(t.nextToken()))
	elif command == "image":
		var image: String = t.nextToken()
		var nrIms: int = J.parseInt(t.nextToken())
		var reuseindices: Array = []
		while t.hasMoreTokens():
			var a: int = J.parseInt(t.nextToken())
			var b: int = J.parseInt(t.nextToken())
			reuseindices = add(reuseindices, a, b)
		enemy = Enemy.new(name, attributes,
				Enemy.loadImages(image, nrIms, reuseindices))
		cardPreferences = {}
		enemy.setTriggers(triggers)
		enemy.setItems(items)
		enemy.setDieSound(diesound)
		enemy.setStartFrame(startFrame)
	elif command == "cardPreference":
		while t.hasMoreTokens():
			var card: String = t.nextToken()
			var percent: int = J.parseInt(t.nextToken())
			cardPreferences[card] = percent
		enemy.setCardPreferences(cardPreferences)
	elif command == "hitFrame":
		pass
	elif command == "frameTimes":
		pass
	elif command == "armor":
		var armorDefense: int = J.parseInt(t.nextToken())
		var armorMagicDefense: int = J.parseInt(t.nextToken())
		enemy.setArmor(armorDefense, armorMagicDefense)
	elif command == "preferences":
		var attPer: int = J.parseInt(t.nextToken())
		var magPer: int = 0
		if t.hasMoreTokens():
			magPer = J.parseInt(t.nextToken()) + attPer
		enemy.setPreferences(attPer, magPer)
	elif command == "scale":
		var scale: float = J.parseFloat(t.nextToken())
		scale /= 1000.0
		info.set_(EnemyInfo.SCALE, scale)
	elif command == "height":
		info.set_(EnemyInfo.HEIGHT, J.parseFloat(t.nextToken()))
	elif command == "middle":
		info.set_(EnemyInfo.MIDDLE_POINT, J.parseFloat(t.nextToken()))
	elif command == "depth":
		info.set_(EnemyInfo.DEPTH, J.parseFloat(t.nextToken()))
	elif command == "xoffset":
		info.set_(EnemyInfo.X_OFFSET, J.parseFloat(t.nextToken()))
	elif command == "attackSpec":
		command = t.nextToken()
		attackInfo = AttackInfo.new(
				"Attack", 1.0, Slot.ATTACK, Card.NO_ELEMENT, false,
				1.0, [], CharacterRow.RANDOM)
		if command == "{":
			attackSpec = true
		else:
			executeAttackSpec(command, t)
			info.setAttack(attackInfo)
	elif command == "run":
		var args: Array = Parser.getArgument(t.nextToken())
		command = args[0]
		var value: String = args[1]
		if command == "script":
			script_ = BossScript.new(value, info)
			enemy.setScript(script_)
	else:
		if command.begins_with("dialog"):
			current.add(parser.getDialogSequence(t))
		else:
			var args: Array = Parser.getArgument(command)
			command = args[0]
			if command == "end":
				var time: String = args[1]
				var i: int
				if time == "begin":
					i = BossDialog.BEGINNING
				elif time == "endEnemyDead":
					i = BossDialog.ENEMY_DEAD
					enemy.setDialog(bd)
				elif time == "endPartyDead":
					i = BossDialog.PARTY_DEAD
					enemy.setDialog(bd)
				else:
					i = J.parseInt(time)
				bd.set_(i, current)
				current = BossesDialog.new()
			elif command == "nextPlace":
				var n: Array = Parser.getText(t, args[1])
				enemy.setNextPlace(n[0])


func getEnemy():
	return enemy


## Appends a pair of reuse indices (destination, source) to a new copy of
## the given array.
func add(reuseindices, a, b):
	var array: Array = J.array(reuseindices.size() + 2, 0)
	for i in range(reuseindices.size()):
		array[i] = reuseindices[i]
	array[reuseindices.size()] = a
	array[reuseindices.size() + 1] = b
	return array
