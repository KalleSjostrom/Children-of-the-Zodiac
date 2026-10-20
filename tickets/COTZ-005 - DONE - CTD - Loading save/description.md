Crash when loading save. This is because it's saved on the First Floor using the always available save. The first floor has no savepoint so it crashes on load. I can see either of these options
1. Support saving anywhere in the labyrinth! This will require 'start' to support any node in the labyrinth.
2. Loading the save would start at the last save point
3. Disallow saving anywhere (as originally intented)

Solution I want: Save revamp (Depends on COTZ-004)
1. Show slot time stamp, year, day, month and time
2. Save functionality based on difficulty:
	- Easy
		a. autosaves after 
			- each battle in a separate (hidden) slot - will require to save from anywhere (number 1. at the start)
			- each scene-change (such as entering/exiting a village, entering a labyrinth, entering the world-map and so on)
		b. still allow manual slots to be saved anywhere
	- Medium
		a. Same as Easy.a
		b. allow manual saves at save-slots in labyrinth but anywhere in the world.
	- Original
		a. allow manual saves at save-slots in labyrinth and anywhere in the world.