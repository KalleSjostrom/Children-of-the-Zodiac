# Port notes: villages

Files ported: `graphics/DoubleBackground.gd`, `graphics/Sprite2D.gd` (class
`GameSprite2D`), `villages/Village.gd`, `villages/VillageLoader.gd`,
`villages/Villager.gd`, `villages/utils/{AnimatedObjects, Dialog, PartyMember,
Player}.gd`. The files that were already ported (Animation, DialogSequence, Loot,
Obstacle, ObstacleHandler, Position, Sign, SortingElement) are unchanged.

## API notes for callers

* **Sprite maps**: Java's `HashMap<Integer, Sprite> sprites` used `hashCode()`
  keys. Here it is a `Dictionary` keyed by `get_instance_id()`. That applies to
  `Village.getVillagers()`, `addSprite`, `addVillagers`, `addOnlyVillagers`, and
  the `SortingElement` indices. Code that puts sprites into these maps must use
  `get_instance_id()` too.
* `DoubleBackground.BOTTOM_LAYER` is `-1` as in Java. The skeleton had `1`,
  which was wrong.
* The `top`/`bottom` image maps in `DoubleBackground` (Java `HashMap<int[],
  String>` with identity keys) are Arrays of `[pos, name]` pairs, in insertion
  order. Java's order was undefined.
* `DoubleBackground.init(path, name, nightLayer = null, extra = null)`: the
  2-argument form `init(name, nightLayer)` is recognised when the second
  argument is a `bool`.
* `DoubleBackground.move(a, b, duration = null)`: with 2 arguments it is
  `move(XorY, amount)`, with 3 it is `move(distance, direction, duration)`.
* `Dialog`: `draw(g)` draws the current dialog, and `draw(g, bool first, name,
  fl, sl, small)` is the public overload. Java's private `draw(g, name, fl, sl,
  int pos, small)` is reached when the second argument is not a bool; inside the
  class it is `_drawLines`. The private `drawQuestion(g, first, alt)` is
  `drawQuestion(g, first, alt)` with `title == null`, or `_drawQuestion`. The
  static `drawGift(g, first, second, loot)` is `Dialog.drawGiftStatic`.
  `Dialog.getDialog()` creates the singleton lazily.
* `Village.exit()` with no argument goes to the landscape. `exit(mode)` is
  `GameMode.exit`.
* `Village.resume()` with no argument is the Java override. With a detection
  mode it forwards to `resumeWith(...)`.
* `Villager.update(f)` with one argument is `InstructionFollower.update`.
  `update(f, player, reset)` is the Villager overload: dispatch is on
  `reset == null`.
* `Villager.loadImages(name, int nr)` is recognised by an `int` second argument.
  Otherwise the call goes to `Sprite.loadImages`.
* `Villager.checkCollision(p)` uses a max distance of 25. With more arguments it
  is the `Sprite` version.
* `PartyMember.move()` / `standStill()` with no argument use the current
  direction. With arguments they are the `Sprite` overloads.

## Local workarounds / not fully faithful

* `DoubleBackground.cutImage2`: Java cut the background into 256x256 tiles and
  also wrote them to a cache folder on disk (`<image>folder/xNyM.png`). The port
  cuts them in memory only (`Image.blit_rect`) and writes no files, because
  `res://` is read-only. When the pre-cut folders ship with the game,
  `generateNames` is used as in Java. Tiles for `TYPE_INT_RGB` are converted to
  `FORMAT_RGB8`.
* `Villager.VillagerLoader` "price" command: in Java `prices` is null until the
  first `f` line, so a `price` line before it would throw a
  NullPointerException. The port creates the array instead of crashing.
* `Villager.doCheck`: Java's `try/catch NumberFormatException` is replaced by
  `is_valid_int()`.
* `Village.drawBottom` sorts with `sort_custom` on `yPos` using a cached
  Callable, so nothing is allocated per frame. Godot's sort is not stable, so
  sprites with exactly equal y may swap draw order between frames. Java used a
  stable TimSort.
* If the sprite map and the elements array differ in size, Java would throw (or
  hit a NullPointerException). The port skips the missing entries and calls
  `push_warning`.
* `Village.init` delay thread → `Scheduler.after(delay, ...)`.
* Logger calls were removed. The "could not find in database" warnings are now
  `print`.
* `GameSprite2D` (Sprite2D) uses `GameTexture.fromImage` in place of
  `GameTexture.newTexture`.
* `DoubleBackground`'s Java static initializer
  (`addPermanentlyLoadOnUse(top/greentree.png)`) runs lazily in the first
  constructor call.

## Cross-unit notes

* `store/Door.gd` has class_name `StoreDoor`. Village and VillageLoader use
  `StoreDoor.getDoor` and `StoreDoor.FADE_*`.
* `bodies.system.ParticleSystem` is `BodiesParticleSystem`, and its
  `getName()`, `setName()`, `warmUp()`, `setActive()` and `setActivateStatus()`
  are needed. `SystemLoader.getLoader().buildSystem(name)` must return an Array.
* `sprite/InstructionFollower.gd` (another unit) must dispatch
  `move(bool reset, float elapsed)` (Java protected `move(boolean, float)`) and
  `move()` (the `Sprite.move()` overload) inside its merged
  `move(dir, anim, ia)`. Villager calls `move(reset, f)`, `move(true, t)` and
  `move()`.
* `Instruction.modifyTimeStatic(elapsed, speed)` is used for the Java static
  `Instruction.modifyTime(float, int)`.
* While one of these checks ran, an unrelated transient error appeared: "Cannot
  find member SAVE_DIR in base Save". It came from another unit and went away
  on the next run.
