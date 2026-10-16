class_name LevelFactory
extends AbstractFactory
## Port of factories.LevelFactory: reads levels.bank and stores the level
## information of all characters in the Database. Singleton, created lazily
## (Java: static initializer run on first use of the class).

## Java: -Integer.MIN_VALUE, which overflows to Integer.MIN_VALUE.
static var NO_INCREASE = -2147483648
static var levelFactory = null


func _init() -> void:
	parseFile("levels.bank")


## Gets the only LevelFactory object.
static func getLevelFactory():
	if levelFactory == null:
		levelFactory = LevelFactory.new()
	return levelFactory


## Gets the level information (Dictionary attribute -> value) for the level
## nextLevel of the character with the given name and class.
static func getLevelFor(name, nextLevel, currentClass):
	getLevelFactory()
	return Database.getLevelFor(name, nextLevel, currentClass)


func executeCommand(command: String, tokenizer: StringTokenizer):
	var t: StringTokenizer = tokenizer
	var currentName: String = command
	var currentLevel := {}
	var map: Dictionary = Creature.getAttributMap()
	for k in map:
		var key: int = map.get(k)
		currentLevel[key] = NO_INCREASE

	while t.hasMoreTokens():
		var args: Array = Parser.getArgument(t.nextToken())
		var key: int = map.get(args[0])
		currentLevel[key] = J.parseInt(args[1])
	Database.addLevelUpInfo(currentName, currentLevel)


static func toString(name, classLevel, level, info):
	return (str(name) + "=" + str(classLevel) + ":" + str(level)
		+ " hp=" + str(info.get(Creature.MAX_HP))
		+ " attack=" + str(info.get(Creature.ATTACK))
		+ " magic=" + str(info.get(Creature.MAGIC_ATTACK))
		+ " support=" + str(info.get(Creature.SUPPORT_ATTACK))
		+ " defense=" + str(info.get(Creature.DEFENSE))
		+ " magicDefense=" + str(info.get(Creature.MAGIC_DEFENSE))
		+ ("" if info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL) == LevelFactory.NO_INCREASE
			else " expToNext=" + str(info.get(Creature.EXP_LEFT_TO_NEXT_LEVEL)))
		+ ("" if info.get(Creature.DECK_SIZE) == LevelFactory.NO_INCREASE
			else " deckSize=" + str(info.get(Creature.DECK_SIZE))))
