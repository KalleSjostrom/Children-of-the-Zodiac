package battleTest;

import info.Values;

import java.util.ArrayList;
import java.util.HashMap;

import organizer.GameMode;
import organizer.Organizer;

import battle.BattleManager;
import character.Character;
import factories.EnemyFactory;
import factories.Load;
import factories.EnemyFactory.EnemyGroup;
import graphics.Graphics;

public class BattleTest extends GameMode {
	
	private BattleManager manager;
	private boolean inited = false;
	private String name = Organizer.convert("Empyrian_Temple--The_Zodiac");
	
	public void init(HashMap<String, String> info) {
		EnemyFactory ef = EnemyFactory.getEnemyFactory();
		name = Organizer.convert(name);
		EnemyGroup eg = ef.getEnemyGroup(name);
		eg.loadTextures();
		logicLoading = false;
	}
	
	public BattleTest() {
		// Log.setLogging(true);
		inited = false;
		manager = new BattleManager();
		HashMap<String, String> info = new HashMap<String, String>();
		info.put("music", "battle");
		info.put("boss", "false");
		info.put("name", name);
		manager.init(info);
	}

	public void update(float elapsedTime) {
		manager.update(elapsedTime);
		if (manager.getBattleMode() == BattleManager.EXIT) {
			ArrayList<Character> list = Load.getCharacters();
			for (int i = 0; i < list.size(); i++) {
				list.get(i).resetBattleStats();
			}
			manager.killOggPlayer();
			super.exitWithoutFading(Values.BATTLE_TEST);
			nextPlace = "";
		}
		super.update(elapsedTime);
	}

	public void draw(float dt, Graphics g) {
		g.loadIdentity();
		g.setColor(1);
		g.setLightEnabled(false);
		
		if (!inited) {
			manager.initDraw(g);
			inited = true;
		}
		manager.draw(dt, g);
	}
}
