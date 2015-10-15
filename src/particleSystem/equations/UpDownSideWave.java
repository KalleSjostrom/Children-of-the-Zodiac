package particleSystem.equations;

import particleSystem.ParticleSystem.InterpolationInfo;
import bodies.Vector3f;

public class UpDownSideWave implements VectorEquation {
	
	private float omega;
	private float time;
	
	private float amplifier;
	private float phi;
	private boolean horizontal;
	private InterpolationInfo info;

	// Period in second
	public UpDownSideWave(float period, float amplifier, float phi, 
			InterpolationInfo info, boolean horizontal) {
		omega = (float) ((2 * Math.PI) / period);	
		this.amplifier = amplifier;
		this.phi = phi;
		this.horizontal = horizontal;
		this.info = info;
	}

	public Vector3f modifyVector(Vector3f v, float elapsedTime) {
		float theta = (omega * time) + phi;
		time += elapsedTime;
		float sin = (float) (Math.sin(theta) * amplifier);
		if (horizontal) {
			v.x = info.interpolate(null, time).x + sin;
		} else {
			v.y = info.interpolate(null, time).y + sin;
		}
		return v;
	}

	public Vector3f getVectorAfterTime(Vector3f v, float time) {
		float theta = (omega * time) + phi;
		float sin = (float) (Math.sin(theta) * amplifier);
		if (horizontal) {
			v.x += sin;
		} else {
			v.y += sin;
		}
		return v;
	}
}
