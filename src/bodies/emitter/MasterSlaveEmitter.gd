class_name MasterSlaveEmitter
extends AbstractEmitter
## Port of bodies.emitter.MasterSlaveEmitter: when a body of the master system
## is re-emitted, a body of the slave system is emitted from its position.

var bodyPool = {}
var master = null
var slave = null


func _init(settings = null, shape = null) -> void:
	super(settings, shape)


func setSystems(master, slave):
	self.master = master
	self.slave = slave


## Java emitFrom() (no arguments); the other overloads go to AbstractEmitter.
func emitFrom(pool = null, master = null):
	if pool != null:
		return super.emitFrom(pool, master)
	var p = bodyPool.get(self.master)
	if p == null:
		push_error("MasterSlaveEmitter: no pool for the master system")
		return true
	super.emitFrom(p, null)
	return p.is_empty()


func postEmit(b):
	if not b.isQueuedForEmittance():
		b.queueForEmittance()
		if b.getParent() == master:
			var slavePool = bodyPool.get(slave)
			if slavePool != null:
				emitFrom(slavePool, b)
			else:
				push_error("MasterSlaveEmitter: no pool for the slave system")
		bodyPool.get(b.getParent()).append(b)


func fillPool(b):
	b.queueForEmittance()
	var pool = bodyPool.get(b.getParent())
	if pool == null:
		pool = []
		bodyPool[b.getParent()] = pool
	pool.append(b)
