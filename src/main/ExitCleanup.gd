class_name ExitCleanup
extends RefCounted
## Port fix: Java's garbage collector freed everything when the game quit.
## Reference counting cannot free script objects that refer to each other (a
## floor's nodes and doors, a battle and its enemies, a cutscene and its time
## line, a menu's nodes), so Godot reported them at exit, with the textures
## they keep: thousands of objects with a game loaded. Main calls release
## when the game quits, after it freed the modes' scenes: every reference
## between the script objects that the scripts' static variables and the
## nodes reach is dropped, so all of them are freed before the renderer shuts
## down. What the game leaves while it runs is released by the classes' own
## port fixes (docs/ARCHITECTURE.md section 8).


## Drops the references that the script objects (RefCounted) reachable from
## the loaded scripts' static variables and from root's nodes hold to other
## objects, arrays, dictionaries and callables. References to nodes stay
## (the tree frees them).
static func release(root: Node) -> void:
	var pending: Array = []
	for c in ProjectSettings.get_global_class_list():
		var path: String = c["path"]
		if not ResourceLoader.has_cached(path):
			continue
		var script: Script = load(path)
		for p in script.get_property_list():
			if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				pending.append(script.get(p["name"]))
	var nodes: Array[Node] = [root]
	while not nodes.is_empty():
		var n: Node = nodes.pop_back()
		nodes.append_array(n.get_children(true))
		pending.append_array(_values(n))
	var objects := {} # instance id -> object
	while not pending.is_empty():
		var v = pending.pop_back()
		match typeof(v):
			TYPE_OBJECT:
				if is_instance_valid(v) and v is RefCounted and not (v is Script) \
						and v.get_script() != null and not objects.has(v.get_instance_id()):
					objects[v.get_instance_id()] = v
					pending.append_array(_values(v))
			TYPE_ARRAY:
				pending.append_array(v)
			TYPE_DICTIONARY:
				pending.append_array(v.keys())
				pending.append_array(v.values())
			TYPE_CALLABLE:
				pending.append(v.get_object())
				pending.append_array(v.get_bound_arguments())
	for o in objects.values():
		_clear(o)


## The values of o's script variables.
static func _values(o: Object) -> Array:
	var out := []
	for p in o.get_property_list():
		if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(o.get(p["name"]))
	return out


static func _clear(o: Object) -> void:
	for p in o.get_property_list():
		if not (p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v = o.get(p["name"])
		match typeof(v):
			TYPE_OBJECT:
				if is_instance_valid(v) and v is RefCounted:
					o.set(p["name"], null)
			TYPE_ARRAY, TYPE_DICTIONARY:
				if not v.is_read_only():
					v.clear()
			TYPE_CALLABLE:
				o.set(p["name"], Callable())
