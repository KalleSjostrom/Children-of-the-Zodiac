class_name CardStoreFactory
extends AbstractFactory
## Port of factories.CardStoreFactory: all the card stores in the game.
## The bank is created lazily on first use (Java: static initializer).

static var bank = null
var current = ""
var counter: int = 0
var storeStatus: int = 0


func _init() -> void:
	parseFile("cardStores.bank")


static func _getBank():
	if bank == null:
		bank = {}
		CardStoreFactory.new()
	return bank


## Gets the normal cards in the store with the given name.
static func getCardsFor(storeName):
	var b = _getBank()
	var status: int = maxi(Database.getStatusFor(storeName), 0)
	var d = b.get(storeName)
	var newDeck = Deck.new(null)
	var i: int = d.getCurrentDeckSize() - 1
	while i >= 0:
		var c = d.getCard(i)
		if c.getStoreStatus() <= status:
			var cardStatus: int = Database.getStatusFor(c.getDatabaseName())
			if cardStatus == -1:
				newDeck.addCard(c)
		i -= 1
	return newDeck


func executeCommand(command: String, tokenizer: StringTokenizer):
	if command == "store":
		var name: String = tokenizer.nextToken().replace("_", " ")
		bank[name] = Deck.new(null)
		current = name
		counter = 0
	elif command == "status":
		storeStatus = J.parseInt(tokenizer.nextToken())
	elif command == "card":
		var dbName: String = current + str(storeStatus) + str(counter)
		var status: int = Database.getStatusFor(current + str(storeStatus) + str(counter))
		counter += 1
		if status == -1:
			var prefix: String = Card.getPrefix(tokenizer.nextToken())
			var name: String = prefix + tokenizer.nextToken()
			var c = Card.createCard(name, tokenizer)
			c.setDatabaseName(dbName)
			c.setStoreStatus(storeStatus)
			bank[current].addCard(c)
