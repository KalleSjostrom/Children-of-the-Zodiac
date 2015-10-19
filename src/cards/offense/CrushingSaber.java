/*
 * Classname: CriticalBlow.java
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
import particleSystem.ShatterParticleSystem;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import battle.enemy.BattleEnemy;
import battle.enemy.EnemyInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

/**
 * The crushing saber card is a battle card with one addition, the chance of an
 * armor break exists.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class CrushingSaber extends Card {

	private static final String[] SHORT_INFO = {"Attack + chance of", "breaking enemy's armor"};
	private int lastAttacker;
	private HitElement preCalculatedElement;
	private boolean armorCrush;

	/**
	 * This method is called to calculate the effect of a "crush blow"-card
	 * being used by the attacker on the given target. The crush blow will
	 * destroy the targets armor for the reset of the turn if the crush is
	 * successful. The rest of the turn means, for all the cards left on the 
	 * attacking hand including this card. If 7 cards is played in one hand
	 * and the crush is successful and played second, six of the played cards
	 * will also hit on an enemy without an armor.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the attacking creature. the one who hits.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		return preCalculatedElement;
	}

	private HitElement useBefore(Creature target, Character attacker) {
		armorCrush = false;
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			String fullName = "";
			String simpleName = "crush";
			int ret = Card.checkPreferences3(
					target, attacker, null, false, this, fullName, simpleName);
			switch (ret) {
			case Card.IMMUNE:
				he = attack(target, attacker, "Immune!", true);
				break;
			case Card.HIT:
				he = hit(target, attacker);
				break;
			case Card.MISS:
				he = attack(target, attacker, "Failed to crush armor!", true);
				break;

			default:
				break;
			}
		}
		return he;
	}

	private HitElement hit(Creature target, Character attacker) {
		HitElement he = null;
		int ans = target.crushArmor();
		switch (ans) {
		case Creature.ARMOR_ALREADY_CRUSHED :
			he = attack(target, attacker, "Armor already crushed!", true);
			break;
		case Creature.ARMOR_CRUSHED :
			armorCrush = true;
			he = attack(target, attacker, "Armor crushed!", true);
			break;
		case Creature.HAS_NO_ARMOR :
			he = attack(target, attacker, "Has no armor!", true);
			break;
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
	 * This method returns the probability that this card would be effective. 
	 * The returned value is an array containing the separate probability for
	 * each level of the card. If the actual card has level two and is used 
	 * in battle it would only hit if </br> <code> 
	 * (Math.random <= getChanceToHit()) </code> </br> is true. The 
	 * getChanceToHit() method returns the array created by this method.
	 * 
	 * @return the probability that this card would be effective.
	 */
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
				"A powerfull blow, strikes down on the target, like the Hammer of",
				"Thor, rendering the targets armor useless for a while. Yet, the",
		"armor will recover due to the magical nature of the crushing saber."};
	}

	protected void createShortInfo() {
		setShortInfo("Power: " + Math.round(getAttackPercent() * 100) + " %");
		setShortInfo("Chance of breaking enemy's armor: " + Math.round(getEffectChanceToHit() * 100) + " %");
	}

	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}

	public void playSound() {
		String s = BattleCard.SOUNDS[lastAttacker];
		BattleCard.playBattleSound(s, 1000);
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		if (info.isOnEnemy()) {
			Character attacker = info.getAttacker();
			if (attacker != null) {
				lastAttacker = attacker.getIndex();
			}
			preCalculatedElement = useBefore(info.getEnemy().getEnemy(), attacker);
		}
		return CrushingSaber.getStaticAnimation(info, armorCrush);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info, boolean armorCrush) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings;
		if (!info.isOnEnemy()) {
			settings = AnimationSettingsFactory.getDefaultNoFade();
			
			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .012f);
			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .012f);
			settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, 0, 0));
			settings.setValue(AnimSettings.SIZE, .01f);
			settings.setValue(AnimSettings.SPEED, .4f);
			settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
			float depth = -6;
			BattleEnemy enemy = info.getEnemy();
			if (enemy != null) {
				depth = enemy.getInfo().get(EnemyInfo.DEPTH);
			}
			settings.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, depth));
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, 0, depth - .5f));
			settings.setVector(AnimSettings.COLLISION_VECTOR, new Vector3f(-1.9f, 1.9f, -1.9f));
			
			settings.setValue(AnimSettings.NR_PARTICLES, 5000);
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .005f);
			settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.SHATTER_EMITTER_TYPE);
			settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100);
			settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
			
			settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.PIXEL);
			settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT);
			settings.setValue(AnimSettings.BLEND_MODE, ParticleSystem.BLEND_MODE_NO_BLEND);
			settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
			
			
			psp.add(0, new ParticleSystem(settings, enemy), 0);
			return psp;
		}
		
		
		settings = BattleCard.getDefaultBattleCardSettings(info.getLevel());
		if (!armorCrush) {
			psp.add(new ParticleSystem(settings), 0);
		} else {
			settings.setValue(AnimSettings.FADE_RANDOM_ADD, .04f);

			psp.add(new ParticleSystem(settings), 1000);

			settings = AnimationSettingsFactory.getDefaultNoFade();

			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .012f);
			settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .012f);
			settings.setValue(AnimSettings.SIZE, .01f);
			settings.setValue(AnimSettings.SPEED, .4f);
			settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
			float depth = -6;
			BattleEnemy enemy = info.getEnemy();
			if (enemy != null) {
				depth = enemy.getInfo().get(EnemyInfo.DEPTH);
			}
			settings.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, depth));
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, 0, depth - .5f));
			settings.setVector(AnimSettings.COLLISION_VECTOR, new Vector3f(-1.9f, 1.9f, -1.9f));

			settings.setValue(AnimSettings.NR_PARTICLES, 5000);
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .005f);
			settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.SHATTER_EMITTER_TYPE);
			settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100);

			settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.PIXEL);
			settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT);
			// TODO: If armor chrushes!
			//		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
			//		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.ZERO);
			//		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .04f);
			psp.add(0, new ShatterParticleSystem(settings, enemy), 0);
		}
		return psp;
	}
}
