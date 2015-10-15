package bodies.particles;

import java.util.Iterator;

import settings.ParticleSettings;
import bodies.Body;
import bodies.Vector3f;
import bodies.system.SystemLoader;

public abstract class Particle extends Body {
	
	protected float fadeValue;
	private Vector3f fade = new Vector3f(1000, .001f, 2000);

	// -- Abstract Methods -- //
	protected abstract float modifyFadeValue(float fadeValue);
	
	// -- Methods -- //
	public void update(float elapsedTime) {
		super.update(elapsedTime);
		fadeValue = modifyFadeValue(fadeValue);
		life -= fadeValue;
	}
	
	// -- Getters -- //
	protected float getFadeValue() {
		return getRandomFade() + getFadeOffset();
	}
	
	protected float getRandomFade() {
		return (float) (Math.random() / fade.x);
	}
	
	protected float getFadeOffset() {
		return fade.y;
	}
	
	protected float getFadeArg() {
		return fade.z;
	}

	// -- Setters -- //
	public void reset() {
		super.reset();
		fadeValue = getFadeValue();
	}
	
	public void checkCollision(Body b) {}
	
	protected void moveStuck(float elapsedTime) {}
	
	public Particle(ParticleSettings settings) {
		if (settings != null) {
			Iterator<Integer> it = settings.iterator();
			while (it.hasNext()) {
				int type = it.next();
				switch (type) {
				case ParticleSettings.POSITION:
					setPosition(settings.getVector(type));
					break;
				case ParticleSettings.MASS:
					setMass(SystemLoader.getValueFromInterval(settings.getString(type)));
					break;
				case ParticleSettings.SIZE:
					setSize(SystemLoader.getValueFromInterval(settings.getString(type)));
					break;
				case ParticleSettings.COLOR:
					setColor(settings.getVector(type));
					break;
				case ParticleSettings.FADE:
					fade = settings.getVector(type);
					break;
				default:
					break;
				}
			}
		}
		reset();
		kill();
		parseArgs(settings.getString(ParticleSettings.SETTINGS));
	}

	private void parseArgs(String args) {
		if (args != null && args.contains("=")) {
			args = args.replaceAll("\\[", "");
			args = args.replaceAll("\\]", "");
			String[] argv;
			if (args.contains(";"))	{
				argv = args.split(";");
			} else {
				argv = new String[]{args};
			}
			for (String s : argv) {
				String[] params = s.split("=");
				executeCommand(params[0], params[1]);
			}
		}
	}

	protected void executeCommand(String command, String value) {
		
	}
}
