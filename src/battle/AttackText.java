/*
 * Classname: AttackText.java
 * 
 * Version information: 0.7.0
 *
 * Date: 18/06/2008
 */
package battle;

import graphics.Graphics;
import graphics.TextManager;
import info.BattleValues;
import info.Values;

import java.util.ArrayList;

import com.jogamp.opengl.GL2;

import com.jogamp.opengl.util.awt.TextRenderer;

/**
 * This class manages the text that is displayed when a character or an enemy
 * has attacked. This text could display "Miss!", "Critical Hit!" or simply 
 * "31" for example. The text is then moved upwards while fading like smoke.
 * It uses the TextRenderer from the JOGL distribution.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 18 June 2008.
 */
public class AttackText {

	private ArrayList<Text> textToDraw = new ArrayList<Text>();
	private TextRenderer text;
	private TextRenderer smallText;
	private TextRenderer smallerText;
	private TextRenderer smallestText;
	private static final AttackText attackText = new AttackText();
	
	public static enum textSize {LARGE, MEDIUM, SMALL, SMALLEST};
	private static final float HALF_DISTANCE = 1.39f;
	public static final float HEIGHT_DISTANCE_BETWEEN_TEXT = .1f;

	/**
	 * Creates a new AttackText with the game font from the class Values.
	 * It uses anti-aliasing and the font size is 30.
	 */
	private AttackText() {
		text = TextManager.createRenderer(40);
		smallText = TextManager.createRenderer(30);
		smallerText = TextManager.createRenderer(Values.BOLD, 20);
		smallestText = TextManager.createRenderer(Values.BOLD, 16);
	}
	
	/**
	 * 
	 * 
	 * @return
	 */
	protected static AttackText getAttackText() {
		return attackText;
	}
	
	public void update(float elapsedTime) {
		synchronized (this) {
			for (int i = 0; i < textToDraw.size(); i++) {
				if (!textToDraw.get(i).update()) {
					textToDraw.remove(i);
					i--;
				}
			}
		}
	}

	/**
	 * This method draws the text stored in the object of this class.
	 * It loads the identity matrix and translates the current matrix
	 * 2 units into the screen.
	 * 
	 * @param gl the GL to draw on.
	 */
	public void draw(Graphics g) {
		g.loadIdentity();
		g.translate(0, 0, BattleValues.STANDARD_Z_DEPTH);
		g.scale(.8f);
		synchronized (this) {
			for (int i = 0; i < textToDraw.size(); i++) {
				Text t = textToDraw.get(i);
				t.draw(g);
			}
		}
	}
	
	/**
	 * Checks if the amount of texts in this object is zero. Then it is done.
	 *  
	 * @return true if there are no more texts in this AttackText
	 */
	protected boolean isDone() {
		return textToDraw.size() == 0;
	}
	
	public void reset() {
		textToDraw.clear();
	}
	
	public void addCenter(String info, float centerx, float y, boolean support, textSize size) {
		centerx += HALF_DISTANCE;
		centerx /= 2 * HALF_DISTANCE;
		int cx = Math.round(centerx * Values.ORIGINAL_RESOLUTION[Values.X]);
		float x = 0; // g.calcAlignCenterTest(info, cx, getRenderer(size), 1.8f);
		centerx = x / Values.ORIGINAL_RESOLUTION[Values.X];
		centerx *= (2 * HALF_DISTANCE);
		centerx -= HALF_DISTANCE;
//		centerx -= .1f;
		add(info, centerx, y, support, size);
	}
	
	public void addCenter(int damage, float centerx, float y, boolean support, textSize size) {
		addCenter(String.valueOf(damage), centerx, y, support, size);
	}
	
	public void addCenter(String info, float centerx, float y, boolean support) {
		addCenter(info, centerx, y, support, textSize.SMALLEST);
	}
	
	public void addCenter(int damage, float centerx, float y, boolean support) {
		addCenter(String.valueOf(damage), centerx, y, support, textSize.SMALLEST);
	}
	
	public void addCenter(String info, boolean support) {
		addCenter(info, 0, 0, support);
	}
	
	public void addCenter(String info, boolean support, float y) {
		addCenter(info, 0, y, support);
	}
	
	public void addCenter(int damage, boolean support) {
		addCenter(String.valueOf(damage), 0, 0, support);
	}
	
	public void add(String info, float x, float y, boolean support) {
		add(info, x, y, support, textSize.SMALL);
	}

	private void add(String info, float x, float y, boolean support, textSize size) {
		Text t = new Text(info);
		t.setXY(x, y);
		t.setRenderer(getRenderer(size));
		t.setColor(support ? Text.GREEN : Text.RED);
		textToDraw.add(t);
	}
	
	private TextRenderer getRenderer(textSize size) {
		TextRenderer t = null;
		switch (size) {
		case LARGE:
			t = text;
			break;
		case MEDIUM:
			t = smallText;
			break;
		case SMALL:
			t = smallerText;
			break;
		case SMALLEST:
			t = smallestText;
			break;
		}
		return t;
	}
	
	public static textSize getSize(boolean large) {
		return large ? textSize.MEDIUM : textSize.SMALLEST;
	}

	/**
	 * A Text object displays a text which can be drawn in 3D space.
	 * This text could display "Miss!", "Critical Hit!" or simply 
	 * "31" for example. The text is then moved upwards while fading like smoke.
	 * It uses the TextRenderer from the JOGL distribution.
	 * 
	 * @author 	    Kalle Sj�str�m
	 * @version     0.7.0 - 18 June 2008.
	 */
	private static class Text {

		public static final float[] GREEN = new float[]{0, 1, 0};
		public static final float[] RED = new float[]{1, 0, 0};
		private TextRenderer textRenderer;
		private String text;
		private float life = 1;
		private float x = (float) (Math.random() - .5f) / 2 ;
		private float y = 0;
		private static float FADE = .00048f;
		private float[] color = RED;

		/**
		 * Sets the color of the attack text to the given one.
		 * 
		 * @param newColor the color to set.
		 */
		public void setColor(float[] newColor) {
			color = newColor;
		}

		/**
		 * Constructs a new Text object whit the given string to draw.
		 * 
		 * @param info the string to draw.
		 */
		public Text(String info) {
			text = info;
		}
		
		/**
		 * Sets the x and y position of the text.
		 * 
		 * @param x the x position to set.
		 * @param y the y position to set.
		 */
		public void setXY(float x, float y) {
			this.x = x;
			this.y = y; // - .15f + Values.rand.nextFloat() * .3f;
		}

		/**
		 * Sets the size of the text.
		 * 
		 * @param renderer the renderer to use when drawing the text.
		 */
		public void setRenderer(TextRenderer renderer) {
			textRenderer = renderer;
		}

		/**
		 * Draws the string stored in this Text with the given textRenderer
		 * on the given GL object. This method assumes that the textRenderer
		 * has been initialized with begin3DRendering() and that the 
		 * end3DRendering() is called after this method.
		 * 
		 * @param g the GL object to use to draw.
		 */
		public void draw(Graphics g) {
			textRenderer.begin3DRendering();
			g.setColor(color[0], color[1], color[2], life);
			g.setBlendFunc(GL2.GL_ONE_MINUS_SRC_ALPHA);
			textRenderer.draw3D(text, x, y + (1 - life) / 5, 0, 0.005f);
			textRenderer.end3DRendering();
		}

		/**
		 * Updates this texts life (reduces the life by the value fade). 
		 * This has several implications, the height where the text is drawn, 
		 * is higher when life is low and the color of the text has life as
		 * alpha value.
		 * 
		 * @return true if life is above zero.
		 */
		public boolean update() {
			life -= FADE * Values.LOGIC_INTERVAL;
			return life > 0;
		}
	}
}
