package battle.bosses;

import info.Values;

import java.util.ArrayList;
import java.util.StringTokenizer;

import organizer.AbstractMapLoader;
import organizer.Organizer;

import battle.enemy.AttackInfo;
import battle.enemy.EnemyInfo;
import battle.enemy.AttackInfo.AttackInfos;

public class BossScript extends AbstractMapLoader {
	
	private EnemyInfo info;
	private ArrayList<MoveList> moves = new ArrayList<MoveList>();
	private int current = 0;
	private MoveList loadList;

	public BossScript(String filename, EnemyInfo info) {
		this.info = info;
		parseFile(filename);
	}

	public Dialog getDialog() {
		return null;
	}

	public AttackInfo getMove(int lifePercent) {
		MoveList ml = moves.get(current);
		if (!ml.inRange(lifePercent)) {
			current++;
			current %= moves.size();
			return getMove(lifePercent);
		}
		return ml.next();
	}
	
	@Override
	protected void parseFile(String filename) {
		super.parseFile(Values.EnemyMaps, filename + ".script");
	}

	@Override
	protected void executeCommand(String command, StringTokenizer t) {
		if (command.equals("newList")) {
			String name = t.nextToken();
			if (name.contains("-")) {
				String[] interval = name.split("-");
				int high = Integer.parseInt(interval[0]);
				int low = Integer.parseInt(interval[1]);
				loadList = new MoveList(high, low);
			} else if (name.equals("intro")) {
				loadList = new MoveList(MoveList.INTRO);
			}
			moves.add(loadList);
			
		} else if (command.startsWith("attack")) {
			boolean onlyOnce = command.contains("Single");
			AttackInfos infos = new AttackInfos(onlyOnce);
			while (t.hasMoreTokens()) {
				String attackName = Organizer.convertKeepCase(t.nextToken());
				if (attackName.startsWith("nop")) {
					infos.add(AttackInfo.NOP);
				} else {
					infos.add(info.getAttack(attackName));
				}
			}
			loadList.moves.add(infos);
		}
	}
	
	private class MoveList {
		
		public static final int INTRO = 0;
		public static final int LIFE_PERCENT = 1;
		private static final int LOW = 1;
		private int lifeInterval[];
		private ArrayList<AttackInfos> moves;
		private int current;
		private int type;
		
		public MoveList(int high, int low) {
			this(LIFE_PERCENT);
			lifeInterval = new int[]{high, low};
		}

		public MoveList(int type) {
			moves = new ArrayList<AttackInfos>();
			current = 0;
			this.type = type;
		}

		public boolean inRange(int hp) {
			boolean inRange = false;
			switch (type) {
			case LIFE_PERCENT :
				inRange = /*hp <= lifeInterval[HIGH] && */hp >= lifeInterval[LOW];
				break;
			case INTRO :
				inRange = current < moves.size();
				break;
			}
			return inRange;
		}

		public AttackInfo next() {
			AttackInfos ais = moves.get(current);
			boolean onlyOnce = ais.shouldUseThisInfoOnlyOnce();
			AttackInfo a = ais.getRandom();
			if (onlyOnce) {
				moves.remove(current);
			} else {
				current++;
			}
			if (type == LIFE_PERCENT) {
				current %= moves.size();
			}
			return a;
		}
		
		public String toString() {
			return moves.toString();
		}
	}
}
