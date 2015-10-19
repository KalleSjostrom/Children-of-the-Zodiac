package bodies;

import bodies.system.ParticleSystem;
import graphics.GameTexture;
import graphics.Graphics;

public abstract class Body extends PointBody {
	
	private float size = 1f;
	private float radius;
	private boolean waitForEmit;
	
	private ParticleSystem parent;
	protected float life;
	protected float[] rgb = new float[3];

	private boolean queued;

	private Vector3f emittedFrom;
	
	// -- Abstract methods -- //
	public void reset() {
		life = 1;
		setVelocity(new Vector3f());
		setForce(getDefaultForce());
	}
	
	public void setColor(Vector3f v) {
		rgb[0] = v.x;
		rgb[1] = v.y;
		rgb[2] = v.z;
	}
	
	public void setLife(float l) {
		life = l;
	}

	public void kill() {
		life = 0;
	}
		
	public void draw(Graphics g, GameTexture t, Vector3f pPos) {
		if (isAlive()) {
			g.setColor(rgb, life);
			Vector3f pos = getPosition();
			// t.drawMany(g, pos.x + pPos.x, -(pos.y + pPos.y), modifySize(size));
		}
	}	
	
	protected float modifySize(float size) {
		return size;
	}

	// -- Getters -- //
	public float getSize() {
		return size;
	}
	
	public ParticleSystem getParent() {
		return parent;
	}
	
	public float getRadius() {
		return radius;
	}
	
	public boolean isDead() {
		return !isAlive();
	}
		
	public boolean isAlive() {
		return life > 0;
	}
	
	public boolean isWaitingForEmit() {
		return waitForEmit;
	}

	// -- Setters --
	protected void setSize(float s) {
		size = s;
	}
		
	protected void setRadius(float r) {
		radius = r;
	}
	
	public void setParent(ParticleSystem particleSystem) {
		this.parent = particleSystem;
	}

	public boolean isQueuedForEmittance() {
		return queued;
	}

	public void queueForEmittance() {
		queued = true;
	}
	
	public void dequeueForEmittance() {
		queued = false;
	}

	public float getLife() {
		return life;
	}

	public void setEmitPosition(Vector3f emitPosition) {
		emittedFrom = emitPosition;
	}
	
	public Vector3f getEmitPosition() {
		return emittedFrom;
	}
	
	public void draw(Graphics g, int x, int y) {}
}
