class_name BossScript
extends AbstractMapLoader
## Port of battle.bosses.BossScript: the attack script of a boss, read from
## Values.EnemyMaps + filename + ".script".

var info = null
var moves = []
var current: int = 0
var loadList = null


func _init(filename = null, info = null) -> void:
	self.info = info
	parseFile(filename)


func getDialog():
	return null


func getMove(lifePercent):
	var ml = moves[current]
	if not ml.inRange(lifePercent):
		current += 1
		current %= moves.size()
		return getMove(lifePercent)
	return ml.next()


## Java override: parseFile(String filename) reads
## Values.EnemyMaps + filename + ".script". With two arguments the
## AbstractMapLoader version is used.
func parseFile(path: String, filename: String = ""):
	if filename == "":
		super.parseFile(Values.EnemyMaps, path + ".script")
	else:
		super.parseFile(path, filename)


func executeCommand(command: String, tokenizer: StringTokenizer):
	var t: StringTokenizer = tokenizer
	if command == "newList":
		var name: String = t.nextToken()
		if name.contains("-"):
			var interval: Array = J.split(name, "-")
			var high: int = J.parseInt(interval[0])
			var low: int = J.parseInt(interval[1])
			loadList = MoveList.new(high, low)
		elif name == "intro":
			loadList = MoveList.new(MoveList.INTRO)
		moves.append(loadList)
	elif command.begins_with("attack"):
		var onlyOnce: bool = command.contains("Single")
		var infos = AttackInfo.AttackInfos.new(onlyOnce)
		while t.hasMoreTokens():
			var attackName: String = Organizer.convertKeepCase(t.nextToken())
			if attackName.begins_with("nop"):
				infos.add(AttackInfo.NOP)
			else:
				infos.add(info.getAttack(attackName))
		loadList.moves.append(infos)


class MoveList extends RefCounted:
	const INTRO = 0
	const LIFE_PERCENT = 1
	const LOW = 1
	var lifeInterval = null
	var moves = null
	var current: int = 0
	var type: int = 0

	## Java overloads: MoveList(int high, int low) and MoveList(int type).
	func _init(high = null, low = null) -> void:
		moves = []
		current = 0
		if low == null:
			self.type = int(high)
		else:
			self.type = LIFE_PERCENT
			lifeInterval = [int(high), int(low)]

	func inRange(hp):
		var inRange_: bool = false
		match type:
			LIFE_PERCENT:
				inRange_ = hp >= lifeInterval[LOW]
			INTRO:
				inRange_ = current < moves.size()
		return inRange_

	func next():
		var ais = moves[current]
		var onlyOnce: bool = ais.shouldUseThisInfoOnlyOnce()
		var a = ais.getRandom()
		if onlyOnce:
			J.removeAt(moves, current)
		else:
			current += 1
		if type == LIFE_PERCENT:
			# Java would throw on an empty list (% 0); keep current at 0 instead.
			if moves.size() > 0:
				current %= moves.size()
			else:
				current = 0
		return a

	func _to_string():
		return str(moves)
