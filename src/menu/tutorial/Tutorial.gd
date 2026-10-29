class_name Tutorial
extends RefCounted
## Port of menu.tutorial.Tutorial: a tutorial (book of chapters) loaded from a
## .tut file, shown once (status kept in the Database).

## Bridge (phase 3 step B): the UI node of the top layer.
const TUTORIAL_VIEW := "res://scenes/ui/Tutorial.tscn"
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
		if not Main.is_legacy("tutorials"):
			show_page(g)
			return
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

## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): drawTopLayer's
## drawing without the drawing: the same state changes (fadeOldSchoolColor's
## colours and bind, the paper's bind, the font sizes, the text colours,
## startText and finishText; Row.place_rows), and the UI node
## scenes/ui/Tutorial.tscn shows the page where it would have been drawn
## (Graphics.show_ui). --legacy=tutorials keeps the drawing.
func show_page(g):
	var mat = g.canvas_material()
	g.glColor4f(1, 1, 1, .5)
	var dimTint: Color = g.getCurrentColor()
	g.skip_image(Graphics.fadeImage)
	g.glColor4f(1, 1, 1, 1)
	var x: int = int(IMAGE_X) + AbstractPage.xoffset
	g.push()
	var paperTint: Color = g.getCurrentColor()
	var paper = g.skip_image(AbstractPage.images[15])
	g.pop()
	g.setFontSize(34)
	Graphics.setTextColor(0)
	var l = chapter.getCurrentPage()
	g.startText(1.0, 0.0)
	var titleColor: Color = Graphics.text_color(g.text_alpha())
	g.finishText()
	g.setFontSize(26)
	var bold: bool = Graphics.font_bold()
	var rows: Dictionary = Row.place_rows(g, l)
	var view = g.show_ui(TUTORIAL_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_page(dimTint, paper.getGodotTexture() if paper != null else null,
				Vector2i(x - 35, IMAGE_HEIGHT), paperTint, Dialog._text(title), titleColor,
				rows.words, rows.icons, mat, bold)
