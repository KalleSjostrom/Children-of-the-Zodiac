/*
 * Classname: SubGameMode.java
 * 
 * Version information: 0.7.0
 *
 * Date: 30/09/2008
 */
package organizer;


/**
 * A SubGameMode is a game mode run from an instance of GameMode. This class
 * contains methods for every button press. This is done so that one main class
 * can call a subGameModes buttonPressed() when a button is pressed and it is
 * up to the implementation of the SubGameMode what will happen.
 * 
 * @author 		Kalle Sjöström.
 * @version 	0.7.0 - 30 Sep 2008
 */
public abstract class SubGameMode {

    /**
     * This method is called when the player presses the up button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void upPressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the right button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void rightPressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the down button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void downPressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the left button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void leftPressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the circle button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void circlePressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the cross button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void crossPressed(){
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the square button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void squarePressed() {
    	// Unimplemented. Override to implement effect.
    }
    

    /**
     * This method is called when the player presses the triangle button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void trianglePressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the R1 button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void R1Pressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the R2 button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void R2Pressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the L1 button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void L1Pressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the L2 button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void L2Pressed() {
    	// Unimplemented. Override to implement effect.
    }

    /**
     * This method is called when the player presses the select button.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void selectPressed() {
    	// Unimplemented. Override to implement effect.
    }
    
    /**
     * This method is called when the player presses any button.
     * It is calls after the specific button method has been called.
     * Override this method to implement the consequences to this action.
     * This method does nothing if it is not overridden.
     */
    public void buttonPressed() {
    	// Unimplemented. Override to implement effect.
    }
}
