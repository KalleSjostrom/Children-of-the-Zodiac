package battle;

import sound.OggStreamer;
import villages.utils.DialogSequence;

public interface BattleStarter {
	void exitDialog();
	void drawDialog(DialogSequence dialog);
	void leaveBattle();
	void gameOver();
	void exit(String next, boolean fadeBattleMusic);
	void notifySwitchMusic(String music, int fadeSpeed);
	void overwriteStarterMusic(String music, OggStreamer oggPlayer);
}
