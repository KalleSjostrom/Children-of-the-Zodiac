package bodies.emitter;

import java.util.Stack;

import settings.EmitterSettings;
import bodies.Body;
import bodies.Vector3f;
import bodies.system.SystemLoader;

public abstract class AbstractEmitter extends Body {
	
	private float emitPeriod = 2;
	private float time = 0;
	private EmitterShape shape;
	
	private double swiftness;
	private float speed;
	private boolean fade;
	private boolean increase;
	private float cutoff;

	protected AbstractEmitter(EmitterSettings settings, EmitterShape shape) {
		setForce(settings.getVector(EmitterSettings.FORCE));
		emitPeriod = 
			SystemLoader.getValueFromInterval(
				settings.getString(EmitterSettings.EMITTANCE_TIME_STEP));
		this.shape = shape;
	}
	
	public void update(float elapsedTime) {
		time += elapsedTime;
		boolean empty = false;
		while (!empty && time >= emitPeriod) {
			empty = emitFrom();
			time -= emitPeriod;
			if (fade) {
				emitPeriod += (increase ? 1 : -1) * Math.pow(emitPeriod * speed, swiftness);
				fade = increase ? emitPeriod < cutoff : emitPeriod > cutoff;
				if (!fade) {
					emitPeriod = Float.MAX_VALUE;
				}
			}
		}
	}
	
	public void setFade(boolean fade, float speed, float swiftness, boolean increase, float cutoff) {
		this.fade = fade;
		this.speed = speed;
		this.swiftness = swiftness;
		this.increase = increase;
		this.cutoff = cutoff;
	}
	
	public Vector3f getPosition() {
		return shape.getPosition();
	}

	protected void emitFrom(Stack<Body> pool, Body master) {
		if (pool.size() > 0) {
			Body b = pool.pop();
			b.dequeueForEmittance();
			Vector3f pos = null;
			Vector3f vel;
			if (master != null) {
				pos = master.getPosition();
				vel = master.getVelocity().mult(.5f);
			} else {
				pos = shape.getEmittancePos();
				vel = new Vector3f();
			}
			emit(b, pos, vel);
		}
	}
	
	protected EmitterShape getShape() {
		return shape;
	}
	
	public void emitFrom(Body b, EmitterShape warmer) {
		emit(b, warmer.getEmittancePos(), new Vector3f());
	}

	protected void emit(Body b, Vector3f emitPosition, Vector3f vel) {
		b.reset();
		b.setVelocity(vel.clone());
		b.setPosition(emitPosition);
		float magnitude = getForce().length();
		Vector3f direction = getShape().modifyDirection(getForce().normalize());
	
		direction.normalizeLocal();
		direction.multLocal(magnitude);
		b.addForce(direction);
		b.setEmitPosition(emitPosition.clone());
	}
		
	public abstract void postEmit(Body b);
	public abstract void fillPool(Body b);
	protected abstract boolean emitFrom();
}
