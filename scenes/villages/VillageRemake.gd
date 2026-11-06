class_name VillageRemake
extends RefCounted
## A remake of village places from new art (the village-remake skill,
## .claude/skills/village-remake/SKILL.md): other scenes for the places,
## chosen with --village=<remake>[,<remake>...] or the console's "village".
## With no remake active (the default) the places are their scenes in
## scenes/villages/, and nothing here changes anything.
##
## A remake is a folder res://proto/villages/<remake>/. proto/ is left out of
## the shipping export (export_presets.cfg), so game code reaches a remake
## only through this class, by path:
## * <Place>/<file>.tscn: the place's scenes, named like those in
##   scenes/villages/<Place>/ ("Alares.tscn" the base, "Alares - 0.tscn" a
##   variant). A variant the remake has replaces the default one
##   (VillageScene.path_for); one it lacks stays the default.
## * sequences/<chapter>/<name>.seq: cutscenes rewritten for the remake's
##   positions, read instead of maps/Story/Sequences/<chapter>/<name>.seq
##   (VillageStoryLoader.parseFile).
## * The skill's working files (layout.json, the source picture, reports).
##
## A remake scene's villagers walk as the scene says (ActorView.walk_override)
## and the points other places' doors return to are moved
## (VillageScene.entries_from / entries_to).

const ROOT := "res://proto/villages/"

## The active remakes (folder names under ROOT); the first one that has a
## file wins.
static var active: PackedStringArray = []


## The remakes in ROOT.
static func names() -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(ROOT):
		return PackedStringArray()
	return DirAccess.get_directories_at(ROOT)


## Makes list the active remakes (empty: none). Returns "" or what went wrong
## (an unknown remake, as in an export without proto/); nothing changes then.
## Places take it when they are next loaded.
static func set_active(list: PackedStringArray) -> String:
	var known := names()
	for remake in list:
		if not known.has(remake):
			return "No village remake '%s' here (%s)" % [remake, ", ".join(known) if not known.is_empty() else "none"]
	active = list
	return ""


## The remake's scene for relative ("<Place>/<file>.tscn", as under
## scenes/villages/), or "" when no active remake has it.
static func scene_path(relative: String) -> String:
	for remake in active:
		var path := ROOT + remake + "/" + relative
		if ResourceLoader.exists(path):
			return path
	return ""


## The remake's copy of the cutscene name ("<chapter>/<name>", as
## VillageStory names it, without ".seq"), or "" when no active remake has
## one.
static func sequence_path(name: String) -> String:
	for remake in active:
		var path := ROOT + remake + "/sequences/" + name + ".seq"
		if FileAccess.file_exists(path):
			return path
	return ""
