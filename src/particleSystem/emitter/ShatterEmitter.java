package particleSystem.emitter;

import graphics.GraphicHelp;
import graphics.ImageHandler;

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Stack;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;
import battle.enemy.EnemyInfo;
import bodies.Vector3f;

public class ShatterEmitter extends Emitter {

	private boolean imageDateSet;
	private static String enemyName;
	private EnemyInfo enemyInfo;
	private float scale;
	private static int width;
	private static int height;
	private static int[][] pixels;
	private static int[][] alpha;

	public ShatterEmitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitPeriod, int limit) {
		super(particlePool, particles, info, emitPeriod, limit);
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!isDestroyed()) {
			if (!imageDateSet) {
				imageDateSet = true;
				getImage(system);
				enemyInfo = system.getEnemy().getInfo(); 
				scale = enemyInfo.get(EnemyInfo.SCALE) * 800;
			}
			addTime(elapsedTime);
			boolean empty = false;
			while (!empty && getTime() >= getemitPeriod()) {
				if (okToEmit()) {
					Particle p = getParticle(system);
					Vector3f pos = p.getPosition();
					
					float a = 0;
					int x = 0;
					int y = 0;
					Vector3f c = null;
					int tries = 0;
					while (a < .5f && tries < 50) {
						tries++;
						x = (int) (Math.random() * width);
						y = (int) (Math.random() * height);
						a = getAlpha(x, y);
					}
					if (tries >= 50) {
						continue;
					}
					c = getColor(x, y);
					pos.y = y / 200f;
					pos.x = ((x - 0.5f*width) / 200f);
					
					pos.x *= scale;
					pos.y *= scale;
					pos.y += enemyInfo.get(EnemyInfo.HEIGHT);
					pos.x += enemyInfo.get(EnemyInfo.X_OFFSET);
					pos.z = getInfo().getSource().z;
					p.resurrect(system, pos);
					p.setColor(c, a);
					getParticles().add(p);
				}
				empty = !okToEmit();
				addTime(-getemitPeriod());
			}
		}
	}
	
	private static void getImage(ParticleSystem system) {
		String name = system.getEnemy().getCurrentImageName();
		BufferedImage image = 
			ImageHandler.getImage(name);
		if (enemyName != null && name.compareTo(enemyName) == 0) {
			return;
		}
		float w = image.getWidth();
		float h = image.getHeight();
		
		float scalex = .25f;
		float scaley = .25f;
		w *= scalex;
		h *= scaley;
		
		width = Math.round(w);
		height = Math.round(h);
		image = GraphicHelp.scaleImage(image, width, height);

		pixels = new int[height][width * 4];
		alpha = new int[height][width];

		for (int i = 0; i < height; i++) {
			image.getData().getPixels(0, i, width, 1, pixels[(height - 1) - i]);
			image.getAlphaRaster().getPixels(0, i, width, 1, alpha[(height - 1) - i]);
		}
	}
	
	private Vector3f getColor(int x, int y) {
		x *= 4;
		return new Vector3f(
				pixels[y][x]/255f, pixels[y][x+1]/255f, pixels[y][x+2]/255f);
	}
	
	private static float getAlpha(int x, int y) {
		if (alpha[y][x]/255f == 1) {
			float temp = alpha[y][x]/255f;
			alpha[y][x] = 0;
			return temp;
		}
		return alpha[y][x]/255f;
	}
}
