/*
 * Classname: BattleCard.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import battle.enemy.EnemyInfo;
import bodies.Vector3f;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The battle card is the most basic of physical attacking cards. It has
 * nothing special about it. 
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class Destroyer extends Card {
	
	private static final String[] SHORT_INFO = {"Powerful attack", ""};
	private int lastAttacker;
	
	/**
	 * This method is called to calculate the effect of a "Battle"-card
	 * being used by the attacker on the given target. This card will
	 * damage the target.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		return attack(target, attacker);
	}

	/**
	 * Creates the attack percent. This is the amount of percent that this card
	 * should boost the attackers attack. If the attacker attacks with say 17 
	 * in attack and the attack percent is 140 % (1.4f). The attack will be a
	 * total of 23.8 => 24. The created percent is not, however, a single value
	 * but three. One for each level of the card. So a normal battle card could
	 * have 120 % boost for level 1, 160 % boost for level 2 and 300 % boost for 
	 * level 3, for example.
	 *  
	 * @return the list of attack percentage.
	 */
	protected float[] createAttackPercent() {
		return STANDARD_ATTACK_LV4;
	}
	
	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The spirit of the katana resides in this card. The worlds most powerful and",
				"deadly sword, sharp enough to cut through steel as well as foes. To withstand",
				"an impact of this kind, you must be tought and... oh, yeah right, you can't."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
	}

	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	public void playSound() {
		String s = BattleCard.SOUNDS[lastAttacker];
		int[] i = getSoundEffectDelay();
		BattleCard.playBattleSound(s, i[0]);
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		Character attacker = info.getAttacker();
		if (attacker != null) {
			lastAttacker = attacker.getIndex();
		}
		ParticleSystemPacket psp = new ParticleSystemPacket();
		
		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(level);
		
		float middle = info.getEnemy().getInfo().get(EnemyInfo.MIDDLE_POINT);
		// -1.375f
//		middle = -1.05f;
		// -.725f
		float d = info.getEnemy().getInfo().get(EnemyInfo.DEPTH);
		settings.setVector(AnimSettings.SOURCE, new Vector3f(-1.115f, middle - .325f, d));
		settings.setVector(AnimSettings.TARGET, new Vector3f(1.115f, middle + .325f, d));
		settings.setBoolean(AnimSettings.DESTROY_ENEMY_SLICE, true);
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DELAYED);
		settings.setValue(AnimSettings.READY_MODE_DELAY_TIME, 1500);
		
		psp.add(new ParticleSystem(settings, info.getEnemy()), 0);
		return psp;
	}
}
