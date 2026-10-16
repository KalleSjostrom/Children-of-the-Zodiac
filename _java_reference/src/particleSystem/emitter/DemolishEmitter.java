package particleSystem.emitter;

import java.util.ArrayList;
import java.util.Stack;

import battle.enemy.BattleEnemy;
import bodies.Vector3f;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;

public class DemolishEmitter extends Emitter {

	private boolean initiated;

	public DemolishEmitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitTimeStep, int limit) {
		super(particlePool, particles, info, emitTimeStep, limit);
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!initiated) {
			for (Particle p : getParticles()) {
				p.resurrect(system, null);
			}
			initiated = true;
		}
		if (!isDestroyed()) {
			addTime(elapsedTime);
			for (Particle p : getParticles()) {
				Vector3f partpos = p.getPosition();
				Vector3f pos = getInfo().interpolate(system.getPosition().clone(), getTime());
				pos.z = partpos.z;
				p.setPosition(pos);
			}
		}
	}
	
	@Override
	public void destroy(BattleEnemy enemy) {
		if (!isDestroyed() && enemy != null) {
			enemy.setScale();
		}
		super.destroy(enemy);
	}
}
