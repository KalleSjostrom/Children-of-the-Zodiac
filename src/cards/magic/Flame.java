/*
 * Classname: CriticalBlow.java
 * 
 * Version information: 0.7.0
 *
 * Date: 27/12/2008
 */
package cards.magic;

import particleSystem.FlameParticleSystem;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
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
public class Flame extends Card {

	private static final String[] SHORT_INFO = {"Fire magic", ""};
	
	@Override
	protected String getSimpleName() {
		return "Fire";
	}
	
	/**
	 * This method sets the element to fire.
	 */
	@Override
	protected void setElement() {
		element = FIRE_ELEMENT;
	}

	/**
	 * Creates and returns the textual information of the card. This is the
	 * three lines of "story" that tells the player about the card.
	 * 
	 * @return the text describing the card.
	 */
	@Override
	protected String[] createTextInfo() {
		return new String[]{
				"The firey ball of magic will rush toward the target and disintegrate",
				"upon impact. The hot flames created with supreme magic will melt",
				"even the coldes of barriers leaving but a puddle of water."};
	}
	
	@Override
	public String[] getVeryShortInfo() {
		return SHORT_INFO;
	}
	
	@Override
	protected String[] getSoundEffect() {
		return new String[0];
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return new int[0];
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		return Flame.getStaticAnimation(info);
	}

	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings;

		settings = AnimationSettingsFactory.getDefault();
		
		settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0);

		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, .4f);
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, .4f);
		settings.setValue(AnimSettings.SIZE, .2f);
		settings.setValue(AnimSettings.SPEED, 0);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0));
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(5f, 1f, 0).multLocal(.001f));
		float depth = -6;
		BattleEnemy enemy = info.getEnemy();
		if (enemy != null) {
			depth = enemy.getInfo().get(EnemyInfo.DEPTH);
		}
		settings.setVector(AnimSettings.SOURCE, new Vector3f(0, 0, depth));
		settings.setVector(AnimSettings.TARGET, new Vector3f(0, 0, depth - .5f));
//		settings.setVector(AnimSettings.COLLISION_VECTOR, new Vector3f(-1.9f, 1.9f, -1.9f));

		settings.setValue(AnimSettings.NR_PARTICLES, 3000);
//		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .01f);
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.FLAME_EMITTER_TYPE);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 100);

		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND);
		settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT);

		psp.add(0, new FlameParticleSystem(settings, enemy), 0);
		return psp;
	}

	@Override
	public HitElement use(Creature target, Character attacker) {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	protected float[] createAttackPercent() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	protected void createShortInfo() {
		// TODO Auto-generated method stub
		
	}
}
