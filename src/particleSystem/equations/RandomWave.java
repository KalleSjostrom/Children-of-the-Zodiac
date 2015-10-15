package particleSystem.equations;

import bodies.Vector3f;

public class RandomWave implements VectorEquation {

	private float omega;
	private float time;
	
	private float amplifier;
	private float phi;
	private Vector3f weight;
	private Vector3f source;
	
	// Period in second
	public RandomWave(float period, float amplifier, float phi, Vector3f weight, Vector3f source) {
		omega = (float) ((2 * Math.PI) / period);	
		this.amplifier = amplifier;
		this.phi = phi;
		this.weight = weight;
		this.source = source;
	}
	
	public Vector3f modifyVector(Vector3f v, float elapsedTime) {
		time += elapsedTime;
		return modifyVector(v, elapsedTime);
	}

	public Vector3f getVectorAfterTime(Vector3f v, float elapsedTime) {
		float theta = (omega * time) + phi;
		float val = (float) (Math.cos(theta) * amplifier);
		v.x = (float) (source.x + (weight.x != 0 ? val * Math.random() * weight.x : 0));
		v.y = (float) (source.y + (weight.y != 0 ? val * Math.random() * weight.y : 0));
		return v;
	}
}
