package labyrinth;

import graphics.Graphics;

public interface LabyrinthDrawable {

	public void initDraw(Graphics g);

	public void draw(Graphics g);

	public void update(float elapsedTime);

	public void drawTopLayer(Graphics g);

}
