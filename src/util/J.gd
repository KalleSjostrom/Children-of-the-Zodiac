class_name J
extends RefCounted
## Java compatibility helpers used throughout the port.
##
## The original game was written in Java. These static helpers reproduce the
## semantics of the Java standard library calls the game relies on, so the
## ported code can stay close to the original logic.

static var _regex_cache := {}
static var _rng := RandomNumberGenerator.new()
static var _rng_seeded := false


static func _rand() -> RandomNumberGenerator:
	if not _rng_seeded:
		_rng.randomize()
		_rng_seeded = true
	return _rng


## Java's String.split(regex[, limit]): regex based, and trailing empty strings
## are removed when limit == 0.
static func split(s: String, pattern: String, limit: int = 0) -> Array:
	var re: RegEx = _regex_cache.get(pattern)
	if re == null:
		re = RegEx.new()
		re.compile(pattern)
		_regex_cache[pattern] = re
	var result: Array = []
	var start := 0
	var matches := re.search_all(s)
	for m in matches:
		if limit > 0 and result.size() == limit - 1:
			break
		var ms: int = m.get_start()
		var me: int = m.get_end()
		if me == 0 and ms == 0:
			continue # Java ignores a zero-width match at the beginning.
		result.append(s.substr(start, ms - start))
		start = me
	result.append(s.substr(start))
	if limit == 0:
		while result.size() > 1 and result[result.size() - 1] == "":
			result.pop_back()
		if result.size() == 1 and result[0] == "" and s == "":
			return [""]
	return result


## Java's String.substring(begin[, end]).
static func substring(s: String, begin: int, end: int = -1) -> String:
	if end < 0:
		return s.substr(begin)
	return s.substr(begin, end - begin)


## Java's Integer.parseInt. Tolerates surrounding whitespace and a leading '+'.
static func parseInt(s) -> int:
	var t := str(s).strip_edges()
	if t.begins_with("+"):
		t = t.substr(1)
	if not t.is_valid_int():
		push_error("J.parseInt: not an int: '%s'" % s)
		return int(t.to_float())
	return t.to_int()


## Java's Float.parseFloat / Double.parseDouble. Accepts "1f", ".5", "2.0d".
static func parseFloat(s) -> float:
	var t := str(s).strip_edges()
	if t.ends_with("f") or t.ends_with("F") or t.ends_with("d") or t.ends_with("D"):
		t = t.substr(0, t.length() - 1)
	if t.begins_with("+"):
		t = t.substr(1)
	if not t.is_valid_float() and not t.is_valid_int():
		push_error("J.parseFloat: not a float: '%s'" % s)
	return t.to_float()


## Java's Boolean.parseBoolean: true only for "true" (case insensitive).
static func parseBoolean(s) -> bool:
	return str(s).strip_edges().to_lower() == "true"


## Java's Math.round(float) -> int (rounds half up).
static func round(f: float) -> int:
	return int(floor(f + 0.5))


## Java's (int) cast: truncates towards zero.
static func toInt(f: float) -> int:
	return int(f)


## Java's Math.random(): [0, 1).
static func random() -> float:
	return _rand().randf()


## Java's Random.nextInt(n): [0, n).
static func randInt(n: int) -> int:
	if n <= 0:
		return 0
	return _rand().randi() % n


## Java's Random.nextFloat(): [0, 1).
static func randFloat() -> float:
	return _rand().randf()


## Java's Random.nextBoolean().
static func randBool() -> bool:
	return _rand().randi() % 2 == 0


## Java's Random.nextGaussian().
static func randGaussian() -> float:
	return _rand().randfn(0.0, 1.0)


## Creates a 2D array (Java new T[rows][cols]) filled with the given value.
static func array2d(rows: int, cols: int, value = null) -> Array:
	var a: Array = []
	a.resize(rows)
	for i in rows:
		var row: Array = []
		row.resize(cols)
		row.fill(value)
		a[i] = row
	return a


## Creates a 1D array (Java new T[n]) filled with the given value.
static func array(n: int, value = null) -> Array:
	var a: Array = []
	a.resize(n)
	a.fill(value)
	return a


## Java's System.arraycopy.
static func arraycopy(src: Array, src_pos: int, dest: Array, dest_pos: int, length: int) -> void:
	if src == dest and src_pos < dest_pos:
		for i in range(length - 1, -1, -1):
			dest[dest_pos + i] = src[src_pos + i]
	else:
		for i in length:
			dest[dest_pos + i] = src[src_pos + i]


## Java's Arrays.fill.
static func fill(a: Array, value) -> void:
	a.fill(value)


## Deep copy of a (possibly nested) array of primitives.
static func copyArray(a: Array) -> Array:
	return a.duplicate(true)


## Java's String.hashCode().
static func stringHashCode(s: String) -> int:
	var h := 0
	for i in s.length():
		h = (31 * h + s.unicode_at(i)) & 0xFFFFFFFF
	if h >= 0x80000000:
		h -= 0x100000000
	return h


## Java's char arithmetic helper: code point of character at index.
static func charAt(s: String, i: int) -> int:
	return s.unicode_at(i)


## Java's Character.isDigit.
static func isDigit(c) -> bool:
	var code: int = c if c is int else String(c).unicode_at(0)
	return code >= 48 and code <= 57


## Java's Math.signum for floats.
static func signum(f: float) -> float:
	if f > 0.0:
		return 1.0
	if f < 0.0:
		return -1.0
	return 0.0


## Java's Math.toRadians / toDegrees.
static func toRadians(deg: float) -> float:
	return deg_to_rad(deg)


static func toDegrees(rad: float) -> float:
	return rad_to_deg(rad)


## Java's System.currentTimeMillis() (monotonic in this port).
static func currentTimeMillis() -> int:
	return Time.get_ticks_msec()


## Java's System.nanoTime().
static func nanoTime() -> int:
	return Time.get_ticks_usec() * 1000


## Java's String.format for the common %d / %s / %.Nf cases.
static func format(fmt: String, args: Array) -> String:
	return fmt % args


## Java's Collections.shuffle.
static func shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := randInt(i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Java's String.valueOf / Integer.toString.
static func valueOf(v) -> String:
	if v is float:
		var s := str(v)
		if not ("." in s or "e" in s or "inf" in s or "nan" in s):
			s += ".0"
		return s
	if v == null:
		return "null"
	return str(v)


## Java's String.compareTo.
static func compareTo(a: String, b: String) -> int:
	var n: int = min(a.length(), b.length())
	for i in n:
		var d := a.unicode_at(i) - b.unicode_at(i)
		if d != 0:
			return d
	return a.length() - b.length()


## Java's String.compareToIgnoreCase.
static func compareToIgnoreCase(a: String, b: String) -> int:
	return compareTo(a.to_lower(), b.to_lower())


## Java's Character.toUpperCase on first letter etc.
static func capitalize(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)


## Removes and returns the element at index (Java's List.remove(int)).
static func removeAt(a: Array, index: int):
	var v = a[index]
	a.remove_at(index)
	return v


## Removes the first occurrence of value (Java's List.remove(Object)).
static func removeValue(a: Array, value) -> bool:
	var i := a.find(value)
	if i >= 0:
		a.remove_at(i)
		return true
	return false


## Java Integer.MAX_VALUE / MIN_VALUE and Float.MAX_VALUE.
const INT_MAX := 2147483647
const INT_MIN := -2147483648
const FLOAT_MAX := 3.4028235e38
