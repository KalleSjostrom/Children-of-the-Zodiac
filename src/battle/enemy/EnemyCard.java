package battle.enemy;

import equipment.Slot;
import graphics.Graphics;
import info.BattleValues;
import info.Values;
import battle.Hideable;
import cards.Card;

public class EnemyCard extends Hideable {
	
	public EnemyCard() {
		super(7);
		setLimit(false);
		setMovementSpeed(false);
		instantHide();
	}

	public void initDraw(Graphics g) {
		setPos(BattleValues.ENEMY_POSITION);
		String att = Values.Cards + "monsterattack.png";
		String mneutral = Values.Cards + "monsterneutral.png";
		String mfire = Values.Cards + "monsterfire.png";
		String mice = Values.Cards + "monsterice.png";
		String mwind = Values.Cards + "monsterwind.png";
		String mearth = Values.Cards + "monsterearth.png";
		String sup = Values.Cards + "Cure.png";
		loadTexture(att, 0);
		loadTexture(mneutral, 1);
		loadTexture(mfire, 2);
		loadTexture(mice, 3);
		loadTexture(mwind, 4);
		loadTexture(mearth, 5);
		loadTexture(sup, 6);
		
		setSize(0, BattleValues.CARD_SCALE * 1.5f);
		
		createCoords(1);
		draw(g, 0, 0, true);
		draw(g, 1, 0, true);
		draw(g, 2, 0, true);
	}
	
	protected void createCoords(int size) {
		createCoordList(size);
		createCoordFor(0, width, 0, X);
		createCoordFor(-height / 2, height / 2, 0, Y);
		createCoordFor(0, 0, 0, Z);
	}
	
	public void draw(float dt, Graphics g) {
		super.translate(g);
		draw(g, currentList, 0, true);
	}

	public void setImage(int type, int elem) {
		switch (type) {
		case Slot.ATTACK : 
			currentList = Slot.ATTACK;
			break;
		case Slot.MAGIC : 
			currentList = Slot.MAGIC + elem;
			break;
		case Slot.SUPPORT : 
			currentList = Slot.SUPPORT + Card.NR_ELEMENT_MODES - 1;
			break;
		}
	}
}
