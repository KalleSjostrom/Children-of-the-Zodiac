# Port notes: story unit

Files: `src/sprite/{Sprite (already ported), DefaultSprite, Instruction, InstructionFollower, Instructions}.gd`,
`src/story/{AbstractTimeLine, ScrollableTexts, Text, TimeLineEvent, VillageStoryTimeLine}.gd`,
`src/villages/villageStory/{Actor, DialogPackage, Parser, VillageStory, VillageStoryLoader}.gd`.
`tools/check.sh src/story src/villages/villageStory src/sprite` reports 0 failed.

## API notes for callers

- **InstructionFollower.update(f, ...)**: Java has two overloads, `Sprite.update(float)` and
  `InstructionFollower.update(int)`. The int one runs the time through `instruction.modifyTime`.
  The port picks one by the runtime type: an `int` goes to the InstructionFollower version and a
  `float` to the plain Sprite version.
- **InstructionFollower.move(dir, anim, ia)**: when `dir` is a bool it runs Java
  `move(boolean reset, float elapsedTime)`. When `dir` is a float and `anim` an int it runs the
  private `move(float distance, int direction)`. Any other call goes to the inherited Sprite
  overloads, including `move()` with no arguments.
- `Instruction(int dir)` creates a dialog instruction and `Instruction(String dir, standStill, dist, speed)`
  is the other constructor; they share one `_init`. The static `modifyTime(float, int)` is `modifyTimeStatic`.
- The static `DefaultSprite.reset()` is `resetStatic()`. The skeleton had `VILLAGER_LAYER = 1`;
  it is fixed to the Java value `-1`.
- `Instructions.getInstruction(index = null)`: `null` means the current index.
- `Actor`: the constructor takes a Sprite, or `(String path, int images)`. The 3-argument and
  4-argument `move` share one method (with 3 arguments, the third is the duration). The field
  `animate` is `animate_`.
- `Parser`: the instance `getText(tok)` is `getTextObject(tok)`. The private `getDialogPackage`
  is `_getDialogPackage`. `getLongPos` returns `null` or `[y, x, angle]`.
- `Text(fr = null, sr = null)`; `draw(g)` draws with the fade value, `draw(g, alpha)` with the given alpha.
- `VillageStoryTimeLine.init(story)` (skeleton signature `init(name, lab, hinders)`, only the first
  argument is used). `VillageStory.init(info)` works the same way.
- `VillageStoryLoader.parseFile(name)` with one argument loads `Values.StorySequences + name + ".seq"`.
  The field `newVillageInfo` is `newVillageInfo_`.

## Deviations / workarounds

- `VillageStoryTimeLine.setMusicMode`: the Java thread that created and started the
  `OggStreamer` now runs synchronously, as PORTING section 5 says for loading threads.
- Semaphores (`AbstractTimeLine.modeAccess`, `crossAccess`) are removed.
- `Arrays.sort` is a stable sort in Java. The time line events and the actor SortingElements are
  sorted with a local stable sort (`VillageStoryTimeLine._stableSort`), so events that share a
  timestamp keep their file order.
- The inner class `ImageSettings` reads the outer `currentImage`. It gets a `timeLine` field,
  set right after construction.
- `setVillagers`: the villager map is a Dictionary keyed by instance id, not a Java HashMap
  keyed by hashCode. Its iteration order (insertion order) can differ from Java's, which only
  matters when two villagers match the same actor name.
- `VillageStoryLoader`: Java's second `"set"` branch (drawpause) can never be reached and is left out.
- `Parser.error` reports through `push_error` and does not exit the game; this behaviour was
  already in the framework part.
- `currentImage.equals("black")` (an ImageSettings compared with a String, always false in Java)
  is dropped from the code, with the same result.
- `ImageSettings.draw` ignored `scroll` in Java, so `scrollmode=right` and `scrollmode=down`
  never moved the image. Since COTZ-020 the image is drawn moved by the scroll (`drawPos`, also
  for the scene's image entry), `scrollSpeed` per `ORIGINAL_FRAME_MS` of elapsed time (the
  original's ~30 FPS, which the sequences are timed to), and the right scroll stops at the image's
  right edge. The zoom mode's `zoom` and offsets are still read by nothing, as in Java.
- `ScrollableTexts.update` (the credits) moved `speed` per update in Java; the port moves it per
  `ORIGINAL_FRAME_MS` of elapsed time, like `ImageSettings`, so at 60 FPS it is not twice as
  fast. "Ending - Part 3" ended with `endseq` ~22 minutes in (a music fade-out at
  `timea=1200000`); it now ends right after "The end." scrolls off (~246 s).

## Cross-unit issues

- `src/villages/Villager.gd` `update(f, player, reset)` calls `super.update(f)`. In Java this goes
  to `Sprite.update(float)`, with no time modification. `Village.checkVillagers` passes an int,
  so in the port it lands in `InstructionFollower.update(int)` and the animation runs faster or
  slower depending on the instruction speed. Fix in Villager.gd: `super.update(float(f))` in that
  branch, but keep `updateVillager` passing an int.
