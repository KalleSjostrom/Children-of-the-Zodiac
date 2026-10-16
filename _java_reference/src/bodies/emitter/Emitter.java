package bodies.emitter;

import java.util.Stack;

import settings.EmitterSettings;
import bodies.Body;

public class Emitter extends AbstractEmitter {
	
	private Stack<Body> bodyPool = new Stack<Body>();
	
	public Emitter(EmitterSettings settings, EmitterShape shape) {
		super(settings, shape);
	}
	
	@Override
	protected boolean emitFrom() {
		emitFrom(bodyPool, null);
		return bodyPool.empty();
	}
	
	@Override
	public void postEmit(Body b) {
		if (!b.isQueuedForEmittance()) {
			b.queueForEmittance();
			bodyPool.push(b);
		}
	}
	
	@Override
	public void fillPool(Body b) {
		b.queueForEmittance();
		bodyPool.push(b);
	}
}
