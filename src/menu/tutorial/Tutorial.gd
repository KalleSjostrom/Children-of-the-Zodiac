class_name Tutorial
extends RefCounted
## Port of menu.tutorial.Tutorial: a tutorial (book of chapters) loaded from a
## .tut file, shown once (status kept in the Database).

const IMAGE_HEIGHT = 260
const IMAGE_X = 240.0
var active: bool = false
var index: int = -1
var chapter = null
var loader = null
var book = {}
var title = null

func _init(name = null, alwaysShow = null) -> void:
	book = {}
	name = name.to_lower()
	var filename: String = name + ".tut"
	var status: int = Database.getStatusFor(filename)

	var exist: bool = status == 1
	if not exist and alwaysShow:
		exist = status == 2
	if exist:
		exist = GameResourceLoader.getResourceLoader().exists(Values.Tutorials + filename)
		if exist:
			loader = ColorTextLoader.new(int(IMAGE_X) + AbstractPage.xoffset, IMAGE_HEIGHT + 100)
			loader.parseFile(filename)
			book = loader.getBook()
			title = loader.getTitle()
			Database.addStatus(filename, 2)
			if status == 1:
				var cc = loader.getCurrentChapter()
				cc.addRow(true, 0, 0, "This information is now available in the menu.", null, null)
				cc.setSound(Chapter.LAST_PAGE, SoundMap.MENU_QUEST_LOG_ENTRY)
	setActive(exist)

func increment():
	index += 1
	chapter = book.get(index)
	return chapter != null

func setActive(active):
	self.active = active
	if active:
		crossedPressed()

func crossedPressed():
	chapter = book.get(index)
	var done: bool = chapter == null
	if not done:
		done = chapter.next()
	if done:
		chapter = null
	return done

func drawTopLayer(g):
	if active and chapter != null:
		g.fadeOldSchoolColor(1, 1, 1, .5)
		var x: int = int(IMAGE_X) + AbstractPage.xoffset
		var y: int = IMAGE_HEIGHT

		g.push()
		g.drawImage(AbstractPage.images[15], x - 35, IMAGE_HEIGHT)
		g.pop()
		g.setFontSize(34)
		Graphics.setTextColor(0)
		var l = chapter.getCurrentPage()
		g.drawSingleCenteredText(title, y + 50, 1.0, 0.0)

		g.setFontSize(26)
		Row.drawRows(g, l)
