---
name: village-remake
description: Turn a picture of a village (a new design of an existing place, e.g. Alares) into a playable replacement that the game loads instead of the original with --village=<remake> or the console's "village <remake>". It keeps every door, shop, church, sign, loot, spawn and villager working, with collision, an overhead (roof and treetop) layer, the night view if the place has one, new walks for walking villagers, standing villagers at their landmarks, and copies of the place's cutscenes moved to the new layout. Use when the user gives an image of a village and wants to play it in place of the original.
---

# Village remake

Input: a picture of a whole village (top-down 3/4 view, like the game's
villages) and the place it replaces (its folder in `maps/Village`, e.g.
`Alares`). Output: `proto/villages/<remake>/`, loaded by the game only when
`--village=<remake>` is given or the console's `village <remake>` is used.
The default game does not change. `proto/` is left out of the shipping
export.

Worked example: `proto/villages/alares-diorama/` (layout.json, report/). Read
its `layout.json` before writing a new one.

## How the game loads a remake (already built, don't redo)

* `scenes/villages/VillageRemake.gd`: the active remakes. `VillageScene.path_for`
  takes `proto/villages/<remake>/<Place>/<file>.tscn` when it exists;
  `VillageStoryLoader.parseFile` takes `proto/villages/<remake>/sequences/<chapter>/<name>.seq`.
* `ActorView.walk_override` / `walk`: a remake's villager starts at its node's
  position and walks `walk` (the `.char` "in" lines); its dialogs stay the `.char` file's.
* `VillageScene.entries_from` / `entries_to`: points that other places' doors
  return to (an interior's `to_pos`) are moved (`Village.resume`).

## Tools (headless Godot, from the project root)

```
G=/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe
"$G" --headless --path . --script res://tools/village_remake/remake_inventory.gd -- <Place> res://proto/villages/<remake>/report
"$G" --headless --path . --script res://tools/village_remake/remake_view.gd -- <remake> <out.png> --rect=x,y,w,h --zoom=3 --grid=10 [--layout] [--pieces] [--players=x,y;x,y]
"$G" --headless --path . --script res://tools/village_remake/remake_build.gd -- <remake>
"$G" --headless --path . --import
"$G" --headless --path . --script res://tools/village_remake/remake_check.gd -- <remake> [--probe=x,y;x,y]
```

Each takes seconds. Write view and probe pictures to the scratchpad, not the
project. Shared code: `tools/village_remake/remake_lib.gd` (rules, masks,
legacy collision, cutscene parsing), `remake_draw.gd`.

## Steps

1. **Set up.** Name the remake `<place>-<word>` in lower case
   (`alares-diorama`). Create `proto/villages/<remake>/`, copy the picture in
   as `source.<ext>` unchanged, and start `layout.json` with `place`,
   `source`, `scale` and `size`.
2. **Inventory the original.** Run `remake_inventory.gd`, then read
   `report/inventory.txt` and look at `report/inventory.png` (numbered items).
   It lists every feature key the layout must place or drop, the villagers
   (standing or walking, with their walks), the `.vil` obstacle groups (they
   name the buildings; saved in `tools/village_remake/obstacle_groups.json`
   when the `.vil` files were deleted), the cutscenes (and which villager's dialog runs each),
   the doors of other places that return into it, and related places (a
   `<Place> - …` folder without doors that shows the place, such as
   `Alares - Celis`, is a view; see step 4).
3. **Ask the user** (one AskUserQuestion, after looking at the picture):
   * **Scale.** Measure door heights in the picture with `remake_view.gd`.
     The game's characters are 36×56 and the original villages' doors are
     about 45 px tall, so `scale` = 45 / door height, rounded to a value that
     keeps pixels clean (1, 2) unless the user wants more room.
     `size` = the picture's size × scale (after `crop`, if the sky or a
     border must go).
   * **Building roles.** Which building plays which role (church, each shop,
     inn, each house with a door, the mansion of a villager who stands
     outside it). Propose a mapping from the art (signs, crests, wares).
   * **Leftovers.** Original features with no counterpart in the picture (a
     door with no house, an animated object drawn over the old art): drop them
     or put them somewhere. Say what each one does in the game.
4. **Write the layout** (format below), reading coordinates off gridded crops
   (`remake_view.gd --zoom=3 --grid=10`) and checking with `--layout`.
   Village pixels throughout; a position is a sprite's **top-left corner**,
   its feet are at +(18, 54).
5. **Build, import, check.** Iterate until the check has no FAIL. Use
   `--probe` to see which obstacle blocks a position. Look at
   `report/check.png` (red: where feet can't go; green dots: reachable feet;
   blue: overhead pieces).
6. **Play it.** Run the game with the remake and an AutoPlay script
   (`src/main/AutoPlay.gd` header has the commands; `pos` logs the player's
   position) and look at the screenshots: walking (collision, overhead over
   the player behind a building or tree), a door in and out of an interior
   (the return point), every cutscene (`--start="<cutscene>"`; a contact sheet:
   `tools/parity/contact_sheet.gd`). The scripts and shots go to the
   scratchpad. Runs must end: `quit` in the script, `--quit-after-ms`, and a
   `timeout`.
   ```
   "$G" --path . --fixed-fps 60 -- --mute --seed=1 --uncapped --village=<remake> \
       --load="Slot 1" --start=<Place> --autoplay=<script> --shots=<dir> --quit-after-ms=60000
   ```
7. **Report** what was placed where, what was dropped, the remaining check
   warnings and anything that differs from the original (moved cutscene
   steps, sign texts whose directions no longer match).

## The layout (`layout.json`)

```jsonc
{
  "place": "Alares", "source": "source.jpg", "scale": 1, "size": [1408, 768],
  // "crop": [x1, y1, x2, y2]  source pixels, before scaling
  "objects": [            // everything that stands up from the ground
    {"id": "church", "role": "Church", "poly": [[x, y], ...]},
    {"id": "tree_x", "poly": [...], "base": [[x1, y], [x2, y]], "footprint": [[x1, y1, x2, y2]], "cut": y1},
    {"id": "forest_left", "poly": [...], "solid": true, "overhead": false},
    {"id": "barrels", "rect": [x1, y1, x2, y2]}
  ],
  "blocked":  [{"poly": [...]}, {"rect": [...]}, {"flood": [x, y], "tolerance": 30, "within": [...]}],
  "walkable": [{"rect": [...]}],     // carved out of everything above
  "ground":   [{"like": [x, y], "tolerance": 40, "within": [...]}],  // never overhead (see below)
  "features": {                      // every key from the inventory
    "Doors/Church": [x, y], "Doors/cardHouse": null,
    "Actors/Uri": {"pos": [x, y]},                       // keeps its .char walk
    "Actors/Bella": {"pos": [x, y], "walk": ["1 100 false", "2 100 true", "3 100 false"]},
    "Effects/smokesystemAlares": [x, y]
  },
  "entries": [{"from": [old x, old y], "to": [x, y]}],  // the inventory's returns
  "sequences": {"<chapter>/<name>": {"offset": [dx, dy], "pos": {"<actor>": [x, y]},
                                     "replace": [["old text", "new text"]]}},
  "views": [{"place": "Alares - Celis", "origin": [x, y], "features": {...},
             "night": {"windows": [[x1, y1, x2, y2], ...], "glows": [[x1, y1, x2, y2], ...]}}]
}
```

## Collision and overhead (what the build does with an object)

An "o" rectangle blocks the player's position inflated by the sprite
(`ObstacleHandler.addObstacle`): the feet can't be in [y1, y2 + 17], the
sprite's centre not in [x1 − 9, x2 + 10]. Per column x of an object's
outline, with top(x) and base(x) its highest and lowest pixel:

* **overhead** (drawn over sprites, alpha test 0.9): its pixels above
  base(x) − 56 (above `"cut"` when given). A player in front never reaches
  them. The overhead layer is always over every sprite (the legacy draw
  order: no depth sorting), so what is overhead decides who is behind what.
* **footprint** (feet blocked): from min(top + 56, base − 56) (not above top)
  down to base. A player behind is covered by the overhead part.
* **trim**: the build takes the ground off each overhead piece: light pixels
  (road, grass) of the colours just outside the outline, flooding in from
  its edge up to 40 px and stopping at the art's outline. So draw outlines
  a few pixels *outside* the art, never inside it: what the outline leaves
  out of an object is never overhead, what it takes in of the ground is
  trimmed. Shadows stay (as dark as a canopy's edge). `"trim": false` on an
  object keeps its whole outline. Ground the trim can't reach (grass
  showing between a sign's posts, enclosed by the art) goes in `"ground"`:
  regions never overhead, usually `{"like": [x, y], "tolerance": t,
  "within": [x1, y1, x2, y2]}` (every pixel within of the colour at x, y,
  connected or not; keep the art's own colours out of the rect).

So:
* Draw a building's outline down to the wall's base, where the door meets
  its threshold. **Steps, stairs and a porch floor in front of a door are
  ground**: a player stands on them. Leave them out of the outline (notch
  it between the pillars or railings that flank the steps). The door is
  then at (door centre x − 18, wall base − 36): the feet 18 px below the
  wall's base, which is on the steps (the legacy collision keeps the feet
  17 px below an obstacle's bottom edge). An entry back out of the door
  (`entries`) goes 15 px below the door, as the original villages' do.
* An outline must be one vertical run per column. Split a forest that wraps
  around the town into masses (top, bottom: column runs; left and right edges:
  `"solid": true, "overhead": false`).
* **Trees**: give `"base"` at the trunk's foot (else a canopy's sides count
  as ground), a trunk `"footprint"` (else the whole canopy blocks, which
  closes paths between trees) and `"cut"` at the footprint's top (where the
  trunk shows under the canopy): the whole canopy is then overhead, as in
  the original villages. Without it only the canopy's top 30-odd px are,
  and a player behind the tree shows from the waist down through the
  canopy, which looks like a misaligned tree. The cost, as in the
  originals: a player right in front of the trunk has the top ~10 px of
  the head under the canopy's bottom edge. Bushes the same.
* Small props (benches, barrels, mailboxes, anvils, signs) are rects; give a
  tight `"footprint"` where a walkway runs past them. A prop shorter than a
  sprite (56 px) has no overhead, so its rect must reach the top of its art:
  a player behind it stands above the rect, and art sticking out above the
  rect gets drawn under the feet. Go over the whole picture for props:
  every boulder, stump, crate and well is an object (a rock missed in the
  first Alares remake was walked over).
* **Low parts of a building** (a fenced yard, a flower bed, a stall's side
  wings) are their own `"solid": true` objects: the computed footprint
  takes the top 56 px of an outline for a roof to stand behind, which on a
  low fence puts the feet on the fence and its yard's grass over them.
* **Roofs**: the outline must take in the whole roof, its ridge cap
  included (a gable's peak is a flat cap a few px wide, not a point): an
  outline cutting through the roof leaves tiles outside it that are never
  overhead.
* **Bridges**: keep the water `blocked` up to the deck's top edge (the
  top rail stays behind the player) and close the rail posts at the ends
  with small blocked rects. The bottom rail is an object, all of it
  overhead (`"cut"` at its bottom: nobody stands south of it) with a
  `"footprint"` from the deck's bottom edge, so the feet stay on the deck,
  just behind the rail. An arched bridge's deck is a few px narrower in the
  middle.
* Check the pieces, not just the outlines: `remake_view.gd --pieces` (the
  overhead in colour over the rest darkened: ground left in a piece shows
  bright) and `--players=x,y;...` (Kin's feet at each point, under the
  overhead as the game draws him) behind each tree, sign and building.
* Water: a `blocked` polygon (colour floods leak: water and canopy shadow
  are the same colour in AI pictures). Leave bridges out of it.
* Everything the player can't reach must be closed by objects or blocked
  regions; the map is left wherever the player crosses an edge, and the
  check lists the edges reached.

## Placing features

* **Doors**: in front of the new building's door, same radius and facing.
  Store doors (shops, church, inn) need no return point; house doors lead to
  an interior whose door returns via `entries`.
* **Signs and loot**: on the matching art (a signpost, a barrel group, a
  rock, a small tree). Loot is checked before villagers, doors and signs.
* **Spawns**: the entrance (the player comes in facing into the village) and
  any door spawn (the inn's after sleeping).
* **Standing villagers**: move with their landmark (Uri outside the mansion
  door; new = old − old landmark + new landmark), then nudge out of
  obstacles. A standing villager blocks the player within 30 px, so keep
  them out of paths narrower than about 100 px, and two of them more than
  60 px apart where the gap leads somewhere (a sign, a door): together
  they seal it. Never on a bridge's rail or in a blocked area (a garden
  bed: the check fails it); farmers stand at their field's edge (shrink
  the field's blocked rect to let the feet reach the crops). Moving a
  villager who runs a cutscene moves that cutscene's `offset` by the same
  amount.
* **Walking villagers**: a new closed walk in open ground ("in" lines:
  direction 0–3 up, right, down, left; distance; true = stand that long). The
  check traces each walk against the obstacles, but villagers walk through
  what has no collision: a walk across a bridge keeps the feet in the
  middle of the deck, not on a rail.
* Keep two villagers' sprites (36 px wide) from overlapping, walks included.

## Cutscenes

The inventory traces every cutscene's actors. Give each an `offset` that
moves its absolute positions (actor `pos`, `show`/`to` movepos) so the scene
happens around the same landmark (its runner villager's, or the entrance).
Relative moves (`dist`, `tor`, `queue`) stay as they are. The build also:
* moves a position equal to a villager's old home to its new home (walks back home);
* leaves `movepos=-1;-1` (stay put) alone.

Rules of the timeline worth knowing (the tools already follow them):
* `pos=a;b` on an actor or pos line is **y;x** for the party and villagers
  (copied index by index into `[y, x]` arrays) and x;y for extras and
  particle systems (`Sprite.setPos`); `movepos` is always x;y. Layout
  `"pos"` overrides are x, y; the build writes each line in its own order.
* A party member's `pos` is where they walk to before the cutscene starts
  (`Actor.initStartLocation`); from a villager's dialog they start where the
  player stands, from `--start`/`goto` at pos + (40, 40). In the data it is
  the talking spot next to the runner, so the runner-anchored offset keeps
  it right.
* Actor indices: villagers, then extras, then the party (Kin, Celis…), not
  file order.
* Dialog boxes (`dialog packetname=…`) wait for the action button: tap
  CROSS between shots in an AutoPlay script.
* Known, not caused by remakes: a cutscene started with `--start` that ends
  in the village, and an interior entered with the console's `goto` and then
  left, leave the village player without a position (script errors every
  frame). Test those by walking in instead.

When the offset can't fit a move (the new town is smaller), change the start
(`"pos"`) or the move (`"replace"`), keeping as much of the original
movement as fits, and say so in the report. A WARN for a few pixels of
overlap with an object the actor passes in front of or behind is fine.

## Views and night

A view place (`views`) shows part of the remake: the build cuts its
background at `origin` (the view's own size), reuses the overhead pieces and
draws a new night layer (the default layer's blue, and its window light
fading out around each window and glow) when the place is a night variant.
Its cutscenes need entries too.

* `night.windows`: lit windows, each the rect of its **panes** inside the
  frame (village pixels, x2 and y2 excluded; the flower box below is not
  part of it). Read them off a `--zoom=5 --grid=5` crop, or print the
  pixels: the glass is the darkest, coolest part. The build paints the
  glass yellow in the view's background (as the default night background
  has it) and cuts the view's own copies of the overhead pieces that cover
  a window (an inn's upper floor is in its piece); muntins, frames and
  flowers keep their colours. A rect where under a fifth of the pixels
  look like glass stops the build: it is off the window.
* `night.glows`: light without glass (a forge's fire, a lantern).

## Don't

* Edit the default scenes, `.char` or `.seq` files: the remake is a
  copy; the default game must stay as it is (parity).
* Generate art with PixelLab without the user's explicit go-ahead.
* Write whole files that other sessions may be editing (`Main.gd`,
  `GameCommands.gd`, `docs/`): targeted edits only.
