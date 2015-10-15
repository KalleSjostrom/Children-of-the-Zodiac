/*
 * Classname: Drain.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import info.BattleValues;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.Card;
import character.Character;
import character.Creature;
import factories.Load;

/**
 * The Drain card will damage the enemy just like a normal battle card
 * but it will also heal the attacker some percentage of the damage amount.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class Drain extends Card {
	
	private static final float[] DRAIN_PERCENTAGE = {.5f, 1, 1.5f};
	private static final String[] SHORT_INFO = {"Attack + adds some of", "the damage to your hp"};
	private int lastAttacker;

	/**
	 * This method is called to calculate the effect of a drain card being
	 * used by the attacker on the given target. A drain card will draw some
	 * of the life taken from an enemy to the attacker. The attacker will
	 * therefore gain life if the attack took any damage on the enemy.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			he = attack(target, attacker, true);
			if (he.getAttackDamage() > 0) {
				int cure = he.getAttackDamage();
				cure *= DRAIN_PERCENTAGE[he.getCard().getLevel() - 1];
				he.addCure(cure, "Drained");
			}
		}
		return he;
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
				"A nosferatu is a blood sucking creature who gain life by taking",
				"life from other living creatures. This card abides by the same",
				"twisted nature as the lord of darkness."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Will drain " + Math.round(DRAIN_PERCENTAGE[level - 1] * 100)  +" % of the damage");
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
		return Drain.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		int index = Load.getCharacterIndex(info.getAttacker().getName());
		
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .04f);

		psp.add(new ParticleSystem(settings), 0);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 1000);
		settings.setValue(AnimSettings.SIZE, .1f);
//		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .06f);
		settings.setValue(AnimSettings.PARTICLE_MASS, 0f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .001f);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_RANDOM);
		settings.setValue(AnimSettings.MASS_RANDOM_MULT, .3f);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
		
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, -.1f, 0));
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .002f);
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 0);
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DESTROYED);
		
		float x = BattleValues.getCharPosXForSupport(index) + .1f;
		float y = BattleValues.CHARACTER_POS_Y + .1f;
		Vector3f v = new Vector3f(x, y, -2);
		
		settings.setVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT, v);
		settings.setValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT, .6f);
		settings.setBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE, true);
		
		psp.add(0, new ParticleSystem(settings), 0);
		return psp;
	}
}
