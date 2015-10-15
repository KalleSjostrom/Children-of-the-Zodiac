package factories;

import info.Values;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;
import organizer.Organizer;

import villages.villageStory.Parser;
import battle.bosses.BossDialog;
import battle.bosses.BossScript;
import battle.bosses.Dialog;
import battle.character.CharacterRow;
import battle.enemy.AttackInfo;
import battle.enemy.CardInfo;
import battle.enemy.EnemyAttackEffect;
import battle.enemy.EnemyInfo;
import battle.enemy.AttackInfo.Frame;
import bodies.Vector3f;
import cards.Card;
import character.Creature;
import character.Enemy;
import equipment.Slot;

public class EnemyLoader extends AbstractMapLoader {
	
	private float[] attributes = new float[14];
	private boolean attackSpec;
	private Enemy enemy;
	private EnemyInfo info = new EnemyInfo();
	private BossScript script;
	private Parser parser = new Parser();
	private String name;
	private String diesound;
	private AttackInfo attackInfo;
	private HashMap<String, Integer> triggers = new HashMap<String, Integer>();
	private HashMap<String, Integer> items = new HashMap<String, Integer>();
	private HashMap<String, Integer> cardPreferences;
	private int startFrame;

	public EnemyLoader(String name) {
		parseFile(name);
		enemy.setInfo(info);
		enemy.setDbName(Organizer.convert(name));
	}

	protected void parseFile(String filename) {
		super.parseFile(Values.EnemyMaps, filename.toLowerCase() + ".enemy");
	}

	protected void executeCommand(String command, StringTokenizer t) {
		if (attackSpec) {
			if (command.equals("}")) {
				attackSpec = false;
				info.setAttack(attackInfo);
			} else {
				executeAttackSpec(command, t);
			}
		} else {
			executeStringCommand(command, t);
		}
	}
	
	private void executeAttackSpec(String command, StringTokenizer t) {
		do {
			String[] args = Parser.getArgument(command);
			command = args[0];
			String val = args[1];
			if (command.equals("type")) {
				int type;
				if (val.equalsIgnoreCase("off")) {
					type = Slot.ATTACK;
				} else if (val.equalsIgnoreCase("mag")) {
					type = Slot.MAGIC;
				} else if (val.equalsIgnoreCase("sup")) {
					type = Slot.SUPPORT;
				} else if (val.equalsIgnoreCase("no")) {
					type = Slot.NO_TYPE;
				} else {
					type = Integer.parseInt(val);
				}
				attackInfo.setType(type);
			} else if (command.equals("name")) {
				attackInfo.setName(Organizer.convertKeepCase(val));
			} else if (command.equals("power")) {
				attackInfo.setPower(Float.parseFloat(val));
			} else if (command.equals("anim")) {
				String[] frameNames = val.split("--");
				for (String s : frameNames) {
					s = s.replace("(", "");
					s = s.replace(")", "");
					int frame = 0;
					int animTime = 100;
					int characterMode = 0;
					boolean usePreloaded = false;
					boolean defaultFrame = false;
					boolean shake = false;
					boolean cameraShake = false;
					boolean shouldHit = false;
					boolean shouldExit = false;
					boolean shouldClearSystems = false;
					boolean shouldPreload = false;
					String[] temps = s.split(",");
					String soundEffect = null;
					String startMusic = null;
					CardInfo info = null;
					float riseSpeed = 0;
					for (String temp : temps) {
						if (!temp.equals("")) {
							args = Parser.getArgument(temp);
							command = args[0];
							val = args[1];
							if (command.startsWith("f")) {
								frame = Integer.parseInt(val);
							} else if (command.startsWith("a")) {
								animTime = Integer.parseInt(val);
							} else if (command.startsWith("h")) {
								shouldHit = Boolean.parseBoolean(val);
							} else if (command.startsWith("u")) {
								usePreloaded = Boolean.parseBoolean(val);
							} else if (command.startsWith("d")) {
								defaultFrame = Boolean.parseBoolean(val);
							} else if (command.startsWith("se")) {
								soundEffect = val;
							} else if (command.startsWith("sm")) {
								startMusic = Organizer.convertKeepCase(val);
							} else if (command.startsWith("s")) {
								shake = Boolean.parseBoolean(val);
							} else if (command.startsWith("cs")) {
								cameraShake = Boolean.parseBoolean(val);
							} else if (command.startsWith("exit")) {
								shouldExit = Boolean.parseBoolean(val);
							} else if (command.startsWith("r")) {
								riseSpeed = Float.parseFloat(val);
							} else if (command.startsWith("cps")) {
								shouldClearSystems = Boolean.parseBoolean(val);
							} else if (command.startsWith("pl")) {
								shouldPreload = Boolean.parseBoolean(val);
							} else if (command.startsWith("cm")) {
								characterMode = Integer.parseInt(val);
							} else if (command.startsWith("c")) {
//								m+Earth:.9;.8;-6
								String c = null;
								Vector3f source = null;
								if (val.contains(":")) { // Has source vector
									String[] cardTemp = val.split(":");
									c = cardTemp[0];
									String v = cardTemp[1];
									String[] va = v.split(";");
									source = new Vector3f(
											Float.parseFloat(va[0]),
											Float.parseFloat(va[1]),
											Float.parseFloat(va[2]));
								} else {
									c = val;
								}
								String[] ca = c.split("\\+");
								Card card = null;
								if (ca.length == 2) {
									card = Card.createCard(Card.getPrefix(ca[0]) + ca[1], 1, false);
								} else {
									int level = Integer.parseInt(ca[1]);
									card = Card.createCard(Card.getPrefix(ca[0]) + ca[2], level, false);
								}
								info = new CardInfo(card, source);
							}
						}
					}
					Frame f = new Frame(
							frame, animTime, shouldHit, usePreloaded, 
							defaultFrame, shake, cameraShake, soundEffect,
							info, riseSpeed, shouldExit, shouldClearSystems, 
							startMusic, shouldPreload, characterMode);
					attackInfo.addFrame(f);
				}
			} else if (command.equals("onAll")) {
				attackInfo.setOnAll(Boolean.parseBoolean(val));
			} else if (command.equals("target")) {
				int target;
				if (val.equals("rand")) {
					target = CharacterRow.RANDOM;
				} else {
					target = Integer.parseInt(val);
				}
				attackInfo.setTarget(target);
			} else if (command.equals("element")) {
				int element;
				if (val.equals("neutral")) {
					element = Card.NO_ELEMENT;
				} else if (val.equals("fire")) {
					element = Card.FIRE_ELEMENT;
				} else if (val.equals("ice")) {
					element = Card.ICE_ELEMENT;
				} else if (val.equals("earth")) {
					element = Card.EARTH_ELEMENT;
				} else if (val.equals("wind")) {
					element = Card.WIND_ELEMENT;
				} else {
					element = Integer.parseInt(val);
				}
				attackInfo.setElement(element);
			} else if (command.equals("probability") || command.equals("p")) {
				attackInfo.setProbability(Float.parseFloat(val));
			} else if (command.equals("effect")) {
				attackInfo.addEffects(EnemyAttackEffect.createEffects(val));
			}
			command = null;
			if (t.hasMoreTokens()) {
				command = t.nextToken();
			}
		} while (command != null);
	}

	private void executeStringCommand(String command, StringTokenizer t) {
		if (command.equals("name")) {
			name = Organizer.convertKeepCase(t.nextToken());
		} else if (command.equals("defense")) {
			attributes[Creature.DEFENSE] = Integer.parseInt(t.nextToken());
		} else if (command.equals("trigger")) {
			String[] args = Parser.getArgument(t.nextToken());
			triggers.put(args[0], Integer.parseInt(args[1]));
		} else if (command.equals("item")) {
			String[] args = Parser.getArgument(t.nextToken());
			items.put(args[0], Integer.parseInt(args[1]));
		} else if (command.equals("diesound")) {
			diesound = Organizer.convertKeepCase(t.nextToken());
		} else if (command.compareTo("startFrame") == 0) {
			startFrame = Integer.parseInt(t.nextToken());
			System.out.println("Read start frame " + startFrame + " " + name);
		} else if (command.equals("magicDefense")) {
			attributes[Creature.MAGIC_DEFENSE] = Integer.parseInt(t.nextToken());
		} else if (command.equals("agility")) {
			attributes[Creature.AGILITY] = Integer.parseInt(t.nextToken());
		} else if (command.equals("evade")) {
			attributes[Creature.EVADE] = Integer.parseInt(t.nextToken());
		} else if (command.equals("hit")) {
			attributes[Creature.HIT] = Integer.parseInt(t.nextToken());
		} else if (command.equals("attack")) {
			attributes[Creature.ATTACK] = Integer.parseInt(t.nextToken());
		} else if (command.equals("support")) {
			attributes[Creature.SUPPORT_ATTACK] = Integer.parseInt(t.nextToken());
		} else if (command.equals("magic")) {
			attributes[Creature.MAGIC_ATTACK] = Integer.parseInt(t.nextToken());
		} else if (command.equals("hp")) {
			attributes[Creature.MAX_HP] = Integer.parseInt(t.nextToken());
			attributes[Creature.HP] = attributes[Creature.MAX_HP];
		} else if (command.equals("element")) {
			attributes[Creature. ELEMENT] = Integer.parseInt(t.nextToken());
		} else if (command.equals("gold")) {
			attributes[Creature.GOLD_SPOILS] = Integer.parseInt(t.nextToken());
		} else if (command.equals("experience")) {
			attributes[Creature.EXPERIENCE_SPOILS] = Integer.parseInt(t.nextToken());
		} else if (command.equals("criticalChance")) {
			attributes[Creature.CRITICAL_HIT_PRECENT] = Integer.parseInt(t.nextToken());
		} else if (command.equals("image")) {
			String image = t.nextToken(); 
			int nrIms = Integer.parseInt(t.nextToken());
			int[] reuseindices = new int[0]; 
			while (t.hasMoreTokens()) {
				reuseindices = add(reuseindices, 
						Integer.parseInt(t.nextToken()), 
						Integer.parseInt(t.nextToken()));
			}
			enemy = new Enemy(name, attributes, 
					Enemy.loadImages(image, nrIms, reuseindices));
			cardPreferences = new HashMap<String, Integer>();
			enemy.setTriggers(triggers);
			enemy.setItems(items);
			enemy.setDieSound(diesound);
			enemy.setStartFrame(startFrame);
			System.out.println("Set start frame " + startFrame + " " + enemy.getName());
		} else if (command.equals("cardPreference")) {
			while (t.hasMoreTokens()) {
				String card = t.nextToken();
				int percent = Integer.parseInt(t.nextToken());
				cardPreferences.put(card, percent);
			}
			enemy.setCardPreferences(cardPreferences);
		} else if (command.equals("hitFrame")) {
		} else if (command.equals("frameTimes")) {
		} else if (command.equals("armor")) {
			int armorDefense = Integer.parseInt(t.nextToken());
			int armorMagicDefense = Integer.parseInt(t.nextToken());
			enemy.setArmor(armorDefense, armorMagicDefense);
		} else if (command.equals("preferences")) {
			int attPer = Integer.parseInt(t.nextToken());
			int magPer = 0;
			if (t.hasMoreTokens()) {
				magPer = Integer.parseInt(t.nextToken()) + attPer;
			}
			enemy.setPreferences(attPer, magPer);
		} else if (command.equals("scale")) {
			float scale = Float.parseFloat(t.nextToken());
			scale /= 1000;
			info.set(EnemyInfo.SCALE, scale);
		} else if (command.equals("height")) {
			info.set(EnemyInfo.HEIGHT, Float.parseFloat(t.nextToken()));
		} else if (command.equals("middle")) {
			info.set(EnemyInfo.MIDDLE_POINT, Float.parseFloat(t.nextToken()));
		} else if (command.equals("depth")) {
			info.set(EnemyInfo.DEPTH, Float.parseFloat(t.nextToken()));
		} else if (command.equals("xoffset")) {
			info.set(EnemyInfo.X_OFFSET, Float.parseFloat(t.nextToken()));
		} else if (command.equals("attackSpec")) {
			command = t.nextToken();
			attackInfo = new AttackInfo(
					"Attack", 1, Slot.ATTACK, Card.NO_ELEMENT, false, 
					1, new ArrayList<Frame>(), CharacterRow.RANDOM);
			if (command.equals("{")) {
				attackSpec = true;
			} else {
				executeAttackSpec(command, t);
				info.setAttack(attackInfo);
			}
		} else if (command.equals("run")) {
			String[] args = Parser.getArgument(t.nextToken());
			command = args[0];
			String value = args[1];
			if (command.equals("script")) {
				script = new BossScript(value, info);
				enemy.setScript(script);
			}
		} else {
			if (command.startsWith("dialog")) {
				current.add(parser.getDialogSequence(t));
			} else {
				String[] args = Parser.getArgument(command);
				command = args[0];
				if (command.equals("end")) {
					String time = args[1];
					int i;
					if (time.equals("begin")) {
						i = BossDialog.BEGINNING;
					} else if (time.equals("endEnemyDead")) {
						i = BossDialog.ENEMY_DEAD;
						enemy.setDialog(bd);
					} else if (time.equals("endPartyDead")) {
						i = BossDialog.PARTY_DEAD;
						enemy.setDialog(bd);
					} else {
						i = Integer.parseInt(time);
					}
					bd.set(i, current);
					current = new Dialog();
				} else if (command.equals("nextPlace")) {
					String[] n = Parser.getText(t, args[1]);
					enemy.setNextPlace(n[0]);
				}
			}
		}
		
	}
	BossDialog bd = new BossDialog();
	Dialog current = new Dialog();

	public Enemy getEnemy() {
		return enemy;
	}

	/**
	 * Appends a pair of reuse indices to the given array. This method
	 * actually creates a new list, copies in the old one and appends
	 * the pair to the newly created list.
	 * 
	 * Reuse indices are pairs of indices used when images should be reused. 
	 * The first index (in a pair) is the destination index in the image array
	 * and the second is the source. The source is then soft copied to the 
	 * destination.
	 * 
	 * @param reuseindices the list to append to.
	 * @param a the destination index in the enemy texture array.
	 * @param b the source index in the enemy texture array.
	 * @return the new list with the given pair appended.
	 */
	private int[] add(int[] reuseindices, int a, int b) {
		int[] array = new int[reuseindices.length + 2];
		for (int i = 0; i < reuseindices.length; i++) {
			array[i] = reuseindices[i];
		}
		array[reuseindices.length] = a;
		array[reuseindices.length + 1] = b;
		return array;
	}
}
