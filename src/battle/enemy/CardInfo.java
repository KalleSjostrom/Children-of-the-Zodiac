package battle.enemy;

import cards.Card;
import bodies.Vector3f;

public class CardInfo {
	
	private Vector3f source;
	private Card c;
	
	public CardInfo(Card card, Vector3f source) {
		c = card;
		this.source = source;
	}

	public Card getCard() {
		return c;
	}

	public Vector3f getSource() {
		return source;
	}
}
