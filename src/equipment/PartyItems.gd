class_name PartyItems
extends RefCounted
## Port of equipment.PartyItems: the shared assets of the party (gold, the
## main deck, items, steps and battles).

var mainDeck = Deck.new(null)
var items: Items = Items.new()
var gold: int = 0
var steps: int = 0
var battles: int = 0


## Constructs a new backpack with the given initial amount of gold.
func _init(g = null) -> void:
	if g != null:
		gold = g


func addGold(p_gold):
	gold += p_gold


func getGold():
	return gold


## Sets the main deck (the deck every party member can access via the menu).
func setMainDeck(d):
	mainDeck = d


func getMainDeck():
	return mainDeck


## Adds the given card to the main deck.
func addCard(c):
	mainDeck.addCard(c)


func getSteps():
	return steps


func setSteps(step):
	steps = step


## Takes one step. The counter is incremented.
func takeStep():
	steps += 1


func getBattles():
	return battles


func setBattles(b):
	battles = b


## The battle counter is incremented.
func incrementBattle():
	battles += 1


## Java overloads: addItem(String name, int number) and addItem(Item item).
func addItem(name, number = null):
	if number == null and name is Items.Item:
		items.add(name)
	else:
		items.add(Organizer.convertKeepCase(name), number)


func addItems(p_items):
	for key in p_items:
		var val: int = p_items[key]
		addItem(key, val)


func take(name, number):
	items.take(name, number)


## Gets the item with the given index from the list.
func getItem(i):
	return items.getItem(i)


## Gets the number of items in the list.
func itemSize():
	return items.getSize()


func hasItem(string):
	for i in items.getSize():
		if items.getItem(i).getName() == string:
			return true
	return false
