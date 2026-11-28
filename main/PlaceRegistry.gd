class_name PlaceRegistry
extends RefCounted
## The places of maps/Main/main.bank (phase 4.3; docs/ARCHITECTURE.md section
## 17): read once at start into typed places. The game asks it what a place
## name leads to (resolve, info_for). Decision 5 keeps the .bank file as the
## data: nothing is generated from it.
##
## A place's key is its name as the game compares names: lower case, "_" as a
## space (key_of: Values.convert). Three prefixes name a node of a
## world map instead of a place of their own; they lead to the world's place
## with that node as its "startNode":
##   land<node>             the world map whose index has the node
##                          (LandscapeLoader.checkPlace,
##                          resources/world_map/place_index.tres)
##   land::<music>::<node>  the same, and the world map's music for its next
##                          start (Landscape.setInfo: normal, continue, night)
##   air<node>              the airship's world ("airworld"; any key that
##                          begins with "air", "airworld" itself too)
##
## The parsed places never change. What the game changes while it runs is an
## overlay of info keys that every later lookup of the place applies:
## "startNode", written by every lookup through a prefix (a mere check too:
## the music check of a fade out, a battle's, the console's goto), so a world
## map entered by its own name starts at the node the last lookup left; and
## "nextPlace" (update_next_place_for: a mission's door, an IfDoor's first
## use). Loading a game undoes neither. This is what the Organizer did by
## writing into main.bank's shared dictionaries (plan 9.3).

## The file, under Values.MainMap.
const BANK := "main.bank"
## The airship's world.
const AIR_WORLD := "airworld"


## One "place" line of main.bank.
class Place:
	extends RefCounted
	## The name as lookups compare it (PlaceRegistry.key_of).
	var key: String
	## The name as written.
	var name: String
	## The mode the place starts (Values.TITLE, VILLAGE, LABYRINTH, ...).
	var mode: int
	## The music ("" if the line has none).
	var music: String
	## The labyrinth's .map file, a village's or a cutscene's folder ("" if
	## none).
	var map: String
	## The place a cutscene leads to as main.bank has it ("" if none; the
	## game may change it: PlaceRegistry.update_next_place_for).
	var next_place: String
	## Every key="value" of the line as the legacy parse reads it (the `var`s
	## substituted), read-only: what the legacy modes get (info_of).
	var fields: Dictionary


	func _init(p_key: String, p_fields: Dictionary) -> void:
		key = p_key
		fields = p_fields
		fields.make_read_only()
		name = str(fields.get("name", ""))
		# The legacy parse of the format: the Organizer read the mode so.
		mode = J.parseInt(fields.get("mode"))
		music = str(fields["music"]) if fields.has("music") else ""
		map = str(fields["map"]) if fields.has("map") else ""
		next_place = str(fields["nextPlace"]) if fields.has("nextPlace") else ""


## Reads main.bank exactly as the legacy loader did (the game's tokenizer and
## Parser: quoted values, `var` substitutions, "#" comments).
class _BankReader:
	extends AbstractMapLoader
	## key -> the line's fields, in the file's order (a later line with the
	## same key replaces the earlier one's fields at its place).
	var lines := {}
	var variables := {}


	func executeCommand(command: String, tok: StringTokenizer) -> void:
		var argument: Array
		var key: String
		var value
		if command == "place":
			var name = null
			var info := {}
			while tok.hasMoreTokens():
				argument = Parser.getArgument(tok.nextToken())
				key = argument[0]
				if String(argument[1]).begins_with("\""):
					value = Parser.getText(tok, argument[1])[0]
				else:
					value = variables.get(argument[1])
				if key == "name":
					name = value
				info[key] = value
			if name == null:
				Parser.error(str(lineCount) + " No Name Found!")
			lines[PlaceRegistry.key_of(name)] = info
		elif command == "var":
			argument = Parser.getArgument(tok.nextToken())
			key = argument[0]
			value = Parser.getText(tok, argument[1])[0]
			variables[key] = value
		else:
			Parser.error(str(lineCount) + " Unknown command " + command)


var _places: Dictionary = {} # key -> Place, in main.bank's order
## The run-time changes: key -> {info key: value}, each in the order first
## written (so an info lists its keys as the shared dictionary did).
var _overlay: Dictionary = {}


## Reads main.bank (once, at start).
func read() -> void:
	var reader := _BankReader.new()
	reader.parseFile(Values.MainMap, BANK)
	for key: String in reader.lines:
		_places[key] = Place.new(key, reader.lines[key])


## The key of a place name: lower case, "_" as a space.
static func key_of(place_name: String) -> String:
	return Values.convert(place_name)


## The place with this name, without the prefixes and their changes, or null.
func get_place(place_name: String) -> Place:
	return _places.get(key_of(place_name))


## Every place, in main.bank's order.
func all() -> Array[Place]:
	var out: Array[Place] = []
	out.assign(_places.values())
	return out


## The place a name leads to (a prefix leads to its world's place), or null.
## A prefix's node becomes the world's "startNode", and land::'s music the
## world map's (Landscape.setInfo): also when the caller only checks the name.
func resolve(place_name: Variant) -> Place:
	if place_name == null:
		return null
	var key := key_of(str(place_name))
	if key.begins_with("land"):
		var node: String
		if key.begins_with("land::"):
			# The legacy format's split (Java's String.split).
			var parts: Array = J.split(key, "::")
			node = parts[2]
			Landscape.setInfo(parts[1])
		else:
			node = key.replace("land", "")
		var world = LandscapeLoader.checkPlace(node)
		# An unknown node failed in the Organizer too (a null world into a
		# typed variable; the Appendix of plan 9.3 has it as a quirk).
		assert(world != null, "PlaceRegistry: no world map has the node '%s'" % node)
		if world == null:
			return null
		_change(String(world), "startNode", node)
		return _places.get(world)
	if key.begins_with("air"):
		_change(AIR_WORLD, "startNode", key.replace("air", ""))
		return _places.get(AIR_WORLD)
	return _places.get(key)


## The info a legacy mode gets for a place (GameMode.init): a new dictionary
## of its fields with the run-time changes applied.
func info_of(place: Place) -> Dictionary:
	var info: Dictionary = place.fields.duplicate()
	var changes: Dictionary = _overlay.get(place.key, {})
	for k: String in changes:
		info[k] = changes[k]
	return info


## What the Organizer's getInformationFor returned: the info of the place the
## name leads to (resolve, with its changes), or null.
func info_for(place_name: Variant) -> Variant:
	var place := resolve(place_name)
	return null if place == null else info_of(place)


## Changes the place a cutscene leads to, for the rest of the session.
func update_next_place_for(place_name: String, next: String) -> void:
	var key := key_of(place_name)
	assert(_places.has(key), "PlaceRegistry: no place '%s'" % place_name)
	if _places.has(key):
		_change(key, "nextPlace", next)


func _change(key: String, info_key: String, value: String) -> void:
	if not _overlay.has(key):
		_overlay[key] = {}
	_overlay[key][info_key] = value
