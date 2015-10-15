package particleSystem.emitter;

import java.util.ArrayList;
import java.util.Stack;

import bodies.Vector3f;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;

public class LineEmitter extends Emitter {

	public LineEmitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitTimeStep, int limit) {
		super(particlePool, particles, info, emitTimeStep, limit);
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!isDestroyed()) {
			addTime(elapsedTime);
			boolean empty = false;
			float nrToEmit = getTime() / getEmitTimeStep();
			float timePerPart = elapsedTime / nrToEmit;
			while (!empty && getTime() >= getEmitTimeStep()) {
				if (okToEmit()) {
					Particle p = getParticle(system);
					Vector3f pos = getInfo().useVectorEquationFromSource();
					p.resurrect(null, pos);
					getParticles().add(p);
					addTimeCounter(timePerPart);
				}
				empty = !okToEmit();
				addTime(-Math.min(elapsedTime, getEmitTimeStep()));
			}
		}
	}
}
