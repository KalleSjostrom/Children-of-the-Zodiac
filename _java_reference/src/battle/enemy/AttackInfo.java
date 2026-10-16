package battle.enemy;

import info.Values;

import java.util.ArrayList;

import particleSystem.ParticleSystemPacket;
import battle.Animation;
import battle.character.CharacterRow;
import cards.Card;
import equipment.Slot;

public class AttackInfo {

	public static final AttackInfo NOP = 
		new AttackInfo("nop", 0, Slot.NO_TYPE, Card.NO_ELEMENT, 
				false, 0, null, CharacterRow.NO_TARGET);
	
	private String name;
	private float power;
	private float probability;
	private int type;
	private int element;
	private int target;
	private boolean isAll;
	private ArrayList<Frame> frames;
	private ArrayList<EnemyAttackEffect> effects = new ArrayList<EnemyAttackEffect>();

	public AttackInfo(
			String name, float power, 
			int type, int element, boolean isAll, float probability, 
			ArrayList<Frame> frames, int target) {
		this.name = name;
		this.power = power;
		this.type = type;
		this.element = element;
		this.isAll = isAll;
		this.probability = probability;
		this.frames = frames;
		this.target = target;
	}

	public ArrayList<Frame> getFrames() {
		return frames;
	}

	public int getType() {
		return type;
	}

	public String getName() {
		return name;
	}
	
	public float getPower() {
		return power;
	}
	
	public int getElement() {
		return element;
	}
	
	public int getTarget() {
		return target;
	}

	public boolean isAll() {
		return isAll;
	}

	public float getProbability() {
		return probability;
	}
	
	public ArrayList<EnemyAttackEffect> getEffects() {
		return effects;
	}
	
	// Setters //
	
	public void setElement(int element) {
		this.element = element;
	}
	
	public void setType(int type) {
		this.type = type;
	}

	public void setName(String name) {
		this.name = name;
	}

	public void setPower(float power) {
		this.power = power;
	}

	public void addFrame(Frame f) {
		frames.add(f);
	}

	public void setOnAll(boolean onAll) {
		this.isAll = onAll;
	}

	public void setTarget(int target) {
		this.target = target;
	}

	public void setProbability(float probability) {
		this.probability = probability;
	}
	
	public void addEffects(ArrayList<EnemyAttackEffect> effects) {
		this.effects.addAll(effects);
	}

	public String toString() {
		return "[AttackInfo=(" +
				"Name=" + name +
				" Power=" + power +
				" Type=" + type +
				" Element=" + element +
				" Is all=" + isAll +
				" Probability=" + probability +
				" Frames=" + frames +
				" Effects=" + effects +
				" Target=" + target + ")]";
	}
	
	public static class AttackInfos {
		
		private ArrayList<AttackInfo> infos = new ArrayList<AttackInfo>();
		private boolean useThisInfoOnlyOnce;
		
		public AttackInfos(boolean onlyOnce) {
			useThisInfoOnlyOnce = onlyOnce;
		}

		public void add(AttackInfo info) {
			infos.add(info);
		}
		
		public AttackInfo getRandom() {
			int index = Values.rand.nextInt(infos.size());
			return infos.get(index);
		}

		public boolean shouldUseThisInfoOnlyOnce() {
			return useThisInfoOnlyOnce;
		}
	}
	
	public static class Frame {
		
		private int frame;
		private int animTime;
		private boolean usePreloaded;
		private boolean defaultFrame;
		private boolean shake;
		private boolean cameraShake;
		private boolean hitFrame;
		private String soundEffect;
		private CardInfo cardInfo;
		private float riseSpeed;
		private boolean shouldExit;
		private boolean shouldHit;
		private boolean shouldClearSystems;
		private boolean shouldPreload;
		private String startMusic;
		private int characterMode;
		
		public Frame(int frame, int animTime, boolean shouldHit, boolean usePreloaded, 
				boolean defaultFrame, boolean shake, boolean cameraShake, 
				String soundEffect, CardInfo cardInfo, float riseSpeed,
				boolean shouldExit, boolean shouldClearSystems, 
				String startMusic, boolean shouldPreload, int characterMode) {
			this.frame = frame;
			this.animTime = animTime;
			this.shouldHit = shouldHit;
			this.usePreloaded = usePreloaded;
			this.defaultFrame = defaultFrame;
			this.shake = shake;
			this.cameraShake = cameraShake;
			this.soundEffect = soundEffect;
			this.cardInfo = cardInfo;
			this.riseSpeed = riseSpeed;
			this.shouldExit = shouldExit;
			this.shouldClearSystems = shouldClearSystems;
			this.startMusic = startMusic;
			this.shouldPreload = shouldPreload;
			this.characterMode = characterMode;
		}
		
		public int getFrame() {
			return frame;
		}

		public int getAnimTime() {
			return animTime;
		}
		
		public boolean isHistFrame() {
			return hitFrame;
		}

		public boolean usePreloaded() {
			return usePreloaded;
		}

		public boolean isDefault() {
			return defaultFrame;
		}
		
		public boolean shouldShake() {
			return shake;
		}
		
		public boolean shouldCameraShake() {
			return cameraShake;
		}
		
		public String getSoundEffect() {
			return soundEffect;
		}
		
		public boolean playSoundEffect() {
			return soundEffect != null;
		}
		
		public boolean shouldSwitchMusic() {
			return startMusic != null;
		}
		
		public String toString() {
			return "(f="+frame+",a"+animTime+",p"+usePreloaded+",d"+defaultFrame+",s"+shake+",se"+soundEffect+")";
		}

		public ParticleSystemPacket getCardSystem(BattleEnemy enemy, int target) {
			Card c = cardInfo.getCard();
			enemy.setTempSource(cardInfo.getSource());
			boolean onEnemy = c.getClass().getName().contains("support");
			Animation.AnimationInfo info = new Animation.AnimationInfo();
//			1, 0, onEnemy, false, enemy, null);
			info.setTarget(target);
			info.setEnemy(enemy);
			info.setOnEnemy(onEnemy);
			return c.getAnimation(info);
		}

		public boolean hasCard() {
			return cardInfo != null;
		}

		public Card getCard() {
			return cardInfo.getCard();
		}

		public float getRiseSpeed() {
			return riseSpeed;
		}

		public boolean shouldRise() {
			return riseSpeed != 0;
		}

		public boolean shouldExit() {
			return shouldExit;
		}

		public boolean shouldHit() {
			return shouldHit;
		}

		public boolean shouldClearSystems() {
			return shouldClearSystems;
		}

		public String getMusic() {
			return startMusic;
		}

		public boolean shouldPreload() {
			return shouldPreload;
		}

		public int characterMode() {
			return characterMode;
		}
	}
}
