/*
 * Classname: Animation.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/01/2008
 */
package villages.utils;

import graphics.GameTexture;
import graphics.Graphics;
import graphics.ImageHandler;

import java.util.ArrayList;

import com.jogamp.opengl.GL2;

/**
 * This class animates the characters in the game.
 * 
 * @author 		Kalle Sj�str�m
 * @version 	0.7.0 - 21 Jan 2008
 */
public class Animation {
    
	public byte currFrameIndex;
	
    private ArrayList<AnimFrame> frames;
    private float animTime;
    private float totalDuration;
    private String name;

    /**
     * Creates a new, empty Animation.
     */
    public Animation() {
//    	this.name = name;
    	frames = new ArrayList<AnimFrame>();
    }
    
    /**
     * Adds an image to the animation with the specified
     * duration (time to display the image).
     * 
     * @param name the image to add.
     * @param duration the time to display the image.
     */
    public void addFrame(String name, int duration) {
        totalDuration += duration;
        frames.add(new AnimFrame(name, totalDuration));
    }
    
    /**
     * Changes the image at position i in the frames.
     * 
     * @param i the index of the frame to be changed.
     * @param image the new image.
     */
    public void changePic(int i, String image) {
    	frames.get(i).changeImage(image);
    }
    
    /**
     * Updates this animation's current image (frame), if necessary.
     * 
     * @param elapsedTime the amount of time that has elapsed.
     */
    public void update(float elapsedTime) {
        if (frames.size() > 1) {
            animTime += elapsedTime;
            if (animTime >= totalDuration) {
                animTime = 0;
                currFrameIndex = 0;
            }

            if (animTime > frames.get(currFrameIndex).endTime) {
            	currFrameIndex++;
            }
        }
    }


    /**
     * Gets this Animation's current image. 
     * 
     * @return this animation current image or 
     * null, if this animation has no images.
     */
    public String getImage() {
        if (frames.size() == 0) {
            return null;
        }
        return frames.get(currFrameIndex).image;
    }
    
    public void draw(Graphics g, int x, int y) {
		GameTexture tex = ImageHandler.getTexture(name);
		tex.bind(g);
		
		int ny = (int) (y);
		int nyh = (int) (y + 55);
		int xw = (int) (x + 36);
		
		float tx = ((currFrameIndex % 4) * 36) / (float) tex.getWidth();
		float ty = ((currFrameIndex / 4) * 36) / (float) tex.getHeight();
		
		float txw = tx + 36.0f / tex.getWidth();
		float tyh = ty + 55.0f / tex.getHeight();
		
		GL2 gl = Graphics.gl2;
		g.beginQuads();
		gl.glTexCoord2f(tx, tyh);
		gl.glVertex2i((int) x, nyh);

		gl.glTexCoord2f(txw, tyh);
		gl.glVertex2i((int) xw, nyh);

		gl.glTexCoord2f(txw, ty);
		gl.glVertex2i((int) xw, ny);

		gl.glTexCoord2f(tx, ty);
		gl.glVertex2i((int) x, ny);
		
		g.end();
    }

    /**
     * The private AnimFram class
     * 
     * This class represents one frame of animation.
     * 
     * @author 	    Kalle Sj�str�m
     * @version     0.7.0 - 21 Jan 2008
     */
    private class AnimFrame {

    	private String image;
    	private float endTime;

        /**
         * Constructs a new animation frame with the given image 
         * and time which this animation should end.
         * 
         * @param image the image of this frame.
         * @param totalDuration the frames end time.
         */
        private AnimFrame(String image, float totalDuration) {
            this.image = image;
            this.endTime = totalDuration;
        }
        
        /**
         * Change this frames image.
         * 
         * @param image the new image.
         */
        private void changeImage(String image) {
            this.image = image;
        }
    }
}
