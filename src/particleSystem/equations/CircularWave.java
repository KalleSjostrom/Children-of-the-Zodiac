package particleSystem.equations;

import bodies.Vector3f;

public class CircularWave implements VectorEquation {

	private float omega;
	private float time;
	
	private float amplifier;
	private float phi;
	private boolean clockWise;
	private float z;
	private boolean useStaticZ;

	// Period in second
	public CircularWave(
			float period, float amplifier, float phi, boolean clockWise) {
		this(period, amplifier, phi, clockWise, false, 0);
	}
	
	public CircularWave(
			float period, float amplifier, float phi, 
			boolean clockWise, boolean useStaticZ, float z) {
		omega = (float) ((2 * Math.PI) / period);	
		this.amplifier = amplifier;
		this.phi = phi;
		this.clockWise = clockWise;
		this.useStaticZ = useStaticZ;
		this.z = z;
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
		v.y += sin; //source.y + sin;
		v.x += cos; //source.x + cos;
		if (useStaticZ) {
			v.z = z;
		}
		return v;
	}
//	
//	public Vector3f getVectorAfterTime(Vector3f v, float time) {
//		float theta = (omega * time) + phi;
//		double t = clockWise ? 2 * Math.PI - theta : theta;
//		float cos = (float) (Math.cos(t) * amplifier);
//		float sin = (float) (Math.sin(t) * amplifier);
//		v.y += sin; //source.y + sin;
//		v.x += cos; //source.x + cos;
//		v.z = -6;
//		return v;
//	}
}
