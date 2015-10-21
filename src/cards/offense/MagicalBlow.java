/*
 * Classname: MagicalBlow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

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
import equipment.Slot;

/**
 * The magical blow card is like a battle card but will damage with the magic
 * attack on the targets magic defense, just like any other magic.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class MagicalBlow extends Card {
	
	private static final String[] SHORT_INFO = {"Attack using magical offense", ""};
	private int lastAttacker;

	/**
	 * This method is called to calculate the effect of a Magical Blow-card
	 * being used by the attacker on the given target. This card will damage 
	 * with the magic attack on the targets magic defense, just like any 
	 * other magic.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		return attack(target, attacker, CRITICAL_PRECENT, "", Slot.MAGIC, Slot.ATTACK, 0, false);
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
				"The attacker will wield a sword brimming with the magic essence",
				"of the attacker. The attack will pass through any physical defense",
				"in much the same way as magical force."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Hit with magical attack power on physical defense");
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
		ParticleSystemPacket psp = new ParticleSystemPacket();
		if (info.getAttacker() != null) {
			lastAttacker = info.getAttacker().getIndex();
		}
		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
		
		settings.setValue(AnimSettings.NR_PARTICLES, 200);
		settings.setValue(AnimSettings.SIZE, .03f);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, .05f);
		psp.add(new ParticleSystem(settings), 0); // Normal
		
		settings.setValue(AnimSettings.SIZE_RANDOM_MULT, .02f);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.2f, .2f, .2f));
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_YELLOW);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND_WHITE);
		psp.add(new ParticleSystem(settings), 0); // YELLOW
		
		settings.setValue(AnimSettings.NR_TEXTURES, 2);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JITTER_4);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_4_45);

		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .08f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .08f);
		
		psp.add(new ParticleSystem(settings), 0);
		return psp;
	}
//	public ParticleSystemPacket getAnimation(AnimationInfo info) {
//		ParticleSystemPacket psp = new ParticleSystemPacket();
//		if (info.getAttacker() != null) {
//			lastAttacker = info.getAttacker().getIndex();
//		}
//		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
//		psp.add(new ParticleSystem(settings), 0);
//		
//		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_YELLOW);
//		
//		settings.setValue(AnimSettings.NR_PARTICLES, 200);
//		settings.setValue(AnimSettings.SIZE, .05f);
//		
////		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEFAULT_EMITTER_TYPE);
//		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
//		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.2f, .2f, .2f));
//		settings.setValue(AnimSettings.EMITTANCE_SPEED, .01f);
//		settings.setValue(AnimSettings.NR_TEXTURES, 1);
//		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND_WHITE);
////		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2);
////		settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.JITTER_3);
////		settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.JITTER_4);
////		settings.setValue(AnimSettings.NR_TEXTURES + 5, ParticleSystem.JITTER_2_45);
////		settings.setValue(AnimSettings.NR_TEXTURES + 6, ParticleSystem.JITTER_3_45);
////		settings.setValue(AnimSettings.NR_TEXTURES + 7, ParticleSystem.JITTER_4_45);
//		
//		psp.add(new ParticleSystem(settings), 0);
//		
//		settings.setValue(AnimSettings.SIZE, .05f);
//		settings.setValue(AnimSettings.SIZE_RANDOM_MULT, .05f);
//		
////		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEFAULT_EMITTER_TYPE);
//		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE);
//		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.2f, .2f, .2f));
//		settings.setValue(AnimSettings.EMITTANCE_SPEED, .01f);
//		settings.setValue(AnimSettings.NR_TEXTURES, 2);
//		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JITTER_4);
//		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_4_45);
//		
//		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
//		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3);
//		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .08f);
//		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .08f);
////		Vector3f target = settings.getVector(AnimSettings.TARGET);
////		Vector3f source = settings.getVector(AnimSettings.SOURCE);
////		float x = target.x - source.x;
////		float y = target.y - source.y;
////		
////		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(x * .1f, y * .1f, 0));
//		
//		psp.add(new ParticleSystem(settings), 0);
//		return psp;
//	}
}
