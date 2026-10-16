package particleSystem.drawable;

import graphics.Graphics;

import java.util.ArrayList;

import com.jogamp.opengl.GL2;

import particleSystem.Particle;
import bodies.Vector3f;

public class SwordBackground implements SystemDrawable {
	
	private Vector3f source;
	private Vector3f target;

	public SwordBackground(Vector3f source, Vector3f target) {
		this.source = source;
		this.target = target;
	}

	public void drawGround(
			Graphics g, boolean destroyed, Vector3f pos, 
			ArrayList<Particle> particles, float particlesLeft) {
		if (!destroyed) {
			float tSize = 0;
			float ySize = .2f;
			//		Vector3f pos = getPosition();
			float x = Math.abs(pos.x - target.x) > ySize ? pos.x : target.x;
			float y = Math.abs(pos.y - target.y) > ySize ? pos.y : target.y;
			float z = target.z;
			float alpha = particles.size() == 0 ? 0 : particlesLeft / (float) particles.size();
			GL2 gl = g.getGL();
			g.setColor(1, 1, 1, alpha);
			g.beginQuads();

			gl.glTexCoord2i(0, 0);
			gl.glVertex3f(source.x - tSize, source.y - ySize, z);
			gl.glTexCoord2i(1, 0);
			gl.glVertex3f(x + tSize, source.y - ySize, z);
			gl.glTexCoord2i(1, 1);
			gl.glVertex3f(x + tSize, y + ySize, z);
			gl.glTexCoord2i(0, 1);
			gl.glVertex3f(source.x - tSize, y + ySize, z);
			g.end();
		}
	}
}
