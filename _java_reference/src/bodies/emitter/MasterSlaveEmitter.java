package bodies.emitter;

import java.util.HashMap;
import java.util.Stack;

import settings.EmitterSettings;
import bodies.Body;
import bodies.system.ParticleSystem;

public class MasterSlaveEmitter extends AbstractEmitter {
	
	private HashMap<ParticleSystem, Stack<Body>> bodyPool = new HashMap<ParticleSystem, Stack<Body>>();
	
	private	ParticleSystem master;
	private	ParticleSystem slave;

	public MasterSlaveEmitter(EmitterSettings settings, EmitterShape shape) {
		super(settings, shape);
	}
	
	public void setSystems(ParticleSystem master, ParticleSystem slave) {
		this.master = master;
		this.slave = slave;
	}
	
	@Override
	protected boolean emitFrom() {
		Stack<Body> p = bodyPool.get(master);
		emitFrom(p, null);
		return p.empty();
	}
	
	@Override
	public void postEmit(Body b) {
		if (!b.isQueuedForEmittance()) {
			b.queueForEmittance();
			if (b.getParent() == master) {
				emitFrom(bodyPool.get(slave), b);
			}
			bodyPool.get(b.getParent()).push(b);
		}
	}
	
	@Override
	public void fillPool(Body b) {
		b.queueForEmittance();
		Stack<Body> pool = bodyPool.get(b.getParent());
		if (pool == null) {
			pool = new Stack<Body>();
			bodyPool.put(b.getParent(), pool);
		}
		pool.push(b);
	}
}
