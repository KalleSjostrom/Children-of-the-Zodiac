package battleBacks;

import graphics.Graphics;

import java.util.Random;

import bodies.Vector3f;

public abstract class BattleParticle {

	protected Vector3f pos = new Vector3f();
	protected Vector3f var = new Vector3f();
	protected float[] color = getColor();
	protected static Random rand = new Random();
	private float originX;
	private float originZ;

	private float[] size = getSize();
	private static final int WIDTH = 0;
	private static final int HEIGHT = 1;
	private static final int s = 2;
	private static final float[] WORLD_SIZE = new float[]{8 * s, -4 * s, 4 * s, 7f};

	protected BattleParticle() {
		resurrect();
		originX = pos.x = ((float) rand.nextFloat() * WORLD_SIZE[0]) + WORLD_SIZE[1];
		pos.y = getInitialHeight();
		originZ = pos.z = -((float) (rand.nextFloat() * WORLD_SIZE[2]) + WORLD_SIZE[3]);
	}

	protected boolean update(Vector3f force) {
		pos.addLocal(force.add(var));
		if (shouldResurrect()) {
			resurrect();
			return true;
		}
		return false;
	}

	protected void resurrect() {
		pos.set(originX, (float) (rand.nextFloat() * 2 + 2f), originZ);
		var.set(
				(float) (rand.nextFloat() - .5f) / 500f,
				-(float) (rand.nextFloat()) / 300f,
				(float) (rand.nextFloat() - .5f) / 500f);
//		resurrected = true;
	}

	protected void drawParticle(Graphics g, int dir, float[] fs, boolean changed, boolean front) {
		g.setColor(1, 1, 1, color[3]);
		float height = size[HEIGHT];
		float width = size[WIDTH];
		g.drawCenteredCurrent2D(pos, height, width);
	}

	protected abstract float[] getSize();
	protected abstract float[] getColor();
	protected abstract boolean shouldResurrect();
	protected abstract float getInitialHeight();
}