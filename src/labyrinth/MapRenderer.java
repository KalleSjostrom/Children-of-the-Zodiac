package labyrinth;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;
import graphics.Utils3D;
import info.LabyrinthMap;

import com.jogamp.opengl.glu.GLU;
import com.jogamp.opengl.glu.GLUquadric;

import battle.Hideable;

public class MapRenderer extends Hideable {
	
	public static final float[] MAP_POSITION = new float[]{-.59f, .365f};
	
	private static final GLU glu = new GLU();
	private static final GLUquadric quad = glu.gluNewQuadric();
	
	private LabyrinthMap map;

	public MapRenderer(LabyrinthMap map) {
		super(0);
		this.map = map;
		setLimit(false);
		setMovementSpeed(false);
	}

	public void initDraw(Graphics g) {
		setPos(MAP_POSITION);	
		setZdepth(-1.6f);
	}
	
	public void draw(
			Graphics g, float alpha, int angle, 
			int origin, int lastOrigin) {
		super.translate(g);
		drawBackground(g, .25f);
		
		g.setColor(1);
		g.scale(.5f);
		g.push();
		g.translate(-.45f, .45f, 0);
		drawBackground(g, .1f);
		
		g.setColor(1);
		GameTexture n = ImageHandler.getTexture(LabyrinthMap.directions[0]);
		angle += 450;
		g.rotate(angle, 0, 0, 1);
		Utils3D.draw3DwithHW(g, n.getTexture(), 0, 0, 0, .00035f);
		g.pop();
		
		g.push();
		angle += 360;
		g.rotate(angle, 0, 0, 1);
		
		map.draw2(g, alpha, origin, lastOrigin, angle);
		
		g.pop();
		GameTexture t = ImageHandler.getTexture(LabyrinthMap.arrows[0]);
		g.setImageColor(1, .85f, 0, 1);
		Utils3D.draw3D(g, t.getTexture(), 0, 0, 0, .09f);
	}
	
	private void drawBackground(Graphics g, float size) {
		g.setTextureEnabled(false);
		g.setColor(0, 0, 0, .5f);
		glu.gluDisk(quad, 0, size, 50, 1);
		g.setTextureEnabled(true);
	}

	@Override
	public void draw(Graphics g) {}
}
