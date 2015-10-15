package battle.enemy;

import graphics.Graphics;
import info.BattleValues;
import info.Values;
import battle.Hideable;

public class AttackBackground extends Hideable {
	
	public AttackBackground() {
		super(1);
		setAxis(Y_AXIS);
		setLimit(-.4f, 0, true);
		setMovementSpeed(false);
		setPos(-.6f, -.73f);
		instantHide();
	}

	public void initDraw(Graphics g) {
		String texture = Values.BattleImages + "attackBack.png";
		loadTexture(texture, 0);
		setSize(0, BattleValues.CARD_SCALE);
		createCoords(1);
		draw(g, 0, 0, true);
	}
	
	protected void createCoords(int size) {
		createCoordList(size);
		createCoordFor(0, width, 0, X);
		createCoordFor(-height / 2, height / 2, 0, Y);
		createCoordFor(0, 0, 0, Z);
	}
	
	public void draw(Graphics g) {
		super.translate(g);
		draw(g, 0, 0, true);
	}
}
