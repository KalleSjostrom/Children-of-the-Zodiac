class_name Help
extends RefCounted
## Port of menu.Help. The drawing code is commented out in the Java source,
## so draw() does nothing (faithful).

var settings = null
var x: int = 0
var y: int = 0
var step: int = 0
var iconx: int = 0
var icony: int = 0
var text = null

func setSettings(settings):
	self.settings = settings
	x = settings[0]
	y = settings[1]
	step = settings[2]
	iconx = x - settings[3]
	icony = y - settings[4]

func setText(text):
	self.text = text

func draw(g):
	pass
