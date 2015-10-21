package bodies.system;

import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;

import settings.EmitterSettings;
import settings.ParticleSettings;
import settings.ShapeSettings;
import settings.SystemSettings;
import villages.villageStory.Parser;
import bodies.emitter.AbstractEmitter;
import bodies.emitter.EmitterFactory;
import bodies.emitter.EmitterShape;
import bodies.emitter.MasterSlaveEmitter;

public class SystemLoader extends AbstractMapLoader {

	private static final int EMITTER_SHAPE = 0;
	private static final int EMITTER = 1;
	private static final int PARTICLE = 2;
	private static final int SYSTEM = 3;
	
	private HashMap<String, ShapeSettings> shapeSettings = new HashMap<String, ShapeSettings>();
	private HashMap<String, EmitterSettings> emitterSettings = new HashMap<String, EmitterSettings>();
	private HashMap<String, ParticleSettings> particleSettings = new HashMap<String, ParticleSettings>();
	private HashMap<String, SystemSettings> systemSettings = new HashMap<String, SystemSettings>();
	private Parser parser = new Parser();
	
	public static SystemLoader getLoader() {
		SystemLoader loader = new SystemLoader();
		loader.parseFile("particleSystems");
		return loader;
	}
	
	/**
	 * Parses the file with the given name to load the village story.
	 * 
	 * @param fileName the name of the file to load.
	 */
	public void parseFile(String fileName) {
		parseFile(Values.ParticleSystemsMaps, fileName + ".info");
	}
	
	public ArrayList<ParticleSystem> buildSystem(String name) {
		ArrayList<ParticleSystem> systems = new ArrayList<ParticleSystem>();
		
		SystemSettings settings = systemSettings.get(name);
		String emitName = settings.getString(SystemSettings.EMITTER_NAME);
		EmitterSettings eSettings = emitterSettings.get(emitName);
		
		String shapeName = eSettings.getString(EmitterSettings.SHAPE_NAME);
		ShapeSettings sSettings = shapeSettings.get(shapeName);
		
		AbstractEmitter emitter = 
			EmitterFactory.createEmitter(eSettings, sSettings);
		
		String warmUpEmitterName = settings.getString(SystemSettings.WARM_UP_SHAPE_NAME);
		EmitterShape warmUpShape = null;
		if (warmUpEmitterName != null) {
			ShapeSettings warmUpEmitterSettings = shapeSettings.get(warmUpEmitterName);
			warmUpShape = EmitterFactory.getShape(warmUpEmitterSettings);
		}
		
		String particleName = settings.getString(SystemSettings.PARTICLE_NAME);
		ParticleSettings pSettings = particleSettings.get(particleName);
		
		ParticleSystem p = new ParticleSystem(settings, pSettings, emitter, warmUpShape);
		systems.add(p);
		String s = eSettings.getString(EmitterSettings.SLAVE_NAME);
		if (s != null && emitter instanceof MasterSlaveEmitter) {
			ParticleSystem slave = getSystem(s, emitter);
			((MasterSlaveEmitter) emitter).setSystems(p, slave);
			systems.add(slave);
			int warmUp = p.getWarmUp();
			float estimated_timestep = 1.0f/60.0f;
			for (int i = 0; i < warmUp; i++) {
				p.update(estimated_timestep);
				slave.update(estimated_timestep);
			}
			p.setWarmUp(0);
		}
		return systems;
	}
	
	private ParticleSystem getSystem(String name, AbstractEmitter emitter) {
		SystemSettings settings = systemSettings.get(name);
		
		String particleName = settings.getString(SystemSettings.PARTICLE_NAME);
		ParticleSettings pSettings = particleSettings.get(particleName);
		
		return new ParticleSystem(settings, pSettings, emitter, null);
	}
	
	/**
	 * This method executes the given command create the 
	 * village story sequence.
	 * 
	 * @param command the command to execute.
	 * @param tok the StringTokenizer containing additional information.
	 */
	protected void executeCommand(String command, StringTokenizer tok) {
		parser.updateLineCounter(lineCount, lastLine);
		if (command.equals("import")) {
			String file = Parser.getArgument(tok.nextToken())[1];
			parseFile(Values.ParticleSystemsMaps, file);
			lineCount -= parser.variableSize();
		} else if (command.equals("var")) {
			parser.addVariable(tok);
		} else if (command.equals("new")) {
			String[] args = Parser.getArgument(tok.nextToken());
			command = args[0];
			String value = args[1];
			if (command.equals("type")) {
				int type = parser.getValue(value);
				switch (type) {
				case EMITTER_SHAPE:
					createEmitterShape(tok);
					break;
				case EMITTER:
					createEmitter(tok);
					break;
				case PARTICLE:
					createParticle(tok);
					break;
				case SYSTEM:
					createSystem(tok);
					break;
				default :
					Parser.error("Type argument must be either of the static variables: " +
					"EMITTER_SHAPE, EMITTER, PARTICLE or SYSTEM in the class SystemLoader");
				break;
				}
			} else {
				Parser.error("A new command must start with the type argument!");
			}
		}
	}
	
	private void createSystem(StringTokenizer tok) {
		SystemSettings settings = new SystemSettings();
		while (tok.hasMoreTokens()) {
			String[] args = Parser.getArgument(tok.nextToken());
			String command = args[0];
			String value = args[1];		
			if (command.equals("name")) {
				settings.setName(value);
			} else if (command.equals("particle")) {
				settings.setString(SystemSettings.PARTICLE_NAME, value);
			} else if (command.equals("nrParticles")) {
				settings.setValue(SystemSettings.NR_PARTICLES, parser.getValue(value));
			} else if (command.equals("emitter")) {
				settings.setString(SystemSettings.EMITTER_NAME, value);
			} else if (command.equals("texture")) {
				settings.setString(SystemSettings.TEXTURE, value);
			} else if (command.equals("additive")) {
				settings.setValue(SystemSettings.ADDITIVE, parser.getValue(value));
			} else if (command.equals("warmUp")) {
				settings.setValue(SystemSettings.WARM_UP_LENGTH, parser.getValue(value));
			} else if (command.equals("warmUpShape")) {
				settings.setString(SystemSettings.WARM_UP_SHAPE_NAME, value);
			} else if (command.equals("background")) {
				settings.setString(SystemSettings.BACKGROUND, value);
			}
		}
		systemSettings.put(settings.getName(), settings);
	}

	private void createParticle(StringTokenizer tok) {
		ParticleSettings settings = new ParticleSettings();
		while (tok.hasMoreTokens()) {
			String[] args = Parser.getArgument(tok.nextToken());
			String command = args[0];
			String value = args[1];		
			if (command.equals("name")) {
				settings.setName(value);
			} else if (command.equals("mass")) {
				settings.setString(ParticleSettings.MASS, value);
			} else if (command.equals("kind")) {
				settings.setValue(ParticleSettings.KIND, parser.getValue(value));
			} else if (command.equals("color")) {
				settings.setVector(ParticleSettings.COLOR, parser.getFloatPos(value));
			} else if (command.equals("size")) {
				settings.setString(ParticleSettings.SIZE, value);
			} else if (command.equals("fade")) {
				settings.setVector(ParticleSettings.FADE, parser.getFloatPos(value));
			} else if (command.equals("settings")) {
				settings.setString(ParticleSettings.SETTINGS, value);
			}
		}
		particleSettings.put(settings.getName(), settings);
	}

	private void createEmitter(StringTokenizer tok) {
		EmitterSettings settings = new EmitterSettings();
		while (tok.hasMoreTokens()) {
			String[] args = Parser.getArgument(tok.nextToken());
			String command = args[0];
			String value = args[1];		
			if (command.equals("name")) {
				settings.setName(value);
			} else if (command.equals("kind")) {
				settings.setValue(EmitterSettings.KIND, parser.getValue(value));
			} else if (command.equals("force")) {
				settings.setVector(EmitterSettings.FORCE, parser.getFloatPos(value));
			} else if (command.equals("timeStep")) {
				settings.setString(EmitterSettings.EMITTANCE_TIME_STEP, value);
			} else if (command.equals("useshape")) {
				settings.setString(EmitterSettings.SHAPE_NAME, value);
			} else if (command.equals("slave")) {
				settings.setString(EmitterSettings.SLAVE_NAME, value);
			}
		}
		emitterSettings.put(settings.getName(), settings);
	}

	private void createEmitterShape(StringTokenizer tok) {
		ShapeSettings settings = new ShapeSettings();
		while (tok.hasMoreTokens()) {
			String[] args = Parser.getArgument(tok.nextToken());
			String command = args[0];
			String value = args[1];		
			if (command.equals("name")) {
				settings.setName(value);
			} else if (command.equals("kind")) {
				settings.setValue(ShapeSettings.KIND, parser.getValue(value));
			} else if (command.equals("pos")) {
				settings.setVector(ShapeSettings.POSITION, parser.getPos(value));
			} else if (command.equals("point")) {
				settings.setVector(ShapeSettings.POINTS, parser.getPos(value));
			} else if (command.equals("angle")) {
				settings.setValue(ShapeSettings.ANGLE, parser.getValue(value));
			} else if (command.equals("image")) {
				settings.setString(ShapeSettings.IMAGE, value);
			} else if (command.equals("flipX")) {
				settings.setValue(ShapeSettings.FLIP_HORIZONTALLY, parser.getValue(value));
			} else if (command.equals("flipY")) {
				settings.setValue(ShapeSettings.FLIP_VERTICALLY, parser.getValue(value));
			} else if (command.equals("scaleX")) {
				settings.setValue(ShapeSettings.SCALE_X, parser.getFloat(value));
			} else if (command.equals("scaleY")) {
				settings.setValue(ShapeSettings.SCALE_Y, parser.getFloat(value));
			} else if (command.startsWith("point")) {
				String[] temp = command.split(":");
				int nr = Integer.parseInt(temp[1]);
				settings.setVector(ShapeSettings.POINTS + nr, parser.getPos(value));
			}
		}
		shapeSettings.put(settings.getName(), settings);
	}
		
	public static float getValueFromInterval(String s) {
		float val;
		if (s == null) return 0;
		
		if (s.contains("-")) {
			String[] interval = s.split("-");
			float first = Float.parseFloat(interval[0]);
			float second = Float.parseFloat(interval[1]);
			float max = Math.max(first, second);
			float min = Math.min(first, second);
			val = (float) (Math.random() * (max - min) + min);
		} else {
			val = Float.parseFloat(s);
		}
		return val;
	}
}
