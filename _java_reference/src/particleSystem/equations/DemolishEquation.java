package particleSystem.equations;

import bodies.Vector3f;

public class DemolishEquation implements VectorEquation {

	private float omega;
	private float time;
	
	private float amplifier;
	private float phi;
	private Vector3f source;
	private boolean clockWise;

	// Period in second
	public DemolishEquation(
			float period, float amplifier, float phi, 
			Vector3f source, boolean clockWise) {
		omega = (float) ((2 * Math.PI) / period);	
		this.amplifier = amplifier;
		this.source = source;
		this.phi = phi;
		this.clockWise = clockWise;
	}

	public Vector3f modifyVector(Vector3f v, float elapsedTime) {
		time += elapsedTime;
		return getVectorAfterTime(v, time);
	}
	
	public Vector3f getVectorAfterTime(Vector3f v, float time) {
		float theta = (omega * time) + phi;
		double t = clockWise ? 2 * Math.PI - theta : theta;
		float cos = (float) (Math.cos(t) * amplifier);
		float sin = (float) (Math.sin(t) * amplifier);
		v.y = source.y + sin;
		v.x = source.x + cos;
		return v;
	}
}
