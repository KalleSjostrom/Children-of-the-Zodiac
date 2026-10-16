class_name JRandom
extends RefCounted
## java.util.Random API on top of RandomNumberGenerator.

var _rng := RandomNumberGenerator.new()


func _init(seed_value = null) -> void:
	if seed_value == null:
		_rng.randomize()
	else:
		_rng.seed = int(seed_value)


func setSeed(seed_value: int) -> void:
	_rng.seed = seed_value


## nextInt() or nextInt(n) -> [0, n).
func nextInt(n: int = -1) -> int:
	if n <= 0:
		return _rng.randi() - 2147483648
	return _rng.randi() % n


func nextFloat() -> float:
	return _rng.randf()


func nextDouble() -> float:
	return _rng.randf()


func nextBoolean() -> bool:
	return _rng.randi() % 2 == 0


func nextGaussian() -> float:
	return _rng.randfn(0.0, 1.0)
