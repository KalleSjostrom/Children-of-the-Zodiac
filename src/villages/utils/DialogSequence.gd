class_name DialogSequence
extends RefCounted
## Port of villages.utils.DialogSequence: one step (two lines of text) in a
## dialog.

var firstLine = null
var secondLine = null
var name = null
var alternatives = null
var question: bool = false
var first: bool = true
var whisper: bool = false
var end: bool = false
var inputQ: bool = false
var gift = null
var triggers = null
var triggerAdds = null
var beforeTriggers = null
var imageName = null
var image: bool = false
var questionNr: int = 0
var prices = [0, 0, 0, 0]
var takeName = null
var takeAmount: int = 0


## Java overloads:
##   DialogSequence(String n, String fl, String sl, boolean f, boolean q, boolean w)
##   DialogSequence(String n, String fl, String sl, boolean f, boolean w)
##   DialogSequence(String fl, String sl)
##   DialogSequence(String[] dialog)
func _init(n = null, fl = null, sl = null, f = null, q = null, w = null) -> void:
	if n is Array:
		var dialog: Array = n
		var i := 0
		if dialog.size() > 2:
			name = dialog[i]
			i += 1
		firstLine = dialog[i]
		i += 1
		secondLine = dialog[i]
	elif f == null:
		firstLine = n
		secondLine = fl
	else:
		var question_: bool = false
		var whisper_: bool
		if w == null:
			whisper_ = bool(q)
		else:
			question_ = bool(q)
			whisper_ = bool(w)
		name = String(n).strip_edges()
		firstLine = String(fl).strip_edges()
		secondLine = String(sl).strip_edges()
		first = bool(f)
		question = question_
		whisper = whisper_


func getName():
	return name


## Sets the list of alternatives (used when a villager asks a question).
func setAlternatives(alt):
	alternatives = alt


func setEsnd(p_end):
	end = p_end


func _to_string():
	return str(firstLine) + "\n" + str(secondLine)


func setGift(p_gift):
	gift = p_gift


func getGift():
	return gift


func setTriggers(p_triggers):
	triggers = p_triggers


func getTriggers():
	return triggers


func setTriggerAdds(t):
	triggerAdds = t


func getTriggerAdds():
	return triggerAdds


func setBeforeTriggers(t):
	beforeTriggers = t


func getBeforeTriggers():
	return beforeTriggers


func setQuestionNr(p_questionNr):
	questionNr = p_questionNr


func setInputQ(b):
	inputQ = b


func isInputQ():
	return inputQ


func setImage(p_imageName):
	image = true
	imageName = p_imageName


func getImage():
	return imageName


func getPrices():
	return prices


func setTake(p_takeName, p_takeAmount):
	takeName = p_takeName
	takeAmount = p_takeAmount
