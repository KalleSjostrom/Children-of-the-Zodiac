/*
 * Classname: SpiritAssult.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import info.BattleValues;
import info.Values;

import java.util.ArrayList;

import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;
import equipment.Slot;
import factories.Load;

/**
 * The spirit assault will damage then enemy with the power of the dead.
 * If any of the party members are dead, there offensive powers will be added
 * to the caster of this card.
 * 
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class EnemyDrain extends Card {

	private static final String[] SHORT_INFO = {"Attack + adds the offense","of dead party members"};
	private int lastAttacker;
	
	@Override
	protected String getSimpleName() {
		return "Drain";
	}
	
	/**
	 * The spirit assault will damage then enemy with the power of the dead.
	 * If any of the party members are dead, there offensive powers will be added
	 * to the caster of this card.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		ArrayList<Character> chars = Load.getCharacters();
		int extraAttack = 0;
		for (int i = 0; i < chars.size(); i++) {
			Character c = chars.get(i);
			if (!c.isAlive()) {
				extraAttack += c.getBattleAttack(Slot.ATTACK);
			}
		}
		return attack(target, attacker, CRITICAL_PRECENT, "", getType(), getType(), extraAttack, false);
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
		return SPECIAL_ATTACK;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The strenght of fallen comrades fills the wielder as the",
				"attack slices through the enemies. But as suddenly as they",
				"appeared, the spirits of the dead soon wanders away."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Hit with the power of your dead party members");
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
		if (info.getAttacker() != null) {
			lastAttacker = info.getAttacker().getIndex();
		}
		return EnemyDrain.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .2f);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.2f, .2f, .2f));
		settings.setValue(AnimSettings.SPEED, .1f);
		settings.setValue(AnimSettings.NR_PARTICLES, 50);
		settings.setValue(AnimSettings.SIZE, .1f);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_RANDOM);
		
		int i = info.getTarget();
		float x = BattleValues.getCharPosXForSupport(i) + .1f;
		float y = BattleValues.CHARACTER_POS_Y + .1f;
		Vector3f v = new Vector3f(x, y, -2);
		settings.setVector(AnimSettings.SOURCE, v);
		settings.setVector(AnimSettings.TARGET, new Vector3f(x, y, -2.1f));
		settings.setVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT, new Vector3f(0, 0, -2));
		settings.setValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT, .2f);
		settings.setBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE, false);
		psp.add(0, new ParticleSystem(settings), 0);
		return psp;
	}
}
