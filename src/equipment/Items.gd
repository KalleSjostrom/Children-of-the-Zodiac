class_name Items
extends RefCounted
## Port of equipment.Items: a list of items. Used by the main menu.

var items: Array = []


## Java overloads: add(String name, int number) and add(Item item).
## Inserts an item in the list. If an item with the same name already
## exists, the number is added to the existing item.
func add(name, number = null):
	if number == null and name is Item:
		var item: Item = name
		var oldItem = getItem(item.name)
		if oldItem == null:
			items.append(item)
		else:
			oldItem.number += item.number
		return
	var it = getItem(name)
	if it == null:
		items.append(Item.new(name, number))
	else:
		it.number += number


func take(name, number):
	var item: Item
	var i := 0
	while i < items.size():
		item = items[i]
		if name == item.name:
			if item.number >= 1:
				item.number -= number
			if item.number <= 0:
				items.remove_at(i)
		i += 1


## Subtracts one from the number of the item with the given name. If the
## number equals one it is removed. Returns the new number.
func reduceNumber(name):
	var number: int = 0
	var item: Item = null
	var i := 0
	while i < items.size():
		item = items[i]
		if name == item.name:
			if item.number > 1:
				item.reduceNr()
				number = item.number
			else:
				items.remove_at(i)
				number = item.number
		i += 1
	return number


## Java overloads: getItem(int i) (protected) and getItem(String name)
## (private).
func getItem(i):
	if i is String:
		for k in items.size():
			if i == items[k].name:
				return items[k]
		return null
	return items[i]


func getSize():
	return items.size()


## Information about an item.
class Item extends RefCounted:
	var name: String = ""
	var number: int = 0

	## Constructs a new item with the given name and number.
	func _init(name = null, Nr = null) -> void:
		if name != null:
			self.name = name
		if Nr != null:
			number = Nr

	func getName():
		return name

	## Gets the number of items that can be used.
	func getNr():
		return number

	## Uses an item: subtracts one from the number.
	func reduceNr():
		number -= 1
