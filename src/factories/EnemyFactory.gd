class_name EnemyFactory
extends AbstractFactory
## Port of factories.EnemyFactory: a bank with all the enemies in the game
## (singleton, created lazily on first use; Java: static initializer).

static var enemyFactory = null
var bank = {}
var enemyBank = {}
var currentName = ""
var currentChance: float = 0.0


func _init() -> void:
	parseFile("enemyBank.bank")


## Gets the only EnemyFactory object.
static func getEnemyFactory():
	if enemyFactory == null:
		enemyFactory = EnemyFactory.new()
	return enemyFactory


## Checks if the enemy group with the given name exists or not.
func doesEnemyGroupExist(name):
	return bank.has(name)


## Gets the enemy group with the specified name.
func getEnemyGroup(name):
	return bank.get(name)


func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "newGroup":
		currentName = Organizer.convertKeepCase(tokenizer.nextToken())
		currentChance = 0.0
		bank[currentName] = EnemyGroup.new()
	elif command == "newEnemy":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var enemy = createEnemy(name)
		enemyBank[name] = enemy
	elif command == "enemy":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var e = enemyBank.get(name)
		var chance: float = J.parseFloat(tokenizer.nextToken())
		currentChance += chance
		var chanceForTwo: float = J.parseFloat(tokenizer.nextToken())
		var chanceForThree: float = J.parseFloat(tokenizer.nextToken())
		var group = bank.get(currentName)
		group.addFrequency(e, [chanceForTwo, chanceForThree])
		group.addChance(currentChance)
		group.addEnemy(e)
	elif command == "dropdata":
		var enemyName: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var e = enemyBank.get(enemyName)
		var itemName: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var item = Items.Item.new(itemName, J.parseInt(tokenizer.nextToken()))
		e.setDropData(item, J.parseFloat(tokenizer.nextToken()))
	elif command == "stats":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var stats: Array = J.array(16, 0)
		for i in range(1, stats.size()):
			stats[i] = J.parseInt(tokenizer.nextToken())
		Bestiary.getBestiary().addEnemy(enemyBank.get(name), stats)
	elif command == "cardPreference":
		var name: String = Organizer.convertKeepCase(tokenizer.nextToken())
		var cardPreferences := {}
		while tokenizer.hasMoreTokens():
			var card: String = tokenizer.nextToken()
			var percent: int = J.parseInt(tokenizer.nextToken())
			cardPreferences[card] = percent
		enemyBank.get(name).setCardPreferences(cardPreferences)


## Creates a new enemy by loading its .enemy file.
func createEnemy(name):
	var enemyLoader = EnemyLoader.new(name)
	return enemyLoader.getEnemy()


## Gets the boss with the given name, loaded anew from its .enemy file for
## each battle. Port fix (COTZ-015): Java returned the bank's enemy, which
## the battle changes (hp, element, boosts, the script's phase and spent
## moves, the dialogs said), so a boss that won faced the party again
## with those after a game over and Continue. The bank's enemy stays for
## the bestiary.
func getBoss(string):
	if not enemyBank.has(string):
		return null
	return createEnemy(string)


## Java test main: loads the start game and draws ten random enemies.
static func main(args):
	Load.setupForTest()
	var map := {}
	var ef = EnemyFactory.getEnemyFactory()
	var eg = ef.getEnemyGroup("Central Pass--Central Part")
	for i in range(10):
		var en = eg.getRandomEnemy()
		if not map.has(en.getName()):
			map[en.getName()] = 0
		var counter: int = map.get(en.getName())
		counter += 1
		map[en.getName()] = counter


## A list with all the enemies in a particular place, with methods for
## getting a random enemy from the group.
class EnemyGroup extends RefCounted:
	var enemies = []
	var chances = []
	var frequency = {}
	var dice = JRandom.new()
	var lastEnemy: int = -1

	func _init() -> void:
		pass

	func addChance(chance):
		chances.append(chance)

	func addFrequency(e, freq):
		frequency[e.getDbName()] = freq

	func addEnemy(enemy):
		enemies.append(enemy)

	## Gets a random enemy (a copy) from this group.
	func getRandomEnemy():
		var rand: float = dice.nextFloat()
		for i in range(chances.size()):
			if chances[i] > rand:
				return enemies[i].copy()
		return enemies[enemies.size() - 1].copy()

	func getFrequency(en):
		return frequency.get(en.getDbName())

	func getEnemies():
		return enemies

	## Loads the textures of the enemies.
	func loadTextures():
		for i in range(enemies.size()):
			var images = enemies[i].getImages()
			for j in range(images.size()):
				ImageHandler.addToCurrentLoadNow(images[j])

	func hasEnemies():
		return enemies.size() > 0
