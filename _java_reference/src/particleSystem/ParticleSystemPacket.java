package particleSystem;

import graphics.Graphics;

import java.util.ArrayList;
import java.util.HashMap;

public class ParticleSystemPacket {
	
	private ArrayList<ParticleSystem> systems = new ArrayList<ParticleSystem>();
	private HashMap<ParticleSystem, Integer> delays = new HashMap<ParticleSystem, Integer>();
	private boolean answerdAlready = false;
	private boolean added = false;
	private boolean useStartStop;
	
	public ParticleSystemPacket() {this(true);}
	public ParticleSystemPacket(boolean useStartStop) {
		this.useStartStop = useStartStop;
	}
	
	public void add(ParticleSystem system, int delay) {
		systems.add(system);
		delays.put(system, delay);
	}
	
	public void add(int i, ParticleSystem system, int delay) {
		systems.add(i, system);
		delays.put(system, delay);
	}
	
	public void draw(Graphics g) {
		// TODO: called when systems.size() == 0...
		if (systems.size() > 0) { // Shouldn't be needed.
			if (useStartStop) systems.get(0).start(g);
			for (ParticleSystem ps : systems) {
				int delay = delays.get(ps);
				if (delay <= 0) {
					ps.draw(g);
				}
			}
			if (useStartStop) systems.get(systems.size()-1).end(g);
		}
	}

	public void update(float elaspsedTime) {
		for (ParticleSystem ps : systems) {
			int delay = delays.get(ps);
			if (delay <= 0) {
				ps.update(elaspsedTime);
			} else {
				delays.put(ps, (int) (delay - elaspsedTime*1000));
			}
		}
	}

	public boolean isDestroyed() {
		boolean isDestroyed = true;
		for (int i = 0; i < systems.size() && isDestroyed; i++) {
			isDestroyed = systems.get(i).isDestroyed();
		}
		return isDestroyed;
	}

	public boolean isDead() {
		boolean isDead = true;
		for (int i = 0; i < systems.size() && isDead; i++) {
			isDead = systems.get(i).isDead();
		}
		return isDead;
	}

	public boolean isReady() {
		if (answerdAlready) {
			return false;
		}
		boolean isReady = true;
		for (int i = 0; i < systems.size() && isReady; i++) {
			isReady = systems.get(i).isReady();
		}
		if (isReady) {
			answerdAlready = true; 
		}
		return isReady;
	}

	public float[] getColor() {
		return systems.get(0).getColor();
	}

	public boolean isAdded() {
		return added;
	}
	
	public boolean add() {
		return added = true;
	}
}
