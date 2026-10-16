# Integration and runtime testing (steps 2 and 3)

State on 2026-10-16: no `## SKELETON` files remain; `tools/check.sh` reports
`CHECKED 375 scripts, 0 failed`; the static checks below report 0 issues; every
script in `tools/autoplay/` runs without script errors.

## Static checks (beyond `tools/check.sh`)

Most variables in the port are untyped, so a wrong method name or argument count
only fails at runtime. These scripts in `tools/port/` catch the classes of bugs
found during integration (run from the project root with `python -I`):

| Script | Finds |
|---|---|
| `calllint.py . <extension_api.json>` | calls to methods that exist nowhere (user code or Godot API), wrong argument counts on known classes (`Class.m()`, `Class.new()`, `self.`, `super.`). Generate the API file with `Godot --headless --dump-extension-api` in an empty folder. |
| `superinit.py . [--fix]` | `_init` methods that never call `super(...)` although an ancestor defines `_init` (see "Constructors" below). `--fix` inserts `super()` when the ancestor accepts 0 arguments. |
| `staticinit.py .` | static initializers that read other classes' static state (see "Static initialization"). Each hit needs a manual look; most are harmless. |
| `constcheck.py src _java_reference/src ported` | constants whose sign differs from Java (the skeleton generator dropped minus signs). The remaining hits are unrelated locals with the same name. |

## Two GDScript differences that the port has to handle

**Constructors.** Godot 4.7 does *not* run the parent's `_init` when a subclass
defines its own `_init` without calling `super(...)`; Java always runs `super()`
implicitly. Every `_init` in a subclass of a class with an `_init` must call
`super(...)` first. (Found because villagers had no instructions; fixed in
Villager and four riddle mini-games.)

**Static initialization.** Godot runs `static var` initializers and
`_static_init` when the script is loaded, in dependency order, through cycles;
Java ran them on first use of the class. A static initializer that reads another
class's static var can therefore see 0/null. `Player.DIRECTIONS` used
`Values.LOGIC_INTERVAL` and was all zeros (the village player could not move); it
is now computed in the first constructor call. `Clock.DEFAULT_X_POS` had the
same problem. All other hits of `staticinit.py` were checked at runtime and have
the right values.

## Fixes made during integration (outside the units' own work)

- `villages/Villager.update(f, player, reset)`: `super.update(float(f))`, so it is
  `Sprite.update(float)` as in Java, not `InstructionFollower.update(int)`.
- `info/Database.reset()` also clears `LevelFactory.levelFactory`, so
  `levels.bank` is parsed again. Java parsed it once, so a second
  `Load.loadGame` in one session left the level table empty (deviation from Java,
  fixes level lookups after game over → load).
- `factories/Load` `counter` command: skips (with a warning) enemies that the
  bestiary does not know. The shipped saves count enemies (`dragon`) that
  `enemyBank.bank` does not define; Java threw a NullPointerException.
- `organizer/Organizer`: `getInformationFor` may return null (Java did); an unknown
  place now gives a clear error and falls back to the title screen instead of a
  crash. New field `loadSlot` implements `--load=<slot>`: the slot is loaded
  after `Values.init()` and the game starts at the saved location (unless
  `--start` is given). `Main.gd` called a non-existent `Load.getLoad()` before.
- `organizer/Cheater.getNextPlace()` returns `""` instead of null (the base
  method is typed `String`).
- `graphics/GLBackend.add_triangles`: a batch after a display-list mesh no longer
  reads the missing `mat` key (labyrinth floors spammed errors).

## Runtime test results (tools/autoplay, windowed with screenshots)

| Test | Command (after `--`) | Result |
|---|---|---|
| title → new game → opening | `--autoplay=tools/autoplay/title_start.txt`, `story_long.txt` | title, menu, Prolog sequence (≈265 s of timed text/images, START skips it as in Java) |
| opening → first labyrinth | `newgame_to_forest.txt` | Prolog → Celis Memory → Running Away → Forest of Reil; walking, minimap, rain, menu |
| village | `--load="Slot 1" --start=Alares` + `village.txt`, `village_walk.txt` | tiles, buildings, villagers walking, player walking and scrolling, party follows |
| random battle | `--load="Slot 1" --start="Forest of Reil--Forest Path-mark0"` + `battle.txt` | encounter, cards, Drain animation, damage text, enemy death, result and spoils screens (gold/exp applied) |
| boss | `--load="Slot 1" --start=Serphia` + `boss.txt` | boss dialog, transformation, attacks, slot locks, character death; one run ended in the Game Over screen (the scripted presses do not win) |
| world map / airship | `--start=landAlares` + `landscape.txt`; `--start=airAlares` | node movement along roads, labels, airship flight and landing |
| menu pages | `--start=Alares` + `menu_pages.txt` | Deck, Equip (stat compare), Key Items, Tutorial, Options, Map, Save |
| buildings | `--start=Alares` + `stores.txt` | weapon store, card store, church, inn (via the Cheater) |
| village story | `--load=Start --start="Celis Memory - Having Fun"` | grayscale memory scene with speech bubbles, night scene, continues into the labyrinth |
| save | menu → Save → Slot 1 | writes `user://saves/Slot 1.sav`; it differs from the shipped `maps/Banks/Slot 1.sav` only in the expected lines (start place, counters for enemies the old save did not know) |

Headless runs (`--headless`) behave the same except that the dummy renderer
cannot return frames: `Values.gd` grabs the screen when the menu opens and
Godot logs `Parameter "t" is null` (`texture_2d_get`) once per menu opening.
This is harmless and only happens headless.

All scripts were re-run headless as a regression pass (0 script errors). A
battle that "never ended" turned out to be the test script, not the game: when
the first card in the hand never fits a slot (Protecting Barrier), blind CROSS
presses choose nothing and every turn passes. `battle.txt` now waits for the
party's turn (`battlemode=1`) and moves past such cards.

The test saves in `maps/Banks/testStarts/` are from an older data version (their
start place "The Story of the World" is not in `main.bank`, node addresses do
not match the maps); use `Slot 1` or `Start` with `--start` instead.

## Known issues / next steps

- **Weather performance:** labyrinths with rain/snow run at ≈30 FPS (10 000
  particles per frame through GDScript + the GL emulation, `src/weather`);
  labyrinths without weather, villages, menus and the boss area run at 60 FPS.
  Battles in rainy labyrinths: 20–28 FPS. Per-frame fades assume 60 FPS, so
  they are slower there. Candidates: batch the particle quads into one
  `ArrayMesh`/`MultiMesh` per frame in the GL backend, or move the weather
  update/draw loop to typed arrays.
- Not exercised yet: level-up screen, riddle mini-games, merging cards,
  buying/selling, inn rest, all later chapters; everything ran with `--mute`.
