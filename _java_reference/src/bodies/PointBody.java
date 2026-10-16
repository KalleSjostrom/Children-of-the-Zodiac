package bodies;

public abstract class PointBody {

	private Vector3f force = new Vector3f();
	private Vector3f velocity = new Vector3f();
	private Vector3f position = new Vector3f();

	private float mass;
	private float inverseMass;
	
	// -- Methods -- //
	public void update(float elapsedTime) {
		Vector3f position = getPosition();
		Vector3f force = getForce();
		Vector3f velocity = getVelocity();
		float invMass = getInverseMass();
		velocity.addLocal(force.mult(elapsedTime * invMass));
		position.addLocal(velocity.mult(elapsedTime));
		setForce(getDefaultForce());
	}

	// -- Adders -- //
	public void addViscousDrag(float k) {
		addForce(velocity.mult(-k));
	}
	
	public void addDrag(float c) {
		addForce(velocity.mult(-c * velocity.length()));
	}
	
	public void addForce(Vector3f f) {
		force.addLocal(f);
	}
		
	public Vector3f getForce() {
		return force;
	}
	
	public Vector3f getDefaultForce() {
		return new Vector3f();
	}
	
	public Vector3f getVelocity() {
		return velocity;
	}
		
	public Vector3f getPosition() {
		return position;
	}
	
	public float getMass() {
		return mass;
	}
	
	public float getInverseMass() {
		return inverseMass;
	}
	
	// -- Setters -- //
	public void setForce(Vector3f force) {
		this.force = force;
	}
	
	public void setVelocity(Vector3f velocity) {
		this.velocity = velocity;
	}
	
	public void setPosition(Vector3f position) {
		this.position = position;
	}
	
	public void setMass(float mass) {
		this.mass = mass;
		inverseMass = 1.0f / mass;
	}
}
