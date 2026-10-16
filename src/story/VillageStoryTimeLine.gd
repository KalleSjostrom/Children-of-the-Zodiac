class_name VillageStoryTimeLine
extends AbstractTimeLine
## Port of story.VillageStoryTimeLine: the time line used in village story
## modes. All the sprites are turned into actors and their instructions are
## executed and updated by the time line.
##
## Port notes:
##  - init(story): the skeleton's merged signature init(name, lab, hinders);
##    only the first argument (the VillageStory) is used.
##  - draw(g) / drawTop(g): the extra skeleton parameters are unused.
##  - The Java thread creating an OggStreamer in setMusicMode runs
##    synchronously. Semaphores are removed.
##  - Arrays.sort (stable) is emulated with a stable sort on compareTo.
##  - The field centerScreen is centerScreen_, the field in is in_.

const VILLAGE_MODE = 0
const BACKFLASH_MODE = 1
const STORY_MODE = 2
const TRANSLUCENT_MODE_OVER_ACTOR = 3
const COVERALL_MODE = 4
const TRANSLUCENT_MODE_UNDER_ACTOR = 5
var members = []
var dialogs = null
var removedVillagers = []
var textList = null
var scrollableText = null
var positions = null
var infoList = null
var dialog = null
var currentText = null
var story = null
var elements = null
var background = null
var currentImage = null
var oggPlayers = null
var crossAccess = null
var imageMode: int = -1
var currentDialog: int = -1
var showing = null
var playersAdded: bool = false
var centerScreen_: bool = true
var centerScreenIndex: int = -1
var fromVillage: bool = false
var scaling: bool = false
var velocity: float = 0.0
var scale: float = 1.0
var scale2: float = 0.0
var x: int = 0
var timeStep: float = 0.0
var in_: bool = false
var staticPos = null
var useStaticPos: bool = false
var bFadeTarget: float = 0.0
var bFadeSpeed: float = 0.0
var bFadeDown: bool = false
var bFadeUp: bool = false
var scrollText = null
var color = [1.0, 1.0, 1.0, 1.0]
var colorSpeed = [0.0, 0.0, 0.0, 0.0]
var village = null
var drawPause: bool = false

func _init(vsl = null, village = null) -> void:
	dialog = Dialog.getDialog()
	DefaultSprite.resetStatic()
	infoList = vsl.getInfo()
	textList = vsl.getTextList()
	scrollableText = vsl.getScrollableText()
	positions = vsl.getPoses()
	fromVillage = vsl.getFromVillage()
	dialogs = vsl.getDialogs()
	drawPause = vsl.shouldPauseDrawings()
	setTimeLineEvents(vsl)
	showing = vsl.getWhoseShowing()
	nextInitTime = dialogs[0].getStartTime() if dialogs.size() > 0 else 0
	nextStopTime = dialogs[0].getStopTime() if dialogs.size() > 0 else 0
	background = village.getBackground()

	setMode(WAITING_FOR_ACTORS)
	fadein = false
	fadeout = false
	fadeValue = 1
	var music = infoList.get(TimeLineEvent.MUSICS)
	if music != null and music.size() > 0:
		oggPlayers = J.array(infoList.get(TimeLineEvent.MUSICS).size(), null)

## Stable sort of an array of objects with compareTo (like Arrays.sort).
static func _stableSort(arr: Array) -> void:
	var decorated := []
	for i in range(arr.size()):
		decorated.append([arr[i], i])
	decorated.sort_custom(func(a, b):
		var c: int = a[0].compareTo(b[0])
		if c != 0:
			return c < 0
		return a[1] < b[1])
	for i in range(arr.size()):
		arr[i] = decorated[i][0]

func setTimeLineEvents(vsl):
	info = vsl.getTimeLineEvents()
	var evs: Array = info.duplicate()
	_stableSort(evs)
	info.clear()
	info.append_array(evs)

## Java: init(VillageStory story).
func init(name, lab = null, hinders = null):
	self.story = name
	elements = J.array(members.size(), null)
	for i in range(members.size()):
		elements[i] = SortingElement.new(members[i].getPos()[Values.Y], i)

func setParty(player, p_fromVillage):
	var pmlist = player.getPartyMembers()
	var size: int = members.size()
	var list = Load.getCharacters()
	if pmlist.size() < list.size():
		for c in list:
			var found: bool = false
			var name: String = c.getName()
			var i: int = 0
			while i < pmlist.size() and not found:
				found = pmlist[i].getName().to_lower() == name.to_lower()
				i += 1
			if not found:
				pmlist.append(PartyMember.new(name))
	for i in range(pmlist.size()):
		var pm = pmlist[i]
		pm.setPos(pm.getPosAsFloatArray())
		var actors = infoList.get(TimeLineEvent.ACTORS)
		var found: bool = false
		var j: int = 0
		while j < actors.size() and not found:
			found = actors[j] == pm.getName()
			j += 1
		if found:
			var a := Actor.new(pm)
			var pos = positions.get(pm.getName())
			if pos != null:
				if self.fromVillage:
					var newPos := [0.0, 0.0]
					newPos[Values.X] = float(pos[Values.X])
					newPos[Values.Y] = float(pos[Values.Y])
					a.setPos(newPos)
				elif not p_fromVillage:
					var newPos := [0.0, 0.0]
					newPos[Values.X] = float(pos[Values.X] + 40)
					newPos[Values.Y] = float(pos[Values.Y] + 40)
					a.setPos(newPos)
			if centerScreenIndex == -1:
				centerScreenIndex = members.size()
			members.append(a)
	for i in range(members.size()):
		var a = members[i]
		var name = a.getName()
		var pos = positions.get(name)
		a.initStartLocation(pos, members)
	playersAdded = members.size() > size
	var pos = positions.get("Background")
	if pos != null:
		background.setPos(0, -pos[0])
		background.setPos(1, -pos[1])
	elif playersAdded:
		background.centerAround(getPos(centerScreenIndex))

func addExtras():
	var actors = infoList.get(TimeLineEvent.ACTORS)
	for i in range(actors.size()):
		if actors[i].contains("Extras"):
			var name: String = actors[i]
			var p = positions.get(name)
			var n := J.split(name, "Extras")
			var images: int = 16
			if n.size() > 1:
				images = J.parseInt(n[1])
			name = n[0]
			if name.contains("Prop"):
				name = name.replace("Prop", "")
			var a := Actor.new(name, images)
			if p != null:
				a.setPos(p)
			members.append(a)

func addParticleSystem():
	var actors = infoList.get(TimeLineEvent.ACTORS)
	for i in range(actors.size()):
		if actors[i].contains("System"):
			var name: String = actors[i]
			var sl = SystemLoader.getLoader()
			var system = sl.buildSystem(Organizer.convert(name))
			var p = positions.get(name)
			var a := Actor.new(system[0])
			if p != null:
				a.setPos(p)
			members.append(a)

## villagers: Java HashMap<Integer, Sprite> (Dictionary).
func setVillagers(villagers):
	var remove := []
	var actors = infoList.get(TimeLineEvent.ACTORS)
	for i in range(actors.size()):
		var actorName: String = actors[i].replace("_", " ")
		for index in villagers.keys():
			var as_ = villagers[index]
			if as_ is Villager:
				var v = as_
				if actorName.begins_with(v.getName()):
					members.append(Actor.new(v))
					remove.append(index)
					break
	actors = infoList.get(TimeLineEvent.ACTORS)
	for index in villagers.keys():
		var as_ = villagers[index]
		if as_ is AnimatedObjects:
			var found: bool = false
			var i: int = 0
			while i < actors.size() and not found:
				found = actors[i] == "Anim"
				if found:
					J.removeAt(actors, i)
					members.append(Actor.new(as_))
					remove.append(index)
				i += 1
	for i in range(remove.size()):
		var removed = villagers.get(remove[i])
		villagers.erase(remove[i])
		removedVillagers.append(removed)
	addExtras()
	addParticleSystem()

func update(elapsedTime: float):
	var et: int = int(elapsedTime)
	if scrollText != null:
		scrollText.update(et)
	if doneMode != ALL_DONE:
		super.update(et)
		if currentImage != null:
			currentImage.update()
		if centerScreen_:
			centerScreen(centerScreenIndex)
		var wait: bool = checkWait(et)
		if wait and compareMode(WAITING_FOR_ACTORS):
			setMode(NORMAL)
		elif doneMode == INPUT_DONE:
			var end: bool = not compareMode(WAITING_FOR_ACTORS)
			if end and centerScreen_:
				end = centerScreen(-1)
			if end:
				story.end(getPos(-1), removedVillagers, playersAdded)
				doneMode = ALL_DONE
			return
		background.update(et)
	if scaling:
		var t2: float = timeStep * timeStep
		if x <= timeStep:
			velocity = 4 * x * ((1.0 / timeStep) - (x / t2))
			var max_: float = 2 * timeStep - (4.0 / 3.0) * timeStep
			x += 1
			scale2 += velocity
			scale = scale2 / max_ + 1 if in_ else 2 - scale2 / max_
	if not drawPause:
		updateFadeValue()
		if currentText != null:
			currentText.updateFadeValue()

func setScaling(time, in_, useStaticPos, pos):
	scaling = true
	velocity = 0
	scale2 = 0
	x = 0
	timeStep = time / Values.LOGIC_INTERVAL
	staticPos = pos
	self.useStaticPos = useStaticPos
	self.in_ = in_

func executeCommand(info):
	var event = info
	var index: int = event.getInfo(TimeLineEvent.INDEX)
	var kind: int = event.getInfo(TimeLineEvent.KIND)
	match kind:
		TimeLineEvent.KIND_IMAGE:
			match event.getInfo(TimeLineEvent.INFO_IMAGE_MODE):
				TimeLineEvent.IMAGE_MODE_BACKFLASH:
					imageMode = BACKFLASH_MODE
				TimeLineEvent.IMAGE_MODE_TRANSLUCENT_UNDER_ACTOR:
					imageMode = TRANSLUCENT_MODE_UNDER_ACTOR
				TimeLineEvent.IMAGE_MODE_TRANSLUCENT_OVER_ACTOR:
					imageMode = TRANSLUCENT_MODE_OVER_ACTOR
				TimeLineEvent.IMAGE_MODE_COVERALL:
					imageMode = COVERALL_MODE
				TimeLineEvent.IMAGE_MODE_STORY:
					imageMode = STORY_MODE
			initImageKind(event, index)
		TimeLineEvent.KIND_TEXT:
			currentText = textList[index]
			currentText.checkFade(event)
			bFadeTarget = event.getInfo(TimeLineEvent.BACKGROUND_FADE_TARGET)
			bFadeTarget = 100.0 if bFadeTarget == 0 else bFadeTarget
			bFadeTarget /= 100
			if fadeValue < bFadeTarget:
				bFadeUp = true
				bFadeDown = false
				bFadeSpeed = .02
			else:
				bFadeUp = false
				bFadeDown = true
				bFadeSpeed = -.02
		TimeLineEvent.KIND_SCROLL_TEXT:
			scrollText = scrollableText
		TimeLineEvent.KIND_VILLAGE:
			imageMode = VILLAGE_MODE
			checkFade(event)
			if event.doesInfoExist(TimeLineEvent.TIME_OF_DAY):
				var time: int = event.getInfo(TimeLineEvent.TIME_OF_DAY)
				if time != -1:
					pass # Values.DAY = time == 1;
			if event.getInfo(TimeLineEvent.SHOW_CURRENT_IMAGE) == 0:
				currentImage = null
		TimeLineEvent.KIND_MUSIC:
			initMusicKind(event, index)
		TimeLineEvent.KIND_MUSIC_OVERWRITE_VILLAGE_MUSIC:
			story.setOggplayerAsVillageCurrent(oggPlayers[index - 1])
		TimeLineEvent.KIND_MUSIC_OVERWRITE_STORY_MUSIC:
			story.setOggplayerAsStoryCurrent(oggPlayers[index - 1])
		TimeLineEvent.KIND_END_SEQ:
			playersAdded = false
			# Java falls through to KIND_END.
			doneMode = TIME_LINE_DONE
			setMode(WAITING_FOR_INPUT)
			updateCross()
		TimeLineEvent.KIND_END:
			doneMode = TIME_LINE_DONE
			setMode(WAITING_FOR_INPUT)
			updateCross()
		TimeLineEvent.KIND_TRIGGER:
			var list = infoList.get(TimeLineEvent.TRIGGERS)
			var key: String = list[index]
			var value: int = event.getInfo(TimeLineEvent.TRIGGER_VALUE)
			Database.addStatus(key, value)
			var found: bool = false
			var i: int = 0
			while i < members.size() and not found:
				var name = members[i].getName()
				if name != null and name == key:
					found = true
					members[i].updateDialog(value)
				i += 1
			if not found:
				var gm = Organizer.getOrganizer().getPreviousMode()
				found = false
				for s in removedVillagers:
					if s is Villager:
						var v = s
						if v.getName().to_lower() == key.to_lower():
							v.updateDialog(value)
							found = true
				if not found:
					if gm is Village:
						var v = gm
						v.updateVillagerDialog(key, value)
		TimeLineEvent.KIND_TRIGGER_INN:
			var list = infoList.get(TimeLineEvent.TRIGGERS)
			var innName: String = list[index]
			var value: int = event.getInfo(TimeLineEvent.TRIGGER_VALUE)
			var sequenceName: String = list[value]
			Database.storeTriggers(innName, sequenceName)
		TimeLineEvent.KIND_SCREEN_MOVE_DIST:
			var distance: int = event.getInfo(TimeLineEvent.MOVE_DISTANCE)
			var direction: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			direction = Values.getCounterAngle(direction)
			background.move(distance, direction, duration)
		TimeLineEvent.KIND_SCREEN_MOVE_TO:
			var mx: int = -event.getInfo(TimeLineEvent.MOVE_X)
			var my: int = -event.getInfo(TimeLineEvent.MOVE_Y)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			background.moveTo(mx, my, int(duration))
		TimeLineEvent.KIND_SCREEN_MOVE_POS:
			var p = [0.0, 0.0]
			p[Values.X] = float(event.getInfo(TimeLineEvent.MOVE_X))
			p[Values.Y] = float(event.getInfo(TimeLineEvent.MOVE_Y))
			if p[0] == -1 and p[1] == -1:
				p = members[event.getInfo(TimeLineEvent.TARGET)].getPos()
				background.centerAround(p)
			else:
				background.setPos(Values.X, int(-p[Values.X]))
				background.setPos(Values.Y, int(-p[Values.Y]))
		TimeLineEvent.KIND_SCREEN_MOVE_STOP:
			background.stopScreen()
		TimeLineEvent.KIND_SCREEN_MOVE_GO:
			var acceleration: float = event.getInfo(TimeLineEvent.MOVE_ACCELERATION) / 1000000.0
			var distance: int = event.getInfo(TimeLineEvent.MOVE_DISTANCE)
			var direction: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			direction = Values.getCounterAngle(direction)
			background.moveScreen(acceleration, distance, duration, direction)
		TimeLineEvent.KIND_SCREEN_MOVE_CENTER:
			centerScreenIndex = index
			centerScreen_ = event.getInfo(TimeLineEvent.CENTER_SCREEN) == 1
		TimeLineEvent.KIND_SCREEN_ZOOM:
			var zoomIn: bool = event.getInfo(TimeLineEvent.SCREEN_ZOOM_IN) == 1
			var time: int = event.getInfo(TimeLineEvent.SCREEN_ZOOM_TIME)
			var sPos: bool = event.getInfo(TimeLineEvent.SCREEN_ZOOM_USE_STATIC_POS) == 1
			var p = [0.0, 0.0]
			p[Values.X] = float(event.getInfo(TimeLineEvent.POS_X))
			p[Values.Y] = float(event.getInfo(TimeLineEvent.POS_Y))
			setScaling(time, zoomIn, sPos, p)
		TimeLineEvent.KIND_ACTOR_SHOW:
			showing[index] = true
			var p = [0.0, 0.0]
			p[Values.X] = float(event.getInfo(TimeLineEvent.MOVE_X))
			p[Values.Y] = float(event.getInfo(TimeLineEvent.MOVE_Y))
			var actor = members[index]
			if not (p[0] == -1 and p[1] == -1):
				actor.setPos(p)
			var dir: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			if dir != -1:
				actor.setMoving(true)
				actor.stop(dir)
		TimeLineEvent.KIND_ACTOR_HIDE:
			showing[index] = false
		TimeLineEvent.KIND_ACTOR_MOVE_TO_RELATIVE:
			var mx: int = event.getInfo(TimeLineEvent.MOVE_X)
			var my: int = event.getInfo(TimeLineEvent.MOVE_Y)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			members[index].moveToRel(mx, my, duration)
		TimeLineEvent.KIND_ACTOR_MOVE_DIST:
			var direction: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			var faceDirection: int = event.getInfo(TimeLineEvent.MOVE_ACTOR_FACE_DIRECTION)
			var distance: int = event.getInfo(TimeLineEvent.MOVE_DISTANCE)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			members[index].move(distance, direction, faceDirection, duration)
		TimeLineEvent.KIND_ACTOR_MOVE_TO:
			var mx: int = event.getInfo(TimeLineEvent.MOVE_X)
			var my: int = event.getInfo(TimeLineEvent.MOVE_Y)
			if mx == -1:
				var target: int = event.getInfo(TimeLineEvent.TARGET)
				var posf = members[target].getPos()
				mx = int(posf[Values.X])
				my = int(posf[Values.Y])
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			if duration == -1:
				var speed: float = event.getInfo(TimeLineEvent.MOVE_SPEED) / 10000.0
				members[index].moveToWithSpeed(mx, my, speed)
			else:
				members[index].moveTo(mx, my, duration)
		TimeLineEvent.KIND_ACTOR_MOVE_STOP:
			var direction: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			members[index].stop(direction)
		TimeLineEvent.KIND_ACTOR_DEACCELERATE:
			members[index].deaccelerateActor()
		TimeLineEvent.KIND_ACTOR_LOOK_TO:
			var mx: int = event.getInfo(TimeLineEvent.POS_X)
			var my: int = event.getInfo(TimeLineEvent.POS_Y)
			if mx == -1:
				var target: int = event.getInfo(TimeLineEvent.TARGET)
				var posf = members[target].getPos()
				mx = int(posf[Values.X])
				my = int(posf[Values.Y])
			members[index].lookTo(mx, my)
		TimeLineEvent.KIND_ACTOR_QUEUE_MOVE:
			var distance: int = event.getInfo(TimeLineEvent.MOVE_DISTANCE)
			var direction: int = event.getInfo(TimeLineEvent.MOVE_DIRECTION)
			var duration: float = event.getInfo(TimeLineEvent.MOVE_DURATION)
			members[index].queueMove(distance, direction, duration)
		TimeLineEvent.KIND_ACTOR_ANIMATION:
			var list = infoList.get(TimeLineEvent.ANIMATIONS)
			var name: String = list[index]
			name = Values.AnimationImages + name + ".png"
			var actorIndex: int = event.getInfo(TimeLineEvent.TARGET)
			var actor = members[actorIndex]
			var pos: int = event.getInfo(TimeLineEvent.ANIMATION_INDEX)
			actor.addAnimation(name, pos)
			actor.animate(pos)
		TimeLineEvent.KIND_ACTOR_EMOTION:
			var emotion: int = event.getInfo(TimeLineEvent.EMOTION)
			var show: bool = event.getInfo(TimeLineEvent.EMOTION_SHOW) == 1
			var shake: bool = event.getInfo(TimeLineEvent.EMOTION_SHAKE) == 1
			members[index].setEmotion(show, emotion, shake)
		TimeLineEvent.KIND_ACTOR_CONTROLL:
			members[index].setControll(event.getInfo(TimeLineEvent.ACTOR_CONTROLL) == 1)
		TimeLineEvent.KIND_ACTOR_RESET_VILLAGER:
			members[index].resetVillager()
		TimeLineEvent.KIND_SET_COLOR:
			color[index] = event.getInfo(TimeLineEvent.COLOR) / 10000.0
			colorSpeed[index] = event.getInfo(TimeLineEvent.COLOR_SPEED) / 10000.0
		TimeLineEvent.KIND_SET_VILLAGE_BACKGROUND:
			var images = infoList.get(TimeLineEvent.IMAGES)
			var newBack = null if index < 0 else images[index]
			village.setBackground(newBack)
		TimeLineEvent.KIND_SET_FADE_IMAGE:
			Graphics.setFadeImage(event.getInfo(TimeLineEvent.FADE_IMAGE))
		TimeLineEvent.KIND_SET_DRAW_PAUSE:
			drawPause = index == 1
		TimeLineEvent.KIND_REMOVE:
			J.removeAt(removedVillagers, index)
		TimeLineEvent.KIND_LEVEL_UP:
			var chars = Load.getCharacters()
			for i in range(chars.size()):
				chars[i].levelUp()
		TimeLineEvent.KIND_CURE_ALL:
			var chars = Load.getCharacters()
			for i in range(chars.size()):
				chars[i].cureFromDead()
				chars[i].curePercent(1)
		TimeLineEvent.KIND_ADD_SPRITE_ON_BOTTOM_LAYER:
			var s = members[index].getSprite()
			if s is DefaultSprite:
				s.placeOnBottomLevel()
				village.addSprite(s)
		TimeLineEvent.KIND_ADD_SPRITE_ON_TOP_LAYER:
			var s = members[index].getSprite()
			if s is DefaultSprite:
				s.placeOnTopLevel()
				village.addSprite(s)
		TimeLineEvent.KIND_FADE_PARTICLE_SYSTEM:
			var list = infoList.get(TimeLineEvent.PARTICLE_SYSTEMS)
			var name: String = list[index]
			var ps = village.getParticleSystem(name)
			var fade: bool = event.isFade()
			var increase: bool = event.getType() == TimeLineEvent.TYPE_FADE_OUT
			var speed: float = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_SPEED) / 10000.0
			var swiftness: float = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_SWIFTNESS) / 10000.0
			var cutoff: float = event.getInfo(TimeLineEvent.PARTICLE_SYS_FADE_CUTOFF) / 10000.0
			ps.getEmitter().setFade(fade, speed, swiftness, increase, cutoff)

func initMusicKind(event, index):
	var music = infoList.get(TimeLineEvent.MUSICS)
	var fade: int = 0
	if event.isFade():
		var fadeIn_: bool = event.getType() == TimeLineEvent.TYPE_FADE_IN
		fade = SoundValues.FADE_IN if fadeIn_ else SoundValues.FADE_OUT
	var time: int = event.getInfo(TimeLineEvent.FADE_TIME)
	var playMode: int = event.getInfo(TimeLineEvent.PLAY_MODE)
	var fadeTarget: int = event.getInfo(TimeLineEvent.FADE_TARGET)
	fadeTarget = 100 if fadeTarget == 0 else fadeTarget
	if index == 0:
		story.setMusicMode(fade, time, (fadeTarget / 100.0) * Values.MAX_VOLUME, playMode)
	else:
		var songName: String = music[index - 1]
		setMusicMode(songName, fade, time, playMode, index - 1)

## Java: private setMusicMode(songName, fade, time, playMode, index).
## The Java loading thread is run synchronously.
func setMusicMode(songName, fade, time = null, playMode = null, index = null):
	if songName.ends_with(".wav"):
		SoundPlayer.playSound("Story/" + songName)
	else:
		if oggPlayers[index] == null:
			oggPlayers[index] = OggStreamer.new(songName)
			oggPlayers[index].play(false, playMode == SoundValues.NORMAL or playMode == SoundValues.RESUME_PLAY)
			oggPlayers[index].fade(fade, time, SoundValues.ALL_THE_WAY, playMode)
		else:
			oggPlayers[index].fade(fade, time, SoundValues.allTheWay(fade), playMode)

func initImageKind(info, index):
	checkFade(info)
	var images = infoList.get(TimeLineEvent.IMAGES)
	var name: String = images[index]
	var found: bool = false
	if currentImage != null:
		if name == currentImage.name:
			currentImage.init(info)
			found = true
	if not found:
		currentImage = ImageSettings.new(name, info)
		currentImage.timeLine = self

func checkWait(time):
	var wait: bool = true
	for i in range(members.size()):
		if showing[i]:
			var actor = members[i]
			actor.update(time)
			if wait:
				wait = actor.isWaiting()
	return wait

func setNextStartTime():
	currentDialog += 1
	if currentDialog < dialogs.size():
		dialog.setDS(dialogs[currentDialog].getSequense(), null)
		setMode(DIALOG)
		nextStopTime = dialogs[currentDialog].getStopTime()
		if currentDialog + 1 < dialogs.size():
			nextInitTime = dialogs[currentDialog + 1].getStartTime()
	else:
		nextInitTime = J.INT_MAX

func setNextStopTime():
	if currentDialog + 1 < dialogs.size():
		nextStopTime = dialogs[currentDialog + 1].getStopTime()
		if compareMode(DIALOG):
			setMode(WAITING_FOR_INPUT)
	else:
		if compareMode(DIALOG):
			setMode(WAITING_FOR_INPUT)
		nextStopTime = J.INT_MAX

func draw(g, alpha = null):
	updateFadeValue()
	if currentText != null:
		currentText.updateFadeValue()
	if scaling and useStaticPos:
		g.translate(staticPos[Values.X], staticPos[Values.Y], 0)
		g.scale(scale)
		g.translate(-staticPos[Values.X], -staticPos[Values.Y], 0)
	if not drawPause:
		for i in range(color.size()):
			if colorSpeed[i] < 0 and color[i] > 0:
				color[i] += colorSpeed[i]
			elif colorSpeed[i] > 0 and color[i] < 1:
				color[i] += colorSpeed[i]

		g.setFadeColor(color[0], color[1], color[2], color[3])
		village.drawBottom(g)
		if imageMode == BACKFLASH_MODE:
			# Java: currentImage.equals("black") compares an ImageSettings
			# with a String and is therefore always false.
			if currentImage != null:
				currentImage.draw(g)
		var bx: int = int(background.getPos()[Values.X])
		var by: int = int(background.getPos()[Values.Y])

		for i in range(members.size()):
			var actor = members[i]
			if actor.getSprite() is DefaultSprite:
				elements[i].setYpos(actor.getSprite().getY())
			else:
				elements[i].setYpos(actor.getPos()[Values.Y])
			elements[i].setIndex(i)
		if imageMode == TRANSLUCENT_MODE_UNDER_ACTOR:
			g.setColor(1, 1, 1, fadeValue)
			currentImage.draw(g)
			g.setColor(1)
		_stableSort(elements)
		for i in range(elements.size()):
			var index: int = elements[i].getIndex()
			if showing[index]:
				var actor = members[index]
				actor.draw(g, bx, by)

		if imageMode != BACKFLASH_MODE:
			village.drawTop(g, null)
		for i in range(members.size()):
			members[i].drawEmotion(g)
		drawTop(g)

func drawTop(g, sprites = null):
	if imageMode == COVERALL_MODE:
		currentImage.draw(g)
	if imageMode == STORY_MODE:
		currentImage.draw(g)
		currentImage.drawTextBack(g)
	g.setFontSize(30)
	if imageMode == VILLAGE_MODE and currentImage != null:
		g.setColor(1)
		currentImage.draw(g)
		g.setColor(1)
	if compareMode(DIALOG) or compareMode(WAITING_FOR_INPUT):
		g.loadIdentity()
		dialog.draw(g)
	if fadeValue < 1 and imageMode != TRANSLUCENT_MODE_OVER_ACTOR \
			and imageMode != TRANSLUCENT_MODE_UNDER_ACTOR:
		g.fadeOldSchool(fadeValue)
	if currentText != null:
		currentText.draw(g)
	if scrollText != null:
		scrollText.draw(g)
	if imageMode == TRANSLUCENT_MODE_OVER_ACTOR:
		g.setColor(1, 1, 1, fadeValue)
		currentImage.draw(g)
		g.setColor(1)

func centerScreen(index):
	var p = getPos(index)
	if p != null:
		var done := [false, false]
		var hx: int = int(Values.ORIGINAL_RESOLUTION[Values.X] / 2)
		var hy: int = int(Values.ORIGINAL_RESOLUTION[Values.Y] / 2)
		for i in range(2):
			var gubbe: int = int(p[i] + background.getPos()[i])
			var half: int = hx if i == Values.X else hy
			if gubbe > half and not background.checkUpRight(i):
				background.move(i, -1)
			elif gubbe < half and not background.checkDownLeft(i):
				background.move(i, 1)
			else:
				done[i] = true
		return done[0] and done[1]
	return true

func getPos(index):
	if index == -1:
		var size: int = Load.getCharacters().size()
		index = members.size() - size
	if index >= 0:
		var a = members[index]
		if a != null:
			return a.getPos()
	return null

func crossPressed():
	if compareMode(DIALOG) or compareMode(WAITING_FOR_INPUT):
		if dialog.isFinished():
			updateCross()

func updateCross():
	acquire()
	if compareMode(WAITING_FOR_INPUT):
		if doneMode == TIME_LINE_DONE:
			if playersAdded:
				var pos = getPos(-1)
				var charName: String
				var a
				var characters = Load.getCharacters()
				for i in range(members.size()):
					var found: bool = false
					a = members[i]
					for j in range(characters.size()):
						charName = characters[j].getName()
						if charName == a.getName():
							found = true
							a.createStopInstructions(pos)
					if not found:
						push_warning("Couldn't find character " + str(a.getName()))
			setMode(WAITING_FOR_ACTORS)
			doneMode = INPUT_DONE
		else:
			setMode(NORMAL)
	elif compareMode(DIALOG):
		setMode(NORMAL)

## Java: acquires the cross press semaphore (not needed, single threaded).
func acquire():
	pass

func killOggPlayer():
	if oggPlayers != null:
		for i in range(oggPlayers.size()):
			if oggPlayers[i] != null:
				oggPlayers[i].exit()

func setVillage(village):
	self.village = village


class ImageSettings extends RefCounted:
	var scrollingRight: bool = false
	var scrollingDown: bool = false
	var scroll: float = 0.0
	var scrollDownMax: float = 0.0
	var scrollDownMin: float = 0.0
	var offsetx: float = 0.0
	var offsety: float = 0.0
	var zoom: float = 1.0
	var size: float = 1.0
	var name: String = ""
	var width: int = 0
	var height: int = 0
	var scrollSpeed: float = 0.0
	var pos = null
	## The outer VillageStoryTimeLine (Java inner class access).
	var timeLine = null

	func _init(name = null, info = null) -> void:
		self.name = name
		init(info)

	func init(info):
		var tSize: int = info.getInfo(TimeLineEvent.SIZE)
		if tSize != 0:
			size = tSize / 100.0
		var imageKind: int = info.getInfo(TimeLineEvent.INFO_IMAGE_SCROLL_MODE)
		pos = [info.getInfo(TimeLineEvent.MOVE_X), info.getInfo(TimeLineEvent.MOVE_Y)]
		var tex = ImageHandler.getTexture(name)
		scrollSpeed = info.getInfo(TimeLineEvent.INFO_IMAGE_SCROLL_SPEED) / 10000.0
		var tempScroll: float = scroll
		width = int(tex.getWidth())
		height = int(tex.getHeight() * size)
		match imageKind:
			TimeLineEvent.IMAGE_SCROLL_MODE_ZOOM:
				zoom = 2.0
				offsetx = -270
				offsety = -80
			TimeLineEvent.IMAGE_SCROLL_MODE_SCROLL_RIGHT:
				scrollingRight = true
				scrollingDown = false
			TimeLineEvent.IMAGE_SCROLL_MODE_NORMAL:
				scrollingRight = false
				scrollingDown = false
			TimeLineEvent.IMAGE_SCROLL_MODE_SCROLL_DOWN:
				scroll = 0
				scrollDownMax = absf(height) - absf(Values.WIDE_SCREEN_HEIGHT)
				scrollingRight = false
				scrollingDown = true
			TimeLineEvent.PAUSE:
				scroll = tempScroll

	func draw(g):
		g.drawImage(name, pos[0], pos[1], size)

	func drawTextBack(g):
		g.loadIdentity()
		g.drawImage(Graphics.textBack, 0, 576, 1)

	func update():
		zoom = 1.0 if zoom <= 1 else zoom - .0007 * zoom
		if scrollingRight:
			scroll -= scrollSpeed
		elif timeLine.currentImage.scrollingDown:
			scroll = minf(scrollDownMax, scroll + scrollSpeed)
		offsetx += 0.0 if offsetx >= 0 else .3
		offsety += 0.0 if offsety >= 0 else .084375
