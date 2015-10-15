package input;

import java.awt.event.KeyEvent;

import organizer.GameMode;

public class FakeInputManager extends InputManager {

	public FakeInputManager() {
		keyActions = new GameAction[600];
		createGameActions();
		
	}
	
	public void createGameActions() {
		for (int i = 0; i <= GameMode.NUMBER_OF_BUTTONS; i++) {
			keyActions[i] = new GameAction(
					GameAction.DETECT_INITAL_PRESS_ONLY);
		}
		mapToKey(keyActions[GameMode.UP], KeyEvent.VK_UP);
		mapToKey(keyActions[GameMode.RIGHT], KeyEvent.VK_RIGHT);
		mapToKey(keyActions[GameMode.DOWN], KeyEvent.VK_DOWN);
		mapToKey(keyActions[GameMode.LEFT], KeyEvent.VK_LEFT);
		mapToKey(keyActions[GameMode.TRIANGLE], KeyEvent.VK_W);
		mapToKey(keyActions[GameMode.CIRCLE], KeyEvent.VK_D);
		mapToKey(keyActions[GameMode.CROSS], KeyEvent.VK_S);
		mapToKey(keyActions[GameMode.SQUARE], KeyEvent.VK_A);
		mapToKey(keyActions[GameMode.START], KeyEvent.VK_ENTER);
		mapToKey(keyActions[GameMode.SELECT], KeyEvent.VK_SPACE);
		mapToKey(keyActions[GameMode.R2], KeyEvent.VK_3);
		mapToKey(keyActions[GameMode.R1], KeyEvent.VK_E);
		mapToKey(keyActions[GameMode.L1], KeyEvent.VK_Q);
		mapToKey(keyActions[GameMode.L2], KeyEvent.VK_1);
	}

	@Override
	public boolean isActive() {
		return true;
	}

	@Override
	public void reset() {
		// TODO Auto-generated method stub
		
	}
}
