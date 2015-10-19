package organizer;

import info.Values;

import java.awt.Cursor;
import java.awt.DisplayMode;
import java.awt.Frame;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.awt.Point;
import java.awt.Toolkit;
import java.awt.Window;
import com.jogamp.opengl.awt.GLCanvas;
import com.jogamp.opengl.GLCapabilities;
import com.jogamp.opengl.GLProfile;

import javax.swing.SwingUtilities;
import java.util.logging.*;

public class Screen extends Frame {

	/**
	 * Generated serial version ID.
	 */
	private static final long serialVersionUID = 1080765186805003344L;
	private static GraphicsDevice device;
	private FPSAnimator anim;
	private boolean fullScreen;
	private int frameWidth;
	private int frameHeight;
	private static Screen s = new Screen();
	private GLCanvas canvas;
	private static Logger logger = Logger.getLogger("Screen");
	
	private Screen() {
		super("Children of the Zodiac");
	}
	
	public static Screen getScreen() {
		return s;
	}
	
	protected void init(GameCore core) {
		SwingUtilities.invokeLater(setFullScreen(core));
		SwingUtilities.invokeLater(startAnimation());
	}
	
	private Runnable setFullScreen(final GameCore core) {
		final Screen screen = this;
		Runnable r = new Runnable() {
			public void run() {
//				screen.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
				fullScreen = Values.check(Values.FULL_SCREEN);
				screen.setUndecorated(fullScreen);
				screen.setIgnoreRepaint(true);
				screen.setResizable(false);
				
				DisplayMode displayMode = Values.getDisplayMode();
						
				device = GraphicsEnvironment.
						getLocalGraphicsEnvironment().getDefaultScreenDevice();
				if (fullScreen && device.isFullScreenSupported()) {
					device.setFullScreenWindow(screen);
					if (device.isDisplayChangeSupported()) {
						try {
							device.setDisplayMode(displayMode);
						} catch (IllegalArgumentException ex) {
							// ignore
						}
					}
				} else {
					if (fullScreen) {
						logger.log(Level.WARNING, "Display device does not support full screen");
					}
				}
				
				frameWidth = displayMode.getWidth();
				frameHeight = displayMode.getHeight();
				
				screen.setSize(frameWidth, frameHeight);
				Values.setResolution(frameWidth, frameHeight);
				GLCapabilities capabilities = new GLCapabilities(GLProfile.get(GLProfile.GL4));
				capabilities.setDoubleBuffered(true);
				checkCapabilities(capabilities);
				
				canvas = new GLCanvas(capabilities);
				canvas.addGLEventListener(new GameEventListener(core));

				add(canvas);
				canvas.setCursor(getCursor());
				
				anim = new FPSAnimator(canvas, (int) (Values.FPS));
				screen.setVisible(true);
				canvas.setFocusable(false);
			}
		};
		return r;
	}
	public void setFPS(int fps) {
		Values.FPS = fps;
		Values.INTERVAL = 1000f / Values.FPS;
		Values.LOGIC_INTERVAL = 1000f / Values.FPS;
	}
	
	private Runnable startAnimation() {
		Runnable r = new Runnable() {
			public void run() {
				while (anim == null) { Values.sleep(100); }
				anim.start();
			}
		};
		return r;
	}

	public Cursor getCursor() {
		return Toolkit.getDefaultToolkit().createCustomCursor(
				Toolkit.getDefaultToolkit().getImage(""),
				new Point(0,0), "invisible");
	}
	
	public void swapFullScreen() {
		fullScreen = !fullScreen;
		this.dispose();
		this.setResizable(fullScreen);
		this.setUndecorated(fullScreen);
		device.setFullScreenWindow(fullScreen ? this : null);
		if (fullScreen) {
			this.validate();
		} else {
			this.setVisible(true);
		}
	}

	protected void exitScreen() {
		anim.stop();
		Window window = device.getFullScreenWindow();
		if (window != null) {
			window.dispose();
		}
		device.setFullScreenWindow(null);
	}
	
	private void checkCapabilities(GLCapabilities capabilities) {
		if (!capabilities.getHardwareAccelerated()) {
			logger.log(Level.WARNING, "Default GLCapabilities not hardware accelerated!");
			logger.info("Trying to set...");
			capabilities.setHardwareAccelerated(true);
		}
		if (!capabilities.getDoubleBuffered()) {
			logger.log(Level.WARNING, "Default GLCapabilities not double buffered!");
			logger.info("Trying to set...");
			capabilities.setDoubleBuffered(true);
		}
		if (capabilities.getRedBits() != 8) {
			logger.log(Level.WARNING, "Red bits set to " + capabilities.getRedBits());
			logger.info("Trying to set...");
			capabilities.setRedBits(8);
		}	
		if (capabilities.getGreenBits() != 8) {
			logger.log(Level.WARNING, "Green bits set to " + capabilities.getGreenBits());
			logger.info("Trying to set...");
			capabilities.setGreenBits(8);
		}
		if (capabilities.getBlueBits() != 8) {
			logger.log(Level.WARNING, "Blue bits set to " + capabilities.getBlueBits());
			logger.info("Trying to set...");
			capabilities.setBlueBits(8);
		}
		if (capabilities.getAlphaBits() != 8) {
			logger.log(Level.WARNING, "Alpha bits was " + capabilities.getAlphaBits());
			logger.info("Trying to set to 8...");
			capabilities.setAlphaBits(8);
			logger.log(Level.WARNING, "Alpha bits is set to " + capabilities.getAlphaBits());
		}
	}
}