/*
 * Classname: Death.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import info.Values;
import particleSystem.ImageParticleSystem;
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

/**
 * This class represents the Death magic in the game. The Death magic 
 * is a special card that does not attack like most of the others. 
 * Instead of attack percent it has a chance percent which contains the
 * probability that the death card should hit. If the card hits the target
 * dies immediately. This is the major difference. The card can only hit
 * or miss, not hit hard or weak.
 * 
 * @author 		Kalle Sjöström 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class BlackDeath extends Card {

	private static final String[] SHORT_INFO = {"Chance of instant kill", ""};
	public static final String TEXT = "Instant Kill!";
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_DEATH};
	private static final int[] DELAYS = {0};
	
	@Override
	protected String getSimpleName() {
		return "Death";
	}

	/**
	 * This method is called to calculate the effect of a "death"-card
	 * being used by the attacker on the given target. This card will 
	 * kill the target instantly if successful. The attacker is not 
	 * important when using this card because the chance to kill lies 
	 * solely in the card.
	 * 
	 * @param target the target creature. The one getting hit.
	 * @param attacker the character who is attacking.
	 * @return the HitElement containing the information about the attack.
	 */
	public HitElement use(
			Creature target, Character attacker) {
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			if (Values.rand.nextFloat() <= getEffectChanceToHit()) {
				int damage = target.getAttribute(Creature.HP);
				he = new HitElement(this, damage, HitElement.NORMAL, TEXT);
			} else {
				he = new HitElement(this, -1, HitElement.MISS, "");
			}
		}
		return he;
	}
	
	/**
	 * This method returns null because this card does not have any attack
	 * percentage, so this method should not be called.
	 * 
	 * @return null this card does not have an attack percent.
	 */
	protected float[] createAttackPercent() {
		return null;
	}
	
	/**
	 * This method returns the probability that the Death card would be
	 * effective. The returned value is an array containing the separate
	 * probability for each level of the card. If the actual card has level
	 * two and is used in battle it would only hit if </br>
	 * <code> (Math.random <= getChanceToHit()) </code> </br>
	 * is true. The getChanceToHit() method returns the array created by
	 * this method.
	 * 
	 * @return the probability that the Death card would be effective.
	 */
	protected float[] createEffectChancePercent() {
		return new float[]{.4f, .5f, .6f};
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	protected String[] createTextInfo() {
		return new String[]{
				"The grim reaper will make an appearance if this card is successfully",
				"used. The foe before the wielder will follow the reaper down to",
				"the netherworld where an eternity of pain awaits."};
	}
	
	protected void createShortInfo() {
		setShortInfo(Math.round(getEffectChanceToHit() * 100) + " % to kill your foe");
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
		return BlackDeath.getStaticAnimation(info);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefaultNoFade();
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE);
		Vector3f s = info.getEnemy().getTempSource();
		settings.setVector(AnimSettings.SOURCE, new Vector3f(s.x, s.y, s.z + .5f));
		settings.setVector(AnimSettings.TARGET, new Vector3f(s));
		settings.setValue(AnimSettings.NR_PARTICLES, 1);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0);
		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.ZERO);
		settings.setValue(AnimSettings.SIZE, .2f);
		settings.setValue(AnimSettings.SPEED, .3f);
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.DEATH_0);
		
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .1f);

		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEMOLISH_EMITTER_TYPE);
		settings.setValue(AnimSettings.BLEND_MODE, ParticleSystem.BLEND_MODE_NO_BLEND);
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
		
		settings.setValue(AnimSettings.NR_TEXTURES, 1);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
		psp.add(new ImageParticleSystem(settings), 0);
		return psp;
	}
}
