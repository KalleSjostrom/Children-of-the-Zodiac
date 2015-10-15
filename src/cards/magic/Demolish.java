/*
 * Classname: Demolish.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import info.Values;
import particleSystem.SphereParticleSystem;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import particleSystem.ParticleValues;
import particleSystem.ParticleSystem.InterpolationInfo;
import particleSystem.equations.CircularWave;
import particleSystem.equations.UpDownSideWave;
import settings.AnimSettings;
import battle.HitElement;
import battle.Animation.AnimationInfo;
import battle.enemy.BattleEnemy;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;
import character.Character;
import character.Creature;

public class Demolish extends Card {

	private static final String[] SHORT_INFO = {"Offense & Defense down", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_DEMOLISH, SoundMap.MAGICS_DEMOLISH, SoundMap.MAGICS_DEMOLISH};
	private static final int[] DELAYS = {825, 0, 0};
	private HitElement preCalculatedElement;
	private boolean demolished;

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
		demolished = false;
		HitElement he = Card.checkPreferences(target, attacker, this, null);
		if (he == null) {
			target.boostAttack(TURNS_TO_BOOST_MANY, -getAttackPercent());
			target.boostDefense(TURNS_TO_BOOST_MANY, -getAttackPercent());
			demolished = true;
			he = new HitElement(this, -1, HitElement.NORMAL, "Off & Def down!");
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
	@Override
	protected float[] createAttackPercent() {
		return STANDARD_BOOST_LOW;
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
				"Sends away spheres of burning antimatter creating a black hole",
				"of colossal proportions. This will have severe effect on the targets",
				"physical attributes due to the cosmic energy pouring out of the hole."};
	}
	
	@Override
	protected void createShortInfo() {
		setShortInfo("Lowers enemy's attack and defense with " + Math.round(getAttackPercent() * 100) + " %");
	}
	
	@Override
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
		info.setLevel(getLevel());
		preCalculatedElement = useBefore(info.getEnemy().getEnemy(), info.getAttacker());
		return Demolish.getStaticAnimation(info, demolished);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info, boolean demolished) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		
		BattleEnemy enemy = info.getEnemy();
		if (demolished) {
			// Make enemy smaller
		} else {
			enemy = null;
			// Don't =)
		}
		
		settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEMOLISH_EMITTER_TYPE);
		settings.setValue(AnimSettings.SPEED, 6f);
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK);
		float period = 1.5f;
		float amplitude = .5f;
		CircularWave wave = new CircularWave(period, amplitude, 0, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 1);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0);
		settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 1);
		settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, true);
		settings.setVector(AnimSettings.GRAVITY, new Vector3f(0, 0, 0));
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(0, 0, 0f));
		settings.getVector(AnimSettings.SOURCE).z = 0;
		Card.setSourceTargetVectorToLength(6, settings);
		int delay = 230;
		float sizescalar = 1.5f;
		settings.setValue(AnimSettings.SIZE, .2f * sizescalar);
		psp.add(new SphereParticleSystem(settings, enemy), 0);
		settings.setValue(AnimSettings.SIZE, .15f * sizescalar);
		psp.add(new SphereParticleSystem(settings, enemy), delay);
		settings.setValue(AnimSettings.SIZE, .12f * sizescalar);
		psp.add(new SphereParticleSystem(settings, enemy), delay*2);
		settings.setValue(AnimSettings.SIZE, .08f * sizescalar);
		psp.add(new SphereParticleSystem(settings, enemy), delay*3);
		if (info.getLevel() == 1) {
			return psp;
		}
		wave = new CircularWave(period, amplitude, (float) (2*Math.PI / 3), false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		
		settings.setValue(AnimSettings.SIZE, .2f * sizescalar);
		psp.add(new SphereParticleSystem(settings), 0);
		settings.setValue(AnimSettings.SIZE, .15f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay);
		settings.setValue(AnimSettings.SIZE, .12f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay*2);
		settings.setValue(AnimSettings.SIZE, .08f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay*3);
		if (info.getLevel() == 2) {
			return psp;
		}
		wave = new CircularWave(period, amplitude, (float) (4*Math.PI / 3), false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		
		settings.setValue(AnimSettings.SIZE, .2f * sizescalar);
		psp.add(new SphereParticleSystem(settings), 0);
		settings.setValue(AnimSettings.SIZE, .15f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay);
		settings.setValue(AnimSettings.SIZE, .12f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay*2);
		settings.setValue(AnimSettings.SIZE, .08f * sizescalar);
		psp.add(new SphereParticleSystem(settings), delay*3);
		return psp;
	}
	
	// Cross like
	public static ParticleSystemPacket getAlternativeStaticAnimation(
			int nrTarget, int target, boolean onEnemy, boolean onAll, BattleEnemy enemy) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_MULTIPLE_TIMES);
		settings.setValue(AnimSettings.SIZE, .15f);
		settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0);
		settings.setValue(AnimSettings.SPEED, 3);
		settings.setVector(AnimSettings.POSITION_NOISE, new Vector3f(.05f, .05f, .05f));
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 150);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .1f);

		InterpolationInfo info = ParticleSystem.calcInterpolationInfo(settings);
		
		settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK);
		UpDownSideWave wave = new UpDownSideWave(1f, .2f, 0, info, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);

		wave = new UpDownSideWave(1f, .2f, 0, info, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new UpDownSideWave(1f, .2f, (float) Math.PI, info, false);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);
		
		wave = new UpDownSideWave(1f, .2f, (float) Math.PI, info, true);
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave);
		psp.add(new ParticleSystem(settings), 0);
		return psp;
	}
}
