package particleSystem.equations;

import bodies.Vector3f;

public class WhirlWind implements VectorEquation {

	private float omega;
	private float time;
	
	private float amplifier;
	private float phi;
	private Vector3f source;
	private boolean clockWise;
	private float totalTime;

	// Period in second
	public WhirlWind(
			float period, float amplifier, float phi, 
			Vector3f source, boolean clockWise, float totalTime) {
		omega = (float) ((2 * Math.PI) / period);	
		this.amplifier = amplifier;
		this.source = source;
		this.phi = phi;
		this.clockWise = clockWise;
		this.totalTime = totalTime;
	}

	public Vector3f modifyVector(Vector3f v, float elapsedTime) {
		time += elapsedTime;
		return getVectorAfterTime(v, time);
	}
	
	public Vector3f getVectorAfterTime(Vector3f v, float time) {
		float percent = (float) (Math.pow(time / totalTime, 2f) * 8f + 0.5f + 2*time);
		float theta = (omega * time) + phi;
		double t = clockWise ? 2 * Math.PI - theta : theta;
		float cos = (float) (Math.cos(t) * amplifier * percent);
		float sin = (float) (Math.sin(t) * amplifier * percent);
		v.z = source.z + sin;
		v.x = source.x + cos;
		v.y = (float) (v.y + (Math.random()-.5f)*.3f);
		return v;
	}
}
