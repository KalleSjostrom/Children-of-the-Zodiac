package weather;

import graphics.Graphics;

import java.util.Random;

import com.jogamp.opengl.GL2;

public abstract class WeatherParticle {

	protected float[] pos = new float[3];
	protected float[] var = new float[3];
	protected float[] color = getColor();
	protected static Random rand = new Random();
	private double[] vars = new double[3];
	private float originX;
	private float originZ;

	private static float[][] angles;
	private float[] size = getSize();
	private boolean resurrected;
	private static final int WIDTH = 0;
	private static final int HEIGHT = 1;
	private static final int S = 0;
	private static final int SX = 1;
	private static final int SZ = 2;

	static {
		angles = new float[361][2];
		for (int i = 0; i <= 360; i++) {
			double theta = Math.toRadians(i - 180);
			angles[i][0] = (float) (Math.cos(theta));
			angles[i][1] = (float) (Math.sin(theta));
		}
	}

	protected WeatherParticle() {
		resurrect();
		int[] wSize = getWorldSize();
		originX = pos[0] = ((float) rand.nextFloat() * wSize[0]) + wSize[1];
		pos[1] = getInitialHeight();
		originZ = pos[2] = -((float) (rand.nextFloat() * wSize[2]) + wSize[3]);
	}


	protected int[] getWorldSize() {
//		return new int[]{11 * 4, 2*4, 13 * 4, 0};
		return new int[]{13 * 4, 0, 13 * 4, 0};
	}

	protected boolean update(float[] force) {
		pos[0] += force[0] + var[0];
		pos[1] += force[1] + var[1];
		pos[2] += force[2] + var[2];
		if (shouldResurrect()) {
			resurrect();
			return true;
		}
		return false;
	}

	protected void resurrect() {
		pos[0] = originX;
		pos[1] = (float) (rand.nextFloat() * 2 + 2f); // from 2 to 4
		pos[2] = originZ;
		
		var[0] = (float) (rand.nextFloat() - .5f) / 500f;
		var[1] = -(float) (rand.nextFloat()) / 300f;
		var[2] = (float) (rand.nextFloat() - .5f) / 500f;
		resurrected = true;
	}

	protected boolean drawParticle(Graphics g, int dir, float[] fs, boolean changed, boolean front) {
		double s;
		double sx;
		double sz;
		if (changed || resurrected) {
			sx = vars[SX] = pos[0] - fs[0];
			sz = vars[SZ] = pos[2] - fs[1];
			s = vars[S] = 
				sx * angles[dir + 180][0] + 
				sz * angles[dir + 180][1];
			resurrected = false;
		} else {
			sx = vars[SX];
			sz = vars[SZ];
			s = vars[S];
		}
		/*
		 * s is like the distance from the camera to the far clipping plane
		 * or the projection of the snow flake on the line-of-sight.
		 * 
		 * 4 is one square
		 */
		//int farClip = 20;
		float farClip = front ? 7.5f : 20;
		float nearClip = front ? 3 : 7.5f;
		boolean inside;
		inside = s > 3 && s < 7;
		if (s > nearClip && s < farClip) { // 20 * 8
			// Distance from the eye to the snowflake.
			double distSquared = sx * sx + sz * sz;
			double sSquared = s * s;
			if ((3.7 * distSquared) < 5 * sSquared) {
				/*if (front) {
					gl.glColor4f(1, 0, 0, color[3]);
				} else {
				
				*/
				GL2 gl = g.getGL();
					gl.glColor4f(1, 1, 1, color[3]);
				//}
				float height = /*(1.3f - color[3]) */ size[HEIGHT];
				float width = /*(1.3f - color[3]) */ size[WIDTH];
				float x1 = pos[0] - width / 2f;
				float y1 = pos[1] - height / 2f;
				float y2 = y1 + height;
				float z1 = pos[2] - width / 2f;
				gl.glTexCoord2i(0, 0);
				gl.glVertex3f(x1, y1, z1);
				if ((dir > 45 && dir < 225) || dir < -135) {
					gl.glTexCoord2i(0, 1);
					gl.glVertex3f(x1, y2, z1);
					if ((dir > -135 && dir < -45) || (dir > 45 && dir < 135)) {
						float x2 = x1 + width;
						gl.glTexCoord2i(1, 1);
						gl.glVertex3f(x2, y2, z1);
						gl.glTexCoord2i(1, 0);
						gl.glVertex3f(x2, y1, z1);
					} else {
						float z2 = z1 + width;
						gl.glTexCoord2i(1, 1);
						gl.glVertex3f(x1, y2, z2);
						gl.glTexCoord2i(1, 0);
						gl.glVertex3f(x1, y1, z2);
					}
				} else {
					gl.glTexCoord2i(1, 0);
					if ((dir > -135 && dir < -45) || (dir > 45 && dir < 135)) {
						float x2 = x1 + width;
						gl.glVertex3f(x2, y1, z1);
						gl.glTexCoord2i(1, 1);
						gl.glVertex3f(x2, y2, z1);
					} else {
						float z2 = z1 + width;
						gl.glVertex3f(x1, y1, z2);
						gl.glTexCoord2i(1, 1);
						gl.glVertex3f(x1, y2, z2);
					}
					gl.glTexCoord2i(0, 1);
					gl.glVertex3f(x1, y2, z1);
				}
			}
		}
		return inside;
	}

	protected abstract float[] getSize();
	protected abstract float[] getColor();
	protected abstract boolean shouldResurrect();
	protected abstract float getInitialHeight();
}