class_name VillageStory
extends GameMode
## Port of villages.villageStory.VillageStory: manages the story sequences
## that take place in the villages. init(info) takes the info map (the extra
## parameters of the merged skeleton signature are unused).

var village = null
var timeLine = null

func init(name, lab = null, hinders = null):
	var info = name
	checkPlayer()
	var vsl := VillageStoryLoader.new()
	vsl.parseFile(str(info.get("map")) + str(info.get("name")))
	var gm = Organizer.getOrganizer().getPreviousMode()
	var fromVillage: bool = gm is Village
	village = null
	if not fromVillage:
		fromVillage = gm is VillageStory and vsl.getPassVillage()
		if fromVillage:
			village = gm.village
	if village == null:
		if fromVillage:
			village = gm
			var n = vsl.newVillageInfo().get("name")
			fromVillage = village.getVillageFolderName().begins_with(n)
			if fromVillage:
				fadein = false
				fadeValue = 1
		if not fromVillage:
			village = Village.new()
			var newInfo = vsl.newVillageInfo()
			var status = newInfo.get("status")
			if status != null:
				var s: int = J.parseInt(status)
				Database.addStatus(newInfo.get("name"), s)
			ImageHandler.setGameMode(Values.VILLAGE)
			village.init(newInfo)
			village.setReady()
			# Delete previous game mode!!
			Organizer.getOrganizer().overwritePreviousMode(village)
			ImageHandler.setGameMode(Values.VILLAGE_STORY)
			fadeValue = J.parseInt(newInfo.get("fadeValue"))
	initGameMode(info, Values.DETECT_INIT)
	timeLine = VillageStoryTimeLine.new(vsl, village)
	timeLine.setVillagers(village.getVillagers())
	village.updateSpriteList()
	timeLine.setParty(village.getPlayer(), fromVillage)
	timeLine.setVillage(village)
	timeLine.init(self)

	logicLoading = false

func setOggplayerAsVillageCurrent(player):
	village.oggPlayer = player
	village.music = player.getName()

func setOggplayerAsStoryCurrent(player):
	oggPlayer = player
	music = player.getName()

func checkPlayer():
	var chars = Load.getCharacters()
	var c
	for i in range(chars.size()):
		c = chars[i]
		if not c.isAlive():
			c.cureFromDead()
			c.cure(1)

func update(elapsedTime: float):
	checkGameInput()
	timeLine.update(int(elapsedTime))
	village.checkVillagers(int(elapsedTime))
	super.update(elapsedTime)

func checkGameInput():
	if gameActions[CROSS].isPressed():
		timeLine.crossPressed()
	elif gameActions[CIRCLE].isPressed():
		pass # switchGameMode(Values.SWITCH_BACK);
	elif gameActions[START].isPressed():
		exit(Values.EXIT)
	elif gameActions[UP].isPressed():
		pass
	elif gameActions[DOWN].isPressed():
		pass

func killOggPlayer():
	super.killOggPlayer()
	if village != null:
		village.killOggPlayer()
	if timeLine != null:
		timeLine.killOggPlayer()

func draw(g, alpha = null):
	g.setColor(1)
	timeLine.draw(g)
	super.draw(g)

func end(pos, removedVillagers, playersAdded):
	var gm = Organizer.getOrganizer().getPreviousMode()
	var v = null
	if gm is Village:
		v = gm
	elif gm is VillageStory:
		v = gm.village
		Organizer.getOrganizer().overwritePreviousMode(v)

	if playersAdded:
		v.initFromStory(pos, removedVillagers, nextPlace)
		var switchMusic: bool = infoMap.get("music") != null and infoMap.get("music") != "continue"
		ImageHandler.setGameMode(Values.VILLAGE)
		# super.exit(Values.SWITCH_BACK); // This results in the music and graphics fading in stories such as Alaresnode1.seq
		switchGameMode(Values.SWITCH_BACK, switchMusic, false)
	else:
		v.addOnlyVillagers(removedVillagers)
		v.exit()
		super.exit(Values.LABYRINTH)

func finishOff():
	pass # ImageHandler.clearList(Values.VILLAGE_STORY);
