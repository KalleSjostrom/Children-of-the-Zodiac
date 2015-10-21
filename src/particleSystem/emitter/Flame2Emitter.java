package particleSystem.emitter;

import graphics.GraphicHelp;
import graphics.ImageHandler;

import info.Values;

import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.Stack;

import particleSystem.Particle;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystem.InterpolationInfo;
import battle.enemy.EnemyInfo;
import bodies.Vector3f;

public class Flame2Emitter extends Emitter {

	private boolean imageDateSet;
	private EnemyInfo enemyInfo;
	private float scale;
	private float tempHeight;
	private static int width;
	private static int height;
	private static int[][] pixels;
	private static int[][] alpha;

	public Flame2Emitter(Stack<Particle> particlePool,
			ArrayList<Particle> particles, InterpolationInfo info, float emitPeriod, int limit) {
		super(particlePool, particles, info, emitPeriod, limit);
	}

	public void update(ParticleSystem system, float elapsedTime) {
		if (!isDestroyed()) {
			if (!imageDateSet) {
				imageDateSet = true;
				getImage();
				enemyInfo = system.getEnemy().getInfo(); 
				tempHeight = system.getEnemy().getTempHeight();
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
					int tries = 0;
					double lastr = 0;
					double r = 0;
					while (a < .5f && tries < 10) {
						tries++;
						lastr = r;
						r = Math.random();
						boolean b = tries % 2 == 0;
						x = (int) ((b ? r : lastr) * width);
						y = (int) ((b ? lastr : r) * height);
						a = getAlpha(x, y);
 					}
					if (tries >= 10) {
						continue;
					}
					pos.y = y / 200f;
					pos.x = ((x - 0.5f*width) / 200f);
					
					pos.x *= scale;
					pos.y *= scale;
					pos.y += enemyInfo.get(EnemyInfo.HEIGHT) + tempHeight;
					pos.x += enemyInfo.get(EnemyInfo.X_OFFSET);
					pos.z = getInfo().getSource().z;
					p.resurrect(system, pos);
//					p.setColor(c, a);
					getParticles().add(p);
				}
				empty = !okToEmit();
				addTime(-getemitPeriod());
			}
		}
	}
	
	public static void getImage() {
		String name = Values.BattleImages + "stroke3.png";
		BufferedImage image = 
			ImageHandler.getImage(name);

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
	
	private static float getAlpha(int x, int y) {
		if (alpha[y][x]/255f == 1) {
			float temp = alpha[y][x]/255f;
//			alpha[y][x] = 0;
			return temp;
		}
		return alpha[y][x]/255f;
	}
}
