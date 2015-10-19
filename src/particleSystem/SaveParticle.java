package particleSystem;

import graphics.Graphics;

import java.util.Random;

import com.jogamp.opengl.GL2;

/**
 * This class represents a particle used in the magic particle system.
 * A magic particle system is used in the game when a character uses
 * a magic, like fire, ice and so on.
 * 
 * @author		Kalle Sjöström
 * @version 	0.7.0 - 01 Oct 2008
 */
public class SaveParticle {
	
	private float[] pos = new float[3];
	private float[] rgb = new float[3];
	private float speed;
	private float life;
	private float fade;
	private static final float size = .3f;
	private static final Random rand = new Random();
	
	private static float[][] poses;
	
	static {
		poses = new float[361][2];
		for (int i = 0; i <= 360; i++) {
			double theta = Math.toRadians(i - 180);
			poses[i][0] = (float) (.9 * Math.cos(theta));
			poses[i][1] = (float) (.9 * Math.sin(theta));
		}
	}
	
	protected SaveParticle() {
		resurrect();
		int theta = (int) (rand.nextFloat() * 360);
		pos[0] = poses[theta][0] + SaveSystem.pos[0];
		pos[2] = poses[theta][1] + SaveSystem.pos[1];
		for (int i = 0; i < 400; i++) {
			update();
		}
	}
	
	protected void update() {
		pos[1] += speed;
		if (pos[1] > 1 || life <= 0) {
			resurrect();
		} else {
			life -= fade;
		}
		for (int i = 0; i < 3; i++) {
			rgb[i] += .01f * i + .01f;
			if(rgb[i] > 1) {
				rgb[i] = 0;
			}
		}
	}
	
	private void resurrect() {
		speed = ((float) (rand.nextFloat() * 4) + 8) * .001f;
//		pos[0] = poses[theta][0] + SaveSystem.pos[0];
		pos[1] = -2f;
//		pos[2] = poses[theta][1] + SaveSystem.pos[1];
		life = 1;
		fade = (float) (rand.nextFloat() / 100f) + .0025f;
		rgb[0] = (float) rand.nextFloat();
		rgb[1] = (float) rand.nextFloat();
		rgb[2] = (float) rand.nextFloat();
	}
	
	protected void drawParticle(Graphics g, int dir) {
		g.setColor(rgb, life);
		float x1 = pos[0] - size/2;
		float y1 = pos[1] - size/2;
		float y2 = y1 + size/2;
		float z1 = pos[2] - size/2;
		GL2 gl = Graphics.gl2;
		gl.glTexCoord2i(0, 0);
		gl.glVertex3f(x1, y1, z1);
		switch (dir) {
		case 0 : s3(gl, x1, y1, y2, z1); break;
		case 3 : s2(gl, x1, y1, y2, z1); break;
		case 2 : s1(gl, x1, y1, y2, z1); break;
		case 1 : s4(gl, x1, y1, y2, z1); break;
		}
	}
	
	private void s4(GL2 gl, float x1, float y1, float y2, float z1) {
		float z2 = z1 + size/2;
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(x1, y1, z2);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(x1, y2, z2);
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(x1, y2, z1);
	}

	private void s2(GL2 gl, float x1, float y1, float y2, float z1) {
		float z2 = z1 + size/2;
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(x1, y2, z1);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(x1, y2, z2);
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(x1, y1, z2);
	}

	private void s1(GL2 gl, float x1, float y1, float y2, float z1) {
		float x2 = x1 + size/2;
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(x1, y2, z1);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(x2, y2, z1);
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(x2, y1, z1);
	}
	
	private void s3(GL2 gl, float x1, float y1, float y2, float z1) {
		float x2 = x1 + size/2;
		gl.glTexCoord2i(1, 0);
		gl.glVertex3f(x2, y1, z1);
		gl.glTexCoord2i(1, 1);
		gl.glVertex3f(x2, y2, z1);
		gl.glTexCoord2i(0, 1);
		gl.glVertex3f(x1, y2, z1);
	}

	public float getPos(int i) {
		return pos[i];
	}
}
