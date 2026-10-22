class_name Cheater
extends GameMode
## Port of organizer.Cheater: the developer/debug mode (Select + Down, Space +
## Down on the keyboard). It shows a menu of places the player can be
## teleported to: villages, labyrinth entrances (by mark), story sequences
## of every chapter, the world map (on foot and from the air), stores and
## some boss battles. Cross enters a sub menu / goes to the place, circle
## goes back (from the root it switches back to the previous mode).
## If no game has been loaded, the "Start" save is loaded first.
##
## doCheat(cheat) is called by InputKeyBoardManager when a typed cheat
## (Shift+0 ... Enter) is confirmed: "trigger <name> <value>" sets a database
## status, "open" opens all the roads.

var activeNode = null
var shouldGetInfoFromMain_ = true


## Java: init(HashMap info). The given info is ignored.
func init(name, lab = null, hinders = null):
	var info := {}
	info["music"] = null
	initGameMode(info, Values.DETECT_INIT)
	activeNode = MenuNode.new(null, "")
	fadeValue = 1
	fillRoot()
	logicLoading = false


func setNormalMenuValues(n):
	n.setPositions(40, 40)
	n.setDistance(30)
	n.setEnableColor(JColor.RED)


func fillRoot():
	activeNode.insertChild("Villages")
	activeNode.insertChild("Labyrinths - West Continent")
	activeNode.insertChild("Labyrinths - East Continent")
	activeNode.insertChild("Labyrinths - Ice Continent")
	activeNode.insertChild("Stories")
	activeNode.insertChild("Landscape")
	activeNode.insertChild("Landscape From the Air")
	activeNode.insertChild("Buildings")
	# activeNode.insertChild("Battle Test")
	setNormalMenuValues(activeNode)
	fillStory()
	fillVillages()
	fillLabyrinths()
	fillLandscape(activeNode.getChild("Landscape"))
	fillLandscape(activeNode.getChild("Landscape From the Air"))
	fillStore()


func fillStory():
	var n = activeNode.getChild("Stories")
	fillChapter1(n.insertChild("Prolog"))
	fillChapter2(n.insertChild("Chapter one - Running Away From Home"))
	fillChapter3(n.insertChild("Chapter two - Zazo, the Home of the Miners"))
	fillChapter4(n.insertChild("Chapter three - The Son Returs"))
	fillChapter5(n.insertChild("Chapter four - A Wind of Change"))
	fillChapter6(n.insertChild("Chapter five - Soaring Through the Sky"))
	fillChapter7(n.insertChild("Chapter six - The End Draws Near"))
	fillChapter8(n.insertChild("Epilog"))
	setNormalMenuValues(n)


func fillChapter1(n):
	n.insertChild("Prolog")
	setNormalMenuValues(n)


func fillChapter2(n):
	n.insertChild("Celis Memory - Having Fun")
	n.insertChild("Celis Memory - Ana's Reaction")
	n.insertChild("Celis Memory - Someone's Comming")
	n.insertChild("Celis Memory - Arrival at the New Home")

	n.insertChild("Running Away From Home - Part 1")
	n.insertChild("Home of Celisnode1")
	n.insertChild("Alaresnode1")
	n.insertChild("Talking to Farmer John")
	n.insertChild("Meeting a Crazy Man")
	n.insertChild("Someone's Calling")
	n.insertChild("The Senate of Pensara")
	n.insertChild("The Revelation of Elmer")
	n.insertChild("A Permission From Uri")
	n.insertChild("Encounter With an Ally")
	setNormalMenuValues(n)


func fillChapter3(n):
	n.insertChild("Meanwhile in Zazo")
	n.insertChild("Zazonode1")
	n.insertChild("Zazonode2")
	n.insertChild("After a Hard Days Work")
	n.insertChild("Menthu is Disappointed")
	n.insertChild("Meeting with Farl of Zazo")
	n.insertChild("The Farl Story")
	n.insertChild("Meeting with Farl of Zazo2")
	setNormalMenuValues(n)


func fillChapter4(n):
	n.insertChild("On the Boat to Pensara")
	n.insertChild("A Call From the Gods")
	n.insertChild("Arrival at the Port Town of Parasne")
	n.insertChild("The Mentor of Menthu")
	n.insertChild("Crossroadnode1")
	n.insertChild("Fire Cavern--Hall of Fire-mark0node1")
	n.insertChild("Meanwhile - Teo is Plotting With Vincent")
	n.insertChild("Crossroadnode2")
	n.insertChild("Meeting Vincent af Kinstone")
	n.insertChild("Menthu is Pleased")
	n.insertChild("Berca Desert--South West-mark0node1")
	n.insertChild("The Prison Cell - Celis Speaks Up")
	setNormalMenuValues(n)


func fillChapter5(n):
	n.insertChild("Bercanode1")
	n.insertChild("Meeting With the Rebels")
	n.insertChild("Zalzi Speaks of Her Concerns")
	n.insertChild("Emerge From The Sewers")
	n.insertChild("Kin is Meeting With Vincent")
	n.insertChild("Kin Gets Freed")
	setNormalMenuValues(n)


func fillChapter6(n):
	n.insertChild("Bercanode2")
	n.insertChild("Seeing the Elder of Berca")
	n.insertChild("Meanwhile - Menthu Kills Teo")
	n.insertChild("Vincent Tries to Cool Down the War")
	n.insertChild("Serphia Awakens-Part 1")
	n.insertChild("Serphia Awakens-Part 2")
	n.insertChild("Getting the Crystal of Levitation")
	n.insertChild("Dellnanode1")
	n.insertChild("Dellnanode2")
	n.insertChild("The Entering of Zazo")
	n.insertChild("Asking Farl of Zazo")
	n.insertChild("Reencounter With an Ally")
	setNormalMenuValues(n)


func fillChapter7(n):
	n.insertChild("Elder of Dellna Saves the Day")
	n.insertChild("Celis Wakes Up")
	n.insertChild("A Visit to the Childhood Home - Part 1")
	n.insertChild("Celis Memory - The Killing")
	n.insertChild("Showing the Path to the Gods")
	n.insertChild("Talking to Menthu")
	setNormalMenuValues(n)


func fillChapter8(n):
	n.insertChild("Ending - Part 1.1")
	n.insertChild("Ending - Part 1.2")
	n.insertChild("Ending - Part 1.3")
	n.insertChild("Ending - Part 2.1")
	n.insertChild("Ending - Part 2.2")
	n.insertChild("Ending - Part 2.3")
	n.insertChild("Ending - Part 2.4")
	n.insertChild("Ending - Part 2.5")
	n.insertChild("Ending - Part 2.6")
	n.insertChild("Ending - Part 2.7")
	n.insertChild("Ending - Part 2.8")
	n.insertChild("Ending - Part 2.9")
	n.insertChild("Ending - Part 3")
	setNormalMenuValues(n)


func fillVillages():
	var n = activeNode.getChild("Villages")
	n.insertChild("Home of Celis")
	n.insertChild("Alares")
	n.insertChild("Port of Alares")
	n.insertChild("Pass to Zazo")
	n.insertChild("Zazo - The Home of the Miners")
	n.insertChild("Zazo - The House of Teo")
	n.insertChild("Port of Zazo")
	n.insertChild("The Ship Cabin")
	n.insertChild("Pensara - The Trade District")
	n.insertChild("Pensara - The School District")
	n.insertChild("Pensara - The North District")
	n.insertChild("Parasne")
	n.insertChild("Crossroad")
	n.insertChild("Vincent's Office")
	n.insertChild("The Prison Cell")
	n.insertChild("Berca - Village of the Sun")
	n.insertChild("Serphia Hall")
	n.insertChild("Dellna - The Artic Village")
	n.insertChild("Dellna - The Elder House")
	n.insertChild("Home of the Gods")
	setNormalMenuValues(n)


func fillLabyrinths():
	var n = activeNode.getChild("Labyrinths - West Continent")
	fillReil(n.insertChild("Forest of Reil"))
	fillGrivera(n.insertChild("Grivera"))
	fillPass(n.insertChild("Central Pass"))
	fillZazoMine(n.insertChild("The Great Mine of Zazo"))
	fillEastPass(n.insertChild("East Passage"))
	fillEastForest(n.insertChild("Forest of Bri"))
	fillMtCesadur(n.insertChild("Mt. Cesadur"))
	setNormalMenuValues(n)

	n = activeNode.getChild("Labyrinths - East Continent")
	fillPensaraForest(n.insertChild("Pensara Forest"))
	fillForestOfDorma(n.insertChild("Dorma's Forest"))
	fillFireCavern(n.insertChild("Fire Cavern"))
	fillSilentRuin(n.insertChild("Silent Ruin"))
	fillPrison(n.insertChild("Prison"))
	fillDesert(n.insertChild("Berca Desert"))
	fillSewers(n.insertChild("Sewers"))
	fillTempleOfAegis(n.insertChild("Temple of Aegis"))
	setNormalMenuValues(n)

	n = activeNode.getChild("Labyrinths - Ice Continent")
	fillSnowPass(n.insertChild("Frozen Forest"))
	fillIceCavern(n.insertChild("Ice Cavern"))
	fillAirTemple(n.insertChild("Empyrian Temple"))
	fillMenthusLair(n.insertChild("Menthu's Lair"))
	setNormalMenuValues(n)


func fillForestOfDorma(n):
	n.insertChild("Forest of Hate")
	setNormalMenuValues(n)


func fillReil(n):
	n.insertChild("North Entrance")
	n.insertChild("South Entrance")
	n.insertChild("The Path")
	setNormalMenuValues(n)


func fillGrivera(n):
	n.insertChild("First Floor - Entrance")
	n.insertChild("First Floor - To Second Floor - North Stairs")
	n.insertChild("First Floor - To Second Floor - East Stairs")
	n.insertChild("Second Floor - To First Floor - North Stairs")
	n.insertChild("Second Floor - To First Floor - East Stairs")
	n.insertChild("Second Floor - To Third Floor")
	n.insertChild("Third Floor - To Second Floor")
	n.insertChild("Third Floor - To Fourth Floor")
	n.insertChild("Fourth Floor - To Third Floor")
	n.insertChild("Fourth Floor - To Fifth Floor")
	n.insertChild("Fifth Floor - To Fourth Floor")
	n.insertChild("Boss Door - Entrance")
	n.insertChild("Boss Door - Inside")
	setNormalMenuValues(n)


func fillPass(n):
	n.insertChild("West - Entrance")
	n.insertChild("West - Central")
	n.insertChild("Central - West")
	n.insertChild("Central - North")
	n.insertChild("North - Central")
	n.insertChild("North - North East")
	n.insertChild("North East - North")
	n.insertChild("North East - Exit")
	setNormalMenuValues(n)


func fillZazoMine(n):
	n.insertChild("The Hall - Entrance")
	n.insertChild("The Hall - To West Wing")
	n.insertChild("The Hall - To Mine Core")
	n.insertChild("The Hall - To Tunnel")
	n.insertChild("West Wing - To The Hall")
	n.insertChild("West Wing - To The Great Deep")
	n.insertChild("Great Deep - To West Wing")
	n.insertChild("Great Deep - To The Mine Core")
	n.insertChild("The Mine Core - To The Great Deep")
	n.insertChild("The Mine Core - To The Hall")
	n.insertChild("The Mine Core - To Mine Shaft")
	n.insertChild("Mine Shaft - To The Mine Core")
	n.insertChild("Mine Shaft - To Tunnel")
	n.insertChild("Tunnel - To Mine Shaft")
	n.insertChild("Tunnel - To The Hall")
	setNormalMenuValues(n)


func fillEastPass(n):
	n.insertChild("Entrance")
	n.insertChild("West Mountain - To East Mountain")
	n.insertChild("East Mountain - To West Mountain")
	n.insertChild("East Mountain - To Forest of Bri")
	setNormalMenuValues(n)


func fillEastForest(n):
	n.insertChild("West Forest - To West Mountain")
	n.insertChild("West Forest - To East Forest - North Way")
	n.insertChild("West Forest - To East Forest - South Way")
	n.insertChild("East Forest - To West Forest - North Way")
	n.insertChild("East Forest - To West Forest - South Way")
	n.insertChild("East Forest - Towards Mt. Cesadur")
	setNormalMenuValues(n)


func fillMtCesadur(n):
	n.insertChild("Basement")
	n.insertChild("Basement - 1")
	n.insertChild("Basement - 2")
	n.insertChild("Entrance")
	n.insertChild("Entrance - To Second Floor - North")
	n.insertChild("Entrance - To Second Floor - North West")
	n.insertChild("Entrance - To Second Floor - East")
	n.insertChild("Entrance - To Second Floor - South East")
	n.insertChild("Entrance - To Second Floor - South West")

	n.insertChild("Second Floor - To Entrance - North")
	n.insertChild("Second Floor - To Entrance - North West")
	n.insertChild("Second Floor - To Entrance - East")
	n.insertChild("Second Floor - To Entrance - South East")
	n.insertChild("Second Floor - To Entrance - South West")
	n.insertChild("Second Floor - To Third Floor - North")
	n.insertChild("Second Floor - To Third Floor - North West")
	n.insertChild("Second Floor - To Third Floor - South")

	n.insertChild("Third Floor - To Second Floor - North")
	n.insertChild("Third Floor - To Second Floor - North West")
	n.insertChild("Third Floor - To Second Floor - South")
	n.insertChild("Third Floor - To Fourth Floor - South West")
	n.insertChild("Third Floor - To Fourth Floor - South East")
	n.insertChild("Third Floor - To Fourth Floor - North West")
	n.insertChild("Third Floor - To Fourth Floor - North East")

	n.insertChild("Fourth Floor - To Third Floor - South West")
	n.insertChild("Fourth Floor - To Third Floor - South East")
	n.insertChild("Fourth Floor - To Third Floor - North West")
	n.insertChild("Fourth Floor - To Third Floor - North East")
	n.insertChild("Fourth Floor - To Top Floor")

	n.insertChild("Top Floor - To Fourth Floor")
	n.insertChild("Top Floor - To Boss")
	setNormalMenuValues(n)


func fillPensaraForest(n):
	n.insertChild("South Entrance")
	n.insertChild("North Entrance")
	setNormalMenuValues(n)


func fillFireCavern(n):
	n.insertChild("Hall of Fire - Entrance")
	n.insertChild("Hall of Fire - Blazing Maze")
	n.insertChild("Hall of Fire - Furnace")
	n.insertChild("Blazing Maze - Hall of Fire")
	n.insertChild("Blazing Maze - Passage of Ifrit")
	n.insertChild("Passage of Ifrit - Blazing Maze")
	n.insertChild("Passage of Ifrit - Hall of the Damned")
	n.insertChild("Furnace - Hall of Fire")
	n.insertChild("Furnace - Inferno")
	n.insertChild("Inferno - Furnace")
	n.insertChild("Hall of the Damned - Passage of Ifrit")
	setNormalMenuValues(n)


func fillSilentRuin(n):
	n.insertChild("Silent Ruin")
	setNormalMenuValues(n)


func fillPrison(n):
	n.insertChild("Floor 5 - From Prison Cell")
	n.insertChild("Floor 5 - Floor 6")
	n.insertChild("Floor 5 - Floor 4")
	n.insertChild("Floor 6 - Floor 5")
	n.insertChild("Floor 4 - Floor 5")
	n.insertChild("Floor 4 - Floor 3")
	n.insertChild("Floor 3 - Floor 4")
	n.insertChild("Floor 3 - Floor 2")
	n.insertChild("Floor 2 - Floor 3")
	n.insertChild("Floor 2 - Floor 1")
	n.insertChild("Floor 1 - Floor 2")
	n.insertChild("Floor 1 - Exit")
	setNormalMenuValues(n)


func fillDesert(n):
	n.insertChild("South West - Entrance")
	n.insertChild("South West - To South - South Way")
	n.insertChild("South West - To South - North Way")
	n.insertChild("South West - To North")

	n.insertChild("South - To North")
	n.insertChild("South - To South West - South Way")
	n.insertChild("South - To South West - North Way")
	n.insertChild("South - To South East - South Way")
	n.insertChild("South - To South East - North Way")

	n.insertChild("South East - To North - West Way")
	n.insertChild("South East - To North - East Way")
	n.insertChild("South East - To South - North Way")
	n.insertChild("South East - To South - South Way")

	n.insertChild("North West - To South West")
	n.insertChild("North West - To North")

	n.insertChild("North - To South")
	n.insertChild("North - To North West")
	n.insertChild("North - To North East")

	n.insertChild("North East - Exit")
	n.insertChild("North East - To South East - West Way")
	n.insertChild("North East - To South East - East Way")
	n.insertChild("North East - To North")

	setNormalMenuValues(n)


func fillSewers(n):
	n.insertChild("South East - Entrance")
	n.insertChild("South East - To South")
	n.insertChild("South - To South East")
	n.insertChild("South - To North")
	n.insertChild("South - To South West")
	n.insertChild("South West - To South")
	n.insertChild("South West - To North West")
	n.insertChild("North West - To South West")
	n.insertChild("North - To South")
	n.insertChild("North - To North East")
	n.insertChild("North - To Pensara")
	n.insertChild("North East - To North")
	setNormalMenuValues(n)


func fillTempleOfAegis(n):
	n.insertChild("First Floor - Entrance")
	n.insertChild("First Floor - To Second Floor")
	n.insertChild("First Floor - To Base Level - North West")
	n.insertChild("First Floor - To Base Level - North East")
	n.insertChild("First Floor - To Base Level - South West")
	n.insertChild("First Floor - To Base Level - South East")

	n.insertChild("Base Level - To First Floor - North West")
	n.insertChild("Base Level - To First Floor - North East")
	n.insertChild("Base Level - To First Floor - South West")
	n.insertChild("Base Level - To First Floor - South East")

	n.insertChild("Second Floor - To First Floor")
	n.insertChild("Second Floor - To Third Floor")

	n.insertChild("Third Floor - To Second Floor")
	n.insertChild("Third Floor - To Fourth Floor - North East")
	n.insertChild("Third Floor - To Fourth Floor - Center")
	n.insertChild("Third Floor - To Fourth Floor - South West")

	n.insertChild("Fourth Floor - To Third Floor - North East")
	n.insertChild("Fourth Floor - To Third Floor - Center")
	n.insertChild("Fourth Floor - To Third Floor - South West")
	n.insertChild("Fourth Floor - To Fifth Floor")

	n.insertChild("Top Floor - To Fourth Floor")
	n.insertChild("Top Floor - To Crystal Room")
	n.insertChild("Boss")

	setNormalMenuValues(n)


func fillAirTemple(n):
	n.insertChild("Hall of Wind - Entrance")
	n.insertChild("Tower of Magic - Bottom")
	n.insertChild("Tower of Magic - Top")
	n.insertChild("Tower of Strength - Bottom")
	n.insertChild("Tower of Strength - Top")
	n.insertChild("Light")
	n.insertChild("Dark")
	n.insertChild("Demon Floor")
	setNormalMenuValues(n)


func fillMenthusLair(n):
	n.insertChild("Menthu's Lair - Room of Confusion")
	n.insertChild("Menthu's Lair - Hall of Memories")
	n.insertChild("Menthu's Lair - Throne of Serpents")
	n.insertChild("Talking to Menthu")
	n.insertChild("Boss pt.1")
	n.insertChild("Boss pt.2")
	setNormalMenuValues(n)


func fillIceCavern(n):
	n.insertChild("Pillar Room - Entrance")
	n.insertChild("Pillar Room - Frozen Field")
	n.insertChild("Pillar Room - Mysterious Forest")
	n.insertChild("Frozen Field - Pillar Room")
	n.insertChild("Frozen Field - Hall of Confusion")
	n.insertChild("Mysterious Forest - Pillar Room")
	n.insertChild("Mysterious Forest - Hall of Anguish")
	n.insertChild("Hall of Confusion - Frozen Field")
	n.insertChild("Hall of Confusion - Throne Room - North")
	n.insertChild("Hall of Confusion - Throne Room - Center")
	n.insertChild("Hall of Confusion - Throne Room - South")
	n.insertChild("Hall of Anguish - Mysterious Forest")
	n.insertChild("Hall of Anguish - Throne Room - North")
	n.insertChild("Hall of Anguish - Throne Room - Center")
	n.insertChild("Hall of Anguish - Throne Room - South")
	n.insertChild("Throne Room - Hall of Confusion - North")
	n.insertChild("Throne Room - Hall of Confusion - Center")
	n.insertChild("Throne Room - Hall of Confusion - South")
	n.insertChild("Throne Room - Hall of Anguish - North")
	n.insertChild("Throne Room - Hall of Anguish - Center")
	n.insertChild("Throne Room - Hall of Anguish - South")
	n.insertChild("Throne Room - Boss")
	n.insertChild("Boss2")
	setNormalMenuValues(n)


func fillSnowPass(n):
	n.insertChild("Entrance")
	n.insertChild("To Ice Cavern")
	setNormalMenuValues(n)


func fillLandscape(n):
	fillWestContinent(n.insertChild("West Continent"))
	fillEastContinent(n.insertChild("East Continent"))
	fillNorthContinent(n.insertChild("North Continent"))

	setNormalMenuValues(n)


func fillWestContinent(n):
	n.insertChild("Home of Celis")
	n.insertChild("Forest of Reil - North Entrance")
	n.insertChild("Forest of Reil - South Entrance")
	n.insertChild("Alares")
	n.insertChild("Grivera")
	n.insertChild("Port of Alares")
	n.insertChild("Pass to Zazo")
	n.insertChild("Central Pass - North Entrance")
	n.insertChild("Zazo")
	n.insertChild("Port of Zazo")
	n.insertChild("The Great Mine")
	n.insertChild("East Passage")
	n.insertChild("Forest of Bri")
	n.insertChild("Mt. Cesadur")
	setNormalMenuValues(n)


func fillEastContinent(n):
	n.insertChild("Parasne")
	n.insertChild("Pensara Forest - South Entrance")
	n.insertChild("Pensara Forest - North Entrance")
	n.insertChild("Pensara")
	n.insertChild("Crossroad")
	n.insertChild("Fire Cavern")
	n.insertChild("Prison")
	n.insertChild("Desert - West Entrance")
	n.insertChild("Desert - North Entrance")
	n.insertChild("Berca")
	n.insertChild("Temple of Aegis")

	setNormalMenuValues(n)


func fillNorthContinent(n):
	n.insertChild("Dellna")
	n.insertChild("Frozen Forest")
	n.insertChild("Ice Cavern")

	setNormalMenuValues(n)


func fillStore():
	var n = activeNode.getChild("Buildings")
	fillWeaponStore(n.insertChild("Weapon Store"))
	fillCardStore(n.insertChild("Card Store"))
	fillChurchStore(n.insertChild("Church"))
	fillInnStore(n.insertChild("Inn"))
	setNormalMenuValues(n)


func fillWeaponStore(n):
	n.insertChild("Alares")
	n.insertChild("Zazo")
	n.insertChild("Pensara - The Trade District")
	n.insertChild("Berca")
	n.insertChild("Dellna")
	setNormalMenuValues(n)


func fillCardStore(n):
	n.insertChild("Alares--0")
	n.insertChild("Alares--1")
	n.insertChild("Alares--2")
	n.insertChild("Zazo--0")
	n.insertChild("Zazo--1")
	n.insertChild("Zazo--2")
	n.insertChild("Zazo--3")
	n.insertChild("Parasne--0")
	n.insertChild("Parasne--1")
	n.insertChild("Pensara - The Trade District--0")
	n.insertChild("Pensara - The Trade District--1")
	n.insertChild("Pensara - The Trade District--2")
	n.insertChild("Pensara - The Trade District--3")
	n.insertChild("Berca--0")
	n.insertChild("Berca--1")
	n.insertChild("Berca--2")
	n.insertChild("Dellna--0")
	n.insertChild("Dellna--1")
	setNormalMenuValues(n)


func fillChurchStore(n):
	n.insertChild("Alares")
	n.insertChild("Zazo")
	n.insertChild("Pensara - The School District")
	n.insertChild("Berca")
	n.insertChild("Dellna")
	setNormalMenuValues(n)


func fillInnStore(n):
	n.insertChild("Alares")
	n.insertChild("Zazo")
	n.insertChild("Pensara - The Trade District")
	n.insertChild("Berca")
	n.insertChild("Dellna")
	setNormalMenuValues(n)


## Draws the cheat mode: all the places that the player can go to.
func draw(g, alpha = null):
	g.setColor(1)
	g.loadIdentity()
	Graphics.setTextColor(JColor.RED)
	g.setFontSize(26)
	activeNode.drawChildren(g)


## Returns the mode chosen by the player (NO_MODE_IS_SELECTED until then).
func checkExit():
	return mode


## Called when the organizer switches from the Cheater to the chosen mode.
func finishOff():
	# killOggPlayer()
	pass


## Updates the cheater: checks if the player has pressed a button.
func update(elapsedTime: float):
	if gameActions[UP].isPressed():
		activeNode.previousChild()
	elif gameActions[DOWN].isPressed():
		activeNode.nextChild()
	elif gameActions[CROSS].isPressed():
		if activeNode.getCurrentChild().hasChildren():
			activeNode = activeNode.getCurrentChild()
		else:
			if not Load.hasLoaded():
				Load.loadGame("Start")
			switchToNext()
	elif gameActions[CIRCLE].isPressed():
		var n = activeNode.getParent()
		if n != null:
			activeNode = n
		else:
			exitWithoutFading(Values.SWITCH_BACK)
	super.update(elapsedTime)


## Gets the next place (tells the organizer which place to load).
func getNextPlace():
	# GameMode.getNextPlace() is typed String; null means "no place" there too.
	return "" if nextPlace == null else str(nextPlace)


## Called when the player has pressed cross on a place: sets up the values
## that send the player there.
func switchToNext():
	var next: String = activeNode.getCurrentChild().getName()
	var current: String = activeNode.getName()
	var n = activeNode.getParent()
	var parent: String = "" if n == null else n.getName()
	if next == "Battle Test":
		mode = Values.BATTLE_TEST
		nextPlace = ""
		# Values.DAY = true
		shouldGetInfoFromMain_ = false
		Organizer.getOrganizer().setNext(false)
	elif current == "Villages":
		match next:
			"Home of Celis":
				setWestVillage("Home of Celis")
			"Kin's Place":
				setWestVillage("Kin's Place")
			"Alares":
				setWestVillage("Alares")
			"Port of Alares":
				setWestVillage("Port of Alares")
			"Pass to Zazo":
				setWestVillage("Pass to Zazo")
			"Zazo - The Home of the Miners":
				setWestVillage("Zazo")
			"Zazo - The House of Teo":
				setWestVillage("Zazo - Teo's House")
			"Port of Zazo":
				setWestVillage("Port of Zazo")
			"The Ship Cabin":
				setWestVillage("The Ship Cabin")
			"Pensara - The Trade District":
				setEastVillage("Pensara - The Trade District")
			"Pensara - The School District":
				setEastVillage("Pensara - The School District")
			"Pensara - The North District":
				setEastVillage("Pensara - The North District")
			"Parasne":
				setEastVillage("Parasne")
			"Crossroad":
				setEastVillage("Crossroad")
			"Vincent's Office":
				setEastVillage("Vincent's Office")
			"The Prison Cell":
				setEastVillage("The Prison Cell")
			"Berca - Village of the Sun":
				setEastVillage("Berca")
			"Serphia Hall":
				setEastVillage("Serphia Hall")
			"Dellna - The Artic Village":
				setNorthVillage("Dellna")
			"Dellna - The Elder House":
				setNorthVillage("Dellna - Elder House - Floor 1")
			"Home of the Gods":
				setNorthVillage("Home of the Gods")

	elif current == "Forest of Reil":
		match next:
			"North Entrance":
				setLabyrinth("Forest of Reil--Deep_Forest-mark0")
			"South Entrance":
				setLabyrinth("Forest of Reil--Deep_Forest-mark1")
			"The Path":
				setLabyrinth("Forest of Reil--Forest Path-mark0")

	elif current == "Grivera":
		match next:
			"First Floor - Entrance":
				setLabyrinth("Grivera--First Floor-mark0")
			"First Floor - To Second Floor - North Stairs":
				setLabyrinth("Grivera--First Floor-mark1")
			"First Floor - To Second Floor - East Stairs":
				setLabyrinth("Grivera--First Floor-mark2")
			"Second Floor - To First Floor - North Stairs":
				setLabyrinth("Grivera--Second Floor-mark0")
			"Second Floor - To First Floor - East Stairs":
				setLabyrinth("Grivera--Second Floor-mark1")
			"Second Floor - To Third Floor":
				setLabyrinth("Grivera--Second Floor-mark2")
			"Third Floor - To Second Floor":
				setLabyrinth("Grivera--Third Floor-mark0")
			"Third Floor - To Fourth Floor":
				setLabyrinth("Grivera--Third Floor-mark1")
			"Fourth Floor - To Third Floor":
				setLabyrinth("Grivera--Omnious Hall-mark0")
			"Fourth Floor - To Fifth Floor":
				setLabyrinth("Grivera--Omnious Hall-mark1")
			"Fifth Floor - To Fourth Floor":
				setLabyrinth("Grivera--Corridor of Agony-mark0")
			"Boss Door - Entrance":
				setLabyrinth("Grivera--Corridor of Agony-mark1")
			"Boss Door - Inside":
				setLabyrinth("Grivera--Corridor of Agony-mark2")

	elif current == "Central Pass":
		match next:
			"West - Entrance":
				setLabyrinth("Central Pass--West Part-mark0")
			"West - Central":
				setLabyrinth("Central Pass--West Part-mark1")

			"Central - West":
				setLabyrinth("Central Pass--Central Part-mark0")
			"Cenral - North": # sic (the menu says "Central - North")
				setLabyrinth("Central Pass--Central Part-mark1")

			"North - Central":
				setLabyrinth("Central Pass--North Part-mark0")
			"North - North East":
				setLabyrinth("Central Pass--North Part-mark1")

			"North East - North":
				setLabyrinth("Central Pass--North East Part-mark1")
			"North East - Exit":
				setLabyrinth("Central Pass--North East Part-mark0")

	elif current == "The Great Mine of Zazo":
		match next:
			"The Hall - Entrance":
				setLabyrinth("The Great Mine--The Hall-mark0")
			"The Hall - To West Wing":
				setLabyrinth("The Great Mine--The Hall-mark1")
			"The Hall - To Mine Core":
				setLabyrinth("The Great Mine--The Hall-mark2")
			"The Hall - To Tunnel":
				setLabyrinth("The Great Mine--The Hall-mark3")

			"West Wing - To The Hall":
				setLabyrinth("The Great Mine--West Wing-mark0")
			"West Wing - To The Great Deep":
				setLabyrinth("The Great Mine--West Wing-mark1")

			"Great Deep - To West Wing":
				setLabyrinth("The Great Mine--Great Deep-mark0")
			"Great Deep - To The Mine Core":
				setLabyrinth("The Great Mine--Great Deep-mark1")

			"The Mine Core - To The Great Deep":
				setLabyrinth("The Great Mine--The Mine Core-mark1")
			"The Mine Core - To The Hall":
				setLabyrinth("The Great Mine--The Mine Core-mark0")
			"The Mine Core - To Mine Shaft":
				setLabyrinth("The Great Mine--The Mine Core-mark2")

			"Mine Shaft - To The Mine Core":
				setLabyrinth("The Great Mine--Mine Shaft-mark1")
			"Mine Shaft - To Tunnel":
				setLabyrinth("The Great Mine--Mine Shaft-mark0")

			"Tunnel - To Mine Shaft":
				setLabyrinth("The Great Mine--Tunnel-mark1")
			"Tunnel - To The Hall":
				setLabyrinth("The Great Mine--Tunnel-mark0")

	elif current == "East Passage":
		match next:
			"Entrance":
				setLabyrinth("East Passage--West Mountain-mark0")
			"West Mountain - To East Mountain":
				setLabyrinth("East Passage--West Mountain-mark1")
			"East Mountain - To West Mountain":
				setLabyrinth("East Passage--East Mountain-mark1")
			"East Mountain - To Forest of Bri":
				setLabyrinth("East Passage--East Mountain-mark0")

	elif current == "Forest of Bri":
		match next:
			"West Forest - To West Mountain":
				setLabyrinth("Forest of Bri--West Forest-mark0")
			"West Forest - To East Forest - North Way":
				setLabyrinth("Forest of Bri--West Forest-mark1")
			"West Forest - To East Forest - South Way":
				setLabyrinth("Forest of Bri--West Forest-mark2")
			"East Forest - To West Forest - North Way":
				setLabyrinth("Forest of Bri--East Forest-mark1")
			"East Forest - To West Forest - South Way":
				setLabyrinth("Forest of Bri--East Forest-mark2")
			"East Forest - Towards Mt. Cesadur":
				setLabyrinth("Forest of Bri--East Forest-mark0")

	elif current == "Mt. Cesadur":
		match next:
			"Basement":
				setLabyrinth("Mt. Cesadur--Basement-mark0")
			"Basement - 1":
				setLabyrinth("Mt. Cesadur--Basement-mark1")
			"Basement - 2":
				setLabyrinth("Mt. Cesadur--Basement-mark2")
			"Entrance":
				setLabyrinth("Mt. Cesadur--Entrance-mark0")
			"Entrance - To Second Floor - North":
				setLabyrinth("Mt. Cesadur--Entrance-mark1")
			"Entrance - To Second Floor - North West":
				setLabyrinth("Mt. Cesadur--Entrance-mark2")
			"Entrance - To Second Floor - East":
				setLabyrinth("Mt. Cesadur--Entrance-mark3")
			"Entrance - To Second Floor - South East":
				setLabyrinth("Mt. Cesadur--Entrance-mark4")
			"Entrance - To Second Floor - South West":
				setLabyrinth("Mt. Cesadur--Entrance-mark5")

			"Second Floor - To Entrance - North":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark0")
			"Second Floor - To Entrance - North West":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark2")
			"Second Floor - To Entrance - East":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark1")
			"Second Floor - To Entrance - South East":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark3")
			"Second Floor - To Entrance - South West":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark4")
			"Second Floor - To Third Floor - North":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark5")
			"Second Floor - To Third Floor - North West":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark6")
			"Second Floor - To Third Floor - South":
				setLabyrinth("Mt. Cesadur--Second_Floor-mark7")

			"Third Floor - To Second Floor - North":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark0")
			"Third Floor - To Second Floor - North West":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark1")
			"Third Floor - To Second Floor - South":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark2")
			"Third Floor - To Fourth Floor - South West":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark3")
			"Third Floor - To Fourth Floor - South East":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark4")
			"Third Floor - To Fourth Floor - North West":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark5")
			"Third Floor - To Fourth Floor - North East":
				setLabyrinth("Mt. Cesadur--Third_Floor-mark6")

			"Fourth Floor - To Third Floor - South West":
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark0")
			"Fourth Floor - To Third Floor - South East":
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark1")
			"Fourth Floor - To Third Floor - North West":
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark3")
			"Fourth Floor - To Third Floor - North East":
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark2")
			"Fourth Floor - To Top Floor":
				setLabyrinth("Mt. Cesadur--Fourth Floor-mark4")

			"Top Floor - To Fourth Floor":
				setLabyrinth("Mt. Cesadur--Mountain Top-mark0")
			"Top Floor - To Boss":
				setLabyrinth("Mt. Cesadur--Mountain Top-mark2")

	elif current == "Pensara Forest":
		match next:
			"South Entrance":
				setLabyrinth("Pensara Forest--Forest-mark0")
			"North Entrance":
				setLabyrinth("Pensara Forest--Forest-mark1")

	elif current == "Dorma's Forest":
		if next == "Forest of Hate":
			setLabyrinth("Dorma's Forest--Forest of Hate-mark0")

	elif current == "Fire Cavern":
		match next:
			"Hall of Fire - Entrance":
				setLabyrinth("Fire Cavern--Hall of Fire-mark0")
			"Hall of Fire - Blazing Maze":
				setLabyrinth("Fire Cavern--Hall of Fire-mark1")
			"Hall of Fire - Furnace":
				setLabyrinth("Fire Cavern--Hall of Fire-mark2")
			"Blazing Maze - Hall of Fire":
				setLabyrinth("Fire Cavern--Blazing Maze-mark0")
			"Blazing Maze - Passage of Ifrit":
				setLabyrinth("Fire Cavern--Blazing Maze-mark1")
			"Passage of Ifrit - Blazing Maze":
				setLabyrinth("Fire Cavern--Passage of Ifrit-mark0")
			"Passage of Ifrit - Hall of the Damned":
				setLabyrinth("Fire Cavern--Passage of Ifrit-mark1")
			"Furnace - Hall of Fire":
				setLabyrinth("Fire Cavern--Furnace-mark0")
			"Furnace - Inferno":
				setLabyrinth("Fire Cavern--Furnace-mark1")
			"Inferno - Furnace":
				setLabyrinth("Fire Cavern--Inferno-mark0")
			"Hall of the Damned - Passage of Ifrit":
				setLabyrinth("Fire Cavern--Hall of the Damned-mark0")

	elif current == "Silent Ruin":
		setLabyrinth("Silent Ruin--The Great Ruins-mark0")
	elif current == "Prison":
		match next:
			"Floor 5 - From Prison Cell":
				setLabyrinth("Pensara Prison--Floor 5-mark0")
			"Floor 5 - Floor 6":
				setLabyrinth("Pensara Prison--Floor 5-mark1")
			"Floor 5 - Floor 4":
				setLabyrinth("Pensara Prison--Floor 5-mark2")
			"Floor 6 - Floor 5":
				setLabyrinth("Pensara Prison--Floor 6-mark0")
			"Floor 4 - Floor 5":
				setLabyrinth("Pensara Prison--Floor 4-mark1")
			"Floor 4 - Floor 3":
				setLabyrinth("Pensara Prison--Floor 4-mark0")
			"Floor 3 - Floor 4":
				setLabyrinth("Pensara Prison--Floor 3-mark0")
			"Floor 3 - Floor 2":
				setLabyrinth("Pensara Prison--Floor 3-mark1")
			"Floor 2 - Floor 3":
				setLabyrinth("Pensara Prison--Floor 2-mark1")
			"Floor 2 - Floor 1":
				setLabyrinth("Pensara Prison--Floor 2-mark0")
			"Floor 1 - Floor 2":
				setLabyrinth("Pensara Prison--Floor 1-mark0")
			"Floor 1 - Exit":
				setLabyrinth("Pensara Prison--Floor 1-mark1")

	elif current == "Berca Desert":
		match next:
			"South West - Entrance":
				setLabyrinth("Berca Desert--South West-mark0")
			"South West - To South - South Way":
				setLabyrinth("Berca Desert--South West-mark1")
			"South West - To South - North Way":
				setLabyrinth("Berca Desert--South West-mark2")
			"South West - To North":
				setLabyrinth("Berca Desert--South West-mark3")

			"South - To North":
				setLabyrinth("Berca Desert--South-mark0")
			"South - To South West - South Way":
				setLabyrinth("Berca Desert--South-mark1")
			"South - To South West - North Way":
				setLabyrinth("Berca Desert--South-mark2")
			"South - To South East - South Way":
				setLabyrinth("Berca Desert--South-mark3")
			"South - To South East - North Way":
				setLabyrinth("Berca Desert--South-mark4")

			"South East - To North - West Way":
				setLabyrinth("Berca Desert--South East-mark0")
			"South East - To North - East Way":
				setLabyrinth("Berca Desert--South East-mark1")
			"South East - To South - North Way":
				setLabyrinth("Berca Desert--South East-mark2")
			"South East - To South - South Way":
				setLabyrinth("Berca Desert--South East-mark3")

			"North West - To South": # sic (the menu says "North West - To South West")
				setLabyrinth("Berca Desert--North West-mark0")
			"North West - To North":
				setLabyrinth("Berca Desert--North West-mark1")

			"North - To South":
				setLabyrinth("Berca Desert--North-mark0")
			"North - To North West":
				setLabyrinth("Berca Desert--North-mark1")
			"North - To North East":
				setLabyrinth("Berca Desert--North-mark2")

			"North East - Exit":
				setLabyrinth("Berca Desert--North East-mark0")
			"North East - To South East - West Way":
				setLabyrinth("Berca Desert--North East-mark1")
			"North East - To South East - East Way":
				setLabyrinth("Berca Desert--North East-mark3")
			"North East - To North":
				setLabyrinth("Berca Desert--North East-mark2")

	elif current == "Sewers":
		match next:
			"South East - Entrance":
				setLabyrinth("The Sewers--South East-mark0")
			"South East - To South":
				setLabyrinth("The Sewers--South East-mark1")

			"South - To South East":
				setLabyrinth("The Sewers--South-mark0")
			"South - To North":
				setLabyrinth("The Sewers--South-mark1")
			"South - To South West":
				setLabyrinth("The Sewers--South-mark2")

			"South West - To South":
				setLabyrinth("The Sewers--South_West-mark0")
			"South West - To North West":
				setLabyrinth("The Sewers--South_West-mark1")

			"North West - To South West":
				setLabyrinth("The Sewers--North_West-mark0")

			"North - To South":
				setLabyrinth("The Sewers--North-mark0")
			"North - To North East":
				setLabyrinth("The Sewers--North-mark1")
			"North - To Pensara":
				setLabyrinth("The Sewers--North-mark6")

			"North East - To North":
				setLabyrinth("The Sewers--North_East-mark0")

	elif current == "Temple of Aegis":
		match next:
			"First Floor - Entrance":
				setLabyrinth("Temple of Aegis--First Floor-mark0")
			"First Floor - To Second Floor":
				setLabyrinth("Temple of Aegis--First Floor-mark1")
			"First Floor - To Base Level - North West":
				setLabyrinth("Temple of Aegis--First Floor-mark2")
			"First Floor - To Base Level - North East":
				setLabyrinth("Temple of Aegis--First Floor-mark3")
			"First Floor - To Base Level - South West":
				setLabyrinth("Temple of Aegis--First Floor-mark4")
			"First Floor - To Base Level - South East":
				setLabyrinth("Temple of Aegis--First Floor-mark5")

			"Base Level - To First Floor - North West":
				setLabyrinth("Temple of Aegis--Base Level-mark0")
			"Base Level - To First Floor - North East":
				setLabyrinth("Temple of Aegis--Base Level-mark1")
			"Base Level - To First Floor - South West":
				setLabyrinth("Temple of Aegis--Base Level-mark2")
			"Base Level - To First Floor - South East":
				setLabyrinth("Temple of Aegis--Base Level-mark3")

			"Second Floor - To First Floor":
				setLabyrinth("Temple of Aegis--Second Floor-mark0")
			"Second Floor - To Third Floor":
				setLabyrinth("Temple of Aegis--Second Floor-mark1")

			"Third Floor - To Second Floor":
				setLabyrinth("Temple of Aegis--Third Floor-mark0")
			"Third Floor - To Fourth Floor - North East":
				setLabyrinth("Temple of Aegis--Third Floor-mark1")
			"Third Floor - To Fourth Floor - Center":
				setLabyrinth("Temple of Aegis--Third Floor-mark2")
			"Third Floor - To Fourth Floor - South West":
				setLabyrinth("Temple of Aegis--Third Floor-mark3")

			"Fourth Floor - To Third Floor - North East":
				setLabyrinth("Temple of Aegis--Fourth Floor-mark0")
			"Fourth Floor - To Third Floor - Center":
				setLabyrinth("Temple of Aegis--Fourth Floor-mark1")
			"Fourth Floor - To Third Floor - South West":
				setLabyrinth("Temple of Aegis--Fourth Floor-mark2")
			"Fourth Floor - To Fifth Floor":
				setLabyrinth("Temple of Aegis--Fourth Floor-mark3")

			"Top Floor - To Fourth Floor":
				setLabyrinth("Temple of Aegis--Top Floor-mark0")
			"Top Floor - To Crystal Room":
				setLabyrinth("Temple of Aegis--Top Floor-mark1")
			"Boss":
				setBossBattleArea("Serphia")

	elif current == "Frozen Forest":
		match next:
			"Entrance":
				setLabyrinth("Frozen Forest--Forest Passage-mark0")
			"To Ice Cavern":
				setLabyrinth("Frozen Forest--Forest Passage-mark1")

	elif current == "Ice Cavern":
		# Java has "Hall of Anguish - Mysterious Forest" twice; the first wins.
		match next:
			"Pillar Room - Entrance":
				setLabyrinth("Ice Cavern--Pillar Room-mark0")
			"Pillar Room - Frozen Field":
				setLabyrinth("Ice Cavern--Pillar Room-mark2")
			"Pillar Room - Mysterious Forest":
				setLabyrinth("Ice Cavern--Pillar Room-mark1")
			"Frozen Field - Pillar Room":
				setLabyrinth("Ice Cavern--Frozen Field-mark0")
			"Frozen Field - Hall of Confusion":
				setLabyrinth("Ice Cavern--Frozen Field-mark1")
			"Mysterious Forest - Pillar Room":
				setLabyrinth("Ice Cavern--Mysterious Forest-mark0")
			"Mysterious Forest - Hall of Anguish":
				setLabyrinth("Ice Cavern--Mysterious Forest-mark14")
			"Hall of Confusion - Frozen Field":
				setLabyrinth("Ice Cavern--Hall of Confusion-mark1")
			"Hall of Confusion - Throne Room - North":
				setLabyrinth("Ice Cavern--Hall of Confusion-mark3")
			"Hall of Confusion - Throne Room - Center":
				setLabyrinth("Ice Cavern--Hall of Confusion-mark2")
			"Hall of Confusion - Throne Room - South":
				setLabyrinth("Ice Cavern--Hall of Confusion-mark0")
			"Hall of Anguish - Mysterious Forest":
				setLabyrinth("Ice Cavern--Hall of Anguish-mark0")
			"Hall of Anguish - Throne Room - North":
				setLabyrinth("Ice Cavern--Hall of Anguish-mark3")
			"Hall of Anguish - Throne Room - Center":
				setLabyrinth("Ice Cavern--Hall of Anguish-mark2")
			"Hall of Anguish - Throne Room - South":
				setLabyrinth("Ice Cavern--Hall of Anguish-mark0")
			"Throne Room - Hall of Confusion - North":
				setLabyrinth("Ice Cavern--Throne Room-mark4")
			"Throne Room - Hall of Confusion - Center":
				setLabyrinth("Ice Cavern--Throne Room-mark5")
			"Throne Room - Hall of Confusion - South":
				setLabyrinth("Ice Cavern--Throne Room-mark0")
			"Throne Room - Hall of Anguish - North":
				setLabyrinth("Ice Cavern--Throne Room-mark3")
			"Throne Room - Hall of Anguish - Center":
				setLabyrinth("Ice Cavern--Throne Room-mark2")
			"Throne Room - Hall of Anguish - South":
				setLabyrinth("Ice Cavern--Throne Room-mark1")
			"Throne Room - Boss":
				setLabyrinth("Ice Cavern--Throne Room-mark7")
			"Boss2":
				setBossBattleArea("Menthuattack")

	elif current == "Empyrian Temple":
		match next:
			"Hall of Wind - Entrance":
				setLabyrinth("Empyrian Temple--Hall of Wind-mark0")
			"Tower of Magic - Bottom":
				setLabyrinth("Empyrian Temple--Tower of Magic-mark0")
			"Tower of Magic - Top":
				setLabyrinth("Empyrian Temple--Tower of Magic-mark7")
			"Tower of Strength - Bottom":
				setLabyrinth("Empyrian Temple--Tower of Strength-mark0")
			"Tower of Strength - Top":
				setLabyrinth("Empyrian Temple--Tower of Strength-mark7")
			"Light":
				setLabyrinth("Empyrian Temple--Light-mark0")
			"Dark":
				setLabyrinth("Empyrian Temple--Dark-mark0")
			"Demon Floor":
				setLabyrinth("Empyrian Temple--Hall of Memories-mark0")

	elif current == "Menthu's Lair":
		match next:
			"Menthu's Lair - Room of Confusion":
				setLabyrinth("Menthu's Lair--Room of Confusion-mark0")
			"Menthu's Lair - Hall of Memories":
				setLabyrinth("Menthu's Lair--Hall of Memories-mark0")
			"Menthu's Lair - Throne of Serpents":
				setLabyrinth("Menthu's Lair--Throne of Serpents-mark0")
			"Talking to Menthu":
				setStory("Talking to Menthu")
			"Boss pt.1":
				setBossBattleArea("Menthu2")
			"Boss pt.2":
				setBossBattleArea("Menthuattack2")

	elif current == "Prolog":
		setProlog(next)
	elif current == "Chapter one - Running Away From Home":
		setStory(next)
	elif current == "Chapter two - Zazo, the Home of the Miners":
		setStory(next)
	elif current == "Chapter three - The Son Returs":
		setStory(next)
	elif current == "Chapter four - A Wind of Change":
		setStory(next)
	elif current == "Chapter five - Soaring Through the Sky":
		setStory(next)
	elif current == "Chapter six - The End Draws Near":
		setStory(next)
	elif current == "Epilog":
		setStory(next)
	elif parent == "Landscape":
		if current == "West Continent":
			match next:
				"Home of Celis":
					setWestLandscape("Home of Celis")
				"Forest of Reil - North Entrance":
					setWestLandscape("Forest of Reil--Deep_Forest-mark0")
				"Forest of Reil - South Entrance":
					setWestLandscape("Forest of Reil--Deep_Forest-mark1")
				"Alares":
					setWestLandscape("Alares")
				"Grivera":
					setWestLandscape("Grivera--First Floor-mark0")
				"Port of Alares":
					setWestLandscape("Port of Alares")
				"Pass to Zazo":
					setWestLandscape("Pass to Zazo")
				"Central Pass - North Entrance":
					setWestLandscape("Central Pass--North East Part-mark0")
				"Zazo":
					setWestLandscape("Zazo")
				"Port of Zazo":
					setWestLandscape("Port of Zazo")
				"The Great Mine":
					setWestLandscape("The Great Mine--The Hall-mark0")
				"East Passage":
					setWestLandscape("East Passage--West_Mountain-mark0")
				"Forest of Bri":
					setWestLandscape("Forest of Bri--East_Forest-mark0")
				"Mt. Cesadur":
					setWestLandscape("Mt. Cesadur--Entrance-mark0")

		elif current == "East Continent":
			match next:
				"Parasne":
					setEastLandscape("Parasne")
				"Pensara Forest - Souht Entrance": # sic (menu: "South Entrance")
					setEastLandscape("Pensara Forest--Forest-mark0")
				"Pensara Forest - North Entrance":
					setEastLandscape("Pensara Forest--Forest-mark1")
				"Pensara":
					setEastLandscape("Pensara - The Trade District")
				"Crossroad":
					setEastLandscape("Crossroad")
				"Fire Cavern":
					setEastLandscape("Fire Cavern--Hall of Fire-mark0")
				"Prison":
					setEastLandscape("Pensara Prison--Floor 1-mark0")
				"Desert - West Entrance":
					setEastLandscape("Berca Desert--South West-mark0")
				"Desert - North Entrance":
					setEastLandscape("Berca Desert--North West-mark0")
				"Berca":
					setEastLandscape("Berca")
				"Temple of Aegis":
					setEastLandscape("Temple of Aegis--First Floor-mark0")

		elif current == "North Continent":
			match next:
				"Dellna":
					setNorthLandscape("Dellna")
				"Frozen Forest":
					setNorthLandscape("Frozen Forest--Forest Passage-mark0")
				"Ice Cavern":
					setNorthLandscape("Demon Cave4-mark0")

	elif parent == "Landscape From the Air":
		if current == "West Continent":
			match next:
				"Home of Celis":
					setAirLandscape("Home of Celis")
				"Forest of Reil - North Entrance":
					setAirLandscape("Forest of Reil--Deep_Forest-mark0")
				"Forest of Reil - South Entrance":
					setAirLandscape("Forest of Reil--Deep_Forest-mark1")
				"Alares":
					setAirLandscape("Alares")
				"Grivera":
					setAirLandscape("Grivera--First Floor-mark0")
				"Port of Alares":
					setAirLandscape("Port of Alares")
				"Pass to Zazo":
					setAirLandscape("Pass to Zazo")
				"Central Pass - North Entrance":
					setAirLandscape("Central Pass--North East Part-mark0")
				"Zazo":
					setAirLandscape("Zazo")
				"Port of Zazo":
					setAirLandscape("Port of Zazo")
				"The Great Mine":
					setAirLandscape("The Great Mine--The Hall-mark0")
				"East Passage":
					setAirLandscape("East Passage--West_Mountain-mark0")
				"Forest of Bri":
					setAirLandscape("Forest of Bri--East_Forest-mark0")
				"Mt. Cesadur":
					setAirLandscape("Mt. Cesadur--Entrance-mark0")

		elif current == "East Continent":
			match next:
				"Parasne":
					setAirLandscape("Parasne")
				"Pensara Forest - Souht Entrance": # sic (menu: "South Entrance")
					setAirLandscape("Pensara Forest--Forest-mark0")
				"Pensara Forest - North Entrance":
					setAirLandscape("Pensara Forest--Forest-mark1")
				"Pensara":
					setAirLandscape("Pensara - The Trade District")
				"Crossroad":
					setAirLandscape("Crossroad")
				"Fire Cavern":
					setAirLandscape("Fire Cavern--Hall of Fire-mark0")
				"Prison":
					setAirLandscape("Pensara Prison--Floor 1-mark0")
				"Desert - West Entrance":
					setAirLandscape("Berca Desert--South West-mark0")
				"Desert - North Entrance":
					setAirLandscape("Berca Desert--North West-mark0")
				"Berca":
					setAirLandscape("Berca")
				"Temple of Aegis":
					setAirLandscape("Temple of Aegis--First Floor-mark0")

		elif current == "North Continent":
			match next:
				"Dellna":
					setAirLandscape("Dellna")
				"Frozen Forest":
					setAirLandscape("Frozen Forest--Forest Passage-mark0")
				"Ice Cavern":
					setAirLandscape("Demon Cave4-mark0")

	elif current == "Weapon Store":
		WeaponStore.setTestMap(getStoreInfo(next, "Weapon"))
		setStore(Values.WEAPONSTORE)
	elif current == "Card Store":
		CardStore.setTestMap(createStoreInfo(next, "Card"))
		setStore(Values.CARDSTORE)
	elif current == "Church":
		Church.setTestMap(getStoreInfo(next, "Church"))
		setStore(Values.CHURCH)
	elif current == "Inn":
		Inn.setTestMap(getStoreInfo(next, "Inn"))
		setStore(Values.INN)

	elif next == "Landscape Test":
		setLandTest("west")

	# No matching case... #
	else:
		# Java exited the game; the menu stays open.
		@warning_ignore("assert_always_false")
		assert(false, "Cheater: No matching case... Current: " + current + " - Next: " + next)


func setBossBattleArea(name):
	mode = Values.BOSS_BATTLE_AREA
	nextPlace = name
	exit(Values.BOSS_BATTLE_AREA)
	Organizer.getOrganizer().setNext(true)


func setWestVillage(name):
	Database.addStatus("Landscape", Landscape.WEST_CONTINENT)
	setVillage2(name)


func setEastVillage(name):
	Database.addStatus("Landscape", Landscape.EAST_CONTINENT)
	setVillage2(name)


func setNorthVillage(name):
	Database.addStatus("Landscape", Landscape.NORTH_CONTINENT)
	setVillage2(name)


func setVillage2(name):
	mode = Values.VILLAGE
	nextPlace = name
	exit(Values.VILLAGE)
	Organizer.getOrganizer().setNext(true)


func setLandTest(name):
	mode = Values.LANDSCAPE_TEST
	nextPlace = name
	Organizer.getOrganizer().setNext(true)


func setLabyrinth(name):
	nextPlace = name
	exit(Values.LABYRINTH)
	Organizer.getOrganizer().setNext(true)


func setStory(name):
	nextPlace = name
	exit(Values.STORY_SEQUENSE)
	Organizer.getOrganizer().setNext(true)


func setProlog(name):
	nextPlace = name
	exit(Values.STORY_SEQUENSE)
	Organizer.getOrganizer().setNext(true)


func setWestLandscape(name):
	Database.addStatus("Landscape", Landscape.WEST_CONTINENT)
	nextPlace = "land" + name
	exit(Values.LANDSCAPE)
	Organizer.getOrganizer().setNext(true)


func setEastLandscape(name):
	Database.addStatus("Landscape", Landscape.EAST_CONTINENT)
	nextPlace = "land" + name
	exit(Values.LANDSCAPE)
	Organizer.getOrganizer().setNext(true)


func setNorthLandscape(name):
	Database.addStatus("Landscape", Landscape.NORTH_CONTINENT)
	nextPlace = "land" + name
	exit(Values.LANDSCAPE)
	Organizer.getOrganizer().setNext(true)


func setAirLandscape(name):
	nextPlace = "air" + name
	exit(Values.AIR_SHIP)
	Organizer.getOrganizer().setNext(true)


## Loads the village with the given name (main.bank) and returns the
## information map of its building whose name contains type.
func getStoreInfo(next, type):
	var vl := Village.new()
	vl.init(Organizer.getOrganizer().getInformationFor(next))
	return vl.getTestInfoForType(type)


## next is "<village>--<store status>": sets the store status in the
## database and returns the store information.
func createStoreInfo(next, type):
	var temp: Array = J.split(next, "--")
	next = temp[0]
	var status: int = J.parseInt(temp[1])
	var info = getStoreInfo(next, type)
	var storeName = info.get("storeName")
	Database.addStatus(storeName, status)
	return info


func setStore(p_mode):
	exit(p_mode)
	Organizer.getOrganizer().setNext(true)


## The information for the next place is never created here.
func getInfoForNextPlace():
	return null


## True if the organizer should get the information about the next place
## from the main information source (main.bank), false for the stores
## (they use the test map set in switchToNext()).
func shouldGetInfoFromMain():
	return (mode != Values.CARDSTORE and mode != Values.WEAPONSTORE
		and mode != Values.CHURCH and mode != Values.INN) and shouldGetInfoFromMain_


## Executes a typed cheat (InputKeyBoardManager, Shift+0 ... Enter):
##   "trigger <name> <value>" sets the database status name to value.
##   "open" opens all the roads on the world map.
static func doCheat(cheat):
	var commands: Array = J.split(cheat, " ")
	if commands != null and commands.size() > 0:
		if commands[0] == "trigger":
			if commands.size() < 3:
				push_error("Cheater.doCheat: usage: trigger <name> <value>")
				return
			Database.addStatus(commands[1], J.parseInt(commands[2]))
		elif cheat == "open":
			Database.openAllRoads()
			var gm = Organizer.getOrganizer().getCurrentMode()
			if gm is Landscape:
				var l = gm
				# l.openRoads()
