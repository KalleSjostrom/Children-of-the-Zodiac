class_name DifficultyLevel
extends Resource
## One difficulty level (resources/difficulty/*.tres): its name and the
## balancing multipliers the game applies while it is selected (see
## Difficulty). 1.0 everywhere is the original game.

## The name shown in the menus.
@export var display_name := ""
## One line about the level, shown under the choice.
@export_multiline var description := ""
## Experience the party gets from battles.
@export_range(0.0, 10.0, 0.05, "or_greater") var experience_multiplier := 1.0
## Damage enemies deal to the party (attacks and offensive magic; not their
## healing or other support).
@export_range(0.0, 10.0, 0.05, "or_greater") var enemy_damage_multiplier := 1.0
## Damage the party deals to enemies (attacks and offensive magic; not
## healing or other support).
@export_range(0.0, 10.0, 0.05, "or_greater") var ally_damage_multiplier := 1.0
