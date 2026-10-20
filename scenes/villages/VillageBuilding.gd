class_name VillageBuilding
extends Resource
## A building of a village that a door leads to (a "building" line of a .vil
## file): a store, inn, church or house, with its keeper and greeting. Doors
## name it by store_name. VillageScene.load_into turns it into the info map
## of VillageLoader.buildingInfo.

## The name doors use for this building (the building's key).
@export var store_name := ""
## Background image of the store screen (res/Store/).
@export var background := ""
## Image of the keeper (res/Store/), or "_" for none.
@export var keeper := ""
## The keeper's name.
@export var keeper_name := ""
## First line of the keeper's greeting.
@export var first_line := ""
## Second line of the keeper's greeting.
@export var second_line := ""
## Music of the building.
@export var music := ""
