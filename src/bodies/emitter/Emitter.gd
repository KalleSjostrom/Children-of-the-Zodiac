class_name BodiesEmitter
extends AbstractEmitter
## Port of bodies.emitter.Emitter: a regular emitter with one body pool.

var bodyPool = []


func _init(settings = null, shape = null) -> void:
	super(settings, shape)


## Java emitFrom() (no arguments); the other overloads go to AbstractEmitter.
func emitFrom(pool = null, master = null):
	if pool != null:
		return super.emitFrom(pool, master)
	super.emitFrom(bodyPool, null)
	return bodyPool.is_empty()


func postEmit(b):
	if not b.isQueuedForEmittance():
		b.queueForEmittance()
		bodyPool.append(b)


func fillPool(b):
	b.queueForEmittance()
	bodyPool.append(b)
