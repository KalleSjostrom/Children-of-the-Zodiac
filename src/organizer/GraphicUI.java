package organizer;
import info.Values;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.GridLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.StringTokenizer;

import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import javax.swing.border.Border;

/**
 * This is the graphical part of the map editor. This is where the user can
 * build some labyrinths for the Zodiac Children. In the editor, the user can
 * also try the labyrinth directly. 
 * 
 * @author 	Kalle Sjöström
 * @version 	0.5.0 - 03 Aug 2008.
 */
public class GraphicUI {

	private static final long serialVersionUID = 3148997464066137872L;
	
	private JComboBox cb;
	private HashMap<String, String> settings = new HashMap<String, String>();
	
	public static final String RESOLUTION_STRING = "set_resolution";
	public static final String FULLSCREEN_STRING = "set_fullscreen";
	private ArrayList<Object> list = new ArrayList<Object>();

	private JFrame f;

	/**
	 * This method starts the map editor. It creates a new graphical
	 * user interface.
	 * 
	 * @param args the arguments for the map editor. This is not used.
	 */
	public static void main(String[] args) throws IOException {
		if (args.length > 0) {
			Game.run(args, null);
		}
		new GraphicUI("Children of the Zodiac");
	}

	/**
	 * Creates a new GraphicUI with the given title.
	 * 
	 * @param title the title of the JFrame.
	 */
	public GraphicUI(String title) {       
		JFrame.setDefaultLookAndFeelDecorated(true);
		f = new JFrame("BackgroundBorderExample");
		f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		final Container cp = f.getContentPane();
		final JPanel p = new JPanel();
		p.setLayout(new BorderLayout());
		BufferedImage im = ResourceLoader.getResourceLoader().getBufferedImage(Values.MenuImages + "backsmall.jpg");
		Dimension size = new Dimension(im.getWidth(null), im.getHeight(null));
	    f.setPreferredSize(size);
	    f.setMinimumSize(size);
	    f.setMaximumSize(size);
	    f.setSize(size);
	    final Border bkgrnd = new CentredBackgroundBorder(im);
		Runnable r = new Runnable() {
			public void run() {
				p.setBorder(bkgrnd);
				cp.repaint();
			}
		};
		SwingUtilities.invokeLater(r);
		readFile();
		f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		p.add(createResolution(), BorderLayout.CENTER);
		p.add(createStartButton(), BorderLayout.SOUTH);
		
		cp.add(p);

		f.setLocationRelativeTo(null);
		f.pack();
		f.setVisible(true);
	}

	private JPanel createResolution() {
		JPanel p = new JPanel();
		p.setOpaque(false);
		p.setLayout(new GridLayout(1, 2));
		JCheckBox box = new JCheckBox("Fullscreen");
		box.setSelected(true);
		p.add(box);
		box.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				JCheckBox box = (JCheckBox) e.getSource();
		        settings.put(FULLSCREEN_STRING, String.valueOf(box.isSelected()));
			}
		});
		
		String[] res = {"768 x 512", "1024 x 768", "1280 x 960"};
		cb = new JComboBox(res);
		Iterator<String> it = settings.keySet().iterator();
		while (it.hasNext()) {
			String key = it.next();
			String val = settings.get(key);
			if (key.startsWith(RESOLUTION_STRING)) {
				String width = val.split(":")[0];
				for (int j = 0; j < res.length; j++) {
					if (res[j].startsWith(width)) {
						cb.setSelectedIndex(j);
					}
				}
			} else if (key.startsWith("set_fullscreen")) {
				box.setSelected(Boolean.parseBoolean(val));
			}
		}
		cb.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				JComboBox cb = (JComboBox) e.getSource();
		        String item = (String) cb.getSelectedItem();
		        settings.put(RESOLUTION_STRING, item.replace(" x ", ":"));
			}
		});
		p.add(cb);
		return p;
	}
	
	private JButton createStartButton() {
		JButton start = new JButton("Start Game");
		start.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				writeSettings();
				String[] args = new String[settings.size()];
				int index = 0;
				Iterator<String> it = settings.keySet().iterator();
				while (it.hasNext()) {
					String key = it.next();
					args[index++] = key + "=" + settings.get(key);
				}
				Object[] obs = list.size() == 0 ? null : new Object[list.size()];
				for (int i = 0; i < list.size(); i++) {
					obs[i] = list.get(i);
				}
				Game.run(args, obs);
			}
		});
		return start;
	}
	
	private void writeSettings() {
		try {
			PrintWriter writer = new PrintWriter(
					new BufferedWriter(
							new FileWriter(Values.MainMap + "settings.txt")), true);
			Iterator<String> it = settings.keySet().iterator();
			while (it.hasNext()) {
				String key = it.next();
				writer.print(key + "=" + settings.get(key) + " ");
			}
			writer.println();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}	

	private void readFile() {
		try {
			ResourceLoader rl = ResourceLoader.getResourceLoader(); 
			BufferedReader reader = rl.getBufferedReader(Values.MainMap, "settings.txt");
			String line = "";
			line = reader.readLine();
			StringTokenizer st = new StringTokenizer(line);
			int size = st.countTokens();
			for (int i = 0; i < size; i++) {
				String s = st.nextToken();
				String[] list;
				if (s.contains("=")) {
					 list = s.split("=");
				} else {
					list = new String[2];
					list[0] = s;
					list[1] = "";
				}
				settings.put(list[0], list[1]);
			}
			reader.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static class CentredBackgroundBorder implements Border {
	    private final BufferedImage image;
	 
	    public CentredBackgroundBorder(BufferedImage image) {
	        this.image = image;
	    }
	 
	    public void paintBorder(Component c, Graphics g, int x, int y, int width, int height) {
	        int x0 = x + (width-image.getWidth())/2;
	        int y0 = y + (height-image.getHeight())/2;
	        g. drawImage(image, x0, y0, null);
	    }
	 
	    public Insets getBorderInsets(Component c) {
	        return new Insets(0,0,0,0);
	    }
	 
	    public boolean isBorderOpaque() {
	        return true;
	    }
	}
}