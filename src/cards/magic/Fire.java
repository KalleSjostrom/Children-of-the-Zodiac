/*
 * Classname: Fire.java
 * 
 * Version information: 0.7.0
 *
 * Date: 11/11/2008
 */
package cards.magic;

import info.SoundMap;
import info.Values;
import particleSystem.ParticleSystem;
import particleSystem.ParticleSystemPacket;
import settings.AnimSettings;
import battle.Animation.AnimationInfo;
import bodies.Vector3f;
import cards.AnimationSettingsFactory;
import cards.Card;


/**
 * This class represents the Fire magic in the game. The Fire magic 
 * is a basic magic with fire attribute.
 * 
 * @author 		Kalle Sjšstršm 
 * @version 	0.7.0 - 11 Nov 2008
 */
public class Fire extends Magic {
	
	private static final String[] SHORT_INFO = {"Fire magic", ""};
	private static final String[] SOUNDS = {
		SoundMap.MAGICS_FIRE, SoundMap.MAGICS_FIRE, SoundMap.MAGICS_FIRE};
	private static final int[] DELAYS = {295, 100, 100};
	
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
		return SOUNDS;
	}

	@Override
	protected int[] getSoundEffectDelay() {
		return DELAYS;
	}

	@Override
	public ParticleSystemPacket getAnimation(AnimationInfo info) {
		info.setLevel(getLevel());
		return Fire.getStaticAnimation(info);
	}
	
	public static ParticleSystemPacket getStaticAnimation(AnimationInfo info) {
		ParticleSystemPacket psp = new ParticleSystemPacket();
		AnimSettings settings = AnimationSettingsFactory.getDefault();
		settings.setValue(AnimSettings.SPEED, 5);
		
		settings.setValue(AnimSettings.NR_PARTICLES, 200);
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000f) * .05f);
		
		if (!info.isOnEnemy()) {
			Vector3f source = info.getEnemy().getTempSource();
			settings.setVector(AnimSettings.TARGET, new Vector3f(0, -.5f, -1.1f));
			settings.setVector(AnimSettings.SOURCE, source == null ? new Vector3f(0, 0, -6) : source);
			settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z);
			// TODO: Only shadow boar should have subtractive coloring.
			settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true);
			
			float distance = .7f;
			
			switch (info.getLevel()) {
			case 3:
				settings.getVector(AnimSettings.TARGET).x -= distance;
				psp.add(new ParticleSystem(settings), 200);
				settings.getVector(AnimSettings.TARGET).x += distance;
			case 2:
				settings.getVector(AnimSettings.TARGET).x += distance;
				psp.add(new ParticleSystem(settings), 100);
				settings.getVector(AnimSettings.TARGET).x -= distance;
			case 1:
				psp.add(new ParticleSystem(settings), 0);
			}
		} else {
			float distance = 1;
			Card.setSourceTargetVectorToLength(6, settings);

			switch (info.getLevel()) {
			case 3:
				settings.getVector(AnimSettings.SOURCE).x -= distance;
				psp.add(new ParticleSystem(settings), 200);
				settings.getVector(AnimSettings.SOURCE).x += distance;
			case 2:
				settings.getVector(AnimSettings.SOURCE).x += distance;
				psp.add(new ParticleSystem(settings), 100);
				settings.getVector(AnimSettings.SOURCE).x -= distance;
			case 1:
				psp.add(new ParticleSystem(settings), 0);
			}
		}
		return psp;
	}
}
