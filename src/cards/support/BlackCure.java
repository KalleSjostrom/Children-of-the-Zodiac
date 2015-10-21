/*
 * Classname: Cure.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.support;

import info.BattleValues;
import info.SoundMap;
import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import particleSystem.equations.Line;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.SupportCard;
import character.Character;
import character.Creature;

/**
 * The cure card is the most basic of support cards. It just cures the target.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 27 Dec 2008
 */
public class BlackCure extends SupportCard {
	
	private static final String[] SHORT_INFO = {"Cures hp", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_CURE};
	private static final int[] DELAYS = {0};
	
	@Override
	protected String getSimpleName() {
		return "Cure";
	}

	/**
	 * This method is called to calculate the effect of a "Cure"-card
	 * being used by the attacker. This card will cure the one that the
	 * hand (in battle) is currently pointing at. The given target is not
	 * used because not all information is available to calculated the 
	 * cured hp here, so it is calculated by the animator in battle.
	 * 
	 * @param target the target creature. The one getting hit. 
	 * Not used by the cure.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(Creature target, Character attacker) {
		return cure(attacker);
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
		return STANDARD_SUPORT;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The ancient tenjins learned the secret of the curing potion back",
				"in the days of peace and harmony. When using this now, however,",
				"one must put a lot of supporting power for it to be of great use."};
	}
	
	protected void createShortInfo() {
		setShortInfo("Support power: " + Math.round(getAttackPercent() * 100) + " %");
	}

	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	protected String[] getSoundEffect() {
		return SOUNDS;
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return DELAYS;
	}
	
	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return BlackCure.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DEAD);
		float x = -.4f;
		float y = -.6f;
		settings.setVector(AnimSettings.SOURCE, new Vector3f(x, y, -2f));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, y + 2, -2f));
		Line l = new Line(settings.getVector(AnimSettings.SOURCE), .8f);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l);
		addToSystemPacket(psp, settings);
		return psp;
	}

	public static void addTargetToSettings(int target, AnimSettings settings) {
		float x = BattleValues.getCharPosXForSupport(target) - .03f;
		float y = BattleValues.CHARACTER_POS_Y - .05f;
		settings.setVector(AnimSettings.SOURCE, new Vector3f(x, y, -2f));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, y + 1, -2f));
		Line l = new Line(settings.getVector(AnimSettings.SOURCE), .45f);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l);
	}

	public static void addToSystemPacket(ParticleSystemPacket psp,
			AnimSettings settings) {
		settings.setValue(AnimSettings.MASS_RANDOM_MULT, .1f);
		settings.setValue(AnimSettings.SPEED, 1.5f);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK);
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Y_GREATER_TARGET_Y);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, .01f);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, .01f);
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);
		
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(0, .02f, 0));
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .02f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .02f);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, new Vector3f(0, .02f, 0));
		settings.setValue(AnimSettings.SIZE, .1f);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.LINE_EMITTER_TYPE);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 250);
		settings.setValue(AnimSettings.EMITTANCE_PERIOD, .12f);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 3);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JITTER_4);
		settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2_45);
		settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.JITTER_4_45);

		psp.add(new ParticleSystem(settings), 0);
	}
}
