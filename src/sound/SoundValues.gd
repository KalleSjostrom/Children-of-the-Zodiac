class_name SoundValues
extends RefCounted
## Port of sound.SoundValues.

const FAST := 1500
const SLOW := 2500

const FADE_OUT := -1
const FADE_IN := 1
const ALL_THE_WAY := Values.MAX_VOLUME
const HALF := 0.6 * Values.MAX_VOLUME

const NORMAL := -1
const RESUME_PLAY := 0
const PAUSE := 1
const KILL_MUSIC_ON_FADE_DOWN := 2


static func allTheWay(fade: int) -> float:
	var fadelength := ALL_THE_WAY
	if fade == FADE_OUT:
		fadelength = ALL_THE_WAY - fadelength
	return fadelength
