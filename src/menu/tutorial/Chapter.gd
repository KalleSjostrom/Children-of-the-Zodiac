class_name Chapter
extends RefCounted
## Port of menu.tutorial.Chapter: the pages (lists of rows) of a tutorial.

const LAST_PAGE = -10
var chapter: Array = []
var index: int = -1
var yPos: int = 0
var xPos: int = 0
var soundPage: int = -2
var sound = null

func _init(x = null, y = null) -> void:
	chapter = []
	xPos = x
	yPos = y

func next():
	index += 1
	if index == soundPage:
		SoundPlayer.playSound(sound)
	return index >= chapter.size()

func setSound(page, sound):
	if page == LAST_PAGE:
		soundPage = chapter.size() - 1
	else:
		soundPage = page
	self.sound = sound

func getCurrentPage():
	return chapter[index]

func getPage(index):
	return chapter[index]

func addRow(newPage, xoffset, yoffset, string, c, icon):
	var page: Array
	var idx: int = 0
	if newPage:
		page = []
		chapter.append(page)
	else:
		idx = chapter.size() - 1
		page = chapter[idx]
	var x: int = int(xPos) + xoffset
	var y: int = yPos + yoffset
	page.append(Row.new(string, x, y + 40 * page.size(), c, icon))
