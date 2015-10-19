/*
 * Classname: Boss.java
 * 
 * Version information: 0.7.0
 *
 * Date: 21/07/2008
 */
package battle.bosses;

import java.util.HashMap;

import info.Database;
import villages.utils.DialogSequence;
import battle.enemy.AttackInfo;
import battle.enemy.BattleEnemy;
import battle.enemy.EnemyLogic;
import character.Enemy;
import factories.Load;

/**
 * This is a special kind of battle enemy and is used when battling a boss.
 * This class is not done, because it is not decided what should happen when
 * battling bosses.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 21 July 2008
 */
public class Boss extends BattleEnemy {
	
	private BossDialog dialogs;
	private Dialog battleDialog;
	private BossScript script;
	private HashMap<String, Integer> triggers;
	private HashMap<String, Integer> items;

	/**
	 * Creates a new boss from the given enemy.
	 * 
	 * @param enemy the enemy to wrap as a boss.
	 */
	public Boss(Enemy enemy) {
		super(enemy);
		dialogs = enemy.getDialog();
		script = enemy.getScript();
		battleDialog = script.getDialog();
		triggers = enemy.getTriggers();
		items = enemy.getItems();
	}
	
	/**
	 * Triggers the consequences of defeating a boss.
	 */
	public void trigger() {
		Database.addStatus(triggers);
		Load.getPartyItems().addItems(items);
	}
	
	public AttackInfo makeMove(int lifePercent) {
		return EnemyLogic.makeMove(script.getMove(lifePercent));
	}
	
	public void setDialog(int i, Dialog d) {
		dialogs.set(i, d);
	}
	
	public boolean wantsToTalk(int i) {
		if (battleDialog != null) {
			dialogs.set(i, battleDialog);
		}
		return dialogs != null ? dialogs.wantsToTalk(i) : false;
	}
	
	public DialogSequence next(int i) {
		return dialogs.get(i);
	}
	
	public DialogSequence next() {
		return dialogs.get(rounds);
	}
	
	public boolean continueBattleMusic() {
		return false;
	}
}
