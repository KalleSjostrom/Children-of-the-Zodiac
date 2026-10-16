class_name StringTokenizer
extends RefCounted
## Port of java.util.StringTokenizer (delimiters are not returned as tokens).

var _tokens: PackedStringArray = []
var _pos := 0


func _init(s: String = "", delimiters: String = " \t\n\r\f") -> void:
	var current := ""
	for i in s.length():
		var c := s[i]
		if delimiters.contains(c):
			if current != "":
				_tokens.append(current)
				current = ""
		else:
			current += c
	if current != "":
		_tokens.append(current)


func hasMoreTokens() -> bool:
	return _pos < _tokens.size()


func hasMoreElements() -> bool:
	return hasMoreTokens()


func nextToken() -> String:
	if _pos >= _tokens.size():
		push_error("StringTokenizer: NoSuchElementException")
		return ""
	var t := _tokens[_pos]
	_pos += 1
	return t


func nextElement() -> String:
	return nextToken()


func countTokens() -> int:
	return _tokens.size() - _pos
