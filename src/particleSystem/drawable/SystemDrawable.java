package particleSystem.drawable;

import graphics.Graphics;

import java.util.ArrayList;

import particleSystem.Particle;
import bodies.Vector3f;

public interface SystemDrawable {

	public void drawGround(
			Graphics g, boolean destroyed, Vector3f pos, 
			ArrayList<Particle> particles, float particlesLeft);
}
