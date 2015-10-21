package particleSystem.emitter;

import java.util.ArrayList;
import java.util.Stack;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;
import battle.enemy.BattleEnemy;
import bodies.Vector3f;

public class FlareEmitter extends Emitter {

	private float time;
	private float limit = .7f;

	public FlareEmitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitPeriod, int limit) {
		super(particlePool, particles, info, emitPeriod, limit);
		particlePool.addAll(particles);
		particles.clear();
		for (int i = 0; i < 400; i++) {
			Particle p = particlePool.pop();
			particles.add(p);
			Vector3f v = ParticleSystem.getRandomCircleVector(4);
			Vector3f s = info.getSource();
			v.z = s.z;
			p.resurrect(null, v, 0);
		}
	}

	public void destroy(BattleEnemy enemy) {
		super.destroy(enemy);
		getParticles().addAll(getParticlePool());
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!isDestroyed()) {
			time += elapsedTime;
			if (time > limit) {
				for (int i = 0; i < 400; i++) {
					Particle p = getParticles().get(i);
					Vector3f pos = p.getPosition().clone();
					pos.z = 0;
					Vector3f vec = pos.normalizeLocal().mult(-.03f);
					vec.z = pos.z;
					p.setForce(vec);
				}
			}
		}
	}
}
