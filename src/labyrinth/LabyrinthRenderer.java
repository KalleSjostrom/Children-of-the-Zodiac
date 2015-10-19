/*
 * Classname: LabyrinthRenderer.java
 * 
 * Version information: 0.7.0
 *
 * Date: 25/05/2008
 */
package labyrinth;

import graphics.Graphics;
import info.LabyrinthMap;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import com.jogamp.opengl.GL2;

import weather.RainSystem;
import weather.SnowSystem;
import weather.WeatherSystem;

/**
 * This class renders the labyrinth. It draws all the walls, floors and 
 * ceilings with textures. It does not draw any inventory, like chests, doors
 * and so on.
 * 
 * @author 		Kalle Sjöström
 * @version 	0.7.0 - 25 May 2008.
 */
public class LabyrinthRenderer {

	private ArrayList<LabyrinthTexture> textures;
	
	private boolean[] settings;
	private float[][] settingValues;
	private LabyrinthMap map;

	private int tangent = -1;

	/**
	 * Creates a new renderer which will use the given list of textures when 
	 * rendering the labyrinth. It also loads all the textures given.
	 * 
	 * @param textures the hash map containing the textures.
	 */
	public LabyrinthRenderer(ArrayList<LabyrinthTexture> textures) {
		this.textures = textures;

	}
	
	public void setSettings(boolean[] settings, float[][] settingValues) {
		this.settings = settings;
		this.settingValues = settingValues;
	}

	/**
	 * Sets the map to be rendered.
	 * 
	 * @param map the labyrinth map to draw
	 */
	public void setMap(LabyrinthMap map) {
		this.map = map;
	}
	
	protected boolean getSetting(int index) {
		return settings[index];
	}
		
	protected float[] getSettingValue(int index) {
		return settingValues[index];
	}

	public void init(Graphics g) {
		for (int i = 0; i < textures.size(); i++) {
			textures.get(i).loadTexture();
		}
	}

	public void draw(Graphics g) {
		HashMap<Integer, Node> nodes = map.getNodes();
		Iterator<Integer> it = nodes.keySet().iterator();
		
		for (int j = 0; j < 5; j++) {
			int temp = j;
			if (j == MapLoader.WALL) {
				temp = j + 1;
			} else if (j == MapLoader.ROOF) {
				temp = j - 1;
			}
			for (int i = MapLoader.textureNorm[temp][0]; i < MapLoader.textureNorm[temp][1]; i++) {
				textures.get(i).getTexture().bind(g);
				g.beginQuads();
				it = nodes.keySet().iterator();
				while (it.hasNext()) {
					int addr = it.next();
					Node n = nodes.get(addr);
					switch (temp) {
					case MapLoader.FLOOR : n.drawFloors(g, i); break;
					case MapLoader.WALL : n.drawWall(g, i, false, tangent); break;
					case MapLoader.ROOF : if (!settings[MapLoader.SKY]) n.drawRoof(g, i); break;
					case MapLoader.CARPET_FLOOR : n.drawFloors(g, i); break;
					case MapLoader.PILLAR_WALLS : n.drawWall(g, i, true, tangent); break;
					}
				}
				g.end();
			}
		}
	}

	/**
	 * This method adds fog to the 3D scene. It currently uses linear 
	 * fog density. 
	 * 
	 * Ideas to extend this method: 
	 * parameters to change the fog density.
	 * parameters to change the color of the fog (slightly more blue in ice cavern).
	 * parameters to change fog mode. (GL2.GL_LINEAR, GL2.GL_EXP, GL2.GL_EXP2).
	 * parameters to change fog end. (currently 4 times Node.DISTANCE).
	 * 
	 * Problems:
	 * The normal does not work and the fog makes the middle of long walls white.
	 * This could maybe be solved by drawing each and every wall as a separate quad
	 * with separate normals.
	 * 
	 * @param gl the GL to add the fog to.
	 */
	public void addFog(Graphics g) {
		GL2 gl = Graphics.gl2;
		if (settings[MapLoader.FOG]) {
			gl.glEnable(GL2.GL_FOG);
			gl.glFogf(GL2.GL_FOG_MODE, GL2.GL_EXP);
			float[] fog = settingValues[MapLoader.FOG];
			float[] color = new float[4];
			for (int i = 0; i < color.length; i++) {
				color[i] = fog[i];
			}
			gl.glFogf(GL2.GL_FOG_DENSITY, fog[MapLoader.FOG_DENSITY]);
			gl.glFogfv(GL2.GL_FOG_COLOR, color, 0);
			gl.glHint(GL2.GL_FOG_HINT, GL2.GL_NICEST);
			gl.glClearColor(color[0], color[1], color[1], color[2]);
		} else {
			gl.glDisable(GL2.GL_FOG);
		}
	}

	/**
	 * This method adds light to the 3D scene. It currently uses quadratic 
	 * attenuation for the distance fall off.
	 * 
	 * Ideas to extend this method:
	 * Spot function (more like a flash light).
	 * parameters the change the color of the light. (more orange for fire sometimes?).
	 * 
	 * @param g the GL to add the light to.
	 */
	public void addLight(Graphics g) {
		GL2 gl = Graphics.gl2;
		if (settings[MapLoader.LIGHT_0]) {
			addLight(gl, MapLoader.LIGHT_0, GL2.GL_LIGHT0);
		} else {
			gl.glDisable(GL2.GL_LIGHT0);
		}
		if (settings[MapLoader.LIGHT_1]) {
			addLight(gl, MapLoader.LIGHT_1, GL2.GL_LIGHT1);
		} else {
			gl.glDisable(GL2.GL_LIGHT1);
		}
	}
	
    private void addLight(GL2 gl, int index, int glLight) {
    	float[] light = settingValues[index];
    	
    	gl.glLightfv(glLight, GL2.GL_POSITION, light, MapLoader.LIGHT_POSITION);
    	gl.glLightfv(glLight, GL2.GL_AMBIENT, light, MapLoader.LIGHT_AMBIENT);
    	gl.glLightfv(glLight, GL2.GL_DIFFUSE, light, MapLoader.LIGHT_DIFFUSE);
    	gl.glLightfv(glLight, GL2.GL_SPECULAR, light, MapLoader.LIGHT_SPECULAR);

    	gl.glLightf(glLight, GL2.GL_CONSTANT_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION]);
    	gl.glLightf(glLight, GL2.GL_LINEAR_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION + 1]);
    	gl.glLightf(glLight, GL2.GL_QUADRATIC_ATTENUATION, light[MapLoader.LIGHT_ATTENUATION + 2]);
    	gl.glEnable(glLight);
	}

    public void setLight(Graphics g) {
    	GL2 gl = Graphics.gl2;
    	gl.glLightfv(GL2.GL_LIGHT3, GL2.GL_POSITION, new float[]{0, 0, 0, 1}, 0);
    	gl.glLightfv(GL2.GL_LIGHT3, GL2.GL_AMBIENT, new float[]{1, 1, 1, 1}, 0);
    	gl.glLightfv(GL2.GL_LIGHT3, GL2.GL_DIFFUSE, new float[]{1, 1, 1, 1}, 0);
    	gl.glLightfv(GL2.GL_LIGHT3, GL2.GL_SPECULAR, new float[]{1, 1, 1, 1}, 0);

    	gl.glLightf(GL2.GL_LIGHT3, GL2.GL_CONSTANT_ATTENUATION, 1);
    	gl.glLightf(GL2.GL_LIGHT3, GL2.GL_LINEAR_ATTENUATION, 0.01f);
    	gl.glLightf(GL2.GL_LIGHT3, GL2.GL_QUADRATIC_ATTENUATION, 0.015f);
	}
    
	public WeatherSystem getWeatherSystem() {
		WeatherSystem system = null;
		if (settings[MapLoader.USE_SNOW]) {
			system = new SnowSystem();
		} else if (settings[MapLoader.USE_RAIN]) {
			system = new RainSystem();
		}
		return system;
	}

	public void renderSky(Graphics g) {
		/*if (settings[MapLoader.SKY]) {
			g.push();
			g.loadIdentity();
			g.setLightEnabled(false);
			g.setDepthTestEnabled(false);
			g.setTextureEnabled(false);
			GL2 gl = Graphics.gl2;
			// TODO: change to g.setCullFaceEnabled(false);
			gl.glDisable(GL2.GL_CULL_FACE);
			float[] colors = settingValues[MapLoader.SKY];
			g.beginQuads();
			g.setColorv(colors, MapLoader.SKY_TOP_COLOR);
			gl.glVertex3f(-2, .827f, -2);
			gl.glVertex3f(2, .827f, -2);
			
			g.setColorv(colors, MapLoader.SKY_BOTTOM_COLOR);
			gl.glVertex3f(2, 0, -2);
			gl.glVertex3f(-2, 0, -2);
			g.end();
			gl.glEnable(GL2.GL_CULL_FACE);
			
			g.setDepthTestEnabled(true);
			g.setTextureEnabled(true);
			g.pop();
		}*/
	}

	public void setMaterial(Graphics g) {
		float[] material = settingValues[MapLoader.MATERIAL];
		GL2 gl = Graphics.gl2;
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_AMBIENT, material, MapLoader.MATERIAL_AMBIENT);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_DIFFUSE, material, MapLoader.MATERIAL_DIFFUSE);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_SPECULAR, material, MapLoader.MATERIAL_SPECULAR);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_EMISSION, material, MapLoader.MATERIAL_EMISSION);
		gl.glMaterialfv(GL2.GL_FRONT, GL2.GL_SHININESS, material, MapLoader.MATERIAL_SHININESS);
	}
}
