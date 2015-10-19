/*
 * Classname: LaceratingCut.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.offense;

import info.Values;
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

/**
 * The lacerating cut card is a battle card with one addition, the chance of an
 * open wound hit exists.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class LaceratingCut extends Card {

	private static final String[] SHORT_INFO = {"Attack +", "chance for open wound"};
	private int lastAttacker;
	private HitElement preCalculatedElement;
	private boolean openWound;

	/**
	 * This method is called to calculate the effect of a Lacerating Cut-card
	 * being used by the attacker on the given target. This card will cause
	 * the enemy to start bleeding and the life of the target will decrease
	 * some amount each turn for three turns, if the attack is successful.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		return preCalculatedElement;
	}

	public HitElement useBefore(Creature target, Character attacker) {
		openWound = false;
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			String fullName = "";
			String simpleName = "openwound";
			int ret = Card.checkPreferences3(
					target, attacker, null, false, this, fullName, simpleName);
			switch (ret) {
			case Card.IMMUNE:
				he = attack(target, attacker, "Immune!", true);
				break;
			case Card.HIT:
				target.openWound();
				openWound = true;
				he = attack(target, attacker, "Open wound!", true);
				break;
			case Card.MISS:
				he = attack(target, attacker, "Open wound failed!", true);
				break;

			default:
				break;
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

	protected float[] createEffectChancePercent() {
		return STANDARD_EFFECT_CHANCE;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The razor sharp edge of this blade will cut the enemy with much",
				"precision that will cause the enemy to bleed heavily. The bleeding",
		"will stop eventually but it will surely take some time."};
	}

	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Chance to cause open wound " + Math.round(getEffectChanceToHit() * 100) + "%");
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
			lastAttacker = info.getAttacker().getIndex();
		}
		preCalculatedElement = useBefore(info.getEnemy().getEnemy(), attacker);
		return LaceratingCut.getStaticAnimation(info, openWound);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info, boolean openWound) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
		if (!openWound) {
			psp.add(new ParticleSystem(settings), 0);
		} else {
//			settings.setValue(AnimSettings.FADE_RANDOM_ADD, .04f);
			psp.add(new ParticleSystem(settings), 0);
			settings.setValue(AnimSettings.NR_PARTICLES, 500);
			settings.setValue(AnimSettings.SIZE, .06f);
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .12f);
			settings.setValue(AnimSettings.PARTICLE_MASS, 0f);
			settings.setValue(AnimSettings.FADE_RANDOM_ADD, .001f);
			settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_RED);
			settings.setValue(AnimSettings.MASS_RANDOM_MULT, .3f);
			settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE);
			settings.getVector(AnimSettings.SOURCE).y -= .1f;
			settings.getVector(AnimSettings.TARGET).y -= .1f;
			
			settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DESTROYED);

			settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, -.1f, 0));
			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0);
			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .02f);
			settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 0);
			settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);

			psp.add(0, new ParticleSystem(settings), 100);
		}
		return psp;
	}
}
