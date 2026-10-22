# Porting guide: Java (JOGL) → Godot 4.7 GDScript

This project is a file-by-file port of *Children of the Zodiac*. The Java
reference is `_java_reference/src/` (the last commit of the original that
compiled; **always port from there**, not from any other copy). Every Java
class becomes one GDScript file at the same relative path under `src/`
(`_java_reference/src/battle/Battle.java` → `src/battle/Battle.gd`).

The goal is a **faithful** port: same logic, same numbers, same names, so the
game behaves like the original. Do not redesign, simplify or "Godot-ify"
gameplay code. Where Java needs a different construct in GDScript, use the
mappings below.

**Scope (since the modernization, `docs/MODERNIZATION_PLAN.md`):** these
rules apply to the legacy code, i.e. the ported files under `src/` and edits
to them. New code (scenes, resources, converters, tools, and the bridge
members added to legacy classes) follows `docs/ARCHITECTURE.md` instead. The
"Do not" list in section 8 was written for the porting agents; changes for
the modernization may touch any file, but keep the Java names and structure
of the legacy files they touch.

## 1. What already exists

* **Framework (hand written, do NOT edit)** — `src/graphics/{Graphics, GLBackend,
  GameTexture, ImageHandler, GraphicHelp, ImageGraphics, JColor, Utils3D,
  Object2D, TimeHideable}.gd`, `src/organizer/{GameCore, Organizer, GameMode,
  MenuStarter, SubGameMode, GameModeQueue, GameEventListener, AbstractMapLoader,
  ResourceLoader}.gd`, `src/input/*.gd`, `src/sound/{OggStreamer, SoundPlayer,
  SoundValues}.gd`, `src/info/{Values, BattleValues, SoundMap}.gd`,
  `src/story/Fadeable.gd`, `src/battle/Hideable.gd`, `src/util/*.gd`,
  `src/main/*.gd`. Read these files: they document the API you call.
  If you need something the framework lacks, write a local helper in your own
  file and mention it in your notes (section 9).
* **Skeletons** — every other class already has a generated file starting with
  `## SKELETON:`. It declares `class_name`, `extends`, constants, fields, inner
  classes and **method signatures**. You replace the skeleton with the real
  port (remove the `## SKELETON` line when done).
* `villages/villageStory/Parser.gd` is partially done (static helpers); the
  villages/story unit completes it.
* `docs/class_map.tsv` — Java class → GDScript class name → file.
* `docs/skeleton_report.md` — every place where names differ from Java
  (renamed methods/fields/inner classes, merged overloads). Check it whenever
  you call into another package.

Not ported at all (Godot replaces them): `organizer.Game/GraphicUI/Screen/
FPSAnimator`, `graphics.ImageLoader/TextManager`, `sound.ALWrapper/
CachedUrlStream/OggDecoder/VorbisInputStream/Sound`,
`input.DefaultControllerEnvironment`, `MapChecker`, `s`.

## 2. Names and signatures (most important rules)

1. **Keep every Java name**: class names per `class_map.tsv`; method, field,
   constant, parameter and local names exactly as in Java (camelCase). Other
   units call your code using the Java names; they cannot see your file.
2. **Keep the skeleton's method signatures verbatim** (name, number of
   parameters, which ones have defaults, and any type annotations that are
   there). You may rename parameters. Do not add/remove parameters and do not
   add parameter types to methods that are overridden or that override (other
   files depend on the exact signature). The skeleton already merged Java
   overloads across the whole inheritance family.
3. **Overloads** (GDScript has none): all Java overloads of a name are ONE
   method with the skeleton's parameter list. Inside, dispatch on which
   optional arguments are `null` and on their types (`x is String`,
   `x is int`, `x is float`, `x is Array`, `x is Image`, `x is SomeClass`).
   Example — Java `draw(Graphics g)` + `draw(Graphics g, float alpha)` →
   `func draw(g, alpha = null):` and `if alpha == null: ...`. Constructors:
   `_init(a = null, b = null)` dispatching the same way. Callers simply call
   with the Java arguments.
4. Renames applied everywhere (also listed in `skeleton_report.md`):
   * Methods named `get`, `set`, `call`, `connect`, `disconnect`, `free`,
     `notification` → `get_`, `set_`, `call_`, … (Object methods).
   * `toString()` → `_to_string()` (callers: `str(x)`); static `toString(...)`
     keeps its name.
   * A static method with the same name as an instance method in the class
     family → `<name>Static`.
   * A field with the same name as a method → `<field>_`. A field hiding a
     field of a parent class → `<field>_` (it is a different variable in Java).
   * Fields/params named like GDScript keywords (`var`, `in`, `class`,
     `match`, `signal`, `script` ...) → `<name>_`.
   * Inner classes that would shadow a Godot or global class → `<Outer><Name>`.
   * Framework renames: see section 4.
5. Abstract methods: implement with `pass` (or the Java default) in the base.
   Interfaces (`BattleStarter`, `LabyrinthDrawable`, `SystemDrawable`,
   `VectorEquation`) exist as classes but implementing classes do not extend
   them; replace `x instanceof Iface` with `x.has_method("someMethod")`.
6. Inner classes: GDScript inner classes cannot see the outer instance. Pass
   the outer object explicitly (e.g. `Inner.new(self, ...)`) when Java code
   relies on it. Anonymous classes → Callables/lambdas or a small inner class.
7. Never redeclare in a subclass a member that a parent declares (GDScript
   error). Static and instance members cannot share a name.
8. Constructors: Godot does **not** call the parent's `_init` when a subclass
   defines `_init` without `super(...)` (Java always runs `super()`). Start
   every subclass `_init` with `super(...)` (`tools/port/superinit.py` checks
   this).

## 3. Java → GDScript mapping

| Java | GDScript |
|---|---|
| `int`, `long`, `short`, `byte`, `char` | `int` (declare typed: `var x: int = 0`) |
| `float`, `double` | `float` (**always type float variables**: an untyped `var x = 0` is an int and `x / 2` becomes integer division) |
| `boolean` / `String` | `bool` / `String` |
| arrays `T[]`, `T[][]` | untyped `Array` (reference semantics like Java). `new int[n]` → `J.array(n, 0)`, `new float[a][b]` → `J.array2d(a, b, 0.0)`. **Never Packed*Array** for data that Java shares/mutates. |
| `ArrayList`, `LinkedList`, `Stack`, `Queue` | `Array` (`add`→`append`, `get(i)`→`[i]`, `remove(int)`→`J.removeAt`, `remove(Object)`→`J.removeValue`, `size()`→`size()`, `isEmpty()`→`is_empty()`, `contains`→`has`, `indexOf`→`find`, `push`→`append`, `pop`→`pop_back()`, `peek`→`back()`, `clear`→`clear()`, `add(0, x)`→`insert(0, x)`) |
| `HashMap`, `ConcurrentHashMap` | `Dictionary` (`get(k)`→`.get(k)` (null if missing), `put`→`d[k] = v`, `containsKey`→`has`, `keySet()`→`keys()`, `values()`→`values()`, `remove`→`erase`) |
| `Iterator` loops | `for k in dict:` / `for x in array:`; when removing while iterating, iterate over `.duplicate()` |
| `String.equals` / `equalsIgnoreCase` | `==` / `a.to_lower() == b.to_lower()` |
| `s.length()`, `charAt(i)` | `s.length()`, `s[i]` (a 1-char String) or `s.unicode_at(i)` (int, for char arithmetic) |
| `substring(a[, b])` | `J.substring(s, a[, b])` |
| `split(regex[, n])` | **`J.split(s, regex[, n])`** (Java semantics: regex, trailing empty strings dropped). Do not use GDScript `split` for ported code. |
| `startsWith` / `endsWith` / `contains` / `indexOf` / `lastIndexOf` | `begins_with` / `ends_with` / `contains` / `find` / `rfind` |
| `trim`, `toLowerCase`, `toUpperCase`, `replace` | `strip_edges()`, `to_lower()`, `to_upper()`, `replace()` |
| `Integer.parseInt`, `Float.parseFloat`, `Boolean.parseBoolean` | `J.parseInt`, `J.parseFloat`, `J.parseBoolean` |
| `String.valueOf(x)`, `"" + x`, `Integer.toString` | `str(x)` (string concatenation with numbers needs `str()`) |
| `String.format("%d %.1f", a, b)` | `"%d %.1f" % [a, b]` |
| `StringTokenizer` | `StringTokenizer` (`src/util`, same API) |
| `StringBuffer`/`StringBuilder` | `String` (`+=`) |
| `Math.round(f)` | `J.round(f)` (returns int, rounds half up) |
| `(int) f` | `int(f)` |
| `Math.floor/ceil/sqrt/pow/abs/min/max/sin/cos/atan2` | `floor/ceil/sqrt/pow/abs/min/max/sin/cos/atan2` (`floori`, `absi`, `mini`, … when ints are needed) |
| `Math.PI`, `Math.toRadians/toDegrees` | `PI`, `deg_to_rad`, `rad_to_deg` |
| `Math.random()`, `new Random()`, `rand.nextInt(n)` | `J.random()`, `JRandom.new()`, `rand.nextInt(n)` (`Values.rand` is a `JRandom`) |
| `Collections.shuffle(list)` | `J.shuffle(list)` |
| `Collections.sort(list, cmp)` | `list.sort_custom(func(a, b): return cmp(a, b) < 0)` |
| `System.arraycopy`, `Arrays.fill`, `Arrays.copyOf` | `J.arraycopy`, `J.fill`, `.duplicate()` / `slice()` |
| `Integer.MAX_VALUE` etc. | `J.INT_MAX`, `J.INT_MIN`, `J.FLOAT_MAX` |
| `System.currentTimeMillis()` | `J.currentTimeMillis()` (or `Time.get_ticks_msec()`) |
| `x instanceof C` | `x is C` |
| `obj.getClass().getName()` / `Class.forName(n).newInstance()` | `ClassRegistry.getClassName(obj)` / `ClassRegistry.newInstance(n)` (Java names, e.g. `"cards.offense.BattleCard"`) |
| `switch` | `match` (no fall through! duplicate the code or use `if`/`elif` for fall-through cases; `case A: case B:` → `A, B:`) |
| `do { } while (c);` | `while true:` … `if not c: break` |
| `for (int i = a; i < b; i++)` | `for i in range(a, b):` (careful when the loop variable is modified inside or used after the loop: use `while`) |
| `x++` inside expressions, `a = b = c` | split into separate statements |
| `cond ? a : b` | `a if cond else b` |
| `static { … }` | `static func _static_init() -> void:` |
| `static final` primitive/String | `const` (arrays and objects: `static var`, consts are read-only) |
| `java.awt.Color` | `Color`; use **`JColor`** constants (`JColor.WHITE`, `JColor.darkGray`, …) — Godot's own color constants have different values. `new Color(int r,g,b)` → `Color8(r, g, b)`, `new Color(float…)` → `Color(r, g, b)` |
| `Point2D.distance(x1, y1, x2, y2)` | `Vector2(x1, y1).distance_to(Vector2(x2, y2))` |
| `BufferedImage` | `Image` (`getWidth()` → `get_width()`, `getRGB` → `get_pixel`, `new BufferedImage(w, h, …)` → `GraphicHelp.createImage(w, h)`) |
| `Graphics2D g = img.createGraphics()` | `var g := ImageGraphics.new(img)` (setColor, setFont, drawString, fillRect, drawImage) — then `ImageHandler.updateImage(img)` or `GameTexture.updateImage` |
| `Logger`, `logger.log(...)` | remove (or `print` for important info) |
| `System.out.println` | `print` (remove noisy debug prints) |
| `System.exit(n)` | `assert(<what must hold>, "<message>")` plus a guard for release builds; the game's code never quits (`GameCore.exitGame()` is only the player's Escape) |
| `try/catch` | remove; validate instead (`push_error` for unexpected states) |
| `synchronized`, `volatile`, `Semaphore` | remove |
| Threads (`new Thread(){run(){…}}.start()`, `Values.sleep` in threads) | see section 5 |
| `this.x = x` | `self.x = x` (parameters shadow members) |

Calling a method of your own class whose name equals a GDScript builtin
(`load`, `print`, `str`, `range`, `min`, `max`, `round`, `abs`, `hash`, ...)
must be written `self.load()`; unqualified calls go to the builtin.

Typing: give primitive members, locals and parameters (where the skeleton
allows) explicit types (`int`, `float`, `bool`, `String`). Object references
may stay untyped. Keep return types off methods that are overridden unless the
framework base declares one.

## 4. Framework API notes

**Time**: `update(elapsedTime)` receives **milliseconds** (as the original);
`draw(g)` has no time argument; the game runs at 60 FPS (`Values.FPS`) and
per-frame logic in `draw` (fades) relies on that.

**Coordinates**: `Values.createNormalPoint(x, y)` returns `[y, x]`
(`Values.X == 1`, `Values.Y == 0`). Keep using `pos[Values.X]`.
2D drawing uses the original 1024×768 space, y down.

**Graphics (`g`)** emulates the original `graphics.Graphics` *and* the JOGL
`GL2`/`GLU` objects:
* All original methods exist with the same names: `drawImage`, `drawTexture`,
  `drawCenteredImage`, `drawi/drawip/drawipp/drawf/draw3f`, `drawString`,
  `drawWithShadow`, `drawValueWithShadow`, `drawStringRightAligned`,
  `startText/finishText/drawMultiString`, `drawSingleCenteredText`,
  `drawMultiCenteredText`, `Graphics.calcAlignCenter/calcAlignRight/
  getStringWidth` (static), `Graphics.setTextColor` (static),
  `setTextColorAndApply`, `setFontSize(size[, bold])` (even sizes 20–50),
  `setColor(...)`, `setImageColor`, `setFadeColor`, `dim`, `fade`,
  `fadeOldSchool`, `Graphics.setFadeImage`, `scale`, `translate`, `rotate`,
  `push/pop`, `loadIdentity`, `beginQuads/end`, `setBlendFunc`,
  `beginBlend/endBlend`, `setAlphaFunc`, `setTextureEnabled`,
  `setLightEnabled`, `setDepthTestEnabled`, `setAlphaTestEnabled`,
  `setCullFaceEnabled`, `drawGradient`, `generateList/compileDrawList/endList/
  callList/deleteList`, `copyFrame`. `get(String[][])` is `get_()`.
* `setColor`/`setImageColor`/`dim` set the GL current color, which tints
  images and quads. Text uses `Graphics.setTextColor` and ignores the matrix.
* Raw GL: `GL2 gl = g.getGL()` → `var gl := g.getGL()` (returns the Graphics);
  then `gl.glBegin/glEnd/glVertex2i/glVertex2f/glVertex3f/glTexCoord2f/
  glTexCoord2i/glNormal3f/glColor3f/glColor4f/glColor4fv/glEnable/glDisable/
  glBlendFunc/glAlphaFunc/glDepthMask/glPushMatrix/glPopMatrix/glTranslatef/
  glRotatef/glScalef/glLoadIdentity/glMatrixMode/glLightfv/glLightf/
  glMaterialfv/glMaterialf/glFogf/glFogfv/glClearColor/glClear/glHint/
  glPushAttrib/glPopAttrib/glCallList/glNewList/glEndList/glGenLists`,
  `gluDisk`, `gluSphere`, `gluNewQuadric` work as in OpenGL 2.
  `Graphics.gl` / `Graphics.glu` hold the active Graphics (use at call time,
  never in static initializers). GL constants: `GL2.GL_QUADS` →
  `Graphics.GL_QUADS` (all used constants exist).
* Projection: `GameEventListener.set2DNow(g)` / `set3DNow(g)` switch
  immediately; `GameEventListener.set2D()/set3D()` choose the projection at
  the start of the next frames (Organizer does this per mode).
* JOGL `Texture` → **`GameTexture`** (it is both): `ImageHandler.getTexture(n)`
  returns a GameTexture; `.getTexture()` returns itself; `.bind(g)`,
  `.getImageTexCoords()` (left/right/top/bottom), `.getWidth()`,
  `.getHeight()`, `.getData()` (Image), `.updateImage(gl, img)`,
  `.draw(g, x, y[, scale])`. `AWTTextureIO.newTexture(..., image, ...)` →
  `GameTexture.fromImage(name, image)`.
* Images: `ImageHandler.getImage(path[, name])` → `Image`;
  `addToCurrentLoadNow/addPermanentlyLoadNow/...` return the name (loading is
  synchronous); `GraphicHelp.toGrayScale/scaleImage/getImage/createImage`.

**Object2D/Hideable**: Java's protected `Object2D.draw(g, texIndex, coordIndex
[, drawFront])` is `drawTex(...)`; `TimeHideable.hide(int time)` is
`hideFor(time)`; `Hideable`'s protected field `shouldTranslate` is
`shouldTranslate_`.

**GameMode**: the protected `init(info, detectMode[, music])` is
`initGameMode(info, detectMode[, music])` (subclasses override `init(...)` with
the skeleton signature and call `initGameMode`). The protected
`resume(detectionMode[, …])` variants are `resumeWith(...)`;
`setSuspended`, `switchGameMode`, `setMusicMode` take the Java arguments.
`enterMenu()` returns an `Image`. `MenuStarter.enterMenu` flag field is
`enterMenuQueued`.

**Parser** (`villages.villageStory.Parser`): the static `getText(tok, first)`
keeps its name; the Java *instance* method `getText(StringTokenizer)` is
`getTextObject(tok)`.

**Loading data files**: `GameResourceLoader.getResourceLoader()` replaces
`ResourceLoader.getResourceLoader()` (class renamed). Use
`getBufferedReader(path, filename)` (`readLine()` returns `null` at end),
`GameResourceLoader.readText(path)`, `.resolve(path)` (→ `res://` path or
`""`), `.fileExists(path)`, `.listFiles(dir)`, `.listDirectories(dir)`
(replacements for `java.io.File.list()`). Paths are the Java ones
(`Values.VillageMaps + name + ".vil"`), resolved case-insensitively.
`AbstractMapLoader` subclasses override
`func parseFile(path: String, filename: String = "")`; when `filename` is
`""` the single Java argument (the file name) is in `path`.

**Writing files** (saves): only under `user://` (e.g. `user://saves/`), with
`FileAccess`. Reading the shipped `.sav` files under `maps/` stays read-only.

**Sound**: `SoundPlayer.playSound(name)`, `playSoundWithRandom`;
`OggStreamer` (music) keeps its API (`mute()` is `mute_()`).

**Input**: `gameActions[GameMode.CROSS].isPressed()` etc. as in Java;
`GameAction` constants and behaviors are unchanged.

## 5. Threads and waiting

The main loop must never block. Replace Java threads:
* `new Thread(){ run(){ Values.sleep(t); doX(); } }.start()` →
  `Scheduler.after(t, func(): doX())`.
* `while (cond) Values.sleep(n); doX();` in a thread →
  `Scheduler.waitUntil(func(): return not cond, func(): doX())`.
* A thread body with several sleeps/loops → a function using
  `await Scheduler.sleep(ms)`, called **without** `await` (it runs as a
  coroutine).
* Loading threads → just run the code synchronously, then set
  `logicLoading = false`.
* `Values.sleep()` blocks the whole game; only keep it where the original
  blocked the main loop for a few ms. Never wait in a loop for something the
  main loop updates (music fades, input, timers) — it would hang.

## 6. Static initialization

Static variables initialize when their script is loaded. Do not call into
other classes' *static state* from a static initializer if those classes may
not be initialized yet (cycles); prefer lazy initialization
(`static func getX(): if _x == null: _x = ...; return _x`) or
`_static_init()`. Never use `Graphics.gl` in static initializers.

Godot runs static initializers when the script *loads* (through dependency
cycles), Java on first *use*: a `static var`/`_static_init` that reads another
class's static var may see 0/null (e.g. `Values.LOGIC_INTERVAL`). Compute such
values on first use instead (`tools/port/staticinit.py` lists candidates).

## 7. Validation (required)

Run `tools/check.sh src/<your folder> …` (bash) from the project root after
writing files. It refreshes Godot's class cache and compiles the given
scripts, printing errors. It takes a lock, so it may wait for other agents.
* Fix every error located in your files.
* `Failed to compile depended scripts` / `Could not resolve class X` caused by
  a file of another unit being mid-edit: ignore, re-check later.
* Write each file completely in one go (other agents compile against it).
* At the end, `tools/check.sh src/<your folders>` must report 0 failed.
* A clean compile does not prove calls are right (most variables are
  untyped). `tools/port/calllint.py` checks method names and argument counts
  across files; see `docs/port_notes/integration.md`.

## 8. Do not

* Do not edit files outside your unit (framework, other packages, docs other
  than your notes file).
* Do not change skeleton signatures of methods (see 2.2) or class names.
* Do not run the game or Godot editor besides `tools/check.sh`.
* Do not leave `## SKELETON` markers in files you ported.

## 9. Notes file

Write `docs/port_notes/<unit>.md` with: anything callers must know (renamed
or behaviorally different APIs), framework features you needed and the local
workaround, parts you could not port faithfully and why, and TODOs.
