package particleSystem.emitter;

import java.util.ArrayList;
import java.util.Stack;

import battle.enemy.BattleEnemy;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;

public class Emitter {

	private boolean destroyed;
	private float time;
	private float emitTimeStep;
	private float timeCounter;
	private ArrayList<Particle> particles;
	private InterpolationInfo info;
	private Stack<Particle> particlePool;
	private int limit = 1000;

	public Emitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitTimeStep, int limit) {
		this.particlePool = particlePool;
		this.particles = particles;
		this.info = info;
		this.limit = limit;
		this.emitTimeStep = emitTimeStep;
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!destroyed) {
			time += elapsedTime;
			boolean empty = false;
			while (!empty && time >= emitTimeStep) {
				if (okToEmit()) {
					Particle p = getParticle(system);
					p.resurrect(system, null);
					particles.add(p);
				}
				empty = !okToEmit();
				time -= emitTimeStep;
			}
		}
	}
	
	protected Particle getParticle(ParticleSystem system) {
		Particle p = null;
		if (!particlePool.empty()) {
			p = particlePool.pop();
		} else if (particles.size() < limit) {
			p = system.createParticle();
		}
		return p;
	}
	
	public void destroy(BattleEnemy enemy) {
		destroyed = true;
	}

	protected boolean isDestroyed() {
		return destroyed;
	}

	protected float getTime() {
		return time;
	}

	protected float getEmitTimeStep() {
		return emitTimeStep;
	}

	protected float getTimeCounter() {
		return timeCounter;
	}

	protected ArrayList<Particle> getParticles() {
		return particles;
	}

	protected InterpolationInfo getInfo() {
		return info;
	}

	protected Stack<Particle> getParticlePool() {
		return particlePool;
	}
	
	protected void addTime(float elapsedTime) {
		time += elapsedTime;
	}

	protected void addTimeCounter(float time) {
		timeCounter += time;
	}

	public boolean okToEmit() {
		return !particlePool.empty() || particles.size() < limit;
	}
}
