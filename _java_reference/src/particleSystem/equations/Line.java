package particleSystem.equations;

import bodies.Vector3f;

public class Line implements VectorEquation {

	private Vector3f source;
	private float length;
	private static int counterRight;
	private static int counterLeft;

	public Line(Vector3f source, float length) {
		this.source = source;
		this.length = length;
	}

	public Vector3f modifyVector(Vector3f v, float elapsedTime) {
		return getVectorAfterTime(v, 0);
	}
	
	public Vector3f getVectorAfterTime(Vector3f v, float time) {
		v = source.clone();
		double test = Math.random() * length;
		if (test < length / 2) {
			counterLeft++;
		} else {
			counterRight++;
		}
		v.x += test;
		return v;
	}
}
