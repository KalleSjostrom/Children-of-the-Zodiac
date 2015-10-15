package bodies.emitter;

import settings.EmitterSettings;
import settings.ShapeSettings;

public class EmitterFactory {

	private static final int REGULAR = 0;
	private static final int MASTER_SLAVE = 1;
	
	private static final int LINE = 0;
	private static final int BOX = 1;
	private static final int CIRCLE = 2;
	private static final int IMAGE = 3;

	public static AbstractEmitter createEmitter(EmitterSettings eSettings, ShapeSettings sSettings) {
		EmitterShape shape = getShape(sSettings);
		AbstractEmitter emitter = null;
		int kind = (int) eSettings.getValue(EmitterSettings.KIND);
		switch (kind) {
		case REGULAR:
			emitter = new Emitter(eSettings, shape);
			break;
		case MASTER_SLAVE:
			emitter = new MasterSlaveEmitter(eSettings, shape);
			break;
		}
		return emitter;
	}

	public static EmitterShape getShape(ShapeSettings settings) {
		EmitterShape shape = null;
		int kind = (int) settings.getValue(ShapeSettings.KIND);
		switch (kind) {
		case LINE:
			shape = new LineShape(settings);
			break;
		case BOX:
			shape = new BoxShape(settings);
			break;
		case CIRCLE:
			shape = new CircleShape(settings);
			break;
		case IMAGE:
			shape = new ImageShape(settings);
			break;
		}
		return shape;
	}
}
