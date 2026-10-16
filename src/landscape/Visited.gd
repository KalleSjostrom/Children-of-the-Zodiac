class_name Visited
extends RefCounted
## Port of landscape.Visited: stores which roads and nodes the player has
## visited in each landscape zone (singleton).

var visitedNodes = {}
var visitedRoads = {}
static var visited = null


func _init() -> void:
	clearVisited()


func clearVisited():
	visitedNodes.clear()
	visitedRoads.clear()
	for i in range(3):
		visitedNodes["world" + str(i) + ".map"] = []
		visitedRoads["world" + str(i) + ".map"] = []


## Gets the object containing the status for the roads and nodes.
static func getVisited():
	if visited == null:
		visited = Visited.new()
	return visited


## Gets the list of visited node names for the given zone.
func getVnodes(zone):
	return visitedNodes.get(zone)


## Gets the list of visited road addresses for the given zone.
func getVroads(zone):
	return visitedRoads.get(zone)


func setVnodes(zone, Vnodes):
	visitedNodes[zone] = Vnodes


func setVroads(zone, roads):
	visitedRoads[zone] = roads
